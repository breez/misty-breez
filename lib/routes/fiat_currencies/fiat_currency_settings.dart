import 'package:breez_sdk/sdk.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:l_breez/bloc/currency/currency_bloc.dart';
import 'package:l_breez/bloc/currency/currency_state.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/loader.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

const double ITEM_HEIGHT = 72.0;

class FiatCurrencySettings extends StatefulWidget {
  const FiatCurrencySettings({
    super.key,
  });

  @override
  FiatCurrencySettingsState createState() {
    return FiatCurrencySettingsState();
  }
}

class FiatCurrencySettingsState extends State<FiatCurrencySettings> {
  final _scrollController = ScrollController();

  bool isInit = false;

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.fiat_currencies_title),
      ),
      body: BlocBuilder<CurrencyBloc, CurrencyState>(
        buildWhen: (s1, s2) => !listEquals(s1.preferredCurrencies, s2.preferredCurrencies),
        builder: (context, currencyState) {
          if (currencyState.fiatCurrenciesData.isEmpty || currencyState.fiatCurrency == null) {
            return const Center(
              child: Loader(
                color: Colors.white,
              ),
            );
          } else {
            return FutureBuilder(
              future: artificialWait(),
              builder: (context, snapshot) {
                if (isInit == false && snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: Loader(
                      color: Colors.white,
                    ),
                  );
                }

                return DragAndDropLists(
                  listPadding: EdgeInsets.zero,
                  children: [
                    _buildList(context, currencyState),
                  ],
                  lastListTargetSize: 0,
                  lastItemTargetHeight: 8,
                  scrollController: _scrollController,
                  onListReorder: (oldListIndex, newListIndex) => {},
                  onItemReorder: (from, oldListIndex, to, newListIndex) => _onReorder(
                    context,
                    currencyState,
                    from,
                    to,
                  ),
                  itemDragHandle: DragHandle(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Icon(
                        Icons.drag_handle,
                        color: theme.BreezColors.white[200],
                      ),
                    ),
                  ),
                );
              },
            );
          }
        },
      ),
    );
  }

  DragAndDropList _buildList(
    BuildContext context,
    CurrencyState currencyState,
  ) {
    return DragAndDropList(
      header: const SizedBox(),
      canDrag: false,
      children: List.generate(currencyState.fiatCurrenciesData.length, (index) {
        return DragAndDropItem(
          child: _buildFiatCurrencyTile(context, currencyState, index),
          canDrag: currencyState.preferredCurrencies.contains(
            currencyState.fiatCurrenciesData[index].id,
          ),
        );
      }),
    );
  }

  Widget _buildFiatCurrencyTile(
    BuildContext context,
    CurrencyState currencyState,
    int index,
  ) {
    final texts = context.texts();
    final themeData = Theme.of(context);

    final currencyData = currencyState.fiatCurrenciesData[index];
    final prefCurrencies = currencyState.preferredCurrencies.toList();

    return CheckboxListTile(
      key: Key("tile-index-$index"),
      controlAffinity: ListTileControlAffinity.leading,
      activeColor: Colors.white,
      checkColor: themeData.canvasColor,
      value: prefCurrencies.contains(currencyData.id),
      onChanged: (bool? checked) {
        setState(() {
          if (checked == true) {
            prefCurrencies.add(currencyData.id);
            // center item in viewport
            if (_scrollController.offset >= (ITEM_HEIGHT * (prefCurrencies.length - 1))) {
              _scrollController.animateTo(
                ((2 * prefCurrencies.length - 1) * ITEM_HEIGHT -
                        _scrollController.position.viewportDimension) /
                    2,
                curve: Curves.easeOut,
                duration: const Duration(milliseconds: 400),
              );
            }
          } else if (currencyState.preferredCurrencies.length != 1) {
            prefCurrencies.remove(
              currencyData.id,
            );
          }
          _updatePreferredCurrencies(context, currencyState, prefCurrencies);
        });
      },
      subtitle: Text(
        _subtitle(texts, currencyData),
        style: theme.fiatConversionDescriptionStyle,
      ),
      title: RichText(
        text: TextSpan(
          text: currencyData.id,
          style: theme.fiatConversionTitleStyle,
          children: [
            TextSpan(
              text: " (${currencyData.info.symbol?.grapheme ?? ""})",
              style: theme.fiatConversionDescriptionStyle,
            ),
          ],
        ),
      ),
    );
  }

  String _subtitle(BreezTranslations texts, FiatCurrency currencyData) {
    final localizedName = currencyData.info.localizedName;
    if (localizedName.isNotEmpty) {
      for (var localizedName in localizedName) {
        if (localizedName.locale == texts.locale) {
          return localizedName.name;
        }
      }
    }
    return currencyData.info.name;
  }

  void _onReorder(
    BuildContext context,
    CurrencyState currencyState,
    int oldIndex,
    int newIndex,
  ) {
    final preferredFiatCurrencies = List<String>.from(
      currencyState.preferredCurrencies,
    );
    if (newIndex >= preferredFiatCurrencies.length) {
      newIndex = preferredFiatCurrencies.length - 1;
    }
    String item = preferredFiatCurrencies.removeAt(oldIndex);
    preferredFiatCurrencies.insert(newIndex, item);
    _updatePreferredCurrencies(context, currencyState, preferredFiatCurrencies);
  }

  void _updatePreferredCurrencies(
    BuildContext context,
    CurrencyState currencyState,
    List<String> preferredFiatCurrencies,
  ) {
    context.read<CurrencyBloc>().setPreferredCurrencies(preferredFiatCurrencies);
  }

  /// DragAndDropLists has a performance issue with displaying a big list
  /// and blocks the UI thread. Since data retrieval is not the bottleneck, it
  /// blocks the UI thread almost immediately on the screen navigating to this page.
  /// Before the underlying performance issues are fixed on the library.
  /// We've added an artificial wait to display the page route animation and spinning
  /// loader before UI thread is blocked to convey a better UX as a workaround.
  Future artificialWait() async {
    setState(() {
      isInit = true;
    });
    return await Future.delayed(const Duration(milliseconds: 800));
  }
}
