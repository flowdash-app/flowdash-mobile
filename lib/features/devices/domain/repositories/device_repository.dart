abstract class DeviceRepository {
  /// Register device token with backend
  Future<void> registerDevice({
    required String deviceId,
    required String fcmToken,
    required String platform,
  });

  /// Delete device token from backend (on logout)
  Future<void> deleteDevice({
    required String deviceId,
  });
}

