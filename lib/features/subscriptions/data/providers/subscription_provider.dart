import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/network/api_client_provider.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/subscriptions/data/repositories/subscription_repository.dart';
import 'package:flowdash_mobile/features/subscriptions/data/models/subscription_model.dart';

final subscriptionRepositoryProvider = Provider<SubscriptionRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return SubscriptionRepository(
    apiClient: apiClient,
    analytics: analytics,
  );
});

final currentSubscriptionProvider =
    FutureProvider<SubscriptionModel>((ref) async {
  final repository = ref.watch(subscriptionRepositoryProvider);
  return repository.getCurrentSubscription();
});

