export 'wordlist.dart';

/// Application-wide constants
///
/// This file contains constants that are used throughout the application.
/// Group related constants in their own class for better organization.

/// Payment Sheet timing constants for animations and transitions
class PaymentSheetTiming {
  /// Private constructor to prevent instantiation
  PaymentSheetTiming._();

  /// Delay before popping the payment sheet
  static const Duration popDelay = Duration(milliseconds: 2250);
}

/// Network-related constants
class NetworkConstants {
  /// Private constructor to prevent instantiation
  NetworkConstants._();

  /// Default Mempool instance URL
  static const String defaultMempoolInstance = 'https://liquid.fra.mempool.space/';
}

/// Payment-related constants
class PaymentConstants {
  /// Private constructor to prevent instantiation
  PaymentConstants._();

  /// Bitcoin satoshis per BTC
  static const int satoshisPerBitcoin = 100000000;
}

/// Block times for different blockchains in seconds
class BlockTimes {
  /// Private constructor to prevent instantiation
  BlockTimes._();

  /// Average time between Bitcoin blocks in seconds (10 minutes)
  static const int bitcoinBlockTimeSeconds = 600;

  /// Average time between Liquid blocks in seconds (1 minute)
  static const int liquidBlockTimeSeconds = 60;
}
