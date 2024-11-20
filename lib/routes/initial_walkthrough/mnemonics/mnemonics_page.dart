import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/verify_mnemonics_page.dart';
import 'package:l_breez/routes/initial_walkthrough/mnemonics/widgets/mnemonic_seed_list.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/widgets.dart';

class MnemonicsPage extends StatefulWidget {
  final String mnemonics;
  final bool viewMode;

  const MnemonicsPage({required this.mnemonics, super.key, this.viewMode = false});

  @override
  MnemonicsPageState createState() => MnemonicsPageState();
}

class MnemonicsPageState extends State<MnemonicsPage> {
  late List<String> _mnemonicsList;

  @override
  void initState() {
    _mnemonicsList = widget.mnemonics.split(' ');
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();
    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: AutoSizeText(
          (widget.viewMode) ? texts.mnemonics_confirmation_title : texts.backup_phrase_generation_write_words,
        ),
      ),
      body: MnemonicSeedList(mnemonicsList: _mnemonicsList),
      bottomNavigationBar: SingleButtonBottomBar(
        text:
            (widget.viewMode) ? texts.admin_login_dialog_action_ok : texts.backup_phrase_warning_action_next,
        onPressed: () {
          if (widget.viewMode) {
            Navigator.pop(context);
          } else {
            Navigator.push(
              context,
              FadeInRoute<void>(
                builder: (_) => VerifyMnemonicsPage(widget.mnemonics),
              ),
            );
          }
        },
      ),
    );
  }
}
