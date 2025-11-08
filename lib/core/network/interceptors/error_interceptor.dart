import 'package:dio/dio.dart';
import 'package:flowdash_mobile/core/errors/exceptions.dart';

class ErrorInterceptor extends Interceptor {
  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    AppException exception;
    
    switch (err.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        exception = NetworkException('Connection timeout');
        break;
      case DioExceptionType.badResponse:
        final statusCode = err.response?.statusCode;
        if (statusCode == 401) {
          exception = UnauthorizedException();
        } else if (statusCode == 404) {
          exception = NotFoundException();
        } else if (statusCode != null && statusCode >= 500) {
          exception = ServerException();
        } else {
          exception = NetworkException(
            err.response?.data?.toString() ?? 'Network error occurred',
          );
        }
        break;
      case DioExceptionType.cancel:
        exception = NetworkException('Request cancelled');
        break;
      case DioExceptionType.unknown:
      default:
        exception = NetworkException(
          err.message ?? 'Unknown network error occurred',
        );
    }
    
    handler.reject(
      DioException(
        requestOptions: err.requestOptions,
        error: exception,
        type: err.type,
        response: err.response,
      ),
    );
  }
}

