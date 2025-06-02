import 'dart:async';

import 'package:breez_sdk_liquid/breez_sdk_liquid.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:logging/logging.dart';
import 'package:misty_breez/cubit/cubit.dart';

/// Logger for LnUrlService
final Logger _logger = Logger('LnUrlService');

/// A service for handling LNURL operations through Breez SDK Liquid
///
/// This service provides methods to interact with Lightning Network URL (LNURL)
/// functionality, including withdrawals, payments, and authentication.
class LnUrlService {
  /// Internal SDK reference for Breez Liquid operations
  final BreezSDKLiquid _breezSdkLiquid;

  /// Creates a new LnUrlService with the required BreezSDKLiquid instance
  ///
  /// [_breezSdkLiquid] The SDK instance to use for LNURL operations
  LnUrlService(this._breezSdkLiquid);

  /// Process an LNURL withdraw request
  ///
  /// [req] The withdraw request parameters
  ///
  /// Returns a [LnUrlWithdrawResult] with the withdrawal operation result
  /// Throws an exception if the operation fails
  Future<LnUrlWithdrawResult> lnurlWithdraw({required LnUrlWithdrawRequest req}) async {
    _logger.info('Initiating LNURL withdraw');

    try {
      final LnUrlWithdrawResult result = await _executeSDKOperation(
        () => _breezSdkLiquid.instance!.lnurlWithdraw(req: req),
      );

      _logger.info('LNURL withdraw completed successfully');
      return result;
    } catch (e) {
      _logError('lnurlWithdraw', e);
      rethrow;
    }
  }

  /// Prepare an LNURL pay request
  ///
  /// [req] The payment preparation request parameters
  ///
  /// Returns a [PrepareLnUrlPayResponse] with the prepared payment details
  /// Throws an exception if the preparation fails
  Future<PrepareLnUrlPayResponse> prepareLnurlPay({required PrepareLnUrlPayRequest req}) async {
    _logger.info('Preparing LNURL payment');

    try {
      final PrepareLnUrlPayResponse response = await _executeSDKOperation(
        () => _breezSdkLiquid.instance!.prepareLnurlPay(req: req),
      );

      _logger.info('LNURL payment preparation completed');
      return response;
    } catch (e) {
      _logError('prepareLnurlPay', e);
      rethrow;
    }
  }

  /// Execute an LNURL pay request
  ///
  /// [req] The payment request parameters
  ///
  /// Returns a [LnUrlPayResult] with the payment result
  /// Throws an exception if the payment fails
  Future<LnUrlPayResult> lnurlPay({required LnUrlPayRequest req}) async {
    _logger.info('Executing LNURL payment');

    try {
      final LnUrlPayResult result = await _executeSDKOperation(
        () => _breezSdkLiquid.instance!.lnurlPay(req: req),
      );

      _logger.info('LNURL payment executed successfully');
      return result;
    } catch (e) {
      _logError('lnurlPay', e);
      rethrow;
    }
  }

  /// Authenticate using LNURL auth
  ///
  /// [reqData] The authentication request data
  ///
  /// Returns a [LnUrlCallbackStatus] indicating the auth operation result
  /// Throws an exception if authentication fails
  Future<LnUrlCallbackStatus> lnurlAuth({required LnUrlAuthRequestData reqData}) async {
    _logger.info('Authenticating with LNURL');

    try {
      final LnUrlCallbackStatus status = await _executeSDKOperation(
        () => _breezSdkLiquid.instance!.lnurlAuth(reqData: reqData),
      );

      _logger.info('LNURL authentication completed');
      return status;
    } catch (e) {
      _logError('lnurlAuth', e);
      rethrow;
    }
  }

  /// Validate if a Lightning payment is within limits and if there's sufficient balance
  ///
  /// [amount] The payment amount in satoshis
  /// [outgoing] Whether this is an outgoing payment
  /// [lightningLimits] The current Lightning payment limits
  /// [balance] The current wallet balance in satoshis
  ///
  /// Throws appropriate exceptions if validation fails
  void validateLnUrlPayment({
    required BigInt amount,
    required bool outgoing,
    required LightningPaymentLimitsResponse lightningLimits,
    required int balance,
  }) {
    _logger.info('Validating LNURL payment parameters');

    // Check for sufficient balance for outgoing payments
    if (outgoing && amount.toInt() > balance) {
      _logger.warning('Payment validation failed: Insufficient balance');
      throw const InsufficientLocalBalanceError();
    }

    // Get the appropriate limits based on payment direction
    final Limits limits = outgoing ? lightningLimits.send : lightningLimits.receive;

    // Check against maximum limit
    if (amount > limits.maxSat) {
      _logger.warning('Payment validation failed: Exceeds maximum limit');
      throw PaymentExceedsLimitError(limits.maxSat.toInt());
    }

    // Check against minimum limit
    if (amount < limits.minSat) {
      _logger.warning('Payment validation failed: Below minimum limit');
      throw PaymentBelowLimitError(limits.minSat.toInt());
    }

    _logger.info('Payment validation successful');
  }

  /// Execute an SDK operation with consistent error handling
  ///
  /// [operation] The function representing the SDK operation to execute
  ///
  /// Returns the result of the operation
  Future<T> _executeSDKOperation<T>(Future<T> Function() operation) async {
    if (_breezSdkLiquid.instance == null) {
      throw StateError('Breez SDK Liquid instance is not initialized');
    }

    return operation();
  }

  /// Log error with consistent format
  ///
  /// [operation] The name of the operation that failed
  /// [error] The error that occurred
  void _logError(String operation, Object error) {
    _logger.severe('$operation error', error);
  }
}
