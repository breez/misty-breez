import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/mnemonics_page.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/route.dart';
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

class MnemonicsConfirmationPage extends StatefulWidget {
  final String mnemonics;

  static const routeName = "/mnemonics";

  const MnemonicsConfirmationPage({super.key, required this.mnemonics});

  @override
  MnemonicsConfirmationPageState createState() => MnemonicsConfirmationPageState();
}

class MnemonicsConfirmationPageState extends State<MnemonicsConfirmationPage> {
  bool _isUnderstood = false;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
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
        children: [
          const MnemonicsImage(),
          const MnemonicsInstructions(),
          ConfirmationCheckbox(
            isUnderstood: _isUnderstood,
            onPressed: (value) {
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
        image: AssetImage("src/images/generate_backup_phrase.png"),
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
    final texts = context.texts();
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
    super.key,
    required this.onPressed,
    required this.isUnderstood,
  });

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final texts = context.texts();
    return Expanded(
      flex: 1,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Theme(
            data: themeData.copyWith(
              unselectedWidgetColor: Colors.white,
            ),
            child: Checkbox(
                activeColor: Colors.white,
                checkColor: themeData.canvasColor,
                value: isUnderstood,
                onChanged: (value) => onPressed(value!)),
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
    super.key,
    required this.isUnderstood,
    required this.mnemonics,
  });

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();
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
                    FadeInRoute(
                      builder: (context) => MnemonicsPage(mnemonics: mnemonics),
                    ),
                  );
                },
              )
            : Container(),
      ),
    );
  }
}
