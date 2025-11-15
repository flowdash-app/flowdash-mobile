import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flowdash_mobile/core/analytics/analytics_consent_service.dart';
import 'package:flowdash_mobile/core/notifications/push_notification_provider.dart';
import 'package:flowdash_mobile/core/notifications/push_notification_service.dart';
import 'package:flowdash_mobile/core/routing/router_config.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/shared/theme/app_theme.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize logging
  AppLogger.init();

  // Initialize Firebase
  await Firebase.initializeApp();

  // Register background message handler (must be done before any other FCM operations)
  // This handles notifications when the app is terminated
  FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

  // Initialize Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };

  // Pass non-fatal errors to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  // Initialize Performance Monitoring
  final performance = FirebasePerformance.instance;
  performance.setPerformanceCollectionEnabled(true);

  // Initialize SharedPreferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Initialize analytics consent (must be done before runApp)
  // Analytics collection is disabled by default until user consents
  final localStorage = LocalStorage(sharedPreferences);
  final analyticsConsentService = AnalyticsConsentService(localStorage);
  await analyticsConsentService.initializeConsent();

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
      child: const FlowDashApp(),
    ),
  );
}

class FlowDashApp extends ConsumerWidget {
  const FlowDashApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final pushNotificationService = ref.read(pushNotificationServiceProvider);

    // Initialize push notifications (handlers only, no permission request)
    pushNotificationService.initialize();

    // Set user ID when auth state changes
    // Using ref.listen ensures proper subscription management - Riverpod
    // automatically cancels the subscription when the widget is disposed
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
      next.whenData((user) async {
        if (user != null) {
          analytics.setUserId(user.id);

          // Register device token if notifications are enabled
          final notificationSettings = await FirebaseMessaging.instance.getNotificationSettings();
          if (notificationSettings.authorizationStatus == AuthorizationStatus.authorized) {
            // User has granted notification permissions, register device token
            await pushNotificationService.registerDeviceToken();
          }
        } else {
          analytics.setUserId(null);
        }
      });
    });

    // Also register device token on app startup if user is already logged in
    // This ensures last_used_at is updated even if user doesn't log in/out
    final currentAuthState = ref.read(authStateProvider);
    currentAuthState.whenData((user) async {
      if (user != null) {
        final notificationSettings = await FirebaseMessaging.instance.getNotificationSettings();
        if (notificationSettings.authorizationStatus == AuthorizationStatus.authorized) {
          await pushNotificationService.registerDeviceToken();
        }
      }
    });

    return MaterialApp.router(
      title: 'FlowDash',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,

      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: kDebugMode,
    );
  }
}
