import 'package:freezed_annotation/freezed_annotation.dart';

part 'plan_model.freezed.dart';
part 'plan_model.g.dart';

@freezed
sealed class PlanModel with _$PlanModel {
  const factory PlanModel({
    required String tier,
    required String name,
    required double priceMonthly,
    required double priceYearly,
    required List<String> features,
    @Default(false) bool recommended,
  }) = _PlanModel;

  factory PlanModel.fromJson(Map<String, dynamic> json) => _$PlanModelFromJson(json);
}

@freezed
sealed class PlansResponse with _$PlansResponse {
  const factory PlansResponse({required List<PlanModel> plans}) = _PlansResponse;

  factory PlansResponse.fromJson(Map<String, dynamic> json) => _$PlansResponseFromJson(json);
}
