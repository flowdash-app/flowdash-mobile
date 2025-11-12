import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';

part 'workflow_model.freezed.dart';
part 'workflow_model.g.dart';

@freezed
sealed class WorkflowModel with _$WorkflowModel {
  const factory WorkflowModel({
    required String id,
    required String name,
    @Default(false) bool active,
    String? description,
    DateTime? updatedAt,
    DateTime? createdAt,
  }) = _WorkflowModel;

  factory WorkflowModel.fromJson(Map<String, dynamic> json) =>
      _$WorkflowModelFromJson(json);
}

extension WorkflowModelToEntity on WorkflowModel {
  Workflow toEntity() {
    return Workflow(
      id: id,
      name: name,
      active: active,
      description: description,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }
}

extension WorkflowToModel on Workflow {
  WorkflowModel toModel() {
    return WorkflowModel(
      id: id,
      name: name,
      active: active,
      description: description,
      updatedAt: updatedAt,
      createdAt: createdAt,
    );
  }
}

// Make WorkflowModel compatible with Workflow for existing code
extension WorkflowModelAsWorkflow on WorkflowModel {
  Workflow get asWorkflow => toEntity();
}
