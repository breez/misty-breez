import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/widgets/widgets.dart';

class UpdateLnAddressUsernameBottomSheet extends StatefulWidget {
  final String lnAddress;

  const UpdateLnAddressUsernameBottomSheet({
    required this.lnAddress,
    super.key,
  });

  @override
  State<UpdateLnAddressUsernameBottomSheet> createState() => _UpdateLnAddressUsernameBottomSheetState();
}

class _UpdateLnAddressUsernameBottomSheetState extends State<UpdateLnAddressUsernameBottomSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  late final KeyboardDoneAction _doneAction;

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.lnAddress.split('@').first;
    _usernameController.addListener(() => setState(() {}));
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_usernameFocusNode]);

    // Clear any previous error messages when opening the bottom sheet
    final LnAddressCubit lnAddressCubit = context.read<LnAddressCubit>();
    lnAddressCubit.clearUpdateStatus();
  }

  @override
  void dispose() {
    _doneAction.dispose();
    FocusManager.instance.primaryFocus?.unfocus();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    final ThemeData themeData = Theme.of(context);

    return BlocListener<LnAddressCubit, LnAddressState>(
      listenWhen: (LnAddressState previous, LnAddressState current) =>
          current.updateStatus.status != previous.updateStatus.status,
      listener: (BuildContext context, LnAddressState state) {
        if (state.updateStatus.status == UpdateStatus.success) {
          Navigator.pop(context);
          showFlushbar(
            context,
            message: 'Successfully updated Lightning Address username.',
          );
        } else if (state.updateStatus.status == UpdateStatus.error) {
          if (state.updateStatus.error is! UsernameConflictException) {
            showFlushbar(
              context,
              message: 'Failed to update Lightning Address username.',
            );
          }
          _formKey.currentState?.validate();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Align(
                child: Container(
                  margin: const EdgeInsets.only(top: 8.0),
                  width: 40.0,
                  height: 6.5,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(50),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  'Customize Address:',
                  style: themeData.primaryTextTheme.headlineMedium!.copyWith(
                    fontSize: 18.0,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.left,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: BlocBuilder<LnAddressCubit, LnAddressState>(
                    buildWhen: (LnAddressState previous, LnAddressState current) =>
                        current.updateStatus != previous.updateStatus,
                    builder: (BuildContext context, LnAddressState state) {
                      final bool isConflict = state.updateStatus.error is UsernameConflictException;
                      return TextFormField(
                        controller: _usernameController,
                        focusNode: _usernameFocusNode,
                        decoration: InputDecoration(
                          labelText: 'Username',
                          errorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          focusedErrorBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: themeData.colorScheme.error),
                          ),
                          errorMaxLines: 2,
                          errorStyle: themeData.primaryTextTheme.bodySmall!.copyWith(
                            color: themeData.colorScheme.error,
                            height: 1.0,
                          ),
                          suffix: const Padding(
                            padding: EdgeInsets.only(right: 8.0),
                            child: Text('@breez.fun'),
                          ),
                          border: const OutlineInputBorder(),
                          errorText: isConflict ? 'Username is already taken' : null,
                        ),
                        keyboardType: TextInputType.emailAddress,
                        autofocus: true,
                        validator: _validateUsername,
                        inputFormatters: <TextInputFormatter>[
                          UsernameInputFormatter(),
                          // 64 is the maximum allowed length for a username
                          // but a %12.5 margin of error is added for good measure,
                          // which is likely to get sanitized by the UsernameFormatter
                          LengthLimitingTextInputFormatter(72),
                        ],
                        onEditingComplete: () => _usernameFocusNode.unfocus(),
                      );
                    },
                  ),
                ),
              ),
              const SizedBox(height: 8.0),
              Align(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 16.0,
                  ),
                  child: BlocBuilder<LnAddressCubit, LnAddressState>(
                    buildWhen: (LnAddressState previous, LnAddressState current) =>
                        current.updateStatus.status != previous.updateStatus.status,
                    builder: (BuildContext context, LnAddressState state) {
                      return SingleButtonBottomBar(
                        text: texts.currency_converter_dialog_action_done,
                        loading: state.updateStatus.status == UpdateStatus.loading,
                        expand: true,
                        onPressed: _handleSubmit,
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _validateUsername(String? value) {
    final String sanitized = UsernameFormatter.sanitize(value ?? '');
    if (sanitized.isEmpty) {
      return 'Please enter a username';
    }

    if (sanitized.length > 64) {
      return 'Username must not be longer than 64 characters.';
    }

    final LnAddressState state = context.read<LnAddressCubit>().state;
    if (state.updateStatus.error is UsernameConflictException) {
      return 'Username is already taken';
    }

    final String email = '$sanitized@${widget.lnAddress.split('@').last}';
    return EmailValidator.validate(email) ? null : 'Invalid username.';
  }

  void _handleSubmit() {
    if (_usernameController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      final LnAddressCubit lnAddressCubit = context.read<LnAddressCubit>();
      final String username = UsernameFormatter.sanitize(_usernameController.text);
      lnAddressCubit.setupLightningAddress(baseUsername: username);
    }
  }
}
