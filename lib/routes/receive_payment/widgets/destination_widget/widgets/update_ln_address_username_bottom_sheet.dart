import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/widgets/widgets.dart';

/// Bottom sheet to update a Lightning Address username.
class UpdateLnAddressUsernameBottomSheet extends StatefulWidget {
  /// The current Lightning Address
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
  late final String _domain;

  @override
  void initState() {
    super.initState();
    final LnAddressState lnAddressState = context.read<LnAddressCubit>().state;

    // First try to get username from state, fall back to username from widget.lnAddress
    final String username =
        lnAddressState.username ?? (widget.lnAddress.contains('@') ? widget.lnAddress.split('@').first : '');

    // First try to get domain from state, fall back to domain from widget.lnAddress & lastly hardcoded value
    _domain = lnAddressState.domain ??
        (widget.lnAddress.contains('@') ? widget.lnAddress.split('@').last : 'breez.fun');

    _usernameController.text = username;
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

    return BlocListener<LnAddressCubit, LnAddressState>(
      listenWhen: (LnAddressState previous, LnAddressState current) =>
          current.updateStatus.status != previous.updateStatus.status,
      listener: _onUpdateStatusChanged,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const BottomSheetHandle(),
              const BottomSheetTitle(title: 'Customize Address:'),
              UsernameFormField(
                formKey: _formKey,
                controller: _usernameController,
                focusNode: _usernameFocusNode,
                domain: _domain,
                validator: _validateUsername,
              ),
              const SizedBox(height: 8.0),
              SubmitButtonSection(
                doneText: texts.currency_converter_dialog_action_done,
                onPressed: _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Handle changes to the update status from the LnAddressCubit.
  void _onUpdateStatusChanged(BuildContext context, LnAddressState state) {
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
  }

  /// Validates the username input.
  String? _validateUsername(String? value) {
    final String sanitized = UsernameFormatter.sanitize(value ?? '');
    if (sanitized.isEmpty) {
      return 'Please enter a username';
    }

    if (sanitized.length > 64) {
      return 'Username cannot exceed 64 characters.';
    }

    final LnAddressState state = context.read<LnAddressCubit>().state;
    if (state.updateStatus.error is UsernameConflictException) {
      return 'Username is already taken';
    }

    final String email = '$sanitized@$_domain';
    return EmailValidator.validate(email) ? null : 'Invalid username.';
  }

  /// Handles the form submission.
  void _handleSubmit() async {
    if (_usernameController.text.isEmpty) {
      Navigator.pop(context);
      return;
    }

    final LnAddressCubit lnAddressCubit = context.read<LnAddressCubit>();
    lnAddressCubit.clearUpdateStatus();

    if (_formKey.currentState?.validate() ?? false) {
      final String newUsername = UsernameFormatter.sanitize(_usernameController.text);
      final LnAddressState state = lnAddressCubit.state;

      final String currentUsername =
          state.username ?? (widget.lnAddress.contains('@') ? widget.lnAddress.split('@').first : '');

      // Only show confirmation if username is actually changing
      if (currentUsername != newUsername) {
        final bool? confirmed = await promptAreYouSure(
          context,
          title: 'Confirm Username Change',
          body: Text(
            "Changing your Lightning Address username will permanently release '$currentUsername@$_domain'"
            ', making it available for other users.\n\n'
            'Do you want to proceed?',
            style: const TextStyle(color: Colors.white),
          ),
        );

        if (confirmed != true) {
          return;
        }
        lnAddressCubit.setupLightningAddress(baseUsername: newUsername);
      } else {
        Navigator.pop(context);
        return;
      }
    }
  }
}

/// Handle at the top of the bottom sheet
class BottomSheetHandle extends StatelessWidget {
  const BottomSheetHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Align(
      child: Container(
        margin: const EdgeInsets.only(top: 8.0),
        width: 40.0,
        height: 6.5,
        decoration: BoxDecoration(
          color: Colors.white24,
          borderRadius: BorderRadius.circular(50),
        ),
      ),
    );
  }
}

/// Title display for the bottom sheet
class BottomSheetTitle extends StatelessWidget {
  final String title;

  const BottomSheetTitle({
    required this.title,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Text(
        title,
        style: themeData.primaryTextTheme.headlineMedium!.copyWith(
          fontSize: 18.0,
          color: Colors.white,
        ),
        textAlign: TextAlign.left,
      ),
    );
  }
}

/// Username input form field
class UsernameFormField extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController controller;
  final FocusNode focusNode;
  final String domain;
  final FormFieldValidator<String> validator;

  const UsernameFormField({
    required this.formKey,
    required this.controller,
    required this.focusNode,
    required this.domain,
    required this.validator,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Form(
        key: formKey,
        child: BlocBuilder<LnAddressCubit, LnAddressState>(
          buildWhen: (LnAddressState previous, LnAddressState current) =>
              current.updateStatus != previous.updateStatus,
          builder: (BuildContext context, LnAddressState state) {
            final bool isConflict = state.updateStatus.error is UsernameConflictException;
            return TextFormField(
              controller: controller,
              focusNode: focusNode,
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
                suffix: Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: Text('@$domain'),
                ),
                border: const OutlineInputBorder(),
                errorText: isConflict ? 'Username is already taken' : null,
              ),
              keyboardType: TextInputType.emailAddress,
              autofocus: true,
              validator: validator,
              inputFormatters: <TextInputFormatter>[
                UsernameInputFormatter(),
                LengthLimitingTextInputFormatter(64),
              ],
              onEditingComplete: () => focusNode.unfocus(),
            );
          },
        ),
      ),
    );
  }
}

/// Submit button section
class SubmitButtonSection extends StatelessWidget {
  final String doneText;
  final VoidCallback onPressed;

  const SubmitButtonSection({
    required this.doneText,
    required this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
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
              text: doneText,
              loading: state.updateStatus.status == UpdateStatus.loading,
              expand: true,
              onPressed: onPressed,
            );
          },
        ),
      ),
    );
  }
}
