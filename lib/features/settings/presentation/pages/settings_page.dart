import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/core/device/device_provider.dart';
import 'package:flowdash_mobile/features/devices/data/providers/device_provider.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final analytics = ref.read(analyticsServiceProvider);
      analytics.logScreenView(
        screenName: 'settings',
        screenClass: 'SettingsPage',
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authStateProvider);
    final analytics = ref.read(analyticsServiceProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // User info section
          if (authState.value != null)
            Card(
              margin: const EdgeInsets.all(16.0),
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

          // Analytics Consent
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics & Privacy'),
            subtitle: const Text('Manage data collection preferences'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              analytics.logEvent(
                name: 'settings_action',
                parameters: {'action_type': 'view_analytics_consent'},
              );
              const AnalyticsConsentRoute().push(context);
            },
          ),

          const Divider(),

          // Push Notifications
          FutureBuilder<NotificationSettings>(
            future: FirebaseMessaging.instance.getNotificationSettings(),
            builder: (context, snapshot) {
              final isEnabled = snapshot.data?.authorizationStatus == AuthorizationStatus.authorized;
              
              return ListTile(
                leading: Icon(
                  Icons.notifications,
                  color: isEnabled ? null : Colors.grey,
                ),
                title: const Text('Push Notifications'),
                subtitle: Text(
                  isEnabled
                      ? 'Enabled • Device tokens are automatically removed after 30 days of inactivity'
                      : 'Disabled • Enable in app settings',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                trailing: Icon(
                  isEnabled ? Icons.check_circle : Icons.cancel,
                  color: isEnabled ? Colors.green : Colors.grey,
                ),
              );
            },
          ),

          const Divider(),

          // Privacy Policy
          ListTile(
            leading: const Icon(Icons.privacy_tip),
            title: const Text('Privacy Policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              analytics.logEvent(
                name: 'settings_action',
                parameters: {'action_type': 'view_privacy_policy'},
              );
              const PrivacyPolicyRoute().push(context);
            },
          ),

          // Terms of Service
          ListTile(
            leading: const Icon(Icons.description),
            title: const Text('Terms of Service'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              analytics.logEvent(
                name: 'settings_action',
                parameters: {'action_type': 'view_terms_of_service'},
              );
              const TermsOfServiceRoute().push(context);
            },
          ),

          // About
          ListTile(
            leading: const Icon(Icons.info),
            title: const Text('About'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              analytics.logEvent(
                name: 'settings_action',
                parameters: {'action_type': 'view_about'},
              );
              const AboutRoute().push(context);
            },
          ),

          const Divider(),

          // Sign Out
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text(
              'Sign Out',
              style: TextStyle(color: Colors.red),
            ),
            onTap: () async {
              analytics.logEvent(
                name: 'settings_action',
                parameters: {'action_type': 'sign_out'},
              );
              
              // Delete device token before signing out
              try {
                final deviceService = ref.read(deviceServiceProvider);
                final deviceRepository = ref.read(deviceRepositoryProvider);
                final deviceId = await deviceService.getDeviceId();
                await deviceRepository.deleteDevice(deviceId: deviceId);
              } catch (e) {
                // Log error but don't block sign out
                analytics.logFailure(
                  action: 'delete_device_on_logout',
                  error: e.toString(),
                );
              }
              
              final repository = ref.read(authRepositoryProvider);
              await repository.signOut();
              if (context.mounted) {
                const LoginRoute().go(context);
              }
            },
          ),
        ],
      ),
    );
  }
}

