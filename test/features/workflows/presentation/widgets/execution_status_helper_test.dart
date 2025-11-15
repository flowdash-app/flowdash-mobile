import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_status_helper.dart';

void main() {
  group('ExecutionStatusHelper Tests', () {
    group('getStatusColor', () {
      test('returns green for success status', () {
        final color = ExecutionStatusHelper.getStatusColor(WorkflowExecutionStatus.success);
        expect(color, Colors.green);
      });

      test('returns red for error status', () {
        final color = ExecutionStatusHelper.getStatusColor(WorkflowExecutionStatus.error);
        expect(color, Colors.red);
      });

      test('returns blue for running status', () {
        final color = ExecutionStatusHelper.getStatusColor(WorkflowExecutionStatus.running);
        expect(color, Colors.blue);
      });

      test('returns orange for waiting status', () {
        final color = ExecutionStatusHelper.getStatusColor(WorkflowExecutionStatus.waiting);
        expect(color, Colors.orange);
      });

      test('returns grey for canceled status', () {
        final color = ExecutionStatusHelper.getStatusColor(WorkflowExecutionStatus.canceled);
        expect(color, Colors.grey);
      });
    });

    group('getStatusIcon', () {
      test('returns check_circle_outline for success status', () {
        final icon = ExecutionStatusHelper.getStatusIcon(WorkflowExecutionStatus.success);
        expect(icon, Icons.check_circle_outline);
      });

      test('returns error_outline for error status', () {
        final icon = ExecutionStatusHelper.getStatusIcon(WorkflowExecutionStatus.error);
        expect(icon, Icons.error_outline);
      });

      test('returns play_circle_outline for running status', () {
        final icon = ExecutionStatusHelper.getStatusIcon(WorkflowExecutionStatus.running);
        expect(icon, Icons.play_circle_outline);
      });

      test('returns schedule for waiting status', () {
        final icon = ExecutionStatusHelper.getStatusIcon(WorkflowExecutionStatus.waiting);
        expect(icon, Icons.schedule);
      });

      test('returns cancel_outlined for canceled status', () {
        final icon = ExecutionStatusHelper.getStatusIcon(WorkflowExecutionStatus.canceled);
        expect(icon, Icons.cancel_outlined);
      });
    });

    group('getStatusText', () {
      test('returns "Success" for success status', () {
        final text = ExecutionStatusHelper.getStatusText(WorkflowExecutionStatus.success);
        expect(text, 'Success');
      });

      test('returns "Error" for error status', () {
        final text = ExecutionStatusHelper.getStatusText(WorkflowExecutionStatus.error);
        expect(text, 'Error');
      });

      test('returns "Running" for running status', () {
        final text = ExecutionStatusHelper.getStatusText(WorkflowExecutionStatus.running);
        expect(text, 'Running');
      });

      test('returns "Waiting" for waiting status', () {
        final text = ExecutionStatusHelper.getStatusText(WorkflowExecutionStatus.waiting);
        expect(text, 'Waiting');
      });

      test('returns "Canceled" for canceled status', () {
        final text = ExecutionStatusHelper.getStatusText(WorkflowExecutionStatus.canceled);
        expect(text, 'Canceled');
      });
    });

    group('All status enum values are handled', () {
      test('all statuses have color mapping', () {
        for (final status in WorkflowExecutionStatus.values) {
          expect(
            () => ExecutionStatusHelper.getStatusColor(status),
            returnsNormally,
            reason: 'Status $status should have a color mapping',
          );
        }
      });

      test('all statuses have icon mapping', () {
        for (final status in WorkflowExecutionStatus.values) {
          expect(
            () => ExecutionStatusHelper.getStatusIcon(status),
            returnsNormally,
            reason: 'Status $status should have an icon mapping',
          );
        }
      });

      test('all statuses have text mapping', () {
        for (final status in WorkflowExecutionStatus.values) {
          expect(
            () => ExecutionStatusHelper.getStatusText(status),
            returnsNormally,
            reason: 'Status $status should have a text mapping',
          );
        }
      });
    });

    group('Consistency checks', () {
      test('all statuses return non-null values', () {
        for (final status in WorkflowExecutionStatus.values) {
          expect(ExecutionStatusHelper.getStatusColor(status), isNotNull);
          expect(ExecutionStatusHelper.getStatusIcon(status), isNotNull);
          expect(ExecutionStatusHelper.getStatusText(status), isNotNull);
        }
      });

      test('all status texts are non-empty', () {
        for (final status in WorkflowExecutionStatus.values) {
          final text = ExecutionStatusHelper.getStatusText(status);
          expect(text.isNotEmpty, true, reason: 'Status $status text should not be empty');
        }
      });
    });
  });
}

