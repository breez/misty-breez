import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';
import 'package:misty_breez/utils/date/breez_date_utils.dart';

class NwcConnectionDetailPage extends StatefulWidget {
  static const String routeName = '/nwc/connection/detail';

  final NwcConnectionModel connection;

  const NwcConnectionDetailPage({required this.connection, super.key});

  @override
  State<NwcConnectionDetailPage> createState() => _NwcConnectionDetailPageState();
}

class _NwcConnectionDetailPageState extends State<NwcConnectionDetailPage> {
  late NwcConnectionModel _connection;

  @override
  void initState() {
    super.initState();
    _connection = widget.connection;
  }

  void _editConnection() {
    final NwcCubit nwcCubit = context.read<NwcCubit>();
    showNwcConnectBottomSheet(context, nwcCubit: nwcCubit, existingConnection: _connection);
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocListener<NwcCubit, NwcState>(
      listenWhen: (NwcState previous, NwcState current) {
        return previous.isLoading && !current.isLoading && current.connections.isNotEmpty;
      },
      listener: (BuildContext context, NwcState state) {
        final NwcConnectionModel updatedConnection = state.connections.firstWhere(
          (NwcConnectionModel c) => c.name == _connection.name,
          orElse: () => _connection,
        );
        setState(() {
          _connection = updatedConnection;
        });
      },
      child: Scaffold(
        appBar: AppBar(leading: const back_button.BackButton(), title: Text(_connection.name)),
        body: SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeData.customData.surfaceBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: StatusItem(label: 'Connection Name', value: _connection.name),
                  ),
                  const SizedBox(height: 16),
                  if (_connection.periodicBudget != null || _connection.expiryTimeSec != null) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: themeData.customData.surfaceBgColor,
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Connection Parameters',
                            style: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                          ),
                          const SizedBox(height: 8),
                          if (_connection.periodicBudget != null) ...<Widget>[
                            StatusItem(
                              label: 'Max Budget',
                              value: '${_connection.periodicBudget!.maxBudgetSat} sats',
                            ),
                            StatusItem(
                              label: 'Reset Time',
                              value: '${_connection.periodicBudget!.resetTimeSec} seconds',
                            ),
                          ],
                          if (_connection.expiryTimeSec != null)
                            StatusItem(
                              label: 'Expiry Time',
                              value: BreezDateUtils.formatYearMonthDayHourMinuteSecond(
                                DateTime.now().add(Duration(seconds: _connection.expiryTimeSec!)),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: themeData.customData.surfaceBgColor,
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        ShareablePaymentRow(
                          title: 'Connection URI',
                          sharedValue: _connection.connectionString,
                          tilePadding: EdgeInsets.zero,
                          dividerColor: Colors.transparent,
                          shouldPop: false,
                          titleTextStyle: themeData.textTheme.labelMedium?.copyWith(color: Colors.white70),
                          childrenTextStyle: themeData.primaryTextTheme.displaySmall!.copyWith(
                            fontSize: 18.0,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                            height: 1.156,
                          ),
                        ),
                        const SizedBox(height: 16),
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            side: const BorderSide(color: Colors.white),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
                          ),
                          icon: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Icon(Icons.qr_code, size: 20.0),
                          ),
                          label: const Text('SHOW QR'),
                          onPressed: () => _showQRDialog(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        bottomNavigationBar: BlocBuilder<NwcCubit, NwcState>(
          builder: (BuildContext context, NwcState state) {
            return SingleButtonBottomBar(
              text: 'EDIT CONNECTION',
              expand: false,
              loading: state.isLoading,
              onPressed: _editConnection,
            );
          },
        ),
      ),
    );
  }

  void _showQRDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        final Size screenSize = MediaQuery.of(context).size;
        final double qrSize = screenSize.width * 0.8;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: EdgeInsets.zero,
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: screenSize.width,
              height: screenSize.height,
              color: Colors.black.withValues(alpha: 0.7),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).customData.surfaceBgColor,
                    borderRadius: BorderRadius.circular(12.0),
                  ),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: CompactQRImage(data: _connection.connectionString, size: qrSize),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
