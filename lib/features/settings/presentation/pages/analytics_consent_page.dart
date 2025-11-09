import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

class AnalyticsConsentPage extends ConsumerStatefulWidget {
  const AnalyticsConsentPage({super.key});

  @override
  ConsumerState<AnalyticsConsentPage> createState() =>
      _AnalyticsConsentPageState();
}

class _AnalyticsConsentPageState extends ConsumerState<AnalyticsConsentPage> {
  bool _consentEnabled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final consentService = ref.read(analyticsConsentServiceProvider);
      setState(() {
        _consentEnabled = consentService.hasUserConsented();
      });
    });
  }

  Future<void> _updateConsent(bool enabled) async {
    final consentService = ref.read(analyticsConsentServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    await consentService.setAnalyticsConsent(enabled);
    setState(() {
      _consentEnabled = enabled;
    });

    analytics.logEvent(
      name: 'analytics_consent_changed',
      parameters: {'enabled': enabled},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics & Privacy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          const Text(
            'Analytics Data Collection',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'We collect anonymous usage data to help improve FlowDash. This includes:',
            style: TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 8),
          const Padding(
            padding: EdgeInsets.only(left: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('• Screen views and navigation'),
                Text('• Feature usage (workflows, instances)'),
                Text('• App performance metrics'),
                Text('• Error reports (for debugging)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'This data is anonymous and cannot be used to identify you. You can change this setting at any time.',
            style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 24),
          Card(
            child: SwitchListTile(
              title: const Text('Enable Analytics Collection'),
              subtitle: Text(
                _consentEnabled
                    ? 'Analytics collection is enabled'
                    : 'Analytics collection is disabled',
              ),
              value: _consentEnabled,
              onChanged: _updateConsent,
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () {
              const PrivacyPolicyRoute().push(context);
            },
            child: const Text('View Privacy Policy'),
          ),
        ],
      ),
    );
  }
}

