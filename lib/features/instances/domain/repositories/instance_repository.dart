import 'package:flowdash_mobile/features/instances/domain/entities/instance.dart';

abstract class InstanceRepository {
  Future<List<Instance>> getInstances();
  Future<Instance> getInstanceById(String id);
  Future<void> toggleInstance(String id, bool enabled);
  Future<void> refreshInstances();
}

