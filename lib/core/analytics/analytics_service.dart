import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;
  final Logger _logger = AppLogger.getLogger('AnalyticsService');
  final LocalStorage? _localStorage;

  AnalyticsService({LocalStorage? localStorage}) : _localStorage = localStorage;

  /// Check if analytics collection is enabled (user has consented)
  bool _isCollectionEnabled() {
    if (_localStorage == null) {
      // If no localStorage provided, assume enabled (for backward compatibility)
      return true;
    }
    return _localStorage!.hasAnalyticsConsent();
  }

  // Set user ID for all Firebase services
  Future<void> setUserId(String? userId) async {
    if (!_isCollectionEnabled()) {
      _logger.info('setUserId: Skipped - Analytics collection disabled');
      return;
    }

    _logger.info('setUserId: Entry - $userId');

    try {
      if (userId != null) {
        await _analytics.setUserId(id: userId);
        await _crashlytics.setUserIdentifier(userId);
      } else {
        await _analytics.setUserId();
        await _crashlytics.setUserIdentifier('');
      }
      _logger.info('setUserId: Success');
    } catch (e, stackTrace) {
      _logger.severe('setUserId: Failure', e, stackTrace);
    }
  }

  // Log custom events
  Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (!_isCollectionEnabled()) {
      _logger.info('logEvent: Skipped - Analytics collection disabled - $name');
      return;
    }

    _logger.info('logEvent: Entry - $name');

    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters,
      );
      _logger.info('logEvent: Success - $name');
    } catch (e, stackTrace) {
      _logger.severe('logEvent: Failure', e, stackTrace);
    }
  }

  // Log success events
  Future<void> logSuccess({
    required String action,
    Map<String, Object>? parameters,
  }) async {
    await logEvent(
      name: '${action}_success',
      parameters: {
        'action': action,
        'status': 'success',
        ...?parameters,
      },
    );
  }

  // Log failure events
  Future<void> logFailure({
    required String action,
    required String error,
    Map<String, Object>? parameters,
  }) async {
    await logEvent(
      name: '${action}_failure',
      parameters: {
        'action': action,
        'status': 'failure',
        'error': error,
        ...?parameters,
      },
    );

    // Also log to Crashlytics (non-fatal)
    await _crashlytics.recordError(
      Exception(error),
      StackTrace.current,
      reason: 'Action failed: $action',
      fatal: false,
    );
  }

  // Start performance trace
  Trace? startTrace(String name) {
    _logger.info('startTrace: Entry - $name');
    return _performance.newTrace(name);
  }

  // Log screen view
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    if (!_isCollectionEnabled()) {
      _logger.info('logScreenView: Skipped - Analytics collection disabled - $screenName');
      return;
    }

    _logger.info('logScreenView: Entry - $screenName');

    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass,
      );
      _logger.info('logScreenView: Success - $screenName');
    } catch (e, stackTrace) {
      _logger.severe('logScreenView: Failure', e, stackTrace);
    }
  }
}
