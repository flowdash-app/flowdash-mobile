# FlowDash Mobile - Setup Notes

## Current Status

The Flutter project structure has been created with all core components:

✅ Project initialized with Flutter 3.35.7
✅ All dependencies installed and configured
✅ Core utilities (logger, analytics, error handling)
✅ Network layer (API client, interceptors)
✅ Authentication feature structure (domain, data, presentation)
✅ Routing setup with go_router_builder
✅ Shared widgets and theme
✅ Main.dart with Firebase initialization

## Remaining Tasks

### 1. Firebase Configuration (REQUIRED)

Before running the app, you need to:

1. **Create Firebase Project**
   - Go to [Firebase Console](https://console.firebase.google.com/)
   - Create a new project or use existing
   - Add Android and iOS apps

2. **Install FlutterFire CLI**
   ```bash
   dart pub global activate flutterfire_cli
   ```

3. **Configure Firebase**
   ```bash
   flutterfire configure
   ```
   This will generate `lib/firebase_options.dart` and update platform configs.

4. **Download Configuration Files**
   - `google-services.json` for Android → `android/app/`
   - `GoogleService-Info.plist` for iOS → `ios/Runner/`

### 2. Google Sign-In API Updates

The `google_sign_in` package version 7.2.0 may have API changes. The current implementation may need adjustments:

- Check if `signIn()` method exists or has been renamed
- Verify `GoogleSignInAuthentication` properties (`accessToken`, `idToken`)
- Update `GoogleSignIn` constructor if needed

**Location**: `lib/features/auth/data/datasources/auth_remote_datasource.dart`

### 3. Build and Run

After Firebase configuration:

```bash
# Generate route code
flutter pub run build_runner build --delete-conflicting-outputs

# Analyze code
flutter analyze

# Run on device
flutter run
```

### 4. Next Steps

- Implement workflows feature
- Implement instances feature  
- Add deep linking configuration
- Set up CI/CD pipeline
- Configure MCP server integration

## Project Structure

```
lib/
├── core/
│   ├── analytics/          # Analytics service
│   ├── constants/          # App constants
│   ├── errors/             # Exception classes
│   ├── network/            # API client & interceptors
│   ├── routing/            # go_router configuration
│   ├── storage/            # Local storage utilities
│   └── utils/              # Logger and utilities
├── features/
│   ├── auth/               # Authentication feature
│   ├── workflows/           # Workflows feature (to be implemented)
│   └── instances/          # Instances feature (to be implemented)
└── shared/
    ├── theme/              # App theme and colors
    └── widgets/           # Shared widgets
```

## Important Notes

- All services follow the logging pattern (Entry/Success/Failure)
- Analytics integration is ready but requires Firebase setup
- Router uses go_router_builder for type-safe navigation
- State management uses Riverpod with code generation
- Repository pattern implemented for clean architecture

