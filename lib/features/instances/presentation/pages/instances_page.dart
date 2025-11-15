import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/shared/widgets/shimmer_list_tile.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_empty_state.dart';
import 'package:flowdash_mobile/shared/widgets/full_page_error_state.dart';
import 'package:flowdash_mobile/shared/widgets/switchable_list_tile.dart';

class InstancesPage extends ConsumerStatefulWidget {
  const InstancesPage({super.key});

  @override
  ConsumerState<InstancesPage> createState() => _InstancesPageState();
}

class _InstancesPageState extends ConsumerState<InstancesPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'instances',
        screenClass: 'InstancesPage',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final instancesAsync = ref.watch(instancesProvider);

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
          await ref.read(instancesProvider.notifier).refresh();
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('Instances'),
              floating: true,
              snap: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    const AddInstanceRoute().push(context);
                  },
                  tooltip: 'Add Instance',
                ),
              ],
            ),
            instancesAsync.when(
              data: (instances) => instances.isEmpty
                  ? SliverFillRemaining(
                      child: FullPageEmptyState(
                        icon: Icons.cloud_off,
                        title: 'No instances found',
                        message: 'Add an n8n instance to get started with workflows.',
                        actionButton: ElevatedButton.icon(
                          onPressed: () {
                            const AddInstanceRoute().push(context);
                          },
                          icon: const Icon(Icons.add_circle_outline),
                          label: const Text('Add Instance'),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final instance = instances[index];
                          return SwitchableListTile(
                            title: instance.name,
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
                                    color: instance.active ? Colors.green : Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            switchValue: instance.active,
                            onSwitchChanged: (value) async {
                              final repository = ref.read(instanceRepositoryProvider);
                              try {
                                await repository.toggleInstance(instance.id, value);
                                ref.read(instancesProvider.notifier).refresh();
                                ref.read(workflowsWithInstanceProvider.notifier).refresh();
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('Error: $e')),
                                  );
                                  ref.read(instancesProvider.notifier).refresh();
                                }
                              }
                            },
                            wrapInCard: true,
                          );
                        },
                        childCount: instances.length,
                      ),
                    ),
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) => const ShimmerListTile(
                    wrapInCard: true,
                    showTrailing: true,
                  ),
                  childCount: 5,
                ),
              ),
              error: (error, stack) {
                final errorMessage = error.toString().replaceAll('Exception: ', '');
                return SliverFillRemaining(
                  child: FullPageErrorState(
                    icon: Icons.error_outline,
                    title: 'Failed to load instances',
                    message: errorMessage,
                    actionButton: ElevatedButton.icon(
                      onPressed: () {
                        ref.read(instancesProvider.notifier).refresh();
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
