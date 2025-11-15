import 'package:flowdash_mobile/core/network/api_client.dart';
import 'package:flowdash_mobile/features/error_workflows/data/models/error_workflow_setup_state.dart';
import 'package:flowdash_mobile/features/error_workflows/data/repositories/error_workflow_repository.dart';
import 'package:flowdash_mobile/features/error_workflows/data/services/error_workflow_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider for ErrorWorkflowRepository
final errorWorkflowRepositoryProvider = Provider<ErrorWorkflowRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ErrorWorkflowRepository(apiClient);
});

/// Provider for ErrorWorkflowService
final errorWorkflowServiceProvider = Provider<ErrorWorkflowService>((ref) {
  final repository = ref.watch(errorWorkflowRepositoryProvider);
  final prefs = ref.watch(sharedPreferencesProvider);
  return ErrorWorkflowService(repository, prefs);
});

/// Provider for SharedPreferences (if not already defined elsewhere)
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError(
    'sharedPreferencesProvider must be overridden at app initialization',
  );
});

/// Family provider for setup state per instance
final setupStateProvider = FutureProvider.family<ErrorWorkflowSetupState?, String>(
  (ref, instanceId) async {
    final service = ref.watch(errorWorkflowServiceProvider);
    return service.checkSetupStatus(instanceId);
  },
);

/// Provider for API client (if not already defined elsewhere)
final apiClientProvider = Provider<ApiClient>((ref) {
  throw UnimplementedError(
    'apiClientProvider must be overridden at app initialization',
  );
});

