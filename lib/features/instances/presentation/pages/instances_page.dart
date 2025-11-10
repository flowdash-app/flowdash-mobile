import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';

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
          // Clear cache to force server fetch
          final repository = ref.read(instanceRepositoryProvider);
          await repository.refreshInstances();
          
          // Invalidate provider to trigger refresh from server
          ref.invalidate(instancesProvider);
          
          // Wait for the provider to complete its fetch from server
          await ref.read(instancesProvider.future);
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
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.cloud_off,
                                size: 64,
                                color: Colors.grey[400],
                              ),
                              const SizedBox(height: 16),
                              const Text(
                                'No instances found',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Add an n8n instance to get started with workflows.',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: () {
                                  const AddInstanceRoute().push(context);
                                },
                                icon: const Icon(Icons.add_circle_outline),
                                label: const Text('Add Instance'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final instance = instances[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: ListTile(
                              title: Text(instance.name),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(instance.url),
                                  const SizedBox(height: 4),
                                  Text(
                                    instance.active ? 'Active' : 'Inactive',
                                    style: TextStyle(
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
                                  final repository =
                                      ref.read(instanceRepositoryProvider);
                                  try {
                                    // Optimistically update the switch immediately
                                    // The repository will handle the API call and cache update
                                    await repository.toggleInstance(
                                        instance.id, value);
                                    // Invalidate to force refresh from server (cache was cleared)
                                    ref.invalidate(instancesProvider);
                                    // Also refresh workflows since active instance may have changed
                                    ref.invalidate(workflowsProvider);
                                  } catch (e) {
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(content: Text('Error: $e')),
                                      );
                                      // On error, refresh to revert optimistic update
                                      ref.invalidate(instancesProvider);
                                    }
                                  }
                                },
                              ),
                            ),
                          );
                        },
                        childCount: instances.length,
                      ),
                    ),
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(),
                      SizedBox(height: 16),
                      Text(
                        'Loading instances...',
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
              error: (error, stack) {
                final errorMessage = error.toString().replaceAll('Exception: ', '');
                return SliverFillRemaining(
                  child: Center(
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
                            'Failed to load instances',
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
                            onPressed: () => ref.invalidate(instancesProvider),
                            icon: const Icon(Icons.refresh),
                            label: const Text('Retry'),
                          ),
                        ],
                      ),
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
