import 'dart:math';

import 'package:breez_translations/breez_translations_locales.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/home/home_page.dart';
import 'package:l_breez/routes/security/security_page.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/single_button_bottom_bar.dart';

import 'widgets/verify_form.dart';

class VerifyMnemonicsPage extends StatefulWidget {
  final String _mnemonics;

  const VerifyMnemonicsPage(this._mnemonics, {super.key});

  @override
  VerifyMnemonicsPageState createState() => VerifyMnemonicsPageState();
}

class VerifyMnemonicsPageState extends State<VerifyMnemonicsPage> {
  final _formKey = GlobalKey<FormState>();
  final List _randomlySelectedIndexes = [];
  late List<String> _mnemonicsList;
  late bool _hasError;

  @override
  void initState() {
    _mnemonicsList = widget._mnemonics.split(" ");
    _hasError = false;
    _selectIndexes();
    super.initState();
  }

  _selectIndexes() {
    // Select at least one index from each page(0-6,6-11) randomly
    var firstIndex = Random().nextInt(6);
    var secondIndex = Random().nextInt(6) + 6;
    // Select last index randomly from any page, ensure that there are no duplicates and each option has an ~equally likely chance of being selected
    var thirdIndex = Random().nextInt(10);
    if (thirdIndex >= firstIndex) thirdIndex++;
    if (thirdIndex >= secondIndex) thirdIndex++;
    _randomlySelectedIndexes.addAll([firstIndex, secondIndex, thirdIndex]);
    _randomlySelectedIndexes.sort();
  }

  @override
  Widget build(BuildContext context) {
    final themeData = Theme.of(context);
    final query = MediaQuery.of(context);
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: const back_button.BackButton(),
        title: Text(texts.backup_phrase_generation_verify),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16),
        child: SizedBox(
          height: query.size.height - kToolbarHeight - query.padding.top,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              VerifyForm(
                formKey: _formKey,
                mnemonicsList: _mnemonicsList,
                randomlySelectedIndexes: _randomlySelectedIndexes,
                onError: () {
                  setState(() {
                    _hasError = true;
                  });
                },
                errorText: _hasError
                    ? Text(
                        texts.backup_phrase_generation_verification_failed,
                        style: themeData.textTheme.headlineMedium?.copyWith(
                          fontSize: 12,
                        ),
                      )
                    : const SizedBox.shrink(),
              ),
              Text(
                texts.backup_phrase_generation_type_words(
                  _randomlySelectedIndexes[0] + 1,
                  _randomlySelectedIndexes[1] + 1,
                  _randomlySelectedIndexes[2] + 1,
                ),
                style: mnemonicSeedInformationTextStyle.copyWith(
                  color: BreezColors.white[300],
                ),
                textAlign: TextAlign.center,
              ),
              SingleButtonBottomBar(
                text: texts.mnemonics_confirmation_action_verify,
                onPressed: () {
                  setState(() {
                    _hasError = false;
                  });
                  if (_formKey.currentState!.validate() && !_hasError) {
                    final securityCubit = context.read<SecurityCubit>();
                    securityCubit.mnemonicsValidated();
                    Navigator.of(context).popUntil((route) {
                      bool shouldPop = false;
                      // Pop to where the verification flow has started from,
                      // which is either from "Verify Backup Phrase" option on Security page
                      // or through WarningAction on Home page.
                      if (route.settings.name == SecurityPage.routeName ||
                          route.settings.name == Home.routeName) {
                        shouldPop = true;
                      }
                      return shouldPop;
                    });
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
