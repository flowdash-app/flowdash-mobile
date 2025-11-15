import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_local_datasource.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_remote_datasource.dart';
import 'package:flowdash_mobile/features/instances/data/models/instance_model.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:flowdash_mobile/features/instances/domain/repositories/instance_repository.dart';
import 'package:logging/logging.dart';

class InstanceRepositoryImpl implements InstanceRepository {
  final InstanceRemoteDataSource _remoteDataSource;
  final InstanceLocalDataSource _localDataSource;
  final AnalyticsService _analytics;
  final LocalStorage _localStorage;
  final Logger _logger = AppLogger.getLogger('InstanceRepositoryImpl');

  InstanceRepositoryImpl({
    required InstanceRemoteDataSource remoteDataSource,
    required InstanceLocalDataSource localDataSource,
    required AnalyticsService analytics,
    required LocalStorage localStorage,
  }) : _remoteDataSource = remoteDataSource,
       _localDataSource = localDataSource,
       _analytics = analytics,
       _localStorage = localStorage;

  @override
  Future<List<Instance>> getInstances({CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_instances');
    trace?.start();

    _logger.info('getInstances: Entry');

    try {
      // Try local cache first (for optimistic updates)
      final cached = await _localDataSource.getInstances();
      // Only use cache if it exists and is not empty
      // Empty cache might mean no instances were set up yet
      if (cached != null && cached.isNotEmpty) {
        _logger.info('getInstances: Success (cached)');
        await _analytics.logSuccess(action: 'get_instances', parameters: {'source': 'cache'});
        trace?.stop();
        return cached.map((m) => m.toEntity()).toList();
      }

      // Fetch from remote - if this times out, the error will be thrown
      // and FutureProvider will transition to error state
      final instanceModels = await _remoteDataSource.getInstances(cancelToken: cancelToken);

      await _localDataSource.cacheInstances(instanceModels);
      final instances = instanceModels.map((m) => m.toEntity()).toList();
      _logger.info('getInstances: Success (remote) - ${instances.length} instances');
      await _analytics.logSuccess(
        action: 'get_instances',
        parameters: {'source': 'remote', 'count': instances.length},
      );
      trace?.stop();
      return instances;
    } catch (e, stackTrace) {
      // Log error first (don't await - fire and forget to avoid blocking error propagation)
      _logger.severe('getInstances: Failure', e, stackTrace);
      trace?.stop();

      // Log analytics failure (fire and forget - don't block on this)
      _analytics.logFailure(action: 'get_instances', error: e.toString()).catchError((err) {
        // If analytics logging fails, don't let it block error propagation
        _logger.warning('getInstances: Analytics logging failed', err);
      });

      // Rethrow immediately to ensure FutureProvider transitions to error state
      // This is critical - the error must propagate for the UI to show error state
      rethrow;
    }
  }

  @override
  Future<Instance> getInstanceById(String id, {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_instance_by_id');
    trace?.start();

    _logger.info('getInstanceById: Entry - $id');

    try {
      final instanceModel = await _remoteDataSource.getInstanceById(id, cancelToken: cancelToken);

      _logger.info('getInstanceById: Success - $id');
      await _analytics.logSuccess(action: 'get_instance_by_id', parameters: {'instance_id': id});
      trace?.stop();
      return instanceModel.toEntity();
    } catch (e, stackTrace) {
      _logger.severe('getInstanceById: Failure', e, stackTrace);
      trace?.stop();

      // Log analytics failure (fire and forget - don't block on this)
      _analytics
          .logFailure(
            action: 'get_instance_by_id',
            error: e.toString(),
            parameters: {'instance_id': id},
          )
          .catchError((err) {
            _logger.warning('getInstanceById: Analytics logging failed', err);
          });

      // Rethrow immediately to ensure error propagates
      rethrow;
    }
  }

  @override
  Future<Instance> createInstance({
    required String name,
    required String url,
    String? apiKey,
    CancelToken? cancelToken,
  }) async {
    final trace = _analytics.startTrace('create_instance');
    trace?.start();

    _logger.info('createInstance: Entry - name: $name, url: $url');

    try {
      final instanceModel = await _remoteDataSource.createInstance(
        name: name,
        url: url,
        apiKey: apiKey,
        cancelToken: cancelToken,
      );

      // Optimistic update: immediately cache the new instance
      // Get existing instances from cache and add the new one
      final cachedInstances = await _localDataSource.getInstances() ?? [];
      final updatedInstances = [...cachedInstances, instanceModel];
      await _localDataSource.cacheInstances(updatedInstances);

      // Set flag that user has set an instance
      await _localStorage.setHasSetInstance(true);

      final instance = instanceModel.toEntity();
      _logger.info('createInstance: Success - ${instance.id}');
      await _analytics.logSuccess(
        action: 'create_instance',
        parameters: {'instance_id': instance.id, 'name': name},
      );
      trace?.stop();
      return instance;
    } catch (e, stackTrace) {
      _logger.severe('createInstance: Failure', e, stackTrace);
      trace?.stop();

      // Log analytics failure (fire and forget - don't block on this)
      _analytics
          .logFailure(
            action: 'create_instance',
            error: e.toString(),
            parameters: {'name': name, 'url': url},
          )
          .catchError((err) {
            _logger.warning('createInstance: Analytics logging failed', err);
          });

      // Rethrow immediately to ensure error propagates
      rethrow;
    }
  }

  @override
  Future<void> toggleInstance(String id, bool enabled, {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('toggle_instance');
    trace?.start();

    _logger.info('toggleInstance: Entry - $id, enabled: $enabled');

    try {
      // Optimistic update: immediately update cache with new active state
      final cachedInstances = await _localDataSource.getInstances() ?? [];
      final updatedInstances = cachedInstances.map((instance) {
        if (instance.id == id) {
          return instance.copyWith(active: enabled);
        }
        return instance;
      }).toList();
      await _localDataSource.cacheInstances(updatedInstances);
      _logger.info('toggleInstance: Optimistic update applied - $id');

      // Make API call
      await _remoteDataSource.toggleInstance(id, enabled, cancelToken: cancelToken);

      // Set flag if instance is being enabled (user has set an instance)
      if (enabled) {
        await _localStorage.setHasSetInstance(true);
      }

      // After successful API call, we want to fetch fresh data from server
      // But we keep the optimistic cache so the UI updates immediately
      // The provider invalidation will trigger a refetch, which will:
      // 1. First return the optimistic cache (immediate UI update)
      // 2. Then fetch from server in background to sync
      // For now, we'll clear cache after a short delay to force server sync
      // But actually, let's just clear it immediately and let provider fetch fresh
      // The optimistic update already happened, so UI should update via provider invalidation
      await _localDataSource.clearCache();

      _logger.info('toggleInstance: Success - $id');
      await _analytics.logSuccess(
        action: 'toggle_instance',
        parameters: {'instance_id': id, 'enabled': enabled},
      );
      trace?.stop();
    } catch (e, stackTrace) {
      // On error, revert optimistic update by clearing cache
      await _localDataSource.clearCache();
      _logger.severe('toggleInstance: Failure', e, stackTrace);
      trace?.stop();

      // Log analytics failure (fire and forget - don't block on this)
      _analytics
          .logFailure(
            action: 'toggle_instance',
            error: e.toString(),
            parameters: {'instance_id': id, 'enabled': enabled},
          )
          .catchError((err) {
            _logger.warning('toggleInstance: Analytics logging failed', err);
          });

      // Rethrow immediately to ensure error propagates
      rethrow;
    }
  }

  @override
  Future<void> refreshInstances() async {
    _logger.info('refreshInstances: Entry');

    try {
      await _localDataSource.clearCache();
      _logger.info('refreshInstances: Success');
    } catch (e, stackTrace) {
      _logger.severe('refreshInstances: Failure', e, stackTrace);
      rethrow;
    }
  }
}
