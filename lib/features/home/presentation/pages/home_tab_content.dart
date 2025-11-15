import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/notifications/push_notification_provider.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/storage/local_storage_provider.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/providers/workflow_provider.dart';
import 'package:flowdash_mobile/features/workflows/presentation/widgets/workflow_list_tile.dart';
import 'package:flowdash_mobile/features/instances/presentation/providers/instance_provider.dart';
import 'package:flowdash_mobile/shared/widgets/empty_state_card.dart';
import 'package:flowdash_mobile/shared/widgets/error_state_card.dart';
import 'package:flowdash_mobile/shared/widgets/shimmer_list_tile.dart';
import 'package:flowdash_mobile/shared/widgets/section_header.dart';
import 'package:flowdash_mobile/shared/widgets/switchable_list_tile.dart';

class HomeTabContent extends ConsumerStatefulWidget {
  const HomeTabContent({super.key});

  @override
  ConsumerState<HomeTabContent> createState() => _HomeTabContentState();
}

class _HomeTabContentState extends ConsumerState<HomeTabContent> {
  bool _hasCheckedNotificationPermission = false;
  final Logger _logger = AppLogger.getLogger('HomeTabContent');

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

  Future<void> _checkAndRequestNotificationPermission() async {
    // Only check once per widget lifecycle
    if (_hasCheckedNotificationPermission) return;
    _hasCheckedNotificationPermission = true;

    final instancesAsync = ref.read(instancesProvider);
    final localStorage = ref.read(localStorageProvider);
    final pushService = ref.read(pushNotificationServiceProvider);

    // Wait for instances to load
    await instancesAsync.when(
      data: (instances) async {
        // Only request if user has at least one instance
        if (instances.isNotEmpty) {
          // Check if we've already requested permission
          final hasRequested = localStorage.hasRequestedNotificationPermission();
          
          if (!hasRequested) {
            // Check current permission status
            final notificationSettings = await FirebaseMessaging.instance.getNotificationSettings();
            
            // Only request if not already authorized or denied
            if (notificationSettings.authorizationStatus != AuthorizationStatus.authorized &&
                notificationSettings.authorizationStatus != AuthorizationStatus.denied) {
              // Request permission with rationale (check mounted before using context)
              if (mounted) {
                final granted = await pushService.requestPermissionWithRationale(context);
                
                // Mark that we've requested (regardless of whether granted or not)
                await localStorage.setHasRequestedNotificationPermission(true);
                
                if (granted) {
                  // Device token will be registered automatically by pushService
                  _logger.info('Notification permission granted on home page');
                }
              }
            } else {
              // Already authorized or denied, mark as requested
              await localStorage.setHasRequestedNotificationPermission(true);
            }
          }
        }
      },
      loading: () {},
      error: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
    final workflowsAsync = ref.watch(workflowsWithInstanceProvider);
    final instancesAsync = ref.watch(instancesProvider);
    final authState = ref.watch(authStateProvider);

    // Check and request notification permission when instances are loaded
    instancesAsync.whenData((instances) {
      if (instances.isNotEmpty && !_hasCheckedNotificationPermission) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _checkAndRequestNotificationPermission();
        });
      }
    });

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          // Use notifier refresh methods which clear cache and refetch
          await Future.wait([
            ref.read(workflowsWithInstanceProvider.notifier).refresh(),
            ref.read(instancesProvider.notifier).refresh(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              title: const Text('FlowDash'),
              floating: true,
              snap: true,
              actions: [
                // Show loading indicator when either provider is loading
                Builder(
                  builder: (context) {
                    final workflowsLoading = workflowsAsync.isLoading && !workflowsAsync.hasValue;
                    final instancesLoading = instancesAsync.isLoading && !instancesAsync.hasValue;
                    final isLoading = workflowsLoading || instancesLoading;
                    
                    return IconButton(
                      icon: isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.refresh),
                      onPressed: isLoading ? null : () {
                        ref.read(workflowsWithInstanceProvider.notifier).refresh();
                        ref.read(instancesProvider.notifier).refresh();
                      },
                    );
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
                SectionHeader(
                  title: 'Workflows',
                  subtitle: 'Automated workflows from your n8n instance',
                  actionButton: TextButton(
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
                              ...workflows.take(5).map((workflowWithInstance) {
                                return WorkflowListTile(
                                  workflow: workflowWithInstance.workflow,
                                  instanceId: workflowWithInstance.instanceId,
                                  instanceName: workflowWithInstance.instanceName,
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
                  loading: () => Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (index) => const ShimmerListTile(
                          wrapInCard: false,
                          showTrailing: true,
                        ),
                      ),
                    ),
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
                SectionHeader(
                  title: 'Instances',
                  actionButton: TextButton(
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
                              ...instances.take(5).map((instance) {
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
                                  wrapInCard: false,
                                );
                              }),
                              if (instances.length > 5)
                                ListTile(
                                  title: Text(
                                    '${instances.length - 5} more instance${instances.length - 5 > 1 ? 's' : ''}',
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
                  loading: () => Card(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(
                        3,
                        (index) => const ShimmerListTile(
                          wrapInCard: false,
                          showTrailing: true,
                        ),
                      ),
                    ),
                  ),
                  error: (error, stack) {
                    final errorMessage = error.toString().replaceAll('Exception: ', '');
                    
                    return ErrorStateCard(
                      icon: Icons.error_outline,
                      title: 'Failed to load instances',
                      message: errorMessage,
                      actionButton: OutlinedButton.icon(
                        onPressed: () => ref.read(instancesProvider.notifier).refresh(),
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

