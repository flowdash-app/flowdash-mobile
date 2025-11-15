import 'package:freezed_annotation/freezed_annotation.dart';

part 'subscription_model.freezed.dart';
part 'subscription_model.g.dart';

@freezed
sealed class SubscriptionModel with _$SubscriptionModel {
  const factory SubscriptionModel({
    required String userId,
    required String planTier,
    required String planName,
    required String status,
    String? billingPeriod,
    String? platform,
    String? startDate,
    String? endDate,
    required SubscriptionLimits limits,
  }) = _SubscriptionModel;

  factory SubscriptionModel.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionModelFromJson(json);
}

@freezed
sealed class SubscriptionLimits with _$SubscriptionLimits {
  const factory SubscriptionLimits({
    required int togglesPerDay,
    required int refreshesPerDay,
    required int errorViewsPerDay,
    required int triggers,
    required int maxInstances,
    required bool pushNotifications,
  }) = _SubscriptionLimits;

  factory SubscriptionLimits.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionLimitsFromJson(json);
}

@freezed
sealed class VerifyPurchaseRequest with _$VerifyPurchaseRequest {
  const factory VerifyPurchaseRequest({
    required String planTier,
    required String billingPeriod,
    required String platform,
    required String purchaseToken,
    String? receiptData,
  }) = _VerifyPurchaseRequest;

  factory VerifyPurchaseRequest.fromJson(Map<String, dynamic> json) =>
      _$VerifyPurchaseRequestFromJson(json);
}

@freezed
sealed class VerifyPurchaseResponse with _$VerifyPurchaseResponse {
  const factory VerifyPurchaseResponse({
    required String subscriptionId,
    required String planTier,
    required String status,
    required String startDate,
    String? endDate,
    required String message,
  }) = _VerifyPurchaseResponse;

  factory VerifyPurchaseResponse.fromJson(Map<String, dynamic> json) =>
      _$VerifyPurchaseResponseFromJson(json);
}
