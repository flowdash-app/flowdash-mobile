import 'package:flowdash_mobile/core/device/device_provider.dart';
import 'package:flowdash_mobile/core/notifications/push_notification_service.dart';
import 'package:flowdash_mobile/features/devices/data/providers/device_provider.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final pushNotificationServiceProvider = Provider<PushNotificationService>((ref) {
  final deviceService = ref.watch(deviceServiceProvider);
  final deviceRepository = ref.watch(deviceRepositoryProvider);

  return PushNotificationService(deviceService: deviceService, deviceRepository: deviceRepository);
});
