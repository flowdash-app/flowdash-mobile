import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/workflow_list_tile.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_with_instance.dart';

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
    final workflowsAsync = ref.watch(workflowsWithInstanceProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (!didPop) {
          const HomeRoute().go(context);
        }
      },
      child: Scaffold(
        body: RefreshIndicator(
          onRefresh: () async {
            // Clear cache and invalidate provider to force refresh
            final workflowRepository = ref.read(workflowRepositoryProvider);
            await workflowRepository.refreshWorkflows();
            ref.invalidate(workflowsWithInstanceProvider);
            await ref.read(workflowsWithInstanceProvider.future);
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Workflows'),
                    Text(
                      'Manage your n8n workflows',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                    ),
                  ],
                ),
                toolbarHeight: 80,
                floating: true,
                snap: true,
              ),
              workflowsAsync.when(
                data: (workflows) {
                  if (workflows.isEmpty) {
                    return SliverFillRemaining(
                      child: _buildEmptyState(),
                    );
                  }
                  // Create a snapshot to prevent race conditions during build
                  final workflowsSnapshot = List<WorkflowWithInstance>.from(workflows);
                  return SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index >= workflowsSnapshot.length) {
                          return const SizedBox.shrink();
                        }
                        final item = workflowsSnapshot[index];
                        return WorkflowListTile(
                          workflow: item.workflow,
                          instanceId: item.instanceId,
                          instanceName: item.instanceName,
                          showInstanceName: true,
                          showUpdatedDate: true,
                          wrapInCard: true,
                        );
                      },
                      childCount: workflowsSnapshot.length,
                    ),
                  );
                },
                loading: () => const SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text(
                          'Loading workflows...',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                error: (error, stack) => SliverFillRemaining(
                  child: _buildErrorState(error),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.work_outline,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            const Text(
              'No workflows found',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your n8n instances don\'t have any workflows yet. Create workflows in your n8n instances and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () {
                ref.invalidate(workflowsWithInstanceProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    final errorMessage = error.toString().replaceAll('Exception: ', '');
    final isNoInstances = errorMessage.contains('No instances found') ||
        errorMessage.contains('No active instance found');

    if (isNoInstances) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off,
                size: 64,
                color: Colors.orange[300],
              ),
              const SizedBox(height: 16),
              const Text(
                'Instance Required',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage.contains('No instances found')
                    ? 'You need to add an n8n instance before you can view workflows. Add an instance in the Instances section.'
                    : 'You need to activate an n8n instance before you can view workflows. Go to Instances and activate one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () {
                  const HomeInstancesRoute().go(context);
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text('Go to Instances'),
              ),
            ],
          ),
        ),
      );
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red[300],
            ),
            const SizedBox(height: 16),
            const Text(
              'Failed to load workflows',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                // Invalidate will immediately show loading state
                ref.invalidate(workflowsWithInstanceProvider);
              },
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class WorkflowsPage extends ConsumerStatefulWidget {
  const WorkflowsPage({super.key});

  @override
  ConsumerState<WorkflowsPage> createState() => _WorkflowsPageState();
}
