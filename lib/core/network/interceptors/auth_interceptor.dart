import 'package:dio/dio.dart';
import 'package:flowdash_mobile/features/auth/domain/repositories/auth_repository.dart';

class AuthInterceptor extends Interceptor {
  final AuthRepository _authRepository;

  AuthInterceptor(this._authRepository);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _authRepository.getAuthToken();

    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    if (err.response?.statusCode == 401) {
      // Sign out on unauthorized - the repository will handle token cleanup
      try {
        await _authRepository.signOut();
      } catch (_) {
        // Ignore sign out errors in interceptor
      }
    }

    handler.next(err);
  }
}
