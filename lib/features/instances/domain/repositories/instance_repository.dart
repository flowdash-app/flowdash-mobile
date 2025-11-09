import 'package:dio/dio.dart';
import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';

abstract class InstanceRepository {
  Future<List<Instance>> getInstances({CancelToken? cancelToken});
  Future<Instance> getInstanceById(String id, {CancelToken? cancelToken});
  Future<void> toggleInstance(String id, bool enabled, {CancelToken? cancelToken});
  Future<void> refreshInstances();
}
