class AppConstants {
  // API Configuration
  static const String apiBaseUrl = 'https://api.flow-dash.com';
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Storage Keys
  static const String storagePrefix = 'flowdash_';
  static const String authTokenKey = '${storagePrefix}auth_token';
  static const String userIdKey = '${storagePrefix}user_id';
  static const String hasSetInstanceKey = '${storagePrefix}has_set_instance';
  static const String hasCompletedOnboardingKey =
      '${storagePrefix}has_completed_onboarding';

  // Deep Link Scheme
  static const String deepLinkScheme = 'flowdash';
}
