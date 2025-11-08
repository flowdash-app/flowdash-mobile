import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/network/api_client.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final authRepository = ref.watch(authRepositoryProvider);
  return ApiClient(authRepository: authRepository);
});

