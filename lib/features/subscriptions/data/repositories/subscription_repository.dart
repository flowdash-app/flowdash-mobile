import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/analytics/analytics_service.dart';
import 'package:flowdash_mobile/core/network/api_client.dart';
import 'package:flowdash_mobile/features/subscriptions/data/models/plan_model.dart';
import 'package:flowdash_mobile/features/subscriptions/data/models/subscription_model.dart';
import 'package:logging/logging.dart';

class SubscriptionRepository {
  final ApiClient _apiClient;
  final AnalyticsService _analytics;
  final Logger _logger = Logger('SubscriptionRepository');

  SubscriptionRepository({required ApiClient apiClient, required AnalyticsService analytics})
    : _apiClient = apiClient,
      _analytics = analytics;

  Future<List<PlanModel>> getPlans({CancelToken? cancelToken}) async {
    _logger.info('getPlans: Entry');

    try {
      final response = await _apiClient.dio.get('/subscriptions/plans', cancelToken: cancelToken);

      final plansResponse = PlansResponse.fromJson(response.data);

      _analytics.logSuccess(action: 'get_plans', parameters: {'count': plansResponse.plans.length});
      _logger.info('getPlans: Success - ${plansResponse.plans.length} plans');
      return plansResponse.plans;
    } catch (e, stackTrace) {
      _analytics.logFailure(action: 'get_plans', error: e.toString());
      _logger.severe('getPlans: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<SubscriptionModel> getCurrentSubscription({CancelToken? cancelToken}) async {
    _logger.info('getCurrentSubscription: Entry');

    try {
      final response = await _apiClient.dio.get('/subscriptions/current', cancelToken: cancelToken);

      final subscription = SubscriptionModel.fromJson(response.data);

      _analytics.logSuccess(
        action: 'get_current_subscription',
        parameters: {'plan_tier': subscription.planTier},
      );
      _logger.info('getCurrentSubscription: Success - tier: ${subscription.planTier}');
      return subscription;
    } catch (e, stackTrace) {
      _analytics.logFailure(action: 'get_current_subscription', error: e.toString());
      _logger.severe('getCurrentSubscription: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<VerifyPurchaseResponse> verifyPurchase({
    required VerifyPurchaseRequest request,
    CancelToken? cancelToken,
  }) async {
    _logger.info('verifyPurchase: Entry - tier: ${request.planTier}');

    try {
      final response = await _apiClient.dio.post(
        '/subscriptions/verify',
        data: request.toJson(),
        cancelToken: cancelToken,
      );

      final verifyResponse = VerifyPurchaseResponse.fromJson(response.data);

      _analytics.logSuccess(
        action: 'verify_purchase',
        parameters: {
          'plan_tier': request.planTier,
          'billing_period': request.billingPeriod,
          'platform': request.platform,
        },
      );
      _logger.info('verifyPurchase: Success - ${verifyResponse.subscriptionId}');
      return verifyResponse;
    } catch (e, stackTrace) {
      _analytics.logFailure(
        action: 'verify_purchase',
        error: e.toString(),
        parameters: {'plan_tier': request.planTier, 'platform': request.platform},
      );
      _logger.severe('verifyPurchase: Failure', e, stackTrace);
      rethrow;
    }
  }

  Future<void> cancelSubscription({CancelToken? cancelToken}) async {
    _logger.info('cancelSubscription: Entry');

    try {
      await _apiClient.dio.post('/subscriptions/cancel', cancelToken: cancelToken);

      _analytics.logSuccess(action: 'cancel_subscription');
      _logger.info('cancelSubscription: Success');
    } catch (e, stackTrace) {
      _analytics.logFailure(action: 'cancel_subscription', error: e.toString());
      _logger.severe('cancelSubscription: Failure', e, stackTrace);
      rethrow;
    }
  }
}
