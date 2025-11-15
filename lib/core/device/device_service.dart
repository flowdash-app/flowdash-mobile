import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class DeviceService {
  final SharedPreferences _prefs;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();
  final Logger _logger = AppLogger.getLogger('DeviceService');

  static const String _deviceIdKey = 'flowdash_device_id';

  DeviceService(this._prefs);

  /// Get unique device identifier
  /// Returns cached ID if available, otherwise generates and caches it
  Future<String> getDeviceId() async {
    _logger.info('getDeviceId: Entry');

    try {
      // Try to get cached device ID
      final cachedId = _prefs.getString(_deviceIdKey);
      if (cachedId != null && cachedId.isNotEmpty) {
        _logger.info('getDeviceId: Success (cached)');
        return cachedId;
      }

      // Generate new device ID based on platform
      String deviceId;
      if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        // Use Android ID (unique per app installation)
        deviceId = androidInfo.id;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        // Use identifierForVendor (unique per app installation)
        deviceId = iosInfo.identifierForVendor ?? 'unknown-ios';
      } else {
        // Fallback for other platforms
        deviceId = 'unknown-platform-${DateTime.now().millisecondsSinceEpoch}';
      }

      // Cache the device ID
      await _prefs.setString(_deviceIdKey, deviceId);
      _logger.info('getDeviceId: Success (generated)');
      return deviceId;
    } catch (e, stackTrace) {
      _logger.severe('getDeviceId: Failure', e, stackTrace);
      // Fallback: generate a unique ID based on timestamp
      final fallbackId = 'fallback-${DateTime.now().millisecondsSinceEpoch}';
      await _prefs.setString(_deviceIdKey, fallbackId);
      return fallbackId;
    }
  }

  /// Get platform name (ios or android)
  String getPlatform() {
    _logger.info('getPlatform: Entry');

    if (Platform.isAndroid) {
      _logger.info('getPlatform: android');
      return 'android';
    } else if (Platform.isIOS) {
      _logger.info('getPlatform: ios');
      return 'ios';
    } else {
      _logger.info('getPlatform: unknown');
      return 'unknown';
    }
  }

  /// Clear cached device ID (useful for testing or reset)
  Future<void> clearDeviceId() async {
    _logger.info('clearDeviceId: Entry');

    try {
      await _prefs.remove(_deviceIdKey);
      _logger.info('clearDeviceId: Success');
    } catch (e, stackTrace) {
      _logger.severe('clearDeviceId: Failure', e, stackTrace);
      rethrow;
    }
  }
}

