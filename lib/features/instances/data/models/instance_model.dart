import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';

class InstanceModel extends Instance {
  const InstanceModel({
    required super.id,
    required super.name,
    required super.url,
    required super.active,
    super.lastConnectedAt,
    super.createdAt,
  });

  factory InstanceModel.fromJson(Map<String, dynamic> json) {
    return InstanceModel(
      id: json['id'] as String,
      name: json['name'] as String,
      url: json['url'] as String,
      active: json['active'] as bool? ?? false,
      lastConnectedAt: json['lastConnectedAt'] != null
          ? DateTime.parse(json['lastConnectedAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'url': url,
      'active': active,
      if (lastConnectedAt != null)
        'lastConnectedAt': lastConnectedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }

  @override
  InstanceModel copyWith({
    String? id,
    String? name,
    String? url,
    bool? active,
    DateTime? lastConnectedAt,
    DateTime? createdAt,
  }) {
    return InstanceModel(
      id: id ?? this.id,
      name: name ?? this.name,
      url: url ?? this.url,
      active: active ?? this.active,
      lastConnectedAt: lastConnectedAt ?? this.lastConnectedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
