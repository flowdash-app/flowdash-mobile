import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class LoggingInterceptor extends Interceptor {
  final Logger _logger = AppLogger.getLogger('LoggingInterceptor');

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    _logger.info('Request: ${options.method} ${options.uri}');
    if (options.data != null) {
      _logger.fine('Request Body: ${options.data}');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final statusCode = response.statusCode;
    final uri = response.requestOptions.uri;
    
    // Log redirects with more detail
    if (statusCode != null && statusCode >= 300 && statusCode < 400) {
      _logger.warning(
        'Redirect: $statusCode ${response.requestOptions.method} $uri -> ${response.headers.value('location') ?? 'unknown'}',
      );
    } else {
      _logger.info('Response: $statusCode ${response.requestOptions.method} $uri');
    }
    
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    _logger.severe(
      'Error: ${err.requestOptions.method} ${err.requestOptions.uri}',
      err,
      err.stackTrace,
    );
    handler.next(err);
  }
}
