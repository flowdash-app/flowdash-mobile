import 'package:flowdash_mobile/features/devices/domain/repositories/device_repository.dart';
import 'package:flowdash_mobile/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';

class DeviceRepositoryImpl implements DeviceRepository {
  final DeviceRemoteDataSource _remoteDataSource;
  final AnalyticsService _analytics;
  final Logger _logger = AppLogger.getLogger('DeviceRepositoryImpl');

  DeviceRepositoryImpl(this._remoteDataSource, this._analytics);

  @override
  Future<void> registerDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
  }) async {
    _logger.info('registerDevice: Entry - device: $deviceId, platform: $platform');

    try {
      await _remoteDataSource.registerDevice(
        deviceId: deviceId,
        fcmToken: fcmToken,
        platform: platform,
      );

      await _analytics.logSuccess(
        action: 'register_device',
        parameters: {
          'device_id': deviceId,
          'platform': platform,
        },
      );

      _logger.info('registerDevice: Success - device: $deviceId');
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'register_device',
        error: e.toString(),
        parameters: {
          'device_id': deviceId,
          'platform': platform,
        },
      );

      _logger.severe('registerDevice: Failure', e, stackTrace);
      rethrow;
    }
  }

  @override
  Future<void> deleteDevice({
    required String deviceId,
  }) async {
    _logger.info('deleteDevice: Entry - device: $deviceId');

    try {
      await _remoteDataSource.deleteDevice(deviceId: deviceId);

      await _analytics.logSuccess(
        action: 'delete_device',
        parameters: {
          'device_id': deviceId,
        },
      );

      _logger.info('deleteDevice: Success - device: $deviceId');
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'delete_device',
        error: e.toString(),
        parameters: {
          'device_id': deviceId,
        },
      );

      _logger.severe('deleteDevice: Failure', e, stackTrace);
      rethrow;
    }
  }
}

