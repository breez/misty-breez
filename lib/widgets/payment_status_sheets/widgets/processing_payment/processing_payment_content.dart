import 'package:archive/archive.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:lottie/lottie.dart';

/// A widget that displays a payment processing animation and status message.
///
/// This widget handles the visualization of payment processing state, showing
/// an animated loader and appropriate text to inform the user of ongoing operations.
class ProcessingPaymentContent extends StatelessWidget {
  /// Creates a processing payment content widget.
  const ProcessingPaymentContent({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        PaymentProcessingTitle(),
        PaymentProcessingLoadingMessage(),
        PaymentProcessingAnimation(),
      ],
    );
  }
}

/// Displays the processing payment title.
class PaymentProcessingTitle extends StatelessWidget {
  static final Logger _logger = Logger('PaymentProcessingTitle');

  /// Standard horizontal padding for the title.
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 16.0);

  /// Title text size.
  static const double _fontSize = 24.0;

  /// Creates a payment processing title widget.
  const PaymentProcessingTitle({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    try {
      return Padding(
        padding: _padding,
        child: Text(
          texts.processing_payment_dialog_processing_payment,
          style: themeData.dialogTheme.titleTextStyle?.copyWith(
            fontSize: _fontSize,
            color: themeData.isLightTheme ? null : Colors.white,
          ),
          textAlign: TextAlign.center,
        ),
      );
    } catch (e, stackTrace) {
      _logger.warning('Error building title widget', e, stackTrace);
      // Fallback to a simpler text widget if styling fails
      return const Padding(
        padding: _padding,
        child: Text(
          'Processing Payment',
          textAlign: TextAlign.center,
        ),
      );
    }
  }
}

/// Displays the loading message with animated text.
class PaymentProcessingLoadingMessage extends StatelessWidget {
  static final Logger _logger = Logger('PaymentProcessingLoadingMessage');

  /// Standard horizontal padding for the message.
  static const EdgeInsets _padding = EdgeInsets.symmetric(horizontal: 16.0);

  /// Height for the loading message container.
  static const double _height = 64.0;

  /// Creates a payment processing loading message widget.
  const PaymentProcessingLoadingMessage({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    try {
      return Padding(
        padding: _padding,
        child: SizedBox(
          height: _height,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              LoadingAnimatedText(
                loadingMessage: texts.processing_payment_dialog_wait,
                textStyle: themeData.dialogTheme.contentTextStyle,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    } catch (e, stackTrace) {
      _logger.warning('Error building loading message widget', e, stackTrace);
      // Fallback to a simpler text widget if LoadingAnimatedText fails
      return const Padding(
        padding: _padding,
        child: SizedBox(
          height: _height,
          child: Center(
            child: Text('Please wait...'),
          ),
        ),
      );
    }
  }
}

/// Displays the Lottie animation for payment processing.
class PaymentProcessingAnimation extends StatefulWidget {
  /// Creates a payment processing animation widget.
  const PaymentProcessingAnimation({super.key});

  @override
  State<PaymentProcessingAnimation> createState() => _PaymentProcessingAnimationState();
}

class _PaymentProcessingAnimationState extends State<PaymentProcessingAnimation> {
  static final Logger _logger = Logger('PaymentProcessingAnimation');

  /// Maximum number of retry attempts for loading animation.
  static const int _maxRetryAttempts = 3;

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final CustomData customData = themeData.customData;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Lottie.asset(
        customData.loaderAssetPath,
        decoder: (List<int> bytes) => _decodeLottieFileWithRetry(bytes, _maxRetryAttempts),
        repeat: true,
        reverse: false,
        filterQuality: FilterQuality.high,
        fit: BoxFit.fill,
        errorBuilder: (BuildContext context, Object error, StackTrace? stackTrace) {
          _logger.severe(
            'Failed to load Lottie animation',
            error,
            stackTrace,
          );
          // Fallback to a simple CircularProgressIndicator if Lottie fails
          return const Center(child: CircularProgressIndicator());
        },
      ),
    );
  }

  /// Custom decoder for Lottie files with retry mechanism.
  ///
  /// Attempts to decode the Lottie file multiple times before giving up.
  Future<LottieComposition?> _decodeLottieFileWithRetry(List<int> bytes, int remainingAttempts) async {
    try {
      return await LottieComposition.decodeZip(
        bytes,
        filePicker: _selectLottieFileFromArchive,
      );
    } catch (e, stackTrace) {
      if (remainingAttempts > 0) {
        _logger.warning(
          'Error decoding Lottie ZIP file, retrying (${_maxRetryAttempts - remainingAttempts + 1}/$_maxRetryAttempts)',
          e,
          stackTrace,
        );
        // Add a small delay before retrying
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return _decodeLottieFileWithRetry(bytes, remainingAttempts - 1);
      }

      _logger.severe(
        'Failed to decode Lottie ZIP file after $_maxRetryAttempts attempts',
        e,
        stackTrace,
      );
      rethrow; // Let Lottie's error builder handle this after all retries are exhausted
    }
  }

  /// Selects the appropriate Lottie JSON file from the archive.
  ///
  /// Searches for JSON files in the 'animations/' directory.
  ArchiveFile _selectLottieFileFromArchive(List<ArchiveFile> files) {
    try {
      // Cache file list for diagnostics
      final List<String> fileNames = files.map((ArchiveFile f) => f.name).toList();
      _logger.fine('Archive contains ${files.length} files: ${fileNames.join(", ")}');

      return files.firstWhere(
        (ArchiveFile f) => f.name.startsWith('animations/') && f.name.endsWith('.json'),
        orElse: () {
          final String availableFiles = fileNames.join(', ');
          throw Exception('No Lottie animation file found in the archive. Available files: $availableFiles');
        },
      );
    } catch (e, stackTrace) {
      _logger.severe(
        'Failed to select Lottie file from archive',
        e,
        stackTrace,
      );
      rethrow;
    }
  }
}
