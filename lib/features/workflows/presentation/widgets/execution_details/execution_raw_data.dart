import 'package:flowdash_mobile/features/workflows/data/models/execution_data_models.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/execution_data_viewer.dart';
import 'package:flutter/material.dart';

class ExecutionRawData extends StatefulWidget {
  final ExecutionData? data;

  const ExecutionRawData({
    super.key,
    required this.data,
  });

  @override
  State<ExecutionRawData> createState() => _ExecutionRawDataState();
}

class _ExecutionRawDataState extends State<ExecutionRawData> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () {
            setState(() {
              _isExpanded = !_isExpanded;
            });
          },
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              children: [
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  size: 20,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Raw Execution Data',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ],
            ),
          ),
        ),
        if (_isExpanded) ...[
          const SizedBox(height: 8),
          ExecutionDataViewer(data: widget.data),
        ],
      ],
    );
  }
}

