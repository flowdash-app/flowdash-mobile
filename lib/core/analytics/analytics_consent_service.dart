import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';

class AnalyticsConsentService {
  final LocalStorage _localStorage;
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Logger _logger = AppLogger.getLogger('AnalyticsConsentService');

  AnalyticsConsentService(this._localStorage);

  /// Check if user has given consent for analytics
  bool hasUserConsented() {
    final hasConsent = _localStorage.hasAnalyticsConsent();
    _logger.info('hasUserConsented: $hasConsent');
    return hasConsent;
  }

  /// Set analytics consent and enable/disable Firebase Analytics collection
  Future<void> setAnalyticsConsent(bool enabled) async {
    _logger.info('setAnalyticsConsent: Entry - $enabled');

    try {
      // Store consent preference
      await _localStorage.setAnalyticsConsent(enabled);

      // Enable or disable Firebase Analytics collection
      await _analytics.setAnalyticsCollectionEnabled(enabled);

      _logger.info('setAnalyticsConsent: Success - Analytics collection ${enabled ? "enabled" : "disabled"}');
    } catch (e, stackTrace) {
      _logger.severe('setAnalyticsConsent: Failure', e, stackTrace);
      rethrow;
    }
  }

  /// Initialize analytics consent on app startup
  /// Should be called in main.dart after Firebase initialization
  Future<void> initializeConsent() async {
    _logger.info('initializeConsent: Entry');

    try {
      final hasConsent = hasUserConsented();
      await _analytics.setAnalyticsCollectionEnabled(hasConsent);
      _logger.info('initializeConsent: Success - Analytics collection ${hasConsent ? "enabled" : "disabled"}');
    } catch (e, stackTrace) {
      _logger.severe('initializeConsent: Failure', e, stackTrace);
    }
  }
}

