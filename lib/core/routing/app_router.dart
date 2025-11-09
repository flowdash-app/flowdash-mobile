import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flowdash_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:flowdash_mobile/features/home/presentation/pages/home_page.dart';
import 'package:flowdash_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flowdash_mobile/features/workflows/presentation/pages/workflows_page.dart';
import 'package:flowdash_mobile/features/instances/presentation/pages/instances_page.dart';

part 'app_router.g.dart';

@TypedGoRoute<SplashRoute>(path: '/')
class SplashRoute extends GoRouteData with $SplashRoute {
  const SplashRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const SplashPage();
}

@TypedGoRoute<LoginRoute>(path: '/login')
class LoginRoute extends GoRouteData with $LoginRoute {
  const LoginRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const LoginPage();
}

@TypedGoRoute<OnboardingRoute>(path: '/onboarding')
class OnboardingRoute extends GoRouteData with $OnboardingRoute {
  const OnboardingRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const OnboardingPage();
}

@TypedGoRoute<HomeRoute>(path: '/home')
class HomeRoute extends GoRouteData with $HomeRoute {
  const HomeRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) => const HomePage();
}

@TypedGoRoute<WorkflowsRoute>(path: '/workflows')
class WorkflowsRoute extends GoRouteData with $WorkflowsRoute {
  const WorkflowsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const WorkflowsPage();
}

@TypedGoRoute<InstancesRoute>(path: '/instances')
class InstancesRoute extends GoRouteData with $InstancesRoute {
  const InstancesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const InstancesPage();
}
