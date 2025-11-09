import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/storage/local_storage_provider.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  // Riverpod automatically manages the subscription lifecycle
  // The watch() call ensures router rebuilds when authState changes

  return GoRouter(
    routes: $appRoutes,
    redirect: (context, state) {
      // Handle loading state - don't redirect while checking auth
      if (authState.isLoading) {
        return null; // Stay on current route while loading
      }

      final isAuthenticated = authState.value != null;
      final currentLocation = state.matchedLocation;
      final isLoggingIn = currentLocation == LoginRoute().location;
      final isSplash = currentLocation == SplashRoute().location;
      final isOnboarding = currentLocation == OnboardingRoute().location;

      // If not authenticated, redirect to login (unless already on login or onboarding)
      if (!isAuthenticated) {
        if (!isLoggingIn && !isOnboarding) {
          return LoginRoute().location;
        }
        return null;
      }

      // If authenticated, check onboarding status
      if (isAuthenticated) {
        final localStorage = ref.read(localStorageProvider);
        final hasCompletedOnboarding = localStorage.hasCompletedOnboarding();

        // If on login/splash, redirect based on onboarding status
        if (isLoggingIn || isSplash) {
          if (!hasCompletedOnboarding) {
            return OnboardingRoute().location;
          } else {
            return HomeRoute().location;
          }
        }

        // If on onboarding but already completed, redirect to home
        if (isOnboarding && hasCompletedOnboarding) {
          return HomeRoute().location;
        }
      }

      return null;
    },
    debugLogDiagnostics: true,
  );
});
