import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class DeviceRemoteDataSource {
  final Dio _dio;
  final Logger _logger = AppLogger.getLogger('DeviceRemoteDataSource');

  DeviceRemoteDataSource(this._dio);

  /// Register device token with backend
  Future<void> registerDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
    CancelToken? cancelToken,
  }) async {
    _logger.info('registerDevice: Entry - device: $deviceId, platform: $platform');

    try {
      await _dio.post(
        'devices/register',
        data: {
          'device_id': deviceId,
          'fcm_token': fcmToken,
          'platform': platform,
        },
        cancelToken: cancelToken,
      );

      _logger.info('registerDevice: Success - device: $deviceId');
    } catch (e, stackTrace) {
      _logger.severe('registerDevice: Failure', e, stackTrace);
      rethrow;
    }
  }

  /// Delete device token from backend
  Future<void> deleteDevice({
    required String deviceId,
    CancelToken? cancelToken,
  }) async {
    _logger.info('deleteDevice: Entry - device: $deviceId');

    try {
      await _dio.delete(
        'devices',
        data: {
          'device_id': deviceId,
        },
        cancelToken: cancelToken,
      );

      _logger.info('deleteDevice: Success - device: $deviceId');
    } catch (e, stackTrace) {
      _logger.severe('deleteDevice: Failure', e, stackTrace);
      rethrow;
    }
  }
}

