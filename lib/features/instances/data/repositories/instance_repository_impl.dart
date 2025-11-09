import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/utils/retry_helper.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:flowdash_mobile/features/instances/domain/repositories/instance_repository.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_remote_datasource.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_local_datasource.dart';

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
  })  : _remoteDataSource = remoteDataSource,
        _localDataSource = localDataSource,
        _analytics = analytics,
        _localStorage = localStorage;

  @override
  Future<List<Instance>> getInstances({CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_instances');
    trace?.start();

    _logger.info('getInstances: Entry');

    try {
      // Try local cache first
      final cached = await _localDataSource.getInstances();
      if (cached != null) {
        _logger.info('getInstances: Success (cached)');
        await _analytics.logSuccess(
            action: 'get_instances', parameters: {'source': 'cache'});
        trace?.stop();
        return cached;
      }

      // Fetch from remote with retry
      final instances = await RetryHelper.retry(
        operation: () => _remoteDataSource.getInstances(cancelToken: cancelToken),
        maxAttempts: 3,
      );

      await _localDataSource.cacheInstances(instances);
      _logger.info(
          'getInstances: Success (remote) - ${instances.length} instances');
      await _analytics.logSuccess(
        action: 'get_instances',
        parameters: {'source': 'remote', 'count': instances.length},
      );
      trace?.stop();
      return instances;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_instances',
        error: e.toString(),
      );
      trace?.stop();
      _logger.severe('getInstances: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<Instance> getInstanceById(String id, {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('get_instance_by_id');
    trace?.start();

    _logger.info('getInstanceById: Entry - $id');

    try {
      final instance = await RetryHelper.retry(
        operation: () => _remoteDataSource.getInstanceById(id, cancelToken: cancelToken),
        maxAttempts: 3,
      );

      _logger.info('getInstanceById: Success - $id');
      await _analytics.logSuccess(
        action: 'get_instance_by_id',
        parameters: {'instance_id': id},
      );
      trace?.stop();
      return instance;
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'get_instance_by_id',
        error: e.toString(),
        parameters: {'instance_id': id},
      );
      trace?.stop();
      _logger.severe('getInstanceById: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> toggleInstance(String id, bool enabled, {CancelToken? cancelToken}) async {
    final trace = _analytics.startTrace('toggle_instance');
    trace?.start();

    _logger.info('toggleInstance: Entry - $id, enabled: $enabled');

    try {
      await RetryHelper.retry(
        operation: () => _remoteDataSource.toggleInstance(id, enabled, cancelToken: cancelToken),
        maxAttempts: 3,
      );

      // Set flag if instance is being enabled (user has set an instance)
      if (enabled) {
        await _localStorage.setHasSetInstance(true);
      }

      // Invalidate cache after toggle
      await _localDataSource.clearCache();

      _logger.info('toggleInstance: Success - $id');
      await _analytics.logSuccess(
        action: 'toggle_instance',
        parameters: {'instance_id': id, 'enabled': enabled},
      );
      trace?.stop();
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'toggle_instance',
        error: e.toString(),
        parameters: {'instance_id': id, 'enabled': enabled},
      );
      trace?.stop();
      _logger.severe('toggleInstance: Failure', e, stackTrace);
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
