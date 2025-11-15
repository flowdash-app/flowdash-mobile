import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';
import 'package:flowdash_mobile/shared/widgets/info_row.dart';

class NodeExecutionStepTile extends StatelessWidget {
  final String nodeName;
  final NodeRunData nodeData;
  final bool hasError;

  const NodeExecutionStepTile({
    super.key,
    required this.nodeName,
    required this.nodeData,
    this.hasError = false,
  });

  @override
  Widget build(BuildContext context) {
    // Determine node status
    final hasNodeError = hasError || nodeData.error != null;
    final statusColor = hasNodeError ? Colors.red : Colors.green;
    final statusIcon = hasNodeError ? Icons.error_outline : Icons.check_circle_outline;
    final statusText = hasNodeError ? 'Error' : 'Success';

    return Card(
      margin: const EdgeInsets.only(bottom: 8.0),
      child: ExpansionTile(
        leading: Icon(
          statusIcon,
          color: statusColor,
        ),
        title: Text(
          nodeName,
          style: const TextStyle(
            fontWeight: FontWeight.w500,
          ),
        ),
        subtitle: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                statusText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Node type if available
                if (nodeData.type != null)
                  InfoRow(
                    label: 'Type',
                    value: nodeData.type!,
                    labelWidth: 80,
                  ),
                
                // Error message if available
                if (hasNodeError && nodeData.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.red[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.red[300]!),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 16,
                                color: Colors.red[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Error',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.red[700],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            nodeData.error!,
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.red[700],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Node data preview
                if (nodeData.main != null && nodeData.main!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Data Preview',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _formatNodeData(nodeData),
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Full node data (collapsible)
                if (nodeData.main != null || nodeData.type != null || nodeData.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: ExpansionTile(
                      title: const Text(
                        'Full Node Data',
                        style: TextStyle(fontSize: 12),
                      ),
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12.0),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SelectableText(
                            _formatJson(nodeData),
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatNodeData(NodeRunData nodeData) {
    try {
      if (nodeData.main != null && nodeData.main!.isNotEmpty) {
        final firstItem = nodeData.main![0];
        if (firstItem.isNotEmpty) {
          final data = firstItem[0];
          if (data.json != null) {
            final encoder = JsonEncoder.withIndent('  ');
            return encoder.convert(data.json);
          }
        }
      }
      return 'No data available';
    } catch (e) {
      return 'Error formatting data: $e';
    }
  }

  String _formatJson(NodeRunData nodeData) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      final map = <String, dynamic>{};
      if (nodeData.main != null) {
        map['main'] = nodeData.main!.map((list) => 
          list.map((item) => item.json).toList()
        ).toList();
      }
      if (nodeData.type != null) map['type'] = nodeData.type;
      if (nodeData.error != null) map['error'] = nodeData.error;
      return encoder.convert(map);
    } catch (e) {
      return 'Error formatting JSON: $e';
    }
  }
}

