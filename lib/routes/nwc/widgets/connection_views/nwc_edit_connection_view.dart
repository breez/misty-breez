import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/widgets/widgets.dart';

class NwcEditConnectionView extends StatefulWidget {
  final NwcConnectionModel existingConnection;

  const NwcEditConnectionView({required this.existingConnection, super.key});

  @override
  State<NwcEditConnectionView> createState() => _NwcEditConnectionViewState();
}

class _NwcEditConnectionViewState extends State<NwcEditConnectionView> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _maxBudgetSat;
  int? _renewalTimeMins;
  int? _expiryTimeMins;
  bool _showBudgetFields = false;
  bool _showExpiryFields = false;

  @override
  void initState() {
    super.initState();
    _nameController.text = widget.existingConnection.name;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _editConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? expiryTimeMins;
    final bool? removeExpiry;
    if (!_showExpiryFields) {
      removeExpiry = widget.existingConnection.expiresAt != null ? true : null;
      expiryTimeMins = null;
    } else if (_expiryTimeMins == null) {
      // This case handles "Never" if the form returns null for expiry time when fields are shown but option is never
      // However, NwcConnectionForm returns null for expiryTimeMins if option is Never.
      // We need to check if we should remove expiry.
      // If _showExpiryFields is true, but _expiryTimeMins is null, it means "Never" was selected (or custom not impl).
      // If "Never" is selected, we want to remove expiry.
      removeExpiry = widget.existingConnection.expiresAt != null ? true : null;
      expiryTimeMins = null;
    } else {
      expiryTimeMins = _expiryTimeMins;
      removeExpiry = null;
    }

    PeriodicBudgetRequest? periodicBudgetReq;
    bool? removePeriodicBudget;
    if (_showBudgetFields) {
      final int? maxBudgetSatInt = _maxBudgetSat;
      final int? renewalTimeMins = _renewalTimeMins;

      if (maxBudgetSatInt != null) {
        if (renewalTimeMins != null && renewalTimeMins > 0) {
          periodicBudgetReq = PeriodicBudgetRequest(
            maxBudgetSat: BigInt.from(maxBudgetSatInt),
            renewalTimeMins: renewalTimeMins,
          );
        } else {
          periodicBudgetReq = PeriodicBudgetRequest(maxBudgetSat: BigInt.from(maxBudgetSatInt));
        }
      } else {
        if (widget.existingConnection.periodicBudget != null) {
          removePeriodicBudget = true;
        }
      }
    } else if (widget.existingConnection.periodicBudget != null) {
      removePeriodicBudget = true;
    }

    final bool success = await context.read<NwcCubit>().editConnection(
      name: widget.existingConnection.name,
      expiryTimeMins: expiryTimeMins,
      removeExpiry: removeExpiry,
      periodicBudgetReq: periodicBudgetReq,
      removePeriodicBudget: removePeriodicBudget,
    );

    if (success && mounted) {
      Navigator.of(context).pop();
      if (mounted) {
        showFlushbar(
          context,
          message: 'Connection updated successfully',
          duration: const Duration(seconds: 3),
        );
      }
    } else if (mounted) {
      showFlushbar(context, message: 'Failed to update connection', duration: const Duration(seconds: 3));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const BottomSheetHandle(),
        const BottomSheetTitle(title: 'Edit Connection'),
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: NwcConnectionForm(
            formKey: _formKey,
            nameController: _nameController,
            isEditMode: true,
            existingConnection: widget.existingConnection,
            onValuesChanged:
                (
                  int? maxBudgetSat,
                  int? renewalTimeMins,
                  int? expiryTimeMins,
                  bool showBudgetFields,
                  bool showExpiryFields,
                ) {
                  setState(() {
                    _maxBudgetSat = maxBudgetSat;
                    _renewalTimeMins = renewalTimeMins;
                    _expiryTimeMins = expiryTimeMins;
                    _showBudgetFields = showBudgetFields;
                    _showExpiryFields = showExpiryFields;
                  });
                },
          ),
        ),
        const SizedBox(height: 8.0),
        BlocBuilder<NwcCubit, NwcState>(
          builder: (BuildContext context, NwcState state) {
            return Align(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                child: SingleButtonBottomBar(
                  text: 'SAVE',
                  loading: state.isLoading,
                  expand: true,
                  onPressed: _editConnection,
                ),
              ),
            );
          },
        ),
      ],
    );
  }
}
