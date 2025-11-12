import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';

class ExecutionDataViewer extends StatefulWidget {
  final ExecutionData? data;

  const ExecutionDataViewer({
    super.key,
    this.data,
  });

  @override
  State<ExecutionDataViewer> createState() => _ExecutionDataViewerState();
}

class _ExecutionDataViewerState extends State<ExecutionDataViewer> {
  final Map<String, bool> _expandedSections = {};

  @override
  Widget build(BuildContext context) {
    if (widget.data == null) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'No execution data available',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'The execution data field is null. This may indicate:\n'
              '• The execution has no data\n'
              '• The data structure from the API is different than expected\n'
              '• There was an error parsing the data',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    // Convert ExecutionData to Map for display using data class's toJson
    final dataMap = _executionDataToMap(widget.data!);
    
    // Check if the map is empty
    if (dataMap.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Execution data structure is empty',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Data object exists but contains no displayable fields.',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: () => _copyToClipboard(),
              icon: const Icon(Icons.copy, size: 16),
              label: const Text('Copy raw data'),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Execution Data',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyToClipboard(),
              tooltip: 'Copy all data',
            ),
          ],
        ),
        const SizedBox(height: 8),
        ..._buildDataSections(dataMap, 'root'),
      ],
    );
  }

  Map<String, dynamic> _executionDataToMap(ExecutionData data) {
    // Use the data class's toJson() method directly
    // Freezed automatically generates this method with all fields
    return data.toJson();
  }

  List<Widget> _buildDataSections(Map<String, dynamic> data, String parentKey) {
    return data.entries.map((entry) {
      final key = entry.key;
      final value = entry.value;
      final fullKey = parentKey == 'root' ? key : '$parentKey.$key';
      final isExpanded = _expandedSections[fullKey] ?? false;

      if (value is Map<String, dynamic>) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${value.length} ${value.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedSections[fullKey] = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copySectionToClipboard(value),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _formatJson(value),
                        style: const TextStyle(
                          fontSize: 11,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ..._buildDataSections(value, fullKey),
                  ],
                ),
              ),
            ],
          ),
        );
      } else if (value is List) {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ExpansionTile(
            title: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Text(
              '${value.length} ${value.length == 1 ? 'item' : 'items'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            initiallyExpanded: isExpanded,
            onExpansionChanged: (expanded) {
              setState(() {
                _expandedSections[fullKey] = expanded;
              });
            },
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () => _copySectionToClipboard(value),
                          icon: const Icon(Icons.copy, size: 16),
                          label: const Text('Copy'),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: SelectableText(
                        _formatJson(value),
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
        );
      } else {
        return Card(
          margin: const EdgeInsets.only(bottom: 8.0),
          child: ListTile(
            title: Text(
              key,
              style: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 4.0),
              child: SelectableText(
                _formatValue(value),
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            trailing: IconButton(
              icon: const Icon(Icons.copy, size: 18),
              onPressed: () => _copyValueToClipboard(_formatValue(value)),
              tooltip: 'Copy value',
            ),
          ),
        );
      }
    }).toList();
  }

  String _formatJson(dynamic data) {
    try {
      final encoder = JsonEncoder.withIndent('  ');
      return encoder.convert(data);
    } catch (e) {
      return 'Error formatting: $e';
    }
  }

  String _formatValue(dynamic value) {
    if (value == null) return 'null';
    if (value is String) return value;
    if (value is num) return value.toString();
    if (value is bool) return value.toString();
    return _formatJson(value);
  }

  Future<void> _copyToClipboard() async {
    if (widget.data == null) return;
    try {
      // Use toJson to get the full data structure
      final json = widget.data!.toJson();
      final jsonString = _formatJson(json);
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Execution data copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      // Fallback: try to format the data object directly
      final jsonString = _formatJson(widget.data);
      await Clipboard.setData(ClipboardData(text: jsonString));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Execution data copied to clipboard'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _copySectionToClipboard(dynamic data) async {
    final jsonString = _formatJson(data);
    await Clipboard.setData(ClipboardData(text: jsonString));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Section copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _copyValueToClipboard(String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Value copied to clipboard'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }
}

