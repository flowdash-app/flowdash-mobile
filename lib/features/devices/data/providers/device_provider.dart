import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/network/api_client_provider.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/devices/data/datasources/device_remote_datasource.dart';
import 'package:flowdash_mobile/features/devices/data/repositories/device_repository_impl.dart';
import 'package:flowdash_mobile/features/devices/domain/repositories/device_repository.dart';

final deviceRemoteDataSourceProvider = Provider<DeviceRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DeviceRemoteDataSource(apiClient.dio);
});

final deviceRepositoryProvider = Provider<DeviceRepository>((ref) {
  final remoteDataSource = ref.watch(deviceRemoteDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return DeviceRepositoryImpl(remoteDataSource, analytics);
});

