import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow_with_instance.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/workflow_list_tile.dart';
import 'package:flowdash_mobile/shared/widgets/shimmer_list_tile.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_empty_state.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_error_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class _WorkflowsPageState extends ConsumerState<WorkflowsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(screenName: 'workflows', screenClass: 'WorkflowsPage');
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
            // Use notifier refresh method which clears cache and refetches
            await ref.read(workflowsWithInstanceProvider.notifier).refresh();
          },
          child: CustomScrollView(
            slivers: [
              SliverAppBar(
                bottom: PreferredSize(
                  preferredSize: Size.fromHeight(20),
                  child: Text(
                    'Manage your n8n workflows',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
                  ),
                ),
                title: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [Text('Workflows')],
                ),
                toolbarHeight: 80,
                floating: true,
                snap: true,
              ),
              workflowsAsync.when(
                skipLoadingOnRefresh: false,
                data: (workflows) {
                  if (workflows.isEmpty) {
                    return SliverFillRemaining(
                      child: FullPageEmptyState(
                        icon: Icons.work_outline,
                        title: 'No workflows found',
                        message: 'Your n8n instances don\'t have any workflows yet. Create workflows in your n8n instances and they will appear here.',
                        actionButton: OutlinedButton.icon(
                          onPressed: () {
                            ref.read(workflowsWithInstanceProvider.notifier).refresh();
                          },
                          icon: const Icon(Icons.refresh),
                          label: const Text('Refresh'),
                        ),
                      ),
                    );
                  }
                  // Create a snapshot to prevent race conditions during build
                  final workflowsSnapshot = List<WorkflowWithInstance>.from(workflows);
                  return SliverList(
                    delegate: SliverChildBuilderDelegate((context, index) {
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
                    }, childCount: workflowsSnapshot.length),
                  );
                },
                loading: () => SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => const ShimmerListTile(
                      wrapInCard: true,
                      showTrailing: true,
                    ),
                    childCount: 3,
                  ),
                ),
                error: (error, stack) {
                  final errorMessage = error.toString().replaceAll('Exception: ', '');
                  final isNoInstances = errorMessage.contains('No instances found') ||
                      errorMessage.contains('No active instance found');

                  if (isNoInstances) {
                    return SliverFillRemaining(
                      child: FullPageErrorState(
                        icon: Icons.cloud_off,
                        iconColor: Colors.orange[300],
                        title: 'Instance Required',
                        message: errorMessage.contains('No instances found')
                            ? 'You need to add an n8n instance before you can view workflows. Add an instance in the Instances section.'
                            : 'You need to activate an n8n instance before you can view workflows. Go to Instances and activate one.',
                        actionButton: ElevatedButton.icon(
                          onPressed: () {
                            const HomeInstancesRoute().go(context);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Go to Instances'),
                        ),
                      ),
                    );
                  }

                  return SliverFillRemaining(
                    child: FullPageErrorState(
                      icon: Icons.error_outline,
                      title: 'Failed to load workflows',
                      message: errorMessage,
                      actionButton: ElevatedButton.icon(
                        onPressed: () {
                          // Refresh will immediately show loading state
                          ref.read(workflowsWithInstanceProvider.notifier).refresh();
                        },
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
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
