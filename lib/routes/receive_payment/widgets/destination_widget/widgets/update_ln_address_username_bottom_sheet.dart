import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:email_validator/email_validator.dart';
import 'package:flutter/material.dart';
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
  KeyboardDoneAction _doneAction = KeyboardDoneAction();

  @override
  void initState() {
    super.initState();
    _usernameController.text = widget.lnAddress.split('@').first;
    _usernameController.addListener(() => setState(() {}));
    _doneAction = KeyboardDoneAction(focusNodes: <FocusNode>[_usernameFocusNode]);
  }

  @override
  void dispose() {
    super.dispose();
    _doneAction.dispose();
    FocusManager.instance.primaryFocus?.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: BlocBuilder<WebhookCubit, WebhookState>(
          builder: (BuildContext context, WebhookState state) {
            final ThemeData themeData = Theme.of(context);
            final Color errorBorderColor = themeData.colorScheme.error;

            return Column(
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
                    // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
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
                    child: TextFormField(
                      controller: _usernameController,
                      focusNode: _usernameFocusNode,
                      decoration: InputDecoration(
                        // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
                        labelText: 'Username',
                        errorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: errorBorderColor),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: errorBorderColor),
                        ),
                        errorMaxLines: 2,
                        errorStyle: themeData.primaryTextTheme.bodySmall!.copyWith(
                          color: errorBorderColor,
                        ),
                        suffix: const Padding(
                          padding: EdgeInsets.only(right: 8.0),
                          // TODO(erdemyerebasmaz): Retrieve this from lnAddress itself & store it temporarily
                          child: Text(
                            '@breez.fun',
                          ),
                        ),
                        border: const OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      autofocus: true,
                      validator: (String? value) {
                        if (value == null || value.isEmpty) {
                          // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
                          return 'Please enter a username';
                        }
                        final String email = '${value.trim()}@${widget.lnAddress.split('@').last}';
                        // TODO(erdemyerebasmaz): Add these messages to Breez-Translations
                        return EmailValidator.validate(email) ? null : 'Invalid username.';
                      },
                      onEditingComplete: () => _usernameFocusNode.unfocus(),
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
                    child: SingleButtonBottomBar(
                      text: texts.currency_converter_dialog_action_done,
                      expand: true,
                      onPressed: () async {
                        if (_usernameController.text.isEmpty) {
                          Navigator.pop(context);
                          return;
                        }

                        // TODO(erdemyerebasmaz): Implement validation & registration logic
                        // TODO(erdemyerebasmaz): Handle registration errors
                        if (_formKey.currentState?.validate() ?? false) {
                          final WebhookCubit webhookCubit = context.read<WebhookCubit>();
                          await webhookCubit.updateLnAddressUsername(username: _usernameController.text);
                          if (context.mounted) {
                            if (state.lnurlPayError == null) {
                              Navigator.pop(context);
                              showFlushbar(
                                context,
                                message: 'Successfully updated Lightning Address username.',
                              );
                            } else {
                              Navigator.pop(context);
                              showFlushbar(
                                context,
                                message: 'Failed to update Lightning Address username.',
                              );
                            }
                          }
                        }
                      },
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
