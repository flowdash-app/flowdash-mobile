import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/error_workflows/presentation/widgets/carousel_item_wrapper.dart';
import 'package:flowdash_mobile/features/error_workflows/presentation/widgets/instance_id_copy_card.dart';
import 'package:flowdash_mobile/features/error_workflows/presentation/widgets/plan_requirement_banner.dart';
import 'package:flowdash_mobile/features/error_workflows/presentation/widgets/setup_method_card.dart';
import 'package:flowdash_mobile/features/error_workflows/presentation/widgets/test_notification_card.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';
import 'package:flowdash_mobile/features/subscriptions/data/models/subscription_model.dart';
import 'package:go_router/go_router.dart';

/// Error Workflow Onboarding Page with Material Design CarouselView.
/// 
/// Guides users through setting up error notifications with 5 carousel items:
/// 1. Welcome & Introduction
/// 2. Plan Requirement Check
/// 3. Setup Method Selection (Automatic/Manual)
/// 4. Import Instructions (Manual path only)
/// 5. Test & Verify
class ErrorWorkflowOnboardingPage extends ConsumerStatefulWidget {
  final Instance instance;
  final SubscriptionModel subscription;

  const ErrorWorkflowOnboardingPage({
    super.key,
    required this.instance,
    required this.subscription,
  });

  @override
  ConsumerState<ErrorWorkflowOnboardingPage> createState() =>
      _ErrorWorkflowOnboardingPageState();
}

class _ErrorWorkflowOnboardingPageState
    extends ConsumerState<ErrorWorkflowOnboardingPage> {
  int _currentIndex = 0;
  String? _setupMethod; // 'automatic' or 'manual'
  bool _isAutoLoading = false;
  bool _isAutoSuccess = false;
  bool _isAutoError = false;
  String? _autoErrorMessage;
  bool _isManualLoading = false;
  bool _isTestLoading = false;
  bool _isTestSuccess = false;
  bool _isTestError = false;
  String? _testErrorMessage;
  final CancelToken _cancelToken = CancelToken();

  bool get _meetsRequirement =>
      widget.subscription.limits.pushNotifications;

  @override
  void dispose() {
    _cancelToken.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Error Notifications'),
        actions: [
          if (_currentIndex < 4)
            TextButton(
              onPressed: () => context.pop(),
              child: const Text('Skip'),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Progress indicator
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  5,
                  (index) => Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: index == _currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : Theme.of(context)
                              .colorScheme
                              .onSurface
                              .withOpacity(0.3),
                    ),
                  ),
                ),
              ),
            ),
            // Carousel
            Expanded(
              child: CarouselView(
                itemExtent: MediaQuery.of(context).size.width * 0.9,
                shrinkExtent: MediaQuery.of(context).size.width * 0.8,
                padding: const EdgeInsets.all(16),
                onTap: (index) {
                  // Optional: advance on tap
                },
                children: [
                  _buildWelcomeItem(),
                  _buildPlanCheckItem(),
                  _buildSetupMethodItem(),
                  if (_setupMethod == 'manual') _buildImportInstructionsItem(),
                  _buildTestItem(),
                ],
              ),
            ),
            // Navigation buttons
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeItem() {
    return CarouselItemWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_active,
            size: 120,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'Never Miss a Workflow Failure',
            style: Theme.of(context).textTheme.headlineMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Get instant push notifications when your n8n workflows encounter errors',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPlanCheckItem() {
    return CarouselItemWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PlanRequirementBanner(
            currentPlan: widget.subscription.planTier,
            meetsRequirement: _meetsRequirement,
            onUpgrade: () {
              // Navigate to plans page
              context.go('/plans');
            },
          ),
          const SizedBox(height: 24),
          InstanceIdCopyCard(
            instanceId: widget.instance.id,
            instanceName: widget.instance.name,
          ),
        ],
      ),
    );
  }

  Widget _buildSetupMethodItem() {
    if (!_meetsRequirement) {
      return CarouselItemWrapper(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 24),
            Text(
              'Pro Plan Required',
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Upgrade to Pro or higher to set up error notifications',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return CarouselItemWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Choose Setup Method',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          SetupMethodCard(
            icon: Icons.rocket_launch,
            title: 'Automatic',
            description: 'One tap - we\'ll create it for you',
            isRecommended: true,
            isLoading: _isAutoLoading,
            isSuccess: _isAutoSuccess,
            isError: _isAutoError,
            errorMessage: _autoErrorMessage,
            onTap: _handleAutomaticSetup,
          ),
          const SizedBox(height: 16),
          SetupMethodCard(
            icon: Icons.download,
            title: 'Manual',
            description: 'Download and import yourself',
            isLoading: _isManualLoading,
            onTap: _handleManualSetup,
          ),
        ],
      ),
    );
  }

  Widget _buildImportInstructionsItem() {
    return CarouselItemWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.info_outline,
            size: 64,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Import into n8n',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          _buildStep(1, 'Open your n8n instance'),
          _buildStep(2, 'Go to Workflows → Import from File'),
          _buildStep(3, 'Select the downloaded workflow'),
          _buildStep(4, 'Activate the workflow'),
        ],
      ),
    );
  }

  Widget _buildTestItem() {
    return CarouselItemWrapper(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 80,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'Test It Now!',
            style: Theme.of(context).textTheme.headlineSmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          Text(
            'Send a test notification to verify everything works',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          TestNotificationCard(
            onTest: _handleTest,
            isLoading: _isTestLoading,
            isSuccess: _isTestSuccess,
            isError: _isTestError,
            errorMessage: _testErrorMessage,
          ),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              text,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: _currentIndex == 4 && _isTestSuccess
            ? FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Done'),
              )
            : Row(
                children: [
                  if (_currentIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          setState(() {
                            _currentIndex--;
                          });
                        },
                        child: const Text('Back'),
                      ),
                    ),
                  if (_currentIndex > 0) const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: FilledButton(
                      onPressed: _canAdvance()
                          ? () {
                              setState(() {
                                _currentIndex++;
                              });
                            }
                          : null,
                      child: const Text('Next'),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  bool _canAdvance() {
    // Logic to determine if user can proceed to next step
    if (_currentIndex == 1 && !_meetsRequirement) return false;
    if (_currentIndex == 2 && _setupMethod == null) return false;
    return true;
  }

  Future<void> _handleAutomaticSetup() async {
    setState(() {
      _isAutoLoading = true;
      _isAutoError = false;
      _autoErrorMessage = null;
    });

    try {
      // TODO: Call service to create workflow automatically
      // final result = await ref.read(errorWorkflowServiceProvider)
      //     .createWorkflowAutomatically(...);
      
      await Future.delayed(const Duration(seconds: 2)); // Placeholder

      setState(() {
        _isAutoLoading = false;
        _isAutoSuccess = true;
        _setupMethod = 'automatic';
        // _workflowId would be set from result['workflow_id'] in real implementation
      });

      // Auto-advance to test after short delay
      Future.delayed(const Duration(milliseconds: 1500), () {
        if (mounted) {
          setState(() {
            _currentIndex = 4; // Jump to test
          });
        }
      });
    } catch (e) {
      setState(() {
        _isAutoLoading = false;
        _isAutoError = true;
        _autoErrorMessage = e.toString();
      });
    }
  }

  Future<void> _handleManualSetup() async {
    setState(() {
      _isManualLoading = true;
      _setupMethod = 'manual';
    });

    try {
      // TODO: Call service to download template
      // await ref.read(errorWorkflowServiceProvider)
      //     .downloadWorkflowTemplate(...);

      await Future.delayed(const Duration(seconds: 1)); // Placeholder

      setState(() {
        _isManualLoading = false;
      });

      // Advance to import instructions
      setState(() {
        _currentIndex++;
      });
    } catch (e) {
      setState(() {
        _isManualLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to download template: $e')),
        );
      }
    }
  }

  Future<void> _handleTest() async {
    setState(() {
      _isTestLoading = true;
      _isTestError = false;
      _isTestSuccess = false;
      _testErrorMessage = null;
    });

    try {
      // TODO: Call service to send test notification
      // await ref.read(errorWorkflowServiceProvider)
      //     .sendTestNotification(...);

      await Future.delayed(const Duration(seconds: 2)); // Placeholder

      setState(() {
        _isTestLoading = false;
        _isTestSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isTestLoading = false;
        _isTestError = true;
        _testErrorMessage = e.toString();
      });
    }
  }
}

