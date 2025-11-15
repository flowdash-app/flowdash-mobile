import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/storage/local_storage_provider.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:flowdash_mobile/features/instances/domain/repositories/instance_repository.dart';
import 'package:flowdash_mobile/features/instances/data/repositories/instance_repository_impl.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_remote_datasource.dart';
import 'package:flowdash_mobile/features/instances/data/datasources/instance_local_datasource.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';

final instanceLocalDataSourceProvider =
    Provider<InstanceLocalDataSource>((ref) {
  return InstanceLocalDataSource();
});

final instanceRepositoryProvider = Provider<InstanceRepository>((ref) {
  final remoteDataSource = ref.watch(instanceRemoteDataSourceProvider);
  final localDataSource = ref.watch(instanceLocalDataSourceProvider);
  final analytics = ref.watch(analyticsServiceProvider);
  final localStorage = ref.watch(localStorageProvider);
  return InstanceRepositoryImpl(
    remoteDataSource: remoteDataSource,
    localDataSource: localDataSource,
    analytics: analytics,
    localStorage: localStorage,
  );
});

class InstancesNotifier extends AsyncNotifier<List<Instance>> {
  @override
  Future<List<Instance>> build() async {
    final repository = ref.read(instanceRepositoryProvider);
    final cancelToken = CancelToken();

    ref.onDispose(() {
      if (!cancelToken.isCancelled) {
        cancelToken.cancel('Provider disposed');
      }
    });

    return repository.getInstances(cancelToken: cancelToken);
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() async {
      final repository = ref.read(instanceRepositoryProvider);
      await repository.refreshInstances();
      final cancelToken = CancelToken();
      ref.onDispose(() {
        if (!cancelToken.isCancelled) {
          cancelToken.cancel('Provider disposed');
        }
      });
      return repository.getInstances(cancelToken: cancelToken);
    });
  }
}

final instancesProvider = AsyncNotifierProvider<InstancesNotifier, List<Instance>>(() {
  return InstancesNotifier();
});

final instanceProvider =
    FutureProvider.family<Instance, String>((ref, id) async {
  final repository = ref.watch(instanceRepositoryProvider);
  final cancelToken = CancelToken();

  ref.onDispose(() {
    if (!cancelToken.isCancelled) {
      cancelToken.cancel('Provider disposed');
    }
  });

  return repository.getInstanceById(id, cancelToken: cancelToken);
});
