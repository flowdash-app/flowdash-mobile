import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flowdash_mobile/core/routing/app_router.dart';
import 'package:flowdash_mobile/core/routing/router_config.dart';
import 'package:logging/logging.dart';

class PushNotificationService {
  final Logger _logger = Logger('PushNotificationService');
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

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

      if (currentSettings.authorizationStatus ==
          AuthorizationStatus.authorized) {
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
      final settings = await _messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      final granted =
          settings.authorizationStatus == AuthorizationStatus.authorized;
      _logger.info(
          'requestPermissionWithRationale: ${granted ? "Granted" : "Denied"}');

      return granted;
    } catch (e, stackTrace) {
      _logger.severe('requestPermissionWithRationale: Failure', e, stackTrace);
      return false;
    }
  }

  Future<void> _initializeLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

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

    // Show local notification for better control
    if (message.data['type'] == 'workflow_error') {
      await _showLocalNotification(
        title: 'Workflow Error',
        body: message.notification?.body ?? 'A workflow execution failed',
        payload: _encodePayload(message.data),
      );
    }
  }

  void _handleMessageOpenedApp(RemoteMessage message) {
    _logger.info('_handleMessageOpenedApp: ${message.messageId}');
    _navigateFromMessage(message.data);
  }

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

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      0,
      title,
      body,
      details,
      payload: payload,
    );
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

