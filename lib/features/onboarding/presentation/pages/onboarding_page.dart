import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/storage/local_storage_provider.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/onboarding/presentation/widgets/onboarding_slide.dart';

class OnboardingPage extends ConsumerStatefulWidget {
  const OnboardingPage({super.key});

  @override
  ConsumerState<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends ConsumerState<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  bool _analyticsConsent = true; // Default to true

  final List<Map<String, dynamic>> _slides = [
    {
      'title': 'Welcome to FlowDash',
      'description':
          'FlowDash helps you manage and automate your workflows and instances with ease. Get started by exploring the powerful features we offer.',
      'icon': Icons.dashboard,
    },
    {
      'title': 'Manage Your Workflows',
      'description':
          'Create, organize, and control your workflows from one central location. Toggle workflows on or off with a simple tap, and keep everything running smoothly.',
      'icon': Icons.settings_applications,
    },
    {
      'title': 'Control Your Instances',
      'description':
          'Connect and manage your instance(s) seamlessly. The number of instances you can manage depends on your plan. Monitor their status, activate or deactivate them as needed, and stay in control of your infrastructure.',
      'icon': Icons.cloud,
    },
    {
      'title': 'Flexible Plans',
      'description':
          'Choose the plan that fits your needs. From free tier to enterprise solutions, FlowDash scales with you. Upgrade or downgrade anytime.',
      'icon': Icons.card_membership,
    },
    {
      'title': 'Ready to Get Started?',
      'description':
          'You\'re all set! Start managing your workflows and instances right away. If you need help, check out our documentation or contact support.',
      'icon': Icons.rocket_launch,
    },
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Log screen view
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'onboarding',
        screenClass: 'OnboardingPage',
      );
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  Future<void> _completeOnboarding() async {
    final localStorage = ref.read(localStorageProvider);
    final analytics = ref.read(analyticsServiceProvider);
    final consentService = ref.read(analyticsConsentServiceProvider);

    try {
      // Save onboarding completion
      await localStorage.setHasCompletedOnboarding(true);
      
      // Save analytics consent (defaults to true if user didn't change it)
      await consentService.setAnalyticsConsent(_analyticsConsent);
      
      await analytics.logEvent(
        name: 'onboarding_completed',
        parameters: {
          'slide_count': _slides.length,
          'final_slide': _currentPage,
          'analytics_consent': _analyticsConsent,
        },
      );

      if (mounted) {
        const HomeRoute().go(context);
      }
    } catch (e) {
      // Log error but still navigate
      await analytics.logFailure(
        action: 'complete_onboarding',
        error: e.toString(),
      );
      if (mounted) {
        const HomeRoute().go(context);
      }
    }
  }

  void _skipOnboarding() {
    _completeOnboarding();
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isLastPage = _currentPage == _slides.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Skip button
            if (!isLastPage)
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: TextButton(
                    onPressed: _skipOnboarding,
                    child: const Text('Skip'),
                  ),
                ),
              ),

            // Page content
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: _onPageChanged,
                itemCount: _slides.length,
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  final isLastPage = index == _slides.length - 1;
                  
                  return Column(
                    children: [
                      Expanded(
                        child: OnboardingSlide(
                          title: slide['title'] as String,
                          description: slide['description'] as String,
                          icon: slide['icon'] as IconData,
                        ),
                      ),
                      // Analytics consent on last page
                      if (isLastPage)
                        Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32.0,
                            vertical: 16.0,
                          ),
                          child: Card(
                            child: SwitchListTile(
                              title: const Text('Enable Analytics'),
                              subtitle: const Text(
                                'Help us improve FlowDash by sharing anonymous usage data',
                                style: TextStyle(fontSize: 12),
                              ),
                              value: _analyticsConsent,
                              onChanged: (value) {
                                setState(() {
                                  _analyticsConsent = value;
                                });
                              },
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
            ),

            // Page indicator
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                _slides.length,
                (index) => Container(
                  margin: const EdgeInsets.symmetric(horizontal: 4.0),
                  width: _currentPage == index ? 24.0 : 8.0,
                  height: 8.0,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4.0),
                    color: _currentPage == index
                        ? theme.colorScheme.primary
                        : theme.colorScheme.primary.withValues(alpha: 0.3),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Navigation buttons
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 32.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Back button
                  if (_currentPage > 0)
                    TextButton(
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text('Back'),
                    )
                  else
                    const SizedBox.shrink(),

                  // Next/Get Started button
                  ElevatedButton(
                    onPressed: _nextPage,
                    child: Text(isLastPage ? 'Get Started' : 'Next'),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
