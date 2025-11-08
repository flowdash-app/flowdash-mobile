import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/domain/repositories/instance_repository.dart';
import 'package:flowdash_mobile/features/instances/data/repositories/instance_repository_impl.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_remote_datasource.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_local_datasource.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';

final instanceLocalDataSourceProvider = Provider<InstanceLocalDataSource>((ref) {
  return InstanceLocalDataSource();
});

final instanceRepositoryProvider = Provider<InstanceRepository>((ref) {
  final remoteDataSource = ref.watch(instanceRemoteDataSourceProvider);
  final localDataSource = ref.watch(instanceLocalDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  return InstanceRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    analytics: analytics,
  );
});

final instancesProvider = FutureProvider<List<Instance>>((ref) async {
  final repository = ref.watch(instanceRepositoryProvider);
  return repository.getInstances();
});

final instanceProvider = FutureProvider.family<Instance, String>((ref, id) async {
  final repository = ref.watch(instanceRepositoryProvider);
  return repository.getInstanceById(id);
});

