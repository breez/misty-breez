import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_breez_liquid/flutter_breez_liquid.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/widgets.dart';

class NwcEditConnectionView extends StatefulWidget {
  final NwcConnectionModel existingConnection;

  const NwcEditConnectionView({required this.existingConnection, super.key});

  @override
  State<NwcEditConnectionView> createState() => NwcEditConnectionViewState();
}

class NwcEditConnectionViewState extends State<NwcEditConnectionView> {
  final TextEditingController _nameController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  int? _maxBudgetSat;
  int? _renewalTimeMins;
  int? _expiryTimeMins;

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

  Future<void> editConnection() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final int? expiryTimeMins = _expiryTimeMins;
    final bool? removeExpiry;
    if (_expiryTimeMins == null) {
      // If expiry is null, remove it if it previously existed
      removeExpiry = widget.existingConnection.expiresAt != null ? true : null;
    } else {
      removeExpiry = null;
    }

    PeriodicBudgetRequest? periodicBudgetReq;
    bool? removePeriodicBudget;
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
    return Container(
      decoration: ShapeDecoration(
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
        color: Theme.of(context).customData.surfaceBgColor,
      ),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
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
            ) {
              setState(() {
                _maxBudgetSat = maxBudgetSat;
                _renewalTimeMins = renewalTimeMins;
                _expiryTimeMins = expiryTimeMins;
              });
            },
      ),
    );
  }
}
