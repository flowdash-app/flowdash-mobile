import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/workflow_list_tile.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/shared/widgets/empty_state_card.dart';
import 'package:flowdash_mobile/shared/widgets/loading_state_card.dart';
import 'package:flowdash_mobile/shared/widgets/error_state_card.dart';

class HomeTabContent extends ConsumerStatefulWidget {
  const HomeTabContent({super.key});

  @override
  ConsumerState<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends ConsumerState<HomeTabContent> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'home',
        screenClass: 'HomeTabContent',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final workflowsAsync = ref.watch(workflowsProvider);
    final instancesAsync = ref.watch(instancesProvider);
    final authState = ref.watch(authStateProvider);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Clear cache to force server fetch
          final workflowRepository = ref.read(workflowRepositoryProvider);
          final instanceRepository = ref.read(instanceRepositoryProvider);
          await workflowRepository.refreshWorkflows();
          await instanceRepository.refreshInstances();
          
          // Invalidate providers to trigger refresh from server
          ref.invalidate(workflowsProvider);
          ref.invalidate(instancesProvider);
          
          // Wait for both providers to complete their fetch from server
          await Future.wait([
            ref.read(workflowsProvider.future),
            ref.read(instancesProvider.future),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('FlowDash'),
              floating: true,
              snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: () {
                    ref.invalidate(workflowsProvider);
                    ref.invalidate(instancesProvider);
                  },
                ),
              ],
            ),
            SliverPadding(
              padding: const EdgeInsets.all(16.0),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Greeting
                if (authState.value != null && authState.value!.displayName != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 24.0),
                    child: Text(
                      'Hi ${authState.value!.displayName}',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),

                // Workflows section
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Workflows',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Automated workflows from your n8n instance',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                        TextButton(
                          onPressed: () {
                            final analytics = ref.read(analyticsServiceProvider);
                            analytics.logEvent(
                              name: 'view_all_clicked',
                              parameters: {'section': 'workflows'},
                            );
                            const HomeWorkflowsRoute().go(context);
                          },
                          child: const Text('View All'),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                workflowsAsync.when(
                  data: (workflows) => workflows.isEmpty
                      ? EmptyStateCard(
                          icon: Icons.work_outline,
                          title: 'No workflows found',
                          message: 'Create workflows in your active n8n instance and they will appear here.',
                        )
                      : Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...workflows.take(5).map((workflow) {
                                return WorkflowListTile(
                                  workflow: workflow,
                                  showInstanceName: false,
                                  showUpdatedDate: false,
                                  wrapInCard: false,
                                );
                              }),
                              if (workflows.length > 5)
                                ListTile(
                                  title: Text(
                                    '${workflows.length - 5} more workflow${workflows.length - 5 > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    const HomeWorkflowsRoute().go(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                  loading: () => LoadingStateCard(
                    message: 'Loading workflows...',
                  ),
                  error: (error, stack) {
                    final errorMessage = error.toString().replaceAll('Exception: ', '');
                    final isNoInstances = errorMessage.contains('No instances found') ||
                        errorMessage.contains('No active instance found');
                    
                    return ErrorStateCard(
                      icon: isNoInstances ? Icons.cloud_off : Icons.error_outline,
                      iconColor: isNoInstances ? Colors.orange[300] : Colors.red[300],
                      title: isNoInstances
                          ? 'Instance Required'
                          : 'Failed to load workflows',
                      message: isNoInstances
                          ? errorMessage.contains('No instances found')
                              ? 'Add an n8n instance to view workflows'
                              : 'Activate an instance to view workflows'
                          : errorMessage,
                      actionButton: isNoInstances
                          ? OutlinedButton.icon(
                              onPressed: () {
                                const HomeInstancesRoute().go(context);
                              },
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              label: const Text('Go to Instances'),
                            )
                          : null,
                    );
                  },
                ),
                const SizedBox(height: 24),

                // Instances section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Instances',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        final analytics = ref.read(analyticsServiceProvider);
                        analytics.logEvent(
                          name: 'view_all_clicked',
                          parameters: {'section': 'instances'},
                        );
                        const HomeInstancesRoute().go(context);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                instancesAsync.when(
                  data: (instances) => instances.isEmpty
                      ? EmptyStateCard(
                          icon: Icons.cloud_off,
                          title: 'No instances found',
                          message: 'Add an n8n instance to get started with workflows.',
                          actionButton: OutlinedButton.icon(
                            onPressed: () {
                              const HomeInstancesRoute().go(context);
                            },
                            icon: const Icon(Icons.add_circle_outline, size: 18),
                            label: const Text('Add Instance'),
                          ),
                        )
                      : Card(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ...instances.take(3).map((instance) {
                                return ListTile(
                                  title: Text(instance.name),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        instance.url,
                                        style: const TextStyle(fontSize: 12),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        instance.active ? 'Active' : 'Inactive',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: instance.active
                                              ? Colors.green
                                              : Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: Switch(
                                    value: instance.active,
                                    onChanged: (value) async {
                                      final repository = ref
                                          .read(instanceRepositoryProvider);
                                      try {
                                        await repository.toggleInstance(
                                            instance.id, value);
                                        // Invalidate to force refresh from server
                                        ref.invalidate(instancesProvider);
                                        // Also refresh workflows since active instance changed
                                        ref.invalidate(workflowsProvider);
                                      } catch (e) {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                                content: Text('Error: $e')),
                                          );
                                          // On error, refresh to revert optimistic update
                                          ref.invalidate(instancesProvider);
                                        }
                                      }
                                    },
                                  ),
                                );
                              }),
                              if (instances.length > 3)
                                ListTile(
                                  title: Text(
                                    '${instances.length - 3} more instance${instances.length - 3 > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      color: Theme.of(context).colorScheme.primary,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  trailing: const Icon(Icons.chevron_right),
                                  onTap: () {
                                    const HomeInstancesRoute().go(context);
                                  },
                                ),
                            ],
                          ),
                        ),
                  loading: () => LoadingStateCard(
                    message: 'Loading instances...',
                  ),
                  error: (error, stack) {
                    final errorMessage = error.toString().replaceAll('Exception: ', '');
                    
                    return ErrorStateCard(
                      icon: Icons.error_outline,
                      title: 'Failed to load instances',
                      message: errorMessage,
                      actionButton: OutlinedButton.icon(
                        onPressed: () => ref.invalidate(instancesProvider),
                        icon: const Icon(Icons.refresh, size: 18),
                        label: const Text('Retry'),
                      ),
                    );
                  },
                ),
                  ],
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

