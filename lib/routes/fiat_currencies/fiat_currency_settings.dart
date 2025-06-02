import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:drag_and_drop_lists/drag_and_drop_list_interface.dart';
import 'package:drag_and_drop_lists/drag_and_drop_lists.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:misty_breez/cubit/cubit.dart';
import 'package:misty_breez/routes/routes.dart';
import 'package:misty_breez/theme/theme.dart';
import 'package:misty_breez/widgets/back_button.dart' as back_button;
import 'package:misty_breez/widgets/widgets.dart';

class FiatCurrencySettings extends StatefulWidget {
  static const String routeName = '/fiat_currency';

  const FiatCurrencySettings({super.key});

  @override
  FiatCurrencySettingsState createState() => FiatCurrencySettingsState();
}

class FiatCurrencySettingsState extends State<FiatCurrencySettings> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    final BreezTranslations texts = context.texts();

    return Scaffold(
      appBar: AppBar(leading: const back_button.BackButton(), title: Text(texts.fiat_currencies_title)),
      body: BlocBuilder<CurrencyCubit, CurrencyState>(
        buildWhen: (CurrencyState s1, CurrencyState s2) =>
            !listEquals(s1.preferredCurrencies, s2.preferredCurrencies),
        builder: (BuildContext context, CurrencyState currencyState) {
          return FutureBuilder<void>(
            future: artificialWait(),
            builder: (BuildContext context, AsyncSnapshot<void> snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CenteredLoader(color: Colors.white);
              }

              return DragAndDropLists(
                listPadding: EdgeInsets.zero,
                children: <DragAndDropListInterface>[
                  DragAndDropList(
                    header: const SizedBox.shrink(),
                    canDrag: false,
                    children: List<DragAndDropItem>.generate(currencyState.fiatCurrenciesData.length, (
                      int index,
                    ) {
                      return DragAndDropItem(
                        child: FiatCurrencyListTile(
                          index: index,
                          currencyState: currencyState,
                          scrollController: _scrollController,
                          onChanged: (List<String> preferredFiatCurrencies) {
                            _updatePreferredCurrencies(preferredFiatCurrencies);
                          },
                        ),
                        canDrag: currencyState.preferredCurrencies.contains(
                          currencyState.fiatCurrenciesData[index].id,
                        ),
                      );
                    }),
                  ),
                ],
                lastListTargetSize: 0,
                lastItemTargetHeight: 8,
                scrollController: _scrollController,
                onListReorder: (int oldListIndex, int newListIndex) => <dynamic, dynamic>{},
                onItemReorder: (int from, int oldListIndex, int to, int newListIndex) =>
                    _onReorder(currencyState, from, to),
                itemDragHandle: DragHandle(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Icon(Icons.drag_handle, color: BreezColors.white[200]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _onReorder(CurrencyState currencyState, int oldIndex, int newIndex) {
    final List<String> preferredFiatCurrencies = List<String>.from(currencyState.preferredCurrencies);
    if (newIndex >= preferredFiatCurrencies.length) {
      newIndex = preferredFiatCurrencies.length - 1;
    }
    final String item = preferredFiatCurrencies.removeAt(oldIndex);
    preferredFiatCurrencies.insert(newIndex, item);
    _updatePreferredCurrencies(preferredFiatCurrencies);
  }

  void _updatePreferredCurrencies(List<String> preferredFiatCurrencies) {
    final CurrencyCubit currencyCubit = context.read<CurrencyCubit>();
    currencyCubit.setPreferredCurrencies(preferredFiatCurrencies);
  }

  /// DragAndDropLists has a performance issue with displaying a big list
  /// and blocks the UI thread. Since data retrieval is not the bottleneck, it
  /// blocks the UI thread almost immediately on the screen navigating to this page.
  /// Before the underlying performance issues are fixed on the library.
  /// We've added an artificial wait to display the page route animation and spinning
  /// loader before UI thread is blocked to convey a better UX as a workaround.
  Future<void> artificialWait() async {
    return await Future<void>.delayed(const Duration(milliseconds: 450));
  }
}
