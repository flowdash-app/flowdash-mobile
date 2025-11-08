import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';

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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Instances'),
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(instancesProvider);
        },
        child: instancesAsync.when(
          data: (instances) => instances.isEmpty
              ? const Center(child: Text('No instances found'))
              : ListView.builder(
                  itemCount: instances.length,
                  itemBuilder: (context, index) {
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
                                color: instance.active ? Colors.green : Colors.grey,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        trailing: Switch(
                          value: instance.active,
                          onChanged: (value) async {
                            final repository = ref.read(instanceRepositoryProvider);
                            try {
                              await repository.toggleInstance(instance.id, value);
                              ref.invalidate(instancesProvider);
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
                    onPressed: () => ref.invalidate(instancesProvider),
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

