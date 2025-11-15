import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flowdash_mobile/core/device/device_service.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/routing/router_config.dart';
import 'package:flowdash_mobile/features/devices/domain/repositories/device_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:logging/logging.dart';

/// Top-level function to handle background messages when app is terminated
/// This MUST be a top-level function (not inside a class)
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  final logger = Logger('BackgroundMessageHandler');
  logger.info('firebaseMessagingBackgroundHandler: ${message.messageId}');

  // Show local notification when app is terminated
  if (message.data['type'] == 'workflow_error') {
    final notificationsPlugin = FlutterLocalNotificationsPlugin();

    // Initialize notifications
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await notificationsPlugin.initialize(initSettings);

    // Show notification
    const androidDetails = AndroidNotificationDetails(
      'workflow_errors',
      'Workflow Errors',
      channelDescription: 'Notifications for workflow execution failures',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    // Encode payload
    final payload = message.data.entries.map((e) => '${e.key}=${e.value}').join('&');

    await notificationsPlugin.show(
      0,
      'Workflow Error',
      message.notification?.body ?? 'A workflow execution failed',
      details,
      payload: payload,
    );
  }
}

class PushNotificationService {
  final DeviceService _deviceService;
  final DeviceRepository _deviceRepository;
  final Logger _logger = Logger('PushNotificationService');
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

  PushNotificationService({
    required DeviceService deviceService,
    required DeviceRepository deviceRepository,
  }) : _deviceService = deviceService,
       _deviceRepository = deviceRepository;

  Future<void> initialize() async {
    _logger.info('initialize: Entry');

    try {
      // Initialize local notifications (without requesting permission yet)
      await _initializeLocalNotifications();

      // Set up message handlers
      _setupMessageHandlers();

      _logger.info('initialize: Success (without permission request)');
    } catch (e, stackTrace) {
      _logger.severe('initialize: Failure', e, stackTrace);
    }
  }

  Future<bool> requestPermissionWithRationale(BuildContext context) async {
    _logger.info('requestPermissionWithRationale: Entry');

    try {
      // Check current permission status
      final currentSettings = await _messaging.getNotificationSettings();

      if (currentSettings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.info('requestPermissionWithRationale: Already authorized');
        return true;
      }

      if (currentSettings.authorizationStatus == AuthorizationStatus.denied) {
        _logger.info('requestPermissionWithRationale: Previously denied');
        return false;
      }

      // Show rationale dialog
      if (!context.mounted) {
        _logger.warning('requestPermissionWithRationale: Context not mounted');
        return false;
      }

      final shouldRequest = await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Enable Notifications'),
          content: const Text(
            'Get notified when your n8n workflows fail so you can quickly review and fix issues. '
            'We\'ll only send notifications for important events.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(false),
              child: const Text('Not Now'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(dialogContext).pop(true),
              child: const Text('Enable'),
            ),
          ],
        ),
      );

      if (shouldRequest != true) {
        _logger.info('requestPermissionWithRationale: User declined rationale');
        return false;
      }

      // Request permission
      final settings = await _messaging.requestPermission(alert: true, badge: true, sound: true);

      final granted = settings.authorizationStatus == AuthorizationStatus.authorized;
      _logger.info('requestPermissionWithRationale: ${granted ? "Granted" : "Denied"}');

      return granted;
    } catch (e, stackTrace) {
      _logger.severe('requestPermissionWithRationale: Failure', e, stackTrace);
      return false;
    }
  }

  /// Register device token with backend
  /// Call this after permission is granted
  Future<void> registerDeviceToken() async {
    _logger.info('registerDeviceToken: Entry');

    try {
      // Get FCM token
      final fcmToken = await _messaging.getToken();
      if (fcmToken == null) {
        _logger.warning('registerDeviceToken: No FCM token available');
        return;
      }

      // Get device ID and platform
      final deviceId = await _deviceService.getDeviceId();
      final platform = _deviceService.getPlatform();

      // Register with backend
      await _deviceRepository.registerDevice(
        deviceId: deviceId,
        fcmToken: fcmToken,
        platform: platform,
      );

      _logger.info('registerDeviceToken: Success - device: $deviceId, platform: $platform');
    } catch (e, stackTrace) {
      _logger.severe('registerDeviceToken: Failure', e, stackTrace);
      // Don't rethrow - registration failures shouldn't break the app
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(android: androidSettings, iOS: iosSettings);

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );
  }

  void _setupMessageHandlers() {
    // Handle messages when app is in foreground
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Handle messages when app is in background and user taps notification
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Handle initial message if app was opened from terminated state
    _messaging.getInitialMessage().then((message) {
      if (message != null) {
        _handleMessageOpenedApp(message);
      }
    });
  }

  Future<void> _handleForegroundMessage(RemoteMessage message) async {
    _logger.info('_handleForegroundMessage: ${message.messageId}');

    // When app is in foreground, show in-app notification instead of banner
    if (message.data['type'] == 'workflow_error') {
      final context = navigatorKey.currentContext;

      if (context != null && context.mounted) {
        final severity = message.data['severity'] ?? 'error';
        final executionId = message.data['execution_id'];
        final instanceId = message.data['instance_id'];
        final errorMessage = message.notification?.body ?? 'A workflow execution failed';

        // Determine notification style based on severity
        if (severity == 'critical' || severity == 'error') {
          // Show dialog for critical/error notifications
          _showErrorDialog(
            context: context,
            title: message.notification?.title ?? 'Workflow Error',
            message: errorMessage,
            severity: severity,
            onView: (executionId != null && instanceId != null)
                ? () {
                    Navigator.of(context).pop();
                    ExecutionDetailsRoute(
                      executionId: executionId,
                      instanceId: instanceId,
                      workflowName: message.data['workflow_name'],
                    ).push(context);
                  }
                : null,
          );
        } else {
          // Show SnackBar for info/warning notifications
          final backgroundColor = severity == 'warning' ? Colors.orange[700] : Colors.blue[700];
          final icon = severity == 'warning' ? Icons.warning_amber : Icons.info;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(errorMessage, style: const TextStyle(color: Colors.white)),
                  ),
                ],
              ),
              backgroundColor: backgroundColor,
              duration: const Duration(seconds: 6),
              action: (executionId != null && instanceId != null)
                  ? SnackBarAction(
                      label: 'View',
                      textColor: Colors.white,
                      onPressed: () {
                        ExecutionDetailsRoute(
                          executionId: executionId,
                          instanceId: instanceId,
                          workflowName: message.data['workflow_name'],
                        ).push(context);
                      },
                    )
                  : null,
            ),
          );
        }
      } else {
        // Fallback: If no context available, show local notification
        await _showLocalNotification(
          title: message.notification?.title ?? 'Workflow Error',
          body: message.notification?.body ?? 'A workflow execution failed',
          payload: _encodePayload(message.data),
        );
      }
    }
  }

  void _showErrorDialog({
    required BuildContext context,
    required String title,
    required String message,
    required String severity,
    VoidCallback? onView,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        icon: Icon(
          severity == 'critical' ? Icons.error : Icons.error_outline,
          color: Colors.red[700],
          size: 48,
        ),
        title: Text(
          title,
          style: TextStyle(color: Colors.red[700], fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(message, style: const TextStyle(fontSize: 14)),
            if (severity == 'critical') ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: Colors.red[700], size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'This is a critical error that requires immediate attention.',
                        style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Dismiss'),
          ),
          if (onView != null)
            ElevatedButton.icon(
              onPressed: onView,
              icon: const Icon(Icons.visibility),
              label: const Text('View Details'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
            ),
        ],
      ),
    );
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.info('_handleMessageOpenedApp: ${message.messageId}');
    _navigateFromMessage(message.data);
  }

  @pragma('vm:entry-point')
  void _onNotificationTapped(NotificationResponse response) {
    _logger.info('_onNotificationTapped: ${response.payload}');
    if (response.payload != null) {
      final data = _decodePayload(response.payload!);
      _navigateFromMessage(data);
    }
  }

  void _navigateFromMessage(Map<String, dynamic> data) {
    if (data['type'] == 'workflow_error') {
      final executionId = data['execution_id'];
      final instanceId = data['instance_id'];

      if (executionId != null && instanceId != null) {
        final context = navigatorKey.currentContext;
        if (context != null) {
          ExecutionDetailsRoute(
            executionId: executionId,
            instanceId: instanceId,
            workflowName: null,
          ).push(context);
        }
      }
    }
  }

  Future<void> _showLocalNotification({
    required String title,
    required String body,
    String? payload,
  }) async {
    const androidDetails = AndroidNotificationDetails(
      'workflow_errors',
      'Workflow Errors',
      channelDescription: 'Notifications for workflow execution failures',
      importance: Importance.high,
      priority: Priority.high,
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(0, title, body, details, payload: payload);
  }

  String _encodePayload(Map<String, dynamic> data) {
    return data.entries.map((e) => '${e.key}=${e.value}').join('&');
  }

  Map<String, dynamic> _decodePayload(String payload) {
    return Map.fromEntries(
      payload.split('&').map((e) {
        final parts = e.split('=');
        return MapEntry(parts[0], parts.length > 1 ? parts[1] : '');
      }),
    );
  }
}
