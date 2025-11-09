import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<HomePage> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  @override
  void initState() {
    super.initState();
    // Screen view tracking will be handled by analytics service
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
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                child: const Text('Sign Out'),
                onTap: () async {
                  final repository = ref.read(authRepositoryProvider);
                  await repository.signOut();
                  if (context.mounted) {
                    const LoginRoute().go(context);
                  }
                },
              ),
            ],
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
                // User info
                if (authState.value != null)
                  Card(
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: authState.value?.photoUrl != null
                            ? NetworkImage(authState.value!.photoUrl!)
                            : null,
                        child: authState.value?.photoUrl == null
                            ? Text(authState.value?.displayName?[0] ?? 'U')
                            : null,
                      ),
                      title: Text(authState.value?.displayName ?? 'User'),
                      subtitle: Text(authState.value?.email ?? ''),
                    ),
                  ),
                const SizedBox(height: 24),

                // Workflows section
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Workflows',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => const WorkflowsRoute().go(context),
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
                          child: CarouselView(
                            scrollDirection: Axis.horizontal,
                            itemExtent: 200,
                            children: workflows.take(5).map((workflow) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
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
                              );
                            }).toList(),
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
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    TextButton(
                      onPressed: () => const InstancesRoute().go(context),
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
                          child: CarouselView(
                            scrollDirection: Axis.horizontal,
                            itemExtent: 200,
                            children: instances.take(5).map((instance) {
                              return Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 8.0),
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
                              );
                            }).toList(),
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
