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
    @JsonKey(fromJson: _activeFromJson) @Default(false) bool active,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? lastConnectedAt,
    @JsonKey(fromJson: _dateTimeFromJson) DateTime? createdAt,
  }) = _InstanceModel;

  factory InstanceModel.fromJson(Map<String, dynamic> json) =>
      _$InstanceModelFromJson(json);
}

// JSON conversion helpers
bool _activeFromJson(dynamic json) {
  if (json == null) return false;
  if (json is bool) return json;
  // Backend returns 'enabled' but we use 'active' internally
  if (json is Map) {
    return json['enabled'] as bool? ?? json['active'] as bool? ?? false;
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
