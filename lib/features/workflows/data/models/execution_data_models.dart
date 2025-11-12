import 'package:freezed_annotation/freezed_annotation.dart';

part 'execution_data_models.freezed.dart';
part 'execution_data_models.g.dart';

/// Root execution data structure
@freezed
sealed class ExecutionData with _$ExecutionData {
  const factory ExecutionData({
    ResultData? resultData,
    Map<String, dynamic>? executionData,
  }) = _ExecutionData;

  factory ExecutionData.fromJson(Map<String, dynamic> json) =>
      _$ExecutionDataFromJson(json);
}

/// Result data containing run data for nodes
@freezed
sealed class ResultData with _$ResultData {
  const factory ResultData({
    Map<String, NodeRunData>? runData,
  }) = _ResultData;

  factory ResultData.fromJson(Map<String, dynamic> json) =>
      _$ResultDataFromJson(json);
}

/// Individual node execution data
@freezed
sealed class NodeRunData with _$NodeRunData {
  const factory NodeRunData({
    List<List<NodeMainData>>? main,
    String? type,
    String? error,
  }) = _NodeRunData;

  factory NodeRunData.fromJson(Map<String, dynamic> json) =>
      _$NodeRunDataFromJson(json);
}

/// Node main data item (contains json field)
@freezed
sealed class NodeMainData with _$NodeMainData {
  const factory NodeMainData({
    Map<String, dynamic>? json,
  }) = _NodeMainData;

  factory NodeMainData.fromJson(Map<String, dynamic> json) =>
      _$NodeMainDataFromJson(json);
}

