import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/routes.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';

class MnemonicsConfirmationPage extends StatefulWidget {
  final String mnemonics;

  static const String routeName = '/mnemonics';

  const MnemonicsConfirmationPage({required this.mnemonics, super.key});

  @override
  MnemonicsConfirmationPageState createState() => MnemonicsConfirmationPageState();
}

class MnemonicsConfirmationPageState extends State<MnemonicsConfirmationPage> {
  bool _isUnderstood = false;

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const back_button.BackButton(),
        title: AutoSizeText(
          texts.mnemonics_confirmation_title,
          maxLines: 1,
        ),
      ),
      body: Column(
        children: <Widget>[
          const MnemonicsImage(),
          const MnemonicsInstructions(),
          ConfirmationCheckbox(
            isUnderstood: _isUnderstood,
            onPressed: (bool value) {
              setState(() {
                _isUnderstood = value;
              });
            },
          ),
        ],
      ),
      bottomNavigationBar: ConfirmButton(isUnderstood: _isUnderstood, mnemonics: widget.mnemonics),
    );
  }
}

class MnemonicsImage extends StatelessWidget {
  const MnemonicsImage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Expanded(
      flex: 2,
      child: Image(
        image: AssetImage('assets/images/generate_backup_phrase.png'),
        height: 100,
        width: 100,
      ),
    );
  }
}

class MnemonicsInstructions extends StatelessWidget {
  const MnemonicsInstructions({super.key});

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return Padding(
      padding: const EdgeInsets.only(
        left: 48,
        right: 48,
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minHeight: 96,
        ),
        child: Text(
          texts.mnemonics_confirmation_instructions,
          style: mnemonicSeedInformationTextStyle,
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class ConfirmationCheckbox extends StatelessWidget {
  final bool isUnderstood;
  final Function(bool value) onPressed;

  const ConfirmationCheckbox({
    required this.onPressed,
    required this.isUnderstood,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final BreezTranslations texts = context.texts();
    return Expanded(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Theme(
            data: themeData.copyWith(
              unselectedWidgetColor: Colors.white,
            ),
            child: Checkbox(
              activeColor: Colors.white,
              checkColor: themeData.canvasColor,
              value: isUnderstood,
              onChanged: (bool? value) => onPressed(value!),
            ),
          ),
          Text(
            texts.backup_phrase_action_confirm,
            style: mnemonicSeedConfirmationTextStyle,
          ),
        ],
      ),
    );
  }
}

class ConfirmButton extends StatelessWidget {
  final bool isUnderstood;
  final String mnemonics;

  const ConfirmButton({
    required this.isUnderstood,
    required this.mnemonics,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: SizedBox(
        height: 88,
        child: isUnderstood
            ? SingleButtonBottomBar(
                text: texts.backup_phrase_action_next,
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    FadeInRoute<void>(
                      builder: (BuildContext context) => MnemonicsPage(mnemonics: mnemonics),
                    ),
                  );
                },
              )
            : Container(),
      ),
    );
  }
}
