import 'package:breez_translations/breez_translations_locales.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/routes/fiat_currencies/fiat_currency_list_tile.dart';
import 'package:l_breez/theme/theme_provider.dart' as theme;
import 'package:l_breez/widgets/back_button.dart' as back_button;
import 'package:l_breez/widgets/loader.dart';

class FiatCurrencySettings extends StatefulWidget {
  const FiatCurrencySettings({super.key});

  @override
  FiatCurrencySettingsState createState() => FiatCurrencySettingsState();
}

class FiatCurrencySettingsState extends State<FiatCurrencySettings> {
  final _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final texts = context.texts();

    return Scaffold(
      appBar: AppBar(
        leading: const back_button.BackButton(),
        title: Text(texts.fiat_currencies_title),
      ),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        buildWhen: (s1, s2) => !listEquals(s1.preferredCurrencies, s2.preferredCurrencies),
        builder: (context, currencyState) {
          return FutureBuilder(
            future: artificialWait(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: Loader(color: Colors.white));
              }

              return DragAndDropLists(
                listPadding: EdgeInsets.zero,
                children: [
                  DragAndDropList(
                    header: const SizedBox.shrink(),
                    canDrag: false,
                    children: List.generate(
                      currencyState.fiatCurrenciesData.length,
                      (index) {
                        return DragAndDropItem(
                          child: FiatCurrencyListTile(
                            index: index,
                            currencyState: currencyState,
                            scrollController: _scrollController,
                            onChanged: (preferredFiatCurrencies) {
                              _updatePreferredCurrencies(preferredFiatCurrencies);
                            },
                          ),
                          canDrag: currencyState.preferredCurrencies.contains(
                            currencyState.fiatCurrenciesData[index].id,
                          ),
                        );
                      },
                    ),
                  ),
                ],
                lastListTargetSize: 0,
                lastItemTargetHeight: 8,
                scrollController: _scrollController,
                onListReorder: (oldListIndex, newListIndex) => {},
                onItemReorder: (from, oldListIndex, to, newListIndex) => _onReorder(currencyState, from, to),
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
        },
      ),
    );
  }

  void _onReorder(
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
    _updatePreferredCurrencies(preferredFiatCurrencies);
  }

  void _updatePreferredCurrencies(
    List<String> preferredFiatCurrencies,
  ) {
    var currencyCubit = context.read<CurrencyCubit>();
    currencyCubit.setPreferredCurrencies(preferredFiatCurrencies);
  }

  /// DragAndDropLists has a performance issue with displaying a big list
  /// and blocks the UI thread. Since data retrieval is not the bottleneck, it
  /// blocks the UI thread almost immediately on the screen navigating to this page.
  /// Before the underlying performance issues are fixed on the library.
  /// We've added an artificial wait to display the page route animation and spinning
  /// loader before UI thread is blocked to convey a better UX as a workaround.
  Future artificialWait() async {
    return await Future.delayed(const Duration(milliseconds: 450));
  }
}
