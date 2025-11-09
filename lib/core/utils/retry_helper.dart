import 'package:dio/dio.dart';
import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class RetryHelper {
  static final Logger _logger = AppLogger.getLogger('RetryHelper');

  /// Checks if an error is non-retryable (e.g., DNS/connection errors)
  static bool _isNonRetryableError(dynamic error) {
    if (error is DioException) {
      // Connection errors, DNS failures, and connection timeouts
      // should not be retried as they won't resolve by retrying
      switch (error.type) {
        case DioExceptionType.connectionError:
        case DioExceptionType.connectionTimeout:
          return true;
        case DioExceptionType.unknown:
          // Check if it's a DNS/connection error by examining the error message
          final errorMessage = error.message?.toLowerCase() ?? '';
          final errorString = error.toString().toLowerCase();
          if (errorMessage.contains('failed host lookup') ||
              errorMessage.contains('no address associated with hostname') ||
              errorMessage.contains('connection error') ||
              errorString.contains('failed host lookup') ||
              errorString.contains('no address associated with hostname')) {
            return true;
          }
          break;
        default:
          break;
      }
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
