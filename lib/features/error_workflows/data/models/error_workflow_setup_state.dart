import 'package:freezed_annotation/freezed_annotation.dart';

part 'error_workflow_setup_state.freezed.dart';
part 'error_workflow_setup_state.g.dart';

/// Represents the setup state of error workflow notifications for an n8n instance.
///
/// This state is stored locally per instance to track whether the user has
/// configured error notifications and when they last tested it.
@freezed
sealed class ErrorWorkflowSetupState with _$ErrorWorkflowSetupState {
  const factory ErrorWorkflowSetupState({
    /// FlowDash instance ID (UUID) this state belongs to
    required String instanceId,

    /// Whether error workflow setup is complete
    @Default(false) bool isSetupComplete,

    /// Setup method used: 'automatic', 'manual', or 'none'
    @Default('none') String setupMethod,

    /// n8n workflow ID (only if created automatically)
    String? workflowId,

    /// When the workflow was last set up
    DateTime? lastSetupDate,

    /// Whether a test notification was successfully sent
    bool? hasTestedNotification,
  }) = _ErrorWorkflowSetupState;

  factory ErrorWorkflowSetupState.fromJson(Map<String, dynamic> json) =>
      _$ErrorWorkflowSetupStateFromJson(json);
}
