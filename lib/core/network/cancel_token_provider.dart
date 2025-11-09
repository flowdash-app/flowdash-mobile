import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Provider that creates a CancelToken and cancels it when disposed.
/// Use this in providers that make Dio requests to ensure requests are
/// cancelled when the provider is disposed.
final cancelTokenProvider = Provider<CancelToken>((ref) {
  final token = CancelToken();
  ref.onDispose(() {
    if (!token.isCancelled) {
      token.cancel('Provider disposed');
    }
  });
  return token;
});

