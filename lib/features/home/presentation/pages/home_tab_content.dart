import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';

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
      appBar: AppBar(
        title: const Text('FlowDash'),
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
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(workflowsProvider);
          ref.invalidate(instancesProvider);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workflows',
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
                          parameters: {'section': 'workflows'},
                        );
                        const HomeWorkflowsRoute().go(context);
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                workflowsAsync.when(
                  data: (workflows) => workflows.isEmpty
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('No workflows found')),
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: workflows.take(5).length,
                            itemBuilder: (context, index) {
                              final workflow = workflows[index];
                              return SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Card(
                                    child: ListTile(
                                      title: Text(workflow.name),
                                      subtitle: Text(
                                        workflow.active ? 'Active' : 'Inactive',
                                      ),
                                      trailing: Switch(
                                        value: workflow.active,
                                        onChanged: (value) async {
                                          final repository = ref
                                              .read(workflowRepositoryProvider);
                                          try {
                                            await repository.toggleWorkflow(
                                                workflow.id, value);
                                            ref.invalidate(workflowsProvider);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text('Error: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: $error'),
                    ),
                  ),
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
                      ? const Card(
                          child: Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: Text('No instances found')),
                          ),
                        )
                      : SizedBox(
                          height: 200,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: instances.take(5).length,
                            itemBuilder: (context, index) {
                              final instance = instances[index];
                              return SizedBox(
                                width: 200,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                  child: Card(
                                    child: ListTile(
                                      title: Text(instance.name),
                                      subtitle: Text(instance.url),
                                      trailing: Switch(
                                        value: instance.active,
                                        onChanged: (value) async {
                                          final repository = ref
                                              .read(instanceRepositoryProvider);
                                          try {
                                            await repository.toggleInstance(
                                                instance.id, value);
                                            ref.invalidate(instancesProvider);
                                          } catch (e) {
                                            if (context.mounted) {
                                              ScaffoldMessenger.of(context)
                                                  .showSnackBar(
                                                SnackBar(
                                                    content: Text('Error: $e')),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                  loading: () => const Card(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Center(child: CircularProgressIndicator()),
                    ),
                  ),
                  error: (error, stack) => Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text('Error: $error'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

