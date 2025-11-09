import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';

class WorkflowsPage extends ConsumerStatefulWidget {
  const WorkflowsPage({super.key});

  @override
  ConsumerState<WorkflowsPage> createState() => _WorkflowsPageState();
}

class _WorkflowsPageState extends ConsumerState<WorkflowsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'workflows',
        screenClass: 'WorkflowsPage',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final workflowsAsync = ref.watch(workflowsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workflows'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workflowsProvider);
        },
        child: workflowsAsync.when(
          data: (workflows) => workflows.isEmpty
              ? const Center(child: Text('No workflows found'))
              : ListView.builder(
                  itemCount: workflows.length,
                  itemBuilder: (context, index) {
                    final workflow = workflows[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: ListTile(
                        title: Text(workflow.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (workflow.description != null)
                              Text(workflow.description!),
                            const SizedBox(height: 4),
                            Text(
                              workflow.active ? 'Active' : 'Inactive',
                              style: TextStyle(
                                color: workflow.active
                                    ? Colors.green
                                    : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: workflow.active,
                          onChanged: (value) async {
                            final repository =
                                ref.read(workflowRepositoryProvider);
                            try {
                              await repository.toggleWorkflow(
                                  workflow.id, value);
                              ref.invalidate(workflowsProvider);
                            } catch (e) {
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text('Error: $e')),
                                );
                              }
                            }
                          },
                        ),
                      ),
                    );
                  },
                ),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: $error'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () => ref.invalidate(workflowsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
