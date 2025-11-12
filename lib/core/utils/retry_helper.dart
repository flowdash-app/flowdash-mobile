import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class RetryHelper {
  static final Logger _logger = AppLogger.getLogger('RetryHelper');

  /// Checks if an error is non-retryable (e.g., DNS/connection errors, auth errors, parsing errors)
  static bool _isNonRetryableError(dynamic error) {
    // Type cast errors and format errors should not be retried
    // These are data parsing issues, not network issues
    if (error is TypeError || error is FormatException) {
      return true;
    }
    
    // Get error string once for all checks
    final errorString = error.toString().toLowerCase();
    
    // Check for type cast errors in the error message
    if (errorString.contains('type') && 
        (errorString.contains('is not a subtype') || 
         errorString.contains('type cast'))) {
      return true;
    }
    
    // Check if it's a DioException with connection error type
    if (error is DioException) {
      // Check for authentication errors (401) - these should not be retried
      if (error.response?.statusCode == 401) {
        return true;
      }
      
      // Check for client errors (4xx) - these are usually not retryable
      final statusCode = error.response?.statusCode;
      if (statusCode != null && statusCode >= 400 && statusCode < 500) {
        // 401 is already handled above, but other 4xx errors should also not be retried
        // (except maybe 408 Request Timeout, but that's handled by connectionTimeout)
        return true;
      }
      
      // Check for server errors (5xx) - these indicate backend issues that won't be fixed by retrying
      // 502 Bad Gateway, 503 Service Unavailable, and 500 Internal Server Error should not be retried
      // as they indicate configuration or infrastructure issues
      if (statusCode != null && statusCode >= 500 && statusCode < 600) {
        // Don't retry on server errors - they indicate backend configuration issues
        // (e.g., n8n instance behind Cloudflare Access, backend misconfiguration)
        return true;
      }
      
      // Connection errors, DNS failures, and connection timeouts
      // should not be retried as they won't resolve by retrying
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return true;
        case DioExceptionType.unknown:
          // Check if it's a DNS/connection error by examining the error message
          final errorMessage = error.message?.toLowerCase() ?? '';
          // Also check the wrapped error if it exists
          final wrappedError = error.error?.toString().toLowerCase() ?? '';
          if (errorMessage.contains('failed host lookup') ||
              errorMessage.contains('no address associated with hostname') ||
              errorMessage.contains('connection error') ||
              errorMessage.contains('connection errored') ||
              errorString.contains('failed host lookup') ||
              errorString.contains('no address associated with hostname') ||
              wrappedError.contains('failed host lookup') ||
              wrappedError.contains('no address associated with hostname')) {
            return true;
          }
          break;
        default:
          break;
      }
      
      // Check if the wrapped error is a NetworkException with connection error message
      if (error.error != null) {
        final wrappedErrorString = error.error.toString().toLowerCase();
        if (wrappedErrorString.contains('failed host lookup') ||
            wrappedErrorString.contains('no address associated with hostname') ||
            wrappedErrorString.contains('connection errored') ||
            wrappedErrorString.contains('unauthorized')) {
          return true;
        }
      }
    }
    
    // Also check the error message directly for connection/unauthorized errors
    if (errorString.contains('failed host lookup') ||
        errorString.contains('no address associated with hostname') ||
        errorString.contains('connection errored: failed host lookup') ||
        errorString.contains('unauthorized')) {
      return true;
    }
    
    return false;
  }

  static Future<T> retry<T>({
    required Future<T> Function() operation,
    int maxAttempts = 3,
    Duration delay = const Duration(seconds: 1),
  }) async {
    _logger.info('retry: Entry - maxAttempts: $maxAttempts');

    int attempt = 0;
    Exception? lastException;

    while (attempt < maxAttempts) {
      attempt++;
      _logger.info('retry: Attempt $attempt/$maxAttempts');

      try {
        final result = await operation();
        _logger.info('retry: Success on attempt $attempt');
        return result;
      } catch (e, stackTrace) {
        lastException = e is Exception ? e : Exception(e.toString());
        _logger.warning('retry: Attempt $attempt failed', e, stackTrace);

        // Check if this is a non-retryable error (e.g., DNS/connection failure)
        if (_isNonRetryableError(e)) {
          _logger.warning(
            'retry: Non-retryable error detected, skipping remaining attempts',
            e,
            stackTrace,
          );
          throw lastException;
        }

        if (attempt < maxAttempts) {
          final waitTime =
              Duration(milliseconds: delay.inMilliseconds * attempt);
          _logger
              .info('retry: Waiting ${waitTime.inMilliseconds}ms before retry');
          await Future.delayed(waitTime);
        }
      }
    }

    _logger.severe('retry: All $maxAttempts attempts failed');
    throw lastException ??
        Exception('Retry failed after $maxAttempts attempts');
  }
}
