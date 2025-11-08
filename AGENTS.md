# FlowDash Mobile - AI Agents Configuration

This document provides essential information for AI agents working on the FlowDash mobile application.

## Package List and Versions

### Core Dependencies

- **flutter**: SDK (latest stable, target 3.35+ for MCP server support)
- **go_router**: ^16.2.0+ (Navigation with type-safe routing)
- **go_router_builder**: ^4.1.1+ (Code generation for go_router, dev dependency)
- **build_runner**: ^2.6.0+ (Code generation tool, dev dependency)
- **flutter_riverpod**: ^2.5.0+ (State management)
- **riverpod_annotation**: ^2.3.0+ (Riverpod annotations)
- **riverpod_generator**: ^2.3.0+ (Code generation for Riverpod, dev dependency)

### Firebase Packages

- **firebase_core**: ^3.0.0+ (Firebase initialization)
- **firebase_auth**: ^5.0.0+ (Authentication)
- **firebase_messaging**: ^15.0.0+ (Push notifications)
- **firebase_analytics**: ^11.0.0+ (Analytics - REQUIRED)
- **firebase_crashlytics**: ^4.0.0+ (Crash reporting - REQUIRED)
- **firebase_performance**: ^0.9.0+ (Performance monitoring - REQUIRED)

### Authentication

- **google_sign_in**: ^6.2.0+ (Google Sign-In implementation)

### Networking

- **dio**: ^5.4.0+ (HTTP client with interceptors)

### Local Storage

- **shared_preferences**: ^2.2.0+ (Key-value storage)

### Logging

- **logging**: ^1.3.0 (Structured logging)

## Routing with go_router_builder

### TypedGoRoute Annotation Usage

All routes must be defined using `@TypedGoRoute` annotation:

```dart
@TypedGoRoute<HomeRoute>(path: '/')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();
  
  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}
```

### Route Class Structure

- Extend `GoRouteData`
- Mix in the generated mixin (e.g., `$HomeRoute`)
- Override `build` method
- Use `part` directive for generated file: `part 'app_router.g.dart';`

### Type-Safe Navigation

```dart
// Navigate using generated route classes
const HomeRoute().go(context);
const DetailsRoute(id: '123').go(context);

// Push with return value
final result = await const DetailsRoute(id: '123').push<bool>(context);
```

### Route Tree Structure

Routes can be nested using the `routes` parameter:

```dart
@TypedGoRoute<HomeRoute>(
  path: '/',
  routes: <TypedGoRoute<GoRouteData>>[
    TypedGoRoute<DetailsRoute>(path: 'details/:id'),
  ],
)
```

### Code Generation

Always run build_runner after adding/modifying routes:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

## Firebase Auth State Integration

### Router Listener Configuration

The router must listen to Firebase auth state changes:

```dart
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

### Protected Routes

- Routes requiring authentication should check `authState.value != null`
- Redirect unauthenticated users to login
- Use `GoRouterRefreshStream` to listen to auth state changes

### Route Guards

Implement route-level redirects:

```dart
class ProtectedRoute extends GoRouteData {
  @override
  String? redirect(BuildContext context, GoRouterState state) {
    // Check authentication
    return null; // or redirect path
  }
}
```

## Repository Pattern Details

### Data Source Abstraction

- **Remote Data Source**: API calls via Dio
- **Local Data Source**: SharedPreferences for caching
- **Repository Interface**: Defined in domain layer
- **Repository Implementation**: In data layer, combines remote and local sources

### Repository Interface Example

```dart
abstract class WorkflowRepository {
  Future<List<Workflow>> getWorkflows();
  Future<Workflow> getWorkflowById(String id);
  Future<void> toggleWorkflow(String id, bool enabled);
}
```

### Repository Implementation Pattern

```dart
class WorkflowRepositoryImpl implements WorkflowRepository {
  final WorkflowRemoteDataSource _remoteDataSource;
  final WorkflowLocalDataSource _localDataSource;
  final Logger _logger = AppLogger.getLogger('WorkflowRepositoryImpl');
  
  @override
  Future<List<Workflow>> getWorkflows() async {
    _logger.info('getWorkflows: Entry');
    
    try {
      // Try local cache first
      final cached = await _localDataSource.getWorkflows();
      if (cached != null) {
        _logger.info('getWorkflows: Success (cached)');
        return cached;
      }
      
      // Fetch from remote
      final workflows = await _remoteDataSource.getWorkflows();
      await _localDataSource.cacheWorkflows(workflows);
      _logger.info('getWorkflows: Success (remote)');
      return workflows;
    } catch (e, stackTrace) {
      _logger.severe('getWorkflows: Failure', e, stackTrace);
      rethrow;
    }
  }
}
```

### Error Handling in Repositories

- Always catch exceptions
- Log errors with context
- Re-throw as domain exceptions
- Handle network errors gracefully

## State Management (Riverpod)

### Provider Structure

- **State Providers**: For simple state (`StateProvider`)
- **Future Providers**: For async data (`FutureProvider`)
- **Stream Providers**: For real-time data (`StreamProvider`)
- **Notifier Providers**: For complex state logic (`NotifierProvider`)

### Provider Organization

```dart
// Feature-based organization
final authStateProvider = StreamProvider<User?>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

final workflowsProvider = FutureProvider<List<Workflow>>((ref) async {
  final repository = ref.watch(workflowRepositoryProvider);
  return repository.getWorkflows();
});
```

### Provider Dependencies

```dart
final workflowRepositoryProvider = Provider<WorkflowRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return WorkflowRepositoryImpl(apiClient);
});
```

### State Refresh Patterns

```dart
// Refresh provider
ref.invalidate(workflowsProvider);

// Watch for changes
ref.listen(workflowsProvider, (previous, next) {
  // Handle state changes
});
```

## Navigation (go_router with go_router_builder)

### Route Definitions

- Use `@TypedGoRoute` for all routes
- Define route classes extending `GoRouteData`
- Generate code with build_runner

### Generated Route Classes

All routes are aggregated into `$appRoutes` list:

```dart
final GoRouter router = GoRouter(routes: $appRoutes);
```

### Type-Safe Navigation Methods

- `go(context)`: Navigate and replace
- `push(context)`: Navigate and push
- `location`: Get route location string

### Deep Linking

- Configure URL schemes in AndroidManifest.xml and Info.plist
- Use typed routes for deep link handling
- Extract parameters from route constructors

### Navigation Guards

- Implement `redirect` method in route class
- Check authentication state
- Return redirect path or null

### Route Parameters

- **Path parameters**: Defined in route path (`:id`)
- **Query parameters**: Optional constructor parameters
- **Extra parameters**: Use `$extra` parameter name

## Authentication

### Google Sign-In Implementation

```dart
Future<User> signInWithGoogle() async {
  final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
  final GoogleSignInAuthentication googleAuth = await googleUser!.authentication;
  final credential = GoogleAuthProvider.credential(
    accessToken: googleAuth.accessToken,
    idToken: googleAuth.idToken,
  );
  final userCredential = await _firebaseAuth.signInWithCredential(credential);
  return userCredential.user!;
}
```

### Auth Service Abstraction

Design for extensibility:

```dart
abstract class AuthService {
  Future<User> signIn();
  Future<void> signOut();
}

class GoogleAuthService implements AuthService {
  // Google-specific implementation
}

// Future: EmailAuthService, AppleAuthService, etc.
```

### Auth State Management

- Use Riverpod StreamProvider for auth state
- Listen to Firebase `authStateChanges()`
- Update router redirect logic based on auth state

### Sign-Out Functionality

```dart
Future<void> signOut() async {
  await Future.wait([
    _googleSignIn.signOut(),
    _firebaseAuth.signOut(),
  ]);
}
```

## Firebase Integration

### Authentication Flow

1. Initialize Firebase in `main.dart`
2. Configure Firebase Auth
3. Implement sign-in methods
4. Listen to auth state changes
5. Update UI based on auth state

### Push Notification Handling

- Configure Firebase Messaging
- Request permissions
- Handle foreground/background messages
- Process deep links from notifications

### Analytics Events

```dart
await FirebaseAnalytics.instance.logEvent(
  name: 'workflow_toggled',
  parameters: {'workflow_id': id, 'enabled': enabled},
);
```

## Analytics, Crashlytics, and Performance (REQUIRED)

### Initialization

All three services MUST be initialized in `main.dart`:

```dart
// Initialize Crashlytics
FlutterError.onError = (errorDetails) {
  FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
};

PlatformDispatcher.instance.onError = (error, stack) {
  FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  return true;
};

// Initialize Performance Monitoring
final performance = FirebasePerformance.instance;
performance.setPerformanceCollectionEnabled(true);
```

### Analytics Service Pattern

Use a centralized `AnalyticsService` for all analytics tracking:

```dart
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;
  final FirebasePerformance _performance = FirebasePerformance.instance;
  
  // Set user ID (MUST be called after login)
  Future<void> setUserId(String userId) async {
    await _analytics.setUserId(id: userId);
    await _crashlytics.setUserIdentifier(userId);
  }
  
  // Log success events
  Future<void> logSuccess({
    required String action,
    Map<String, Object>? parameters,
  }) async {
    await _analytics.logEvent(
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
    await _analytics.logEvent(
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
  
  // Performance tracing
  Trace? startTrace(String name) {
    return _performance.newTrace(name);
  }
  
  // Screen view tracking
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

### Required Analytics Events

Every service method MUST log analytics:

1. **Success Events**: Log when operations complete successfully
   - Format: `{action}_success`
   - Include: action name, user_id, relevant parameters

2. **Failure Events**: Log when operations fail
   - Format: `{action}_failure`
   - Include: action name, error message, user_id, relevant parameters
   - Also send to Crashlytics as non-fatal error

3. **Performance Traces**: Track operation duration
   - Start trace before operation
   - Stop trace after operation (success or failure)

4. **Screen Views**: Track navigation
   - Log every screen view
   - Include screen name and class

### Integration Pattern

Every service/repository MUST integrate analytics:

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

### User ID Tracking

MUST set user ID after authentication:

```dart
// After successful login
await analyticsService.setUserId(user.id);

// After logout
await analyticsService.setUserId(null); // or clear
```

### Screen View Tracking

MUST track all screen views in route builders:

```dart
@override
Widget build(BuildContext context, GoRouterState state) {
  final analytics = ref.read(analyticsServiceProvider);
  
  WidgetsBinding.instance.addPostFrameCallback((_) {
    analytics.logScreenView(
      screenName: 'workflow_details',
      screenClass: 'WorkflowDetailsPage',
    );
  });
  
  return WorkflowDetailsPage();
}
```

### Crashlytics Integration

- All fatal errors automatically captured
- Non-fatal errors logged via `logFailure`
- User identifiers set for crash attribution
- Custom keys can be set for additional context

### Performance Monitoring

- Track all API calls with traces
- Track user actions (toggles, refreshes, etc.)
- Monitor screen load times
- Track custom metrics

### Configuration Patterns

- Use `firebase_options.dart` (generated by flutterfire)
- Store configuration in environment-specific files
- Use flavors for different environments

## API Client (Dio)

### Base URL Configuration

```dart
_dio.options.baseUrl = 'https://api.flowdash.app';
_dio.options.connectTimeout = const Duration(seconds: 30);
_dio.options.receiveTimeout = const Duration(seconds: 30);
```

### Interceptors

#### Auth Interceptor

- Add JWT token to Authorization header
- Refresh token on 401 responses
- Handle token expiration

#### Logging Interceptor

- Log all requests and responses
- Include request/response bodies in debug mode
- Log errors with stack traces

#### Error Interceptor

- Transform DioExceptions to domain exceptions
- Handle network errors
- Provide user-friendly error messages

### Request/Response Models

- Use Pydantic-like models (json_serializable)
- Validate responses
- Handle null values gracefully

### Error Handling Patterns

```dart
try {
  final response = await _dio.get('/endpoint');
  return ResponseModel.fromJson(response.data);
} on DioException catch (e) {
  if (e.response?.statusCode == 401) {
    throw UnauthorizedException();
  }
  throw NetworkException(e.message);
}
```

## Local Storage (SharedPreferences)

### Key Naming Conventions

- Use prefix: `flowdash_`
- Use snake_case: `flowdash_user_token`
- Group related keys: `flowdash_auth_*`, `flowdash_cache_*`

### Data Serialization Patterns

```dart
// Store JSON
await _prefs.setString('flowdash_workflows', jsonEncode(workflows));

// Retrieve JSON
final json = _prefs.getString('flowdash_workflows');
final workflows = (jsonDecode(json!) as List)
    .map((w) => Workflow.fromJson(w))
    .toList();
```

### Cache Invalidation Strategies

- Set TTL (time-to-live) for cached data
- Invalidate on user action
- Invalidate on app version change
- Clear cache on logout

## Logging

### Logger Initialization Pattern

Every class/service/repository must initialize a logger:

```dart
class MyService {
  final Logger _logger = AppLogger.getLogger('MyService');
  
  Future<void> doSomething() async {
    _logger.info('doSomething: Entry');
    
    try {
      // Implementation
      _logger.info('doSomething: Success');
    } catch (e, stackTrace) {
      _logger.severe('doSomething: Failure', e, stackTrace);
      rethrow;
    }
  }
}
```

### Entry Logging

- Log method entry with method name
- Include relevant parameters (sanitize sensitive data)
- Use INFO level for entry

### Success/Failure Outcome Logging

- Log success with relevant data
- Log failures with exception and stack trace
- Use appropriate log levels:
  - `INFO`: Normal operations
  - `WARNING`: Recoverable issues
  - `SEVERE`: Errors requiring attention

### Logging Levels Configuration

```dart
Logger.root.level = Level.ALL; // Development
Logger.root.level = Level.INFO; // Production
```

### Logger Naming Conventions

- Use class/service name: `AppLogger.getLogger('AuthService')`
- Use feature prefix: `AppLogger.getLogger('auth.AuthService')`
- Keep names descriptive and consistent

### Log Format Standards

- Include timestamp
- Include log level
- Include logger name
- Include message
- Include error/stack trace for failures

## Code Organization

### Feature-Based Folder Structure

```
features/
  feature_name/
    data/
      datasources/
      models/
      repositories/
    domain/
      entities/
      repositories/
      usecases/
    presentation/
      providers/
      pages/
      widgets/
```

### Core vs Shared Modules

- **Core**: App-wide utilities, configs, constants
- **Shared**: Reusable widgets, themes, common components
- **Features**: Feature-specific code (isolated)

### Naming Conventions

- **Files**: snake_case (`auth_service.dart`)
- **Classes**: PascalCase (`AuthService`)
- **Variables**: camelCase (`authService`)
- **Constants**: lowerCamelCase with k prefix (`kApiBaseUrl`)
- **Private members**: _leadingUnderscore

## Error Handling

### Custom Exception Classes

```dart
abstract class AppException implements Exception {
  final String message;
  AppException(this.message);
}

class NetworkException extends AppException {
  NetworkException(super.message);
}

class UnauthorizedException extends AppException {
  UnauthorizedException() : super('Unauthorized');
}
```

### Error Display Patterns

- Show user-friendly messages
- Log technical details
- Provide retry options
- Handle offline scenarios

### Retry Logic

```dart
Future<T> retry<T>(Future<T> Function() fn, {int maxAttempts = 3}) async {
  for (int i = 0; i < maxAttempts; i++) {
    try {
      return await fn();
    } catch (e) {
      if (i == maxAttempts - 1) rethrow;
      await Future.delayed(Duration(seconds: i + 1));
    }
  }
  throw Exception('Max retries exceeded');
}
```

### Error Logging Integration

- Always log errors before displaying
- Include context in error logs
- Use appropriate log levels
- Don't log sensitive information
