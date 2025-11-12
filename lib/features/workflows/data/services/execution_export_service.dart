import 'dart:convert';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_execution.dart';
import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';

class ExecutionExportService {
  final Logger _logger = AppLogger.getLogger('ExecutionExportService');

  /// Generate markdown content from execution data
  String generateMarkdown({
    required WorkflowExecution execution,
    String? workflowName,
    String? instanceName,
  }) {
    _logger.info('generateMarkdown: Entry - executionId: ${execution.id}');

    final buffer = StringBuffer();

    // Header
    buffer.writeln('# Workflow Execution Details\n');

    // Metadata
    buffer.writeln('## Metadata\n');
    buffer.writeln('| Field | Value |');
    buffer.writeln('|-------|-------|');
    if (workflowName != null) {
      buffer.writeln('| Workflow Name | $workflowName |');
    }
    if (instanceName != null) {
      buffer.writeln('| Instance | $instanceName |');
    }
    buffer.writeln('| Execution ID | `${execution.id}` |');
    buffer.writeln('| Workflow ID | `${execution.workflowId}` |');
    buffer.writeln('| Status | **${_statusToString(execution.status)}** |');
    
    if (execution.startedAt != null) {
      buffer.writeln('| Started At | ${execution.startedAt!.toIso8601String()} |');
    }
    if (execution.stoppedAt != null) {
      buffer.writeln('| Stopped At | ${execution.stoppedAt!.toIso8601String()} |');
    }
    if (execution.duration != null) {
      buffer.writeln('| Duration | ${_formatDuration(execution.duration!)} |');
    }
    buffer.writeln('');

    // Error Details
    if (execution.status == WorkflowExecutionStatus.error && execution.errorMessage != null) {
      buffer.writeln('## Error Details\n');
      buffer.writeln('```');
      buffer.writeln(execution.errorMessage);
      buffer.writeln('```');
      buffer.writeln('');
    }

    // Node Execution Summary
    if (execution.data != null) {
      final resultData = execution.data!.resultData;
      if (resultData != null && resultData.runData != null) {
        final runData = resultData.runData!;
        if (runData.isNotEmpty) {
          buffer.writeln('## Node Execution Summary\n');
          buffer.writeln('| Node Name | Status |');
          buffer.writeln('|-----------|--------|');
          
          runData.forEach((nodeName, nodeData) {
            // Try to determine node status from the data
            final status = _getNodeStatus(nodeData);
            buffer.writeln('| $nodeName | $status |');
          });
          buffer.writeln('');
        }
      }
    }

    // Execution Data
    if (execution.data != null) {
      buffer.writeln('## Execution Data\n');
      buffer.writeln('```json');
      final encoder = JsonEncoder.withIndent('  ');
      final dataMap = _executionDataToMap(execution.data!);
      buffer.writeln(encoder.convert(dataMap));
      buffer.writeln('```');
    }

    _logger.info('generateMarkdown: Success - executionId: ${execution.id}');
    return buffer.toString();
  }

  /// Export execution to markdown file and share
  Future<void> exportAndShare({
    required WorkflowExecution execution,
    String? workflowName,
    String? instanceName,
  }) async {
    _logger.info('exportAndShare: Entry - executionId: ${execution.id}');

    try {
      // Generate markdown content
      final markdown = generateMarkdown(
        execution: execution,
        workflowName: workflowName,
        instanceName: instanceName,
      );

      // Get temporary directory
      final tempDir = await getTemporaryDirectory();
      final fileName = 'execution_${execution.id}_${DateTime.now().millisecondsSinceEpoch}.md';
      final file = File('${tempDir.path}/$fileName');

      // Write markdown to file
      await file.writeAsString(markdown);

      // Share the file
      await Share.shareXFiles(
        [XFile(file.path)],
        text: 'Workflow Execution Details',
        subject: 'Execution ${execution.id}',
      );

      _logger.info('exportAndShare: Success - executionId: ${execution.id}, file: $fileName');
    } catch (e, stackTrace) {
      _logger.severe('exportAndShare: Failure', e, stackTrace);
      rethrow;
    }
  }

  String _statusToString(WorkflowExecutionStatus status) {
    switch (status) {
      case WorkflowExecutionStatus.success:
        return 'Success';
      case WorkflowExecutionStatus.error:
        return 'Error';
      case WorkflowExecutionStatus.running:
        return 'Running';
      case WorkflowExecutionStatus.waiting:
        return 'Waiting';
      case WorkflowExecutionStatus.canceled:
        return 'Canceled';
    }
  }

  String _formatDuration(Duration duration) {
    if (duration.inSeconds < 60) {
      return '${duration.inSeconds}s';
    } else if (duration.inMinutes < 60) {
      return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
    } else {
      return '${duration.inHours}h ${duration.inMinutes % 60}m';
    }
  }

  String _getNodeStatus(dynamic nodeData) {
    // Try to determine node status from execution data
    // This is a simple heuristic - can be improved based on actual n8n data structure
    if (nodeData is NodeRunData) {
      return nodeData.error != null ? 'Error' : 'Success';
    }
    if (nodeData is Map && nodeData.containsKey('error')) {
      return 'Error';
    }
    return 'Success';
  }

  Map<String, dynamic> _executionDataToMap(ExecutionData data) {
    final map = <String, dynamic>{};
    if (data.resultData != null) {
      final resultDataMap = <String, dynamic>{};
      if (data.resultData!.runData != null) {
        final runDataMap = <String, dynamic>{};
        data.resultData!.runData!.forEach((key, value) {
          final nodeMap = <String, dynamic>{};
          if (value.main != null) {
            nodeMap['main'] = value.main!.map((list) => 
              list.map((item) => {'json': item.json}).toList()
            ).toList();
          }
          if (value.type != null) nodeMap['type'] = value.type;
          if (value.error != null) nodeMap['error'] = value.error;
          runDataMap[key] = nodeMap;
        });
        resultDataMap['runData'] = runDataMap;
      }
      map['resultData'] = resultDataMap;
    }
    if (data.executionData != null) {
      map['executionData'] = data.executionData;
    }
    return map;
  }
}

