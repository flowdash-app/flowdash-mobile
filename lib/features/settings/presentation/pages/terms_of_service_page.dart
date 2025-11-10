import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

class TermsOfServicePage extends ConsumerStatefulWidget {
  const TermsOfServicePage({super.key});

  @override
  ConsumerState<TermsOfServicePage> createState() =>
      _TermsOfServicePageState();
}

class _TermsOfServicePageState extends ConsumerState<TermsOfServicePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'terms_of_service',
        screenClass: 'TermsOfServicePage',
      );
    });
  }

  String _getLastUpdatedDate() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            title: const Text('Terms of Service'),
            floating: true,
            snap: true,
          ),
          SliverPadding(
            padding: const EdgeInsets.all(16.0),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Last updated: ${_getLastUpdatedDate()}',
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            SizedBox(height: 24),
            Text(
              '1. Acceptance of Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'By using FlowDash, you agree to be bound by these Terms of Service. If you do not agree, please do not use the service.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              '2. Use of Service',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'You agree to use FlowDash only for lawful purposes and in accordance with these Terms. You are responsible for maintaining the security of your account.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              '3. Service Availability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We strive to provide reliable service but do not guarantee uninterrupted access. We reserve the right to modify or discontinue the service at any time.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              '4. Limitation of Liability',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'FlowDash is provided "as is" without warranties. We are not liable for any damages arising from use of the service.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 24),
            Text(
              '5. Changes to Terms',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'We reserve the right to modify these terms at any time. Continued use of the service constitutes acceptance of modified terms.',
              style: TextStyle(fontSize: 16),
            ),
              ],
            ),
              ]),
            ),
          ),
        ],
      ),
    );
  }
}

