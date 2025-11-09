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
    _logger.info(
        'Response: ${response.statusCode} ${response.requestOptions.uri}');
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
