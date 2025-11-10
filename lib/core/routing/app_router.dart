import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/pages/login_page.dart';
import 'package:flowdash_mobile/features/auth/presentation/pages/splash_page.dart';
import 'package:flowdash_mobile/features/home/presentation/pages/main_tab_page.dart';
import 'package:flowdash_mobile/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:flowdash_mobile/features/instances/presentation/pages/add_instance_page.dart';
import 'package:flowdash_mobile/features/settings/presentation/pages/privacy_policy_page.dart';
import 'package:flowdash_mobile/features/settings/presentation/pages/terms_of_service_page.dart';
import 'package:flowdash_mobile/features/settings/presentation/pages/analytics_consent_page.dart';
import 'package:flowdash_mobile/features/settings/presentation/pages/about_page.dart';
import 'package:flowdash_mobile/features/workflows/presentation/pages/workflow_details_page.dart';

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
  Widget build(BuildContext context, GoRouterState state) =>
      const MainTabPage(key: ValueKey('main_tab_page'), initialIndex: 0);
}

// Nested tab routes
@TypedGoRoute<HomeWorkflowsRoute>(path: '/home/workflows')
class HomeWorkflowsRoute extends GoRouteData with $HomeWorkflowsRoute {
  const HomeWorkflowsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainTabPage(key: ValueKey('main_tab_page'), initialIndex: 1);
}

@TypedGoRoute<HomeInstancesRoute>(path: '/home/instances')
class HomeInstancesRoute extends GoRouteData with $HomeInstancesRoute {
  const HomeInstancesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainTabPage(key: ValueKey('main_tab_page'), initialIndex: 2);
}

@TypedGoRoute<AddInstanceRoute>(path: '/instances/add')
class AddInstanceRoute extends GoRouteData with $AddInstanceRoute {
  const AddInstanceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AddInstancePage();
}

@TypedGoRoute<HomeSettingsRoute>(path: '/home/settings')
class HomeSettingsRoute extends GoRouteData with $HomeSettingsRoute {
  const HomeSettingsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainTabPage(key: ValueKey('main_tab_page'), initialIndex: 3);
}

// Standalone routes for deep linking (will redirect to tab view)
@TypedGoRoute<WorkflowsRoute>(path: '/workflows')
class WorkflowsRoute extends GoRouteData with $WorkflowsRoute {
  const WorkflowsRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainTabPage(initialIndex: 1);
}

@TypedGoRoute<InstancesRoute>(path: '/instances')
class InstancesRoute extends GoRouteData with $InstancesRoute {
  const InstancesRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const MainTabPage(initialIndex: 2);
}

@TypedGoRoute<WorkflowDetailsRoute>(path: '/workflows/:workflowId')
class WorkflowDetailsRoute extends GoRouteData with $WorkflowDetailsRoute {
  final String workflowId;
  final String instanceId;
  final String instanceName;

  const WorkflowDetailsRoute({
    required this.workflowId,
    required this.instanceId,
    required this.instanceName,
  });

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      WorkflowDetailsPage(
        workflowId: workflowId,
        instanceId: instanceId,
        instanceName: instanceName,
      );
}

// Settings nested routes
@TypedGoRoute<PrivacyPolicyRoute>(path: '/privacy-policy')
class PrivacyPolicyRoute extends GoRouteData with $PrivacyPolicyRoute {
  const PrivacyPolicyRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const PrivacyPolicyPage();
}

@TypedGoRoute<TermsOfServiceRoute>(path: '/terms-of-service')
class TermsOfServiceRoute extends GoRouteData with $TermsOfServiceRoute {
  const TermsOfServiceRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const TermsOfServicePage();
}

@TypedGoRoute<AnalyticsConsentRoute>(path: '/analytics-consent')
class AnalyticsConsentRoute extends GoRouteData with $AnalyticsConsentRoute {
  const AnalyticsConsentRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AnalyticsConsentPage();
}

@TypedGoRoute<AboutRoute>(path: '/about')
class AboutRoute extends GoRouteData with $AboutRoute {
  const AboutRoute();

  @override
  Widget build(BuildContext context, GoRouterState state) =>
      const AboutPage();
}
