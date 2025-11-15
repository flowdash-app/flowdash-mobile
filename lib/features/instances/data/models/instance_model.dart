import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';

part 'instance_model.freezed.dart';
part 'instance_model.g.dart';

@freezed
sealed class InstanceModel with _$InstanceModel {
  const factory InstanceModel({
    required String id,
    required String name,
    required String url,
    @JsonKey(name: 'enabled', fromJson: _activeFromJson) @Default(false) bool active,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? lastConnectedAt,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? createdAt,
  }) = _InstanceModel;

  factory InstanceModel.fromJson(Map<String, dynamic> json) =>
      _$InstanceModelFromJson(json);
}

// JSON conversion helpers
// The json parameter is the value of the 'enabled' field from the backend
bool _activeFromJson(dynamic json) {
  if (json == null) return false;
  if (json is bool) return json;
  // Handle string representations
  if (json is String) {
    return json.toLowerCase() == 'true';
  }
  return false;
}

DateTime? _dateTimeFromJson(dynamic json) {
  if (json == null) return null;
  if (json is String) {
    try {
      return DateTime.parse(json);
    } catch (e) {
      return null;
    }
  }
  return null;
}

extension InstanceModelToEntity on InstanceModel {
  Instance toEntity() {
    return Instance(
      id: id,
      name: name,
      url: url,
      active: active,
      lastConnectedAt: lastConnectedAt,
      createdAt: createdAt,
    );
  }
}

extension InstanceToModel on Instance {
  InstanceModel toModel() {
    return InstanceModel(
      id: id,
      name: name,
      url: url,
      active: active,
      lastConnectedAt: lastConnectedAt,
      createdAt: createdAt,
    );
  }
}
