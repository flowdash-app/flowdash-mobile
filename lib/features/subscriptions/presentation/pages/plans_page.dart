import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:flowdash_mobile/features/subscriptions/data/providers/subscription_provider.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

class PlansPage extends ConsumerStatefulWidget {
  const PlansPage({super.key});

  @override
  ConsumerState<PlansPage> createState() => _PlansPageState();
}

class _PlansPageState extends ConsumerState<PlansPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'plans',
        screenClass: 'PlansPage',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final repository = ref.read(subscriptionRepositoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Subscription Plans'),
      ),
      body: FutureBuilder(
        future: repository.getPlans(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error loading plans: ${snapshot.error}'),
                ],
              ),
            );
          }

          final plans = snapshot.data ?? [];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: plans.length,
            itemBuilder: (context, index) {
              final plan = plans[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            plan.name,
                            style: Theme.of(context).textTheme.headlineSmall,
                          ),
                          if (plan.recommended) ...[
                            const SizedBox(width: 8),
                            Chip(
                              label: const Text('Recommended'),
                              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        plan.priceMonthly > 0
                            ? '\$${plan.priceMonthly.toStringAsFixed(2)}/month'
                            : 'Free',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      if (plan.priceYearly > 0) ...[
                        Text(
                          '\$${plan.priceYearly.toStringAsFixed(2)}/year',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ],
                      const SizedBox(height: 16),
                      ...plan.features.map((feature) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.check_circle_outline,
                                  size: 20,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(child: Text(feature)),
                              ],
                            ),
                          )),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: plan.priceMonthly > 0
                              ? () {
                                  // TODO: Implement in-app purchase flow
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'In-app purchases will be implemented soon',
                                      ),
                                    ),
                                  );
                                }
                              : null,
                          child: Text(
                            plan.priceMonthly > 0 ? 'Upgrade' : 'Current Plan',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

