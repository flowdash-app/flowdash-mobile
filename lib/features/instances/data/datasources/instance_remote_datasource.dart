import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/network/api_client_provider.dart';
import 'package:flowdash_mobile/features/instances/data/models/instance_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstanceRemoteDataSource {
  final Dio _dio;
  final Logger _logger = AppLogger.getLogger('InstanceRemoteDataSource');

  InstanceRemoteDataSource(this._dio);

  Future<List<InstanceModel>> getInstances({CancelToken? cancelToken}) async {
    _logger.info('getInstances: Entry');

    try {
      final response = await _dio.get(
        '/instances',
        cancelToken: cancelToken,
      );
      final List<dynamic> data = response.data as List<dynamic>;
      final instances = data
          .map((json) => InstanceModel.fromJson(json as Map<String, dynamic>))
          .toList();

      _logger.info('getInstances: Success - ${instances.length} instances');
      return instances;
    } catch (e, stackTrace) {
      _logger.severe('getInstances: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<InstanceModel> getInstanceById(
    String id, {
    CancelToken? cancelToken,
  }) async {
    _logger.info('getInstanceById: Entry - $id');

    try {
      final response = await _dio.get(
        '/instances/$id',
        cancelToken: cancelToken,
      );
      final instance =
          InstanceModel.fromJson(response.data as Map<String, dynamic>);

      _logger.info('getInstanceById: Success - $id');
      return instance;
    } catch (e, stackTrace) {
      _logger.severe('getInstanceById: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<void> toggleInstance(
    String id,
    bool enabled, {
    CancelToken? cancelToken,
  }) async {
    _logger.info('toggleInstance: Entry - $id, enabled: $enabled');

    try {
      await _dio.patch(
        '/instances/$id',
        data: {'active': enabled},
        cancelToken: cancelToken,
      );

      _logger.info('toggleInstance: Success - $id');
    } catch (e, stackTrace) {
      _logger.severe('toggleInstance: Failure', e, stackTrace);
      rethrow;
    }
  }
}

final instanceRemoteDataSourceProvider =
    Provider<InstanceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return InstanceRemoteDataSource(apiClient.dio);
});
