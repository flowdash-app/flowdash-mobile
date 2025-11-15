import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/notifications/push_notification_service.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  return PushNotificationService();
});

