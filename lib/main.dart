import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flowdash_mobile/core/routing/router_config.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/analytics/analytics_consent_service.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';
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
      overrides: [
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
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

    // Set user ID when auth state changes
    // Using ref.listen ensures proper subscription management - Riverpod
    // automatically cancels the subscription when the widget is disposed
    ref.listen<AsyncValue<dynamic>>(authStateProvider, (previous, next) {
      next.whenData((user) {
        if (user != null) {
          analytics.setUserId(user.id);
        } else {
          analytics.setUserId(null);
        }
      });
    });

    return MaterialApp.router(
      title: 'FlowDash',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
