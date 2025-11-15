import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/device/device_service.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return DeviceService(sharedPreferences);
});

