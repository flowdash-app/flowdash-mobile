import 'package:logging/logging.dart';
import 'package:flowdash_mobile/core/utils/logger.dart';

class RetryHelper {
  static final Logger _logger = AppLogger.getLogger('RetryHelper');

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
