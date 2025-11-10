import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/constants/app_constants.dart';
import 'package:flowdash_mobile/core/network/interceptors/auth_interceptor.dart';
import 'package:flowdash_mobile/core/network/interceptors/error_interceptor.dart';
import 'package:flowdash_mobile/core/network/interceptors/logging_interceptor.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';
import 'package:flowdash_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:logging/logging.dart';

class ApiClient {
  final Dio _dio;
  final Logger _logger = AppLogger.getLogger('ApiClient');

  ApiClient({required AuthRepository authRepository}) : _dio = Dio() {
    _logger.info('ApiClient: Initializing');

    _dio.options.baseUrl = AppConstants.apiBaseUrl;
    _dio.options.connectTimeout = AppConstants.connectTimeout;
    _dio.options.receiveTimeout = AppConstants.receiveTimeout;
    // Limit redirects to prevent redirect loops
    // Dio follows redirects automatically by default
    _dio.options.followRedirects = true;
    _dio.options.maxRedirects = 5;

    _dio.interceptors.addAll([
      AuthInterceptor(authRepository),
      LoggingInterceptor(),
      ErrorInterceptor(),
    ]);

    _logger.info('ApiClient: Initialized successfully');
  }

  Dio get dio => _dio;
}
