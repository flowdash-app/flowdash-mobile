# FlowDash Mobile - Development Plan

## Overview

This document provides a comprehensive development plan for the FlowDash mobile application built with Flutter.

## Prerequisites

### 1. Research Latest Package Versions

Before installation, verify the latest stable versions on [pub.dev](https://pub.dev):

- Flutter SDK: Check for latest stable (target 3.35+ for MCP server support)
- go_router: Latest stable (^16.2.0+)
- go_router_builder: Latest stable (^4.1.1+)
- riverpod: Latest stable
- firebase_core, firebase_auth, firebase_messaging, firebase_analytics, firebase_crashlytics, firebase_performance: Latest stable
- google_sign_in: Latest stable
- dio: Latest stable
- shared_preferences: Latest stable
- logging: ^1.3.0
- build_runner: ^2.6.0+

### 2. Flutter Installation

```bash
# Check Flutter version
flutter --version

# Update Flutter to latest stable
flutter upgrade

# Verify Flutter installation
flutter doctor
```

## Project Initialization

### 1. Create Flutter Project

```bash
cd flowdash-mobile
flutter create . --org com.flowdash --project-name flowdash_mobile
```

### 2. Add Dependencies

Update `pubspec.yaml` with the following dependencies:

```yaml
name: flowdash_mobile
description: FlowDash mobile application for n8n management
publish_to: 'none'
version: 1.0.0+1

environment:
  sdk: '>=3.0.0 <4.0.0'

dependencies:
  flutter:
    sdk: flutter
  
  # Routing
  go_router: ^16.2.0
  
  # State Management
  flutter_riverpod: ^2.5.0
  riverpod_annotation: ^2.3.0
  
  # Firebase
  firebase_core: ^3.0.0
  firebase_auth: ^5.0.0
  firebase_messaging: ^15.0.0
  firebase_analytics: ^11.0.0
  firebase_crashlytics: ^4.0.0
  firebase_performance: ^0.9.0
  
  # Authentication
  google_sign_in: ^6.2.0
  
  # HTTP Client
  dio: ^5.4.0
  
  # Local Storage
  shared_preferences: ^2.2.0
  
  # Logging
  logging: ^1.3.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^3.0.0
  
  # Code Generation
  build_runner: ^2.4.0
  go_router_builder: ^4.1.1
  riverpod_generator: ^2.3.0
  custom_lint: ^0.6.0
  riverpod_lint: ^2.3.0

flutter:
  uses-material-design: true
```

### 3. Install Dependencies

```bash
flutter pub get
```

## Project Structure

```
lib/
├── core/
│   ├── config/
│   │   ├── app_config.dart
│   │   └── firebase_config.dart
│   ├── constants/
│   │   └── app_constants.dart
│   ├── errors/
│   │   ├── exceptions.dart
│   │   └── failures.dart
│   ├── network/
│   │   ├── api_client.dart
│   │   ├── interceptors/
│   │   │   ├── auth_interceptor.dart
│   │   │   ├── logging_interceptor.dart
│   │   │   └── error_interceptor.dart
│   │   └── endpoints.dart
│   ├── storage/
│   │   └── local_storage.dart
│   └── utils/
│       ├── logger.dart
│       └── validators.dart
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   ├── datasources/
│   │   │   │   ├── auth_remote_datasource.dart
│   │   │   │   └── auth_local_datasource.dart
│   │   │   └── models/
│   │   │       └── user_model.dart
│   │   ├── domain/
│   │   │   ├── entities/
│   │   │   │   └── user.dart
│   │   │   ├── repositories/
│   │   │   │   └── auth_repository.dart
│   │   │   └── usecases/
│   │   │       ├── sign_in_with_google.dart
│   │   │       └── sign_out.dart
│   │   └── presentation/
│   │       ├── providers/
│   │       │   └── auth_provider.dart
│   │       ├── pages/
│   │       │   ├── login_page.dart
│   │       │   └── splash_page.dart
│   │       └── widgets/
│   │           └── google_sign_in_button.dart
│   ├── workflows/
│   │   ├── data/
│   │   ├── domain/
│   │   └── presentation/
│   └── instances/
│       ├── data/
│       ├── domain/
│       └── presentation/
├── shared/
│   ├── widgets/
│   │   ├── loading_indicator.dart
│   │   └── error_widget.dart
│   └── theme/
│       ├── app_theme.dart
│       └── app_colors.dart
└── main.dart
```

## Implementation Steps

### 1. Firebase Setup

#### a. Create Firebase Project

1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing
3. Add Android and iOS apps
4. Download configuration files:
   - `google-services.json` for Android → `android/app/`
   - `GoogleService-Info.plist` for iOS → `ios/Runner/`

#### b. Install Firebase CLI

```bash
npm install -g firebase-tools
```

#### c. Install FlutterFire CLI

FlutterFire CLI is already included as a dev dependency in `pubspec.yaml`. No global installation needed!

#### d. Configure Firebase

```bash
# Run FlutterFire CLI using dart run
dart run flutterfire_cli:flutterfire configure

# Or create an alias for convenience (optional)
# Add to ~/.zshrc or ~/.bashrc:
# alias flutterfire="dart run flutterfire_cli:flutterfire"
```

### 2. Firebase Analytics, Crashlytics, and Performance Setup

#### a. Initialize Firebase Services

Update `lib/main.dart` to initialize all Firebase services:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
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
  
  runApp(const FlowDashApp());
}
```

#### b. Create Analytics Service

Create `lib/core/analytics/analytics_service.dart`:

```dart
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;
  final Logger _logger = AppLogger.getLogger('AnalyticsService');
  
  // Set user ID for all Firebase services
  Future<void> setUserId(String userId) async {
    _logger.info('setUserId: Entry - $userId');
    
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
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
    await _analytics.logScreenView(
      screenName: screenName,
      screenClass: screenClass,
    );
  }
}
```

#### c. Integrate Analytics in Services

Every service should log analytics events:

```dart
class WorkflowService {
  final AnalyticsService _analytics;
  final Logger _logger = AppLogger.getLogger('WorkflowService');
  
  Future<void> toggleWorkflow(String id, bool enabled) async {
    final trace = _analytics.startTrace('toggle_workflow');
    trace?.start();
    
    _logger.info('toggleWorkflow: Entry - $id, enabled: $enabled');
    
    try {
      // Implementation
      await _analytics.logSuccess(
        action: 'toggle_workflow',
        parameters: {
          'workflow_id': id,
          'enabled': enabled,
        },
      );
      trace?.stop();
      _logger.info('toggleWorkflow: Success');
    } catch (e, stackTrace) {
      await _analytics.logFailure(
        action: 'toggle_workflow',
        error: e.toString(),
        parameters: {
          'workflow_id': id,
          'enabled': enabled,
        },
      );
      trace?.stop();
      _logger.severe('toggleWorkflow: Failure', e, stackTrace);
      rethrow;
    }
  }
}
```

### 3. Logging Setup

Create `lib/core/utils/logger.dart`:

```dart
import 'package:logging/logging.dart';

class AppLogger {
  static void init() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      print('${record.level.name}: ${record.time}: ${record.message}');
      if (record.error != null) {
        print('Error: ${record.error}');
      }
      if (record.stackTrace != null) {
        print('StackTrace: ${record.stackTrace}');
      }
    });
  }
  
  static Logger getLogger(String name) {
    return Logger(name);
  }
}
```

### 4. Routing Setup with go_router_builder

#### a. Create Route Definitions

Create `lib/core/routing/app_router.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flowdash_mobile/features/auth/presentation/pages/splash_page.dart';

part 'app_router.g.dart';

@TypedGoRoute<SplashRoute>(path: '/')
class SplashRoute extends GoRouteData {
  const SplashRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData {
  const LoginRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}

// Add more routes as needed
```

#### b. Generate Route Code

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

#### c. Configure Router with Auth State

Create `lib/core/routing/router_config.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  
  return GoRouter(
    routes: $appRoutes,
    redirect: (context, state) {
      final isAuthenticated = authState.value != null;
      final isLoggingIn = state.matchedLocation == '/login';
      
      if (!isAuthenticated && !isLoggingIn) {
        return '/login';
      }
      
      if (isAuthenticated && isLoggingIn) {
        return '/';
      }
      
      return null;
    },
    refreshListenable: GoRouterRefreshStream(authState),
  );
});
```

### 5. Authentication Setup

#### a. Create Auth Service (Extensible Architecture)

Create `lib/features/auth/domain/repositories/auth_repository.dart`:

```dart
import 'package:flowdash_mobile/features/auth/domain/entities/user.dart';

abstract class AuthRepository {
  Future<User> signInWithGoogle();
  Future<void> signOut();
  Stream<User?> get authStateChanges;
}
```

#### b. Implement Google Sign-In

Create `lib/features/auth/data/datasources/auth_remote_datasource.dart`:

```dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class AuthRemoteDataSource {
  final FirebaseAuth _firebaseAuth;
  final GoogleSignIn _googleSignIn;
  final Logger _logger = AppLogger.getLogger('AuthRemoteDataSource');
  
  AuthRemoteDataSource({
    required FirebaseAuth firebaseAuth,
    required GoogleSignIn googleSignIn,
  })  : _firebaseAuth = firebaseAuth,
        _googleSignIn = googleSignIn;
  
  Future<User> signInWithGoogle() async {
    _logger.info('signInWithGoogle: Entry');
    
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        _logger.warning('signInWithGoogle: User cancelled sign in');
        throw Exception('Sign in cancelled');
      }
      
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      _logger.info('signInWithGoogle: Success - ${userCredential.user?.uid}');
      
      return userCredential.user!;
    } catch (e, stackTrace) {
      _logger.severe('signInWithGoogle: Failure', e, stackTrace);
      rethrow;
    }
  }
  
  Future<void> signOut() async {
    _logger.info('signOut: Entry');
    
    try {
      await Future.wait([
        _googleSignIn.signOut(),
        _firebaseAuth.signOut(),
      ]);
      _logger.info('signOut: Success');
    } catch (e, stackTrace) {
      _logger.severe('signOut: Failure', e, stackTrace);
      rethrow;
    }
  }
  
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges();
  }
}
```

### 6. Repository Pattern Implementation

#### Example Repository with Logging

Create `lib/features/auth/data/repositories/auth_repository_impl.dart`:

```dart
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/auth/domain/entities/user.dart';
import 'package:flowdash_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:flowdash_mobile/features/auth/data/datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDataSource _remoteDataSource;
  final Logger _logger = AppLogger.getLogger('AuthRepositoryImpl');
  
  AuthRepositoryImpl(this._remoteDataSource);
  
  @override
  Future<User> signInWithGoogle() async {
    _logger.info('signInWithGoogle: Entry');
    
    try {
      final firebaseUser = await _remoteDataSource.signInWithGoogle();
      final user = User.fromFirebaseUser(firebaseUser);
      _logger.info('signInWithGoogle: Success - ${user.id}');
      return user;
    } catch (e, stackTrace) {
      _logger.severe('signInWithGoogle: Failure', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Future<void> signOut() async {
    _logger.info('signOut: Entry');
    
    try {
      await _remoteDataSource.signOut();
      _logger.info('signOut: Success');
    } catch (e, stackTrace) {
      _logger.severe('signOut: Failure', e, stackTrace);
      rethrow;
    }
  }
  
  @override
  Stream<User?> get authStateChanges {
    return _remoteDataSource.authStateChanges.map((firebaseUser) {
      return firebaseUser != null ? User.fromFirebaseUser(firebaseUser) : null;
    });
  }
}
```

### 7. State Management with Riverpod

Create `lib/features/auth/presentation/providers/auth_provider.dart`:

```dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flowdash_mobile/features/auth/domain/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  // Return implementation
});

final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});
```

### 8. API Client Setup (Dio)

Create `lib/core/network/api_client.dart`:

```dart
import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:flowdash_mobile/core/network/interceptors/logging_interceptor.dart';
import 'package:flowdash_mobile/core/network/interceptors/error_interceptor.dart';

class ApiClient {
  final Dio _dio;
  final Logger _logger = AppLogger.getLogger('ApiClient');
  
  ApiClient() : _dio = Dio() {
    _logger.info('ApiClient: Initializing');
    
    _dio.options.baseUrl = 'https://api.flow-dash.com';
    _dio.options.connectTimeout = const Duration(seconds: 30);
    _dio.options.receiveTimeout = const Duration(seconds: 30);
    
    _dio.interceptors.addAll([
      AuthInterceptor(),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);
    
    _logger.info('ApiClient: Initialized successfully');
  }
  
  Dio get dio => _dio;
}
```

### 9. Deep Linking Configuration

#### Android (android/app/src/main/AndroidManifest.xml)

```xml
<intent-filter>
    <action android:name="android.intent.action.VIEW" />
    <category android:name="android.intent.category.DEFAULT" />
    <category android:name="android.intent.category.BROWSABLE" />
    <data android:scheme="flowdash" />
</intent-filter>
```

#### iOS (ios/Runner/Info.plist)

```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>flowdash</string>
        </array>
    </dict>
</array>
```

### 10. Main Application Setup

Update `lib/main.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:flutter/foundation.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/core/routing/router_config.dart';
import 'package:flowdash_mobile/shared/theme/app_theme.dart';

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
  
  runApp(
    const ProviderScope(
      child: FlowDashApp(),
    ),
  );
}

class FlowDashApp extends ConsumerWidget {
  const FlowDashApp({super.key});
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    
    return MaterialApp.router(
      title: 'FlowDash',
      theme: AppTheme.lightTheme,
      routerConfig: router,
    );
  }
}
```

## Development Commands

### Code Generation

```bash
# Generate routes and providers
flutter pub run build_runner build --delete-conflicting-outputs

# Watch for changes
flutter pub run build_runner watch --delete-conflicting-outputs
```

### Run Application

```bash
# Run on connected device
flutter run

# Run with specific flavor
flutter run --flavor dev

# Build for release
flutter build apk --release
flutter build ios --release
```

### Testing

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage
```

## Next Steps

1. Implement remaining features (workflows, instances)
2. Add error handling and retry logic
3. Implement caching strategies
4. Add analytics events
5. Set up CI/CD pipeline
6. Configure MCP server integration
