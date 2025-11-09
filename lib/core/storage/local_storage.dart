import 'package:shared_preferences/shared_preferences.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/constants/app_constants.dart';

class LocalStorage {
  final SharedPreferences _prefs;
  final Logger _logger = AppLogger.getLogger('LocalStorage');

  LocalStorage(this._prefs);

  // Token management
  Future<void> saveAuthToken(String token) async {
    _logger.info('saveAuthToken: Entry');
    try {
      await _prefs.setString(AppConstants.authTokenKey, token);
      _logger.info('saveAuthToken: Success');
    } catch (e, stackTrace) {
      _logger.severe('saveAuthToken: Failure', e, stackTrace);
      rethrow;
    }
  }

  String? getAuthToken() {
    return _prefs.getString(AppConstants.authTokenKey);
  }

  Future<void> clearAuthToken() async {
    _logger.info('clearAuthToken: Entry');
    try {
      await _prefs.remove(AppConstants.authTokenKey);
      _logger.info('clearAuthToken: Success');
    } catch (e, stackTrace) {
      _logger.severe('clearAuthToken: Failure', e, stackTrace);
      rethrow;
    }
  }

  // User ID management
  Future<void> saveUserId(String userId) async {
    _logger.info('saveUserId: Entry - $userId');
    try {
      await _prefs.setString(AppConstants.userIdKey, userId);
      _logger.info('saveUserId: Success');
    } catch (e, stackTrace) {
      _logger.severe('saveUserId: Failure', e, stackTrace);
      rethrow;
    }
  }

  String? getUserId() {
    return _prefs.getString(AppConstants.userIdKey);
  }

  Future<void> clearUserId() async {
    _logger.info('clearUserId: Entry');
    try {
      await _prefs.remove(AppConstants.userIdKey);
      _logger.info('clearUserId: Success');
    } catch (e, stackTrace) {
      _logger.severe('clearUserId: Failure', e, stackTrace);
      rethrow;
    }
  }

  // Instance flag management
  Future<void> setHasSetInstance(bool value) async {
    _logger.info('setHasSetInstance: Entry - $value');
    try {
      await _prefs.setBool(AppConstants.hasSetInstanceKey, value);
      _logger.info('setHasSetInstance: Success');
    } catch (e, stackTrace) {
      _logger.severe('setHasSetInstance: Failure', e, stackTrace);
      rethrow;
    }
  }

  bool hasSetInstance() {
    return _prefs.getBool(AppConstants.hasSetInstanceKey) ?? false;
  }

  // Onboarding flag management
  Future<void> setHasCompletedOnboarding(bool value) async {
    _logger.info('setHasCompletedOnboarding: Entry - $value');
    try {
      await _prefs.setBool(AppConstants.hasCompletedOnboardingKey, value);
      _logger.info('setHasCompletedOnboarding: Success');
    } catch (e, stackTrace) {
      _logger.severe('setHasCompletedOnboarding: Failure', e, stackTrace);
      rethrow;
    }
  }

  bool hasCompletedOnboarding() {
    return _prefs.getBool(AppConstants.hasCompletedOnboardingKey) ?? false;
  }

  // Generic cache methods
  Future<void> saveString(String key, String value) async {
    await _prefs.setString('${AppConstants.storagePrefix}$key', value);
  }

  String? getString(String key) {
    return _prefs.getString('${AppConstants.storagePrefix}$key');
  }

  Future<void> remove(String key) async {
    await _prefs.remove('${AppConstants.storagePrefix}$key');
  }

  Future<void> clearAll() async {
    _logger.info('clearAll: Entry');
    try {
      await _prefs.clear();
      _logger.info('clearAll: Success');
    } catch (e, stackTrace) {
      _logger.severe('clearAll: Failure', e, stackTrace);
      rethrow;
    }
  }
}
