import 'package:breez_preferences/breez_preferences.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/dev/dev.dart';
import 'package:l_breez/services/services.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/utils/utils.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';
import 'package:logging/logging.dart';
import 'package:service_injector/service_injector.dart';
import 'package:share_plus/share_plus.dart';

export 'widgets/widgets.dart';

final Logger _logger = Logger('DevelopersView');

/// A view that provides developer tools and debugging options
class DevelopersView extends StatefulWidget {
  static const String routeName = '/developers';

  const DevelopersView({super.key});

  @override
  State<DevelopersView> createState() => _DevelopersViewState();
}

class _DevelopersViewState extends State<DevelopersView> {
  final BreezPreferences _preferences = const BreezPreferences();
  final OverlayManager _overlayManager = OverlayManager();

  BugReportBehavior _bugReportBehavior = BugReportBehavior.prompt;
  String _sdkVersion = '';

  @override
  void initState() {
    super.initState();
    _initializeViewData();
  }

  @override
  void dispose() {
    _overlayManager.removeLoadingOverlay();
    super.dispose();
  }

  /// Initializes all data required by the view
  Future<void> _initializeViewData() async {
    await Future.wait(<Future<void>>[
      _loadSdkVersion(),
      _loadPreferences(),
    ]);
  }

  /// Loads the SDK version
  Future<void> _loadSdkVersion() async {
    try {
      final String version = await SdkVersionService.getSdkVersion();
      if (mounted) {
        setState(() => _sdkVersion = version);
      }
    } catch (e) {
      _logger.warning('Failed to load SDK version: $e');
      if (mounted) {
        setState(() => _sdkVersion = 'Error loading version');
      }
    }
  }

  /// Loads user preferences related to bug reporting
  Future<void> _loadPreferences() async {
    try {
      final BugReportBehavior behavior = await _preferences.bugReportBehavior;
      if (mounted) {
        setState(() => _bugReportBehavior = behavior);
      }
    } catch (e) {
      _logger.warning('Failed to load preferences: $e');
    }
  }

  /// Syncs the wallet with the network
  Future<void> _syncWallet() async {
    _overlayManager.showLoadingOverlay(context);

    try {
      await ServiceInjector().breezSdkLiquid.instance!.sync();

      if (mounted) {
        _showSuccessMessage('Wallet synced successfully.');
      }
    } catch (e) {
      _logger.warning('Failed to sync wallet: $e');

      if (mounted) {
        _showErrorMessage('Failed to sync wallet.');
      }
    } finally {
      _overlayManager.removeLoadingOverlay();
    }
  }

  /// Exports wallet keys and credentials to a zip file
  Future<void> _exportKeys() async {
    _overlayManager.showLoadingOverlay(context);

    try {
      final AccountState accountState = context.read<AccountCubit>().state;
      final WalletInfo? walletInfo = accountState.walletInfo;

      if (walletInfo == null) {
        throw Exception('Wallet info unavailable');
      }

      final String keysZipPath = await WalletArchiveService.createKeysArchive(
        fingerprint: walletInfo.fingerprint,
      );

      Share.shareXFiles(<XFile>[XFile(keysZipPath)]);
    } catch (e) {
      _logger.severe('Failed to export keys: $e');

      if (mounted) {
        _showErrorMessage('Failed to export keys: ${e.toString()}');
      }
    } finally {
      _overlayManager.removeLoadingOverlay();
    }
  }

  /// Share application logs
  Future<void> _shareLogs() async {
    _overlayManager.showLoadingOverlay(context);

    try {
      final String zipPath = await WalletArchiveService.createLogsArchive();
      Share.shareXFiles(<XFile>[XFile(zipPath)]);
    } catch (e) {
      _logger.severe('Failed to share logs: $e');

      if (mounted) {
        _showErrorMessage('Failed to share logs: ${e.toString()}');
      }
    } finally {
      _overlayManager.removeLoadingOverlay();
    }
  }

  /// Rescans on-chain swaps for the user
  Future<void> _rescanOnchainSwaps() async {
    _overlayManager.showLoadingOverlay(context);
    final BreezTranslations texts = getSystemAppLocalizations();
    final ChainSwapCubit chainSwapCubit = context.read<ChainSwapCubit>();

    try {
      await chainSwapCubit.rescanOnchainSwaps();

      if (mounted) {
        _showSuccessMessage('Rescanned on-chain swaps successfully.');
      }
    } catch (e) {
      _logger.warning('Failed to rescan on-chain swaps: $e');

      if (mounted) {
        _showErrorMessage(ExceptionHandler.extractMessage(e, texts));
      }
    } finally {
      _overlayManager.removeLoadingOverlay();
    }
  }

  /// Updates the refund state to enable rebroadcasting refunds
  Future<void> _enableRefundRebroadcast() async {
    _overlayManager.showLoadingOverlay(context);

    try {
      context.read<RefundCubit>().enableRebroadcast();

      if (mounted) {
        _showSuccessMessage('Refunds can now be rebroadcasted.');
      }
    } catch (e) {
      _logger.warning('Failed to enable rebroadcasting refunds: $e');

      if (mounted) {
        _showErrorMessage('Failed to update refund state.');
      }
    } finally {
      _overlayManager.removeLoadingOverlay();
    }
  }

  /// Toggles the bug report behavior setting to prompt
  Future<void> _toggleBugReportBehavior() async {
    _overlayManager.showLoadingOverlay(context);
    try {
      await _preferences.setBugReportBehavior(BugReportBehavior.prompt);

      if (mounted) {
        setState(() => _bugReportBehavior = BugReportBehavior.prompt);
        _showSuccessMessage('Successfully updated bug report setting.');
      }
    } catch (e) {
      _logger.warning('Failed to update bug report setting: $e');

      if (mounted) {
        _showErrorMessage('Failed to update bug report settings');
      }
    } finally {
      _overlayManager.removeLoadingOverlay();
    }
  }

  /// Shows a success message to the user
  void _showSuccessMessage(String message) {
    showFlushbar(context, message: message);
  }

  /// Shows an error message to the user
  void _showErrorMessage(String message) {
    showFlushbar(context, message: message);
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const back_button.BackButton(),
        title: Text(texts.home_drawer_item_title_developers),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: <Widget>[
            _buildInfoCard(),
          ],
        ),
      ),
    );
  }

  /// Builds the information card showing wallet and SDK details
  Widget _buildInfoCard() {
    final ThemeData themeData = Theme.of(context);
    final WalletInfo? walletInfo = context.select<AccountCubit, WalletInfo?>(
      (AccountCubit cubit) => cubit.state.walletInfo,
    );
    return Card(
      color: themeData.customData.surfaceBgColor,
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            StatusItem(label: 'SDK Version', value: _sdkVersion),
            if (walletInfo != null) ...<Widget>[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ShareablePaymentRow(
                  tilePadding: EdgeInsets.zero,
                  dividerColor: Colors.transparent,
                  title: 'Public Key',
                  titleTextStyle: themeData.primaryTextTheme.headlineMedium?.copyWith(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                  sharedValue: walletInfo.pubkey,
                  shouldPop: false,
                ),
              ),
              StatusItem(label: 'Fingerprint', value: walletInfo.fingerprint),
              if (walletInfo.balanceSat > BigInt.zero) ...<Widget>[
                StatusItem(label: 'Balance', value: '${walletInfo.balanceSat}'),
              ],
              if (walletInfo.pendingReceiveSat > BigInt.zero) ...<Widget>[
                StatusItem(label: 'Pending Receive Amount', value: '${walletInfo.pendingReceiveSat}'),
              ],
              if (walletInfo.pendingSendSat > BigInt.zero) ...<Widget>[
                StatusItem(label: 'Pending Send Amount', value: '${walletInfo.pendingSendSat}'),
              ],
              StatusItem(
                label: 'Asset Balances',
                value: '${walletInfo.assetBalances.map(
                      (AssetBalance assetBalance) => assetBalance.name,
                    ).toList()}',
              ),
              _buildActionButtons(),
            ],
          ].expand((Widget widget) sync* {
            yield widget;
            yield const Divider(
              height: 8.0,
              color: Color.fromRGBO(40, 59, 74, 0.5),
              indent: 0.0,
              endIndent: 0.0,
            );
          }).toList()
            ..removeLast(),
        ),
      ),
    );
  }

  /// Builds the grid of action buttons
  Widget _buildActionButtons() {
    final BreezTranslations texts = context.texts();

    final bool hasRefundables = context.select<RefundCubit, bool>(
      (RefundCubit cubit) => cubit.state.hasRefundables,
    );

    return Padding(
      padding: const EdgeInsets.only(top: 32),
      child: GridView.count(
        crossAxisCount: 2,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        mainAxisSpacing: 16.0,
        crossAxisSpacing: 32.0,
        childAspectRatio: 3,
        children: <Widget>[
          GridActionButton(
            icon: Icons.refresh,
            // TODO(erdemyerebasmaz): Add messages to Breez-Translations
            label: 'Sync',
            tooltip: 'Sync Wallet',
            onPressed: _syncWallet,
          ),
          GridActionButton(
            icon: Icons.key,
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            label: 'Keys',
            tooltip: texts.developers_page_menu_export_keys_title,
            onPressed: _exportKeys,
          ),
          GridActionButton(
            icon: Icons.share,
            // TODO(erdemyerebasmaz): Add message to Breez-Translations
            label: 'Logs',
            tooltip: texts.developers_page_menu_share_logs_title,
            onPressed: _shareLogs,
          ),
          GridActionButton(
            icon: Icons.radar,
            // TODO(erdemyerebasmaz): Add messages to Breez-Translations
            label: 'Rescan',
            tooltip: 'Rescan Swaps',
            onPressed: _rescanOnchainSwaps,
          ),
          if (hasRefundables) ...<Widget>[
            GridActionButton(
              icon: Icons.sync_alt,
              // TODO(erdemyerebasmaz): Add messages to Breez-Translations
              label: 'Rebroadcast',
              tooltip: 'Enable Refund Rebroadcast',
              onPressed: _enableRefundRebroadcast,
            ),
          ],
          if (_bugReportBehavior != BugReportBehavior.prompt)
            GridActionButton(
              icon: Icons.bug_report,
              // TODO(erdemyerebasmaz): Add message to Breez-Translations
              label: 'Bug Report',
              tooltip: texts.developers_page_menu_prompt_bug_report_title,
              onPressed: _toggleBugReportBehavior,
            ),
        ],
      ),
    );
  }
}
