import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';

class WorkflowModel extends Workflow {
  const WorkflowModel({
    required super.id,
    required super.name,
    required super.active,
    super.description,
    super.updatedAt,
    super.createdAt,
  });
  
  factory WorkflowModel.fromJson(Map<String, dynamic> json) {
    return WorkflowModel(
      id: json['id'] as String,
      name: json['name'] as String,
      active: json['active'] as bool? ?? false,
      description: json['description'] as String?,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
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
      'active': active,
      if (description != null) 'description': description,
      if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
    };
  }
  
  @override
  WorkflowModel copyWith({
    String? id,
    String? name,
    bool? active,
    String? description,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) {
    return WorkflowModel(
      id: id ?? this.id,
      name: name ?? this.name,
      active: active ?? this.active,
      description: description ?? this.description,
      updatedAt: updatedAt ?? this.updatedAt,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

