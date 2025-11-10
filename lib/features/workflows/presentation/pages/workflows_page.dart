import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/utils/pagination_helper.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/workflows/domain/entities/workflow.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/workflow_list_tile.dart';

// Data structure to hold workflow with instance info
class WorkflowWithInstance {
  final Workflow workflow;
  final String instanceId;
  final String instanceName;

  const WorkflowWithInstance({
    required this.workflow,
    required this.instanceId,
    required this.instanceName,
  });
}

class _WorkflowsPageState extends ConsumerState<WorkflowsPage>
    with PaginationHelper<WorkflowWithInstance> {
  @override
  void initState() {
    super.initState();
    initPagination();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'workflows',
        screenClass: 'WorkflowsPage',
      );
      _loadWorkflows();
    });
  }

  Future<void> _loadWorkflows({bool loadMore = false}) async {
    final workflowRepository = ref.read(workflowRepositoryProvider);
    final instanceRepository = ref.read(instanceRepositoryProvider);

    if (loadMore) {
      // For load more, we need to track cursors per instance
      // This is complex, so for now we'll just fetch more from all instances
      // TODO: Implement proper multi-instance pagination
      await this.loadMore(
        fetchData: (cursor) async {
          // Get all instances
          final instances = await instanceRepository.getInstances();
          if (instances.isEmpty) {
            return (data: <WorkflowWithInstance>[], nextCursor: null);
          }

          // Fetch workflows from all instances (with limit per instance)
          final allWorkflows = <WorkflowWithInstance>[];
          bool hasMore = false;

          for (final instance in instances) {
            try {
              // Fetch next page for this instance
              // Note: This is a simplified approach - ideally we'd track cursor per instance
              final result = await workflowRepository.getWorkflowsPaginated(
                instanceId: instance.id,
                limit: 20,
                cursor: null, // TODO: Track cursor per instance
                cancelToken: null,
              );

              for (final workflow in result.data) {
                allWorkflows.add(WorkflowWithInstance(
                  workflow: workflow,
                  instanceId: instance.id,
                  instanceName: instance.name,
                ));
              }

              if (result.nextCursor != null) {
                hasMore = true;
              }
            } catch (e) {
              // Continue with other instances
            }
          }

          // Sort: by instance name, then by active status, then by name
          allWorkflows.sort((a, b) {
            final instanceCompare = a.instanceName.compareTo(b.instanceName);
            if (instanceCompare != 0) return instanceCompare;

            if (a.workflow.active != b.workflow.active) {
              return b.workflow.active ? 1 : -1;
            }

            return a.workflow.name.compareTo(b.workflow.name);
          });

          return (data: allWorkflows, nextCursor: hasMore ? 'more' : null);
        },
        onStateChanged: (state) => setState(() {}),
      );
    } else {
      await this.loadInitial(
        fetchData: () async {
          // Get all instances
          final instances = await instanceRepository.getInstances();
          if (instances.isEmpty) {
            throw Exception('No instances found. Please add an instance first.');
          }

          // Fetch workflows from all instances (with limit per instance)
          final allWorkflows = <WorkflowWithInstance>[];
          bool hasMore = false;

          for (final instance in instances) {
            try {
              final result = await workflowRepository.getWorkflowsPaginated(
                instanceId: instance.id,
                limit: 20,
                cursor: null,
                cancelToken: null,
              );

              for (final workflow in result.data) {
                allWorkflows.add(WorkflowWithInstance(
                  workflow: workflow,
                  instanceId: instance.id,
                  instanceName: instance.name,
                ));
              }

              if (result.nextCursor != null) {
                hasMore = true;
              }
            } catch (e) {
              // Continue with other instances
            }
          }

          // Sort: by instance name, then by active status, then by name
          allWorkflows.sort((a, b) {
            final instanceCompare = a.instanceName.compareTo(b.instanceName);
            if (instanceCompare != 0) return instanceCompare;

            if (a.workflow.active != b.workflow.active) {
              return b.workflow.active ? 1 : -1;
            }

            return a.workflow.name.compareTo(b.workflow.name);
          });

          return (data: allWorkflows, nextCursor: hasMore ? 'more' : null);
        },
        onStateChanged: (state) => setState(() {}),
      );
    }
  }


  @override
  Widget build(BuildContext context) {
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
            await this.refresh(
              fetchData: () async {
                final workflowRepository = ref.read(workflowRepositoryProvider);
                final instanceRepository = ref.read(instanceRepositoryProvider);

                // Get all instances
                final instances = await instanceRepository.getInstances();
                if (instances.isEmpty) {
                  throw Exception('No instances found. Please add an instance first.');
                }

                // Fetch workflows from all instances
                final allWorkflows = <WorkflowWithInstance>[];
                bool hasMore = false;

                for (final instance in instances) {
                  try {
                    final result = await workflowRepository.getWorkflowsPaginated(
                      instanceId: instance.id,
                      limit: 20,
                      cursor: null,
                      cancelToken: null,
                    );

                    for (final workflow in result.data) {
                      allWorkflows.add(WorkflowWithInstance(
                        workflow: workflow,
                        instanceId: instance.id,
                        instanceName: instance.name,
                      ));
                    }

                    if (result.nextCursor != null) {
                      hasMore = true;
                    }
                  } catch (e) {
                    // Continue with other instances
                  }
                }

                // Sort: by instance name, then by active status, then by name
                allWorkflows.sort((a, b) {
                  final instanceCompare = a.instanceName.compareTo(b.instanceName);
                  if (instanceCompare != 0) return instanceCompare;

                  if (a.workflow.active != b.workflow.active) {
                    return b.workflow.active ? 1 : -1;
                  }

                  return a.workflow.name.compareTo(b.workflow.name);
                });

                return (data: allWorkflows, nextCursor: hasMore ? 'more' : null);
              },
              onStateChanged: (state) => setState(() {}),
            );
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
              if (paginationState.isLoading && paginationState.items.isEmpty)
                const SliverFillRemaining(
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
                )
              else if (paginationState.hasError && paginationState.items.isEmpty)
                SliverFillRemaining(
                  child: _buildErrorState(),
                )
              else if (paginationState.items.isEmpty)
                SliverFillRemaining(
                  child: _buildEmptyState(),
                )
              else
                SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final item = paginationState.items[index];
                      return WorkflowListTile(
                        workflow: item.workflow,
                        instanceId: item.instanceId,
                        instanceName: item.instanceName,
                        showInstanceName: true,
                        showUpdatedDate: true,
                        wrapInCard: true,
                      );
                    },
                    childCount: paginationState.items.length + (paginationState.hasMore ? 1 : 0),
                  ),
                ),
              if (paginationState.hasMore && !paginationState.isLoading)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: OutlinedButton.icon(
                      onPressed: paginationState.isLoadingMore
                          ? null
                          : () => _loadWorkflows(loadMore: true),
                      icon: paginationState.isLoadingMore
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.refresh),
                      label: Text(paginationState.isLoadingMore ? 'Loading...' : 'Load More'),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    final errorMessage = paginationState.error ?? '';
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
              'Your active n8n instance doesn\'t have any workflows yet. Create workflows in your n8n instance and they will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: () => _loadWorkflows(),
              icon: const Icon(Icons.refresh),
              label: const Text('Refresh'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final errorMessage = paginationState.error?.replaceAll('Exception: ', '') ?? 'Unknown error';
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
              onPressed: () => _loadWorkflows(),
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
