import 'dart:async';

import 'package:logging/logging.dart';

/// Executes an operation with retry logic for transient errors.
///
/// [operation] is the async operation to execute.
/// [maxRetries] is the maximum number of retry attempts.
/// [operationName] is used for logging.
Future<T> executeWithRetry<T>(
  Future<T> Function() operation, {
  required String operationName,
  required int maxRetries,
  required Logger logger,
}) async {
  int attempts = 0;
  Exception? lastException;

  while (attempts <= maxRetries) {
    try {
      return await operation();
    } on TimeoutException catch (e, stackTrace) {
      attempts++;
      lastException = e;

      if (attempts <= maxRetries) {
        final Duration backoff = Duration(milliseconds: 500 * (1 << attempts));
        logger.warning(
          'Timeout occurred while trying to $operationName. '
          'Retrying in ${backoff.inMilliseconds}ms (attempt $attempts/$maxRetries)',
          e,
          stackTrace,
        );
        await Future<void>.delayed(backoff);
      } else {
        logger.severe('Max retries exceeded for $operationName', e, stackTrace);
        rethrow;
      }
    } catch (e, stackTrace) {
      // Only retry specific errors that are likely transient
      if (_isTransientError(e)) {
        attempts++;
        lastException = e is Exception ? e : Exception(e.toString());

        if (attempts <= maxRetries) {
          final Duration backoff = Duration(milliseconds: 500 * (1 << attempts));
          logger.warning(
            'Transient error occurred while trying to $operationName. '
            'Retrying in ${backoff.inMilliseconds}ms (attempt $attempts/$maxRetries)',
            e,
            stackTrace,
          );
          await Future<void>.delayed(backoff);
        } else {
          logger.severe('Max retries exceeded for $operationName', e, stackTrace);
          throw lastException;
        }
      } else {
        // Non-transient errors should not be retried
        logger.severe('Non-transient error occurred during $operationName', e, stackTrace);
        rethrow;
      }
    }
  }

  // This should never be reached unless something went wrong
  throw lastException ?? Exception('Failed to $operationName after multiple attempts');
}

/// Determines if an error is transient and can be retried.
bool _isTransientError(dynamic error) {
  // Customize this logic based on specific error types in your application
  return error is TimeoutException ||
      error.toString().contains('network') ||
      error.toString().contains('connection') ||
      error.toString().contains('timeout');
}
