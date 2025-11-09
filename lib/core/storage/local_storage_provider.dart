import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flowdash_mobile/core/storage/local_storage.dart';
import 'package:flowdash_mobile/features/auth/presentation/providers/auth_provider.dart';

final localStorageProvider = Provider<LocalStorage>((ref) {
  final sharedPreferences = ref.watch(sharedPreferencesProvider);
  return LocalStorage(sharedPreferences);
});
