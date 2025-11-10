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
      
      // Handle different response structures
      List<dynamic> data;
      if (response.data is List) {
        // Direct list response
        data = response.data as List<dynamic>;
      } else if (response.data is Map) {
        // Wrapped response - try common keys
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data')) {
          data = responseMap['data'] as List<dynamic>;
        } else if (responseMap.containsKey('instances')) {
          data = responseMap['instances'] as List<dynamic>;
        } else if (responseMap.containsKey('results')) {
          data = responseMap['results'] as List<dynamic>;
        } else {
          // If it's a single instance wrapped, convert to list
          data = [responseMap];
        }
      } else {
        throw FormatException(
          'Unexpected response format: expected List or Map, got ${response.data.runtimeType}',
        );
      }
      
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

  Future<InstanceModel> createInstance({
    required String name,
    required String url,
    String? apiKey,
    CancelToken? cancelToken,
  }) async {
    _logger.info('createInstance: Entry - name: $name, url: $url');

    try {
      final data = <String, dynamic>{
        'name': name,
        'url': url,
        'active': true, // New instances should be active by default
      };
      if (apiKey != null && apiKey.isNotEmpty) {
        data['api_key'] = apiKey;
      }

      final response = await _dio.post(
        '/instances',
        data: data,
        cancelToken: cancelToken,
      );

      // Handle different response structures
      Map<String, dynamic> instanceData;
      if (response.data is Map) {
        final responseMap = response.data as Map<String, dynamic>;
        if (responseMap.containsKey('data')) {
          instanceData = responseMap['data'] as Map<String, dynamic>;
        } else if (responseMap.containsKey('instance')) {
          instanceData = responseMap['instance'] as Map<String, dynamic>;
        } else {
          instanceData = responseMap;
        }
      } else {
        throw FormatException(
          'Unexpected response format: expected Map, got ${response.data.runtimeType}',
        );
      }

      final instance = InstanceModel.fromJson(instanceData);
      _logger.info('createInstance: Success - ${instance.id}');
      return instance;
    } catch (e, stackTrace) {
      _logger.severe('createInstance: Failure', e, stackTrace);
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
      // Backend expects PUT with 'enabled' field (not 'active')
      await _dio.put(
        '/instances/$id',
        data: {'enabled': enabled},
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
