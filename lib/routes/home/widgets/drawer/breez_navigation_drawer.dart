import 'dart:async';

import 'package:auto_size_text/auto_size_text.dart';
import 'package:breez_translations/breez_translations_locales.dart';
import 'package:breez_translations/generated/breez_translations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:l_breez/cubit/cubit.dart';
import 'package:l_breez/models/user_profile.dart';
import 'package:l_breez/routes/home/widgets/drawer/breez_avatar_dialog.dart';
import 'package:l_breez/routes/home/widgets/drawer/breez_drawer_header.dart';
import 'package:l_breez/theme/theme.dart';
import 'package:l_breez/widgets/breez_avatar.dart';
import 'package:theme_provider/theme_provider.dart';

const double _kBreezBottomSheetHeight = 60.0;

class DrawerItemConfig {
  final GlobalKey? key;
  final String name;
  final String title;
  final String icon;
  final bool disabled;
  final void Function(String name)? onItemSelected;
  final Widget? switchWidget;
  final bool isSelected;

  const DrawerItemConfig(
    this.name,
    this.title,
    this.icon, {
    this.key,
    this.onItemSelected,
    this.disabled = false,
    this.switchWidget,
    this.isSelected = false,
  });
}

class DrawerItemConfigGroup {
  final List<DrawerItemConfig> items;
  final String? groupTitle;
  final String? groupAssetImage;
  final bool withDivider;
  final bool isExpanded;

  const DrawerItemConfigGroup(
    this.items, {
    this.groupTitle,
    this.groupAssetImage,
    this.withDivider = true,
    this.isExpanded = true,
  });
}

class BreezNavigationDrawer extends StatelessWidget {
  final List<DrawerItemConfigGroup> _drawerGroupedItems;
  final void Function(String screenName) _onItemSelected;
  final ScrollController _scrollController = ScrollController();

  BreezNavigationDrawer(
    this._drawerGroupedItems,
    this._onItemSelected, {
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);

    return BlocBuilder<UserProfileCubit, UserProfileState>(
      builder: (BuildContext context, UserProfileState userSettings) {
        final List<Widget> children = <Widget>[
          _breezDrawerHeader(context, userSettings.profileSettings),
          const Padding(padding: EdgeInsets.only(top: 16)),
        ];
        for (DrawerItemConfigGroup groupItems in _drawerGroupedItems) {
          children.addAll(
            _createDrawerGroupWidgets(
              groupItems,
              context,
              _drawerGroupedItems.indexOf(groupItems),
              withDivider: children.isNotEmpty && groupItems.withDivider,
            ),
          );
        }

        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: Theme.of(context).appBarTheme.systemOverlayStyle!.copyWith(
                systemNavigationBarColor: themeData.customData.navigationDrawerBgColor,
              ),
          child: Theme(
            data: themeData.copyWith(
              canvasColor: themeData.customData.navigationDrawerBgColor,
            ),
            child: Drawer(
              child: Column(
                children: <Widget>[
                  Expanded(
                    child: ListView(
                      controller: _scrollController,
                      padding: const EdgeInsets.all(0.0),
                      children: children,
                    ),
                  ),
                  const NavigationDrawerFooter(),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  List<Widget> _createDrawerGroupWidgets(
    DrawerItemConfigGroup group,
    BuildContext context,
    int index, {
    bool withDivider = false,
  }) {
    List<Widget> groupItems = group.items
        .map(
          (DrawerItemConfig action) => _actionTile(
            action,
            context,
            action.onItemSelected ?? _onItemSelected,
          ),
        )
        .toList();
    if (group.groupTitle != null && groupItems.isNotEmpty) {
      groupItems = group.items
          .map(
            (DrawerItemConfig action) => _actionTile(
              action,
              context,
              action.onItemSelected ?? _onItemSelected,
              subTile: true,
            ),
          )
          .toList();
      groupItems = <Widget>[
        _ExpansionTile(
          items: groupItems,
          title: group.groupTitle ?? '',
          icon: group.groupAssetImage == null ? null : AssetImage(group.groupAssetImage!),
          controller: _scrollController,
          isExpanded: group.isExpanded,
        ),
      ];
    }

    if (groupItems.isNotEmpty && withDivider && index != 0) {
      groupItems.insert(0, _ListDivider());
    }
    return groupItems;
  }

  Widget _breezDrawerHeader(
    BuildContext context,
    UserProfileSettings user,
  ) {
    return Container(
      color: Theme.of(context).customData.navigationDrawerHeaderBgColor,
      child: BreezDrawerHeader(
        padding: const EdgeInsets.only(left: 16.0),
        child: _buildDrawerHeaderContent(user, context),
      ),
    );
  }

  Widget _buildDrawerHeaderContent(
    UserProfileSettings user,
    BuildContext context,
  ) {
    final BreezTranslations texts = context.texts();

    final List<Widget> drawerHeaderContent = <Widget>[];
    drawerHeaderContent.add(_buildThemeSwitch(context, user));
    drawerHeaderContent
      ..add(
        Row(
          children: <Widget>[
            BreezAvatar(user.avatarURL, radius: 24.0),
          ],
        ),
      )
      ..add(
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: AutoSizeText(
                user.name ?? texts.home_drawer_error_no_name,
                style: navigationDrawerHandleStyle,
              ),
            ),
          ],
        ),
      );

    return GestureDetector(
      onTap: () {
        showDialog<bool>(
          useRootNavigator: false,
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) => const BreezAvatarDialog(),
        );
      },
      child: Column(children: drawerHeaderContent),
    );
  }
}

class NavigationDrawerFooter extends StatelessWidget {
  const NavigationDrawerFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      // Aligns footer with bottom actions bar
      height: _kBreezBottomSheetHeight + 8.0 + MediaQuery.of(context).viewPadding.bottom,
      child: Column(
        children: <Widget>[
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              SvgPicture.asset(
                'assets/images/drawer_footer.svg',
                colorFilter: ColorFilter.mode(
                  BreezColors.white[500]!,
                  BlendMode.srcATop,
                ),
                height: 39,
                width: 183,
                fit: BoxFit.scaleDown,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ListDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(left: 8.0, right: 8.0),
      child: Divider(),
    );
  }
}

GestureDetector _buildThemeSwitch(
  BuildContext context,
  UserProfileSettings user,
) {
  final ThemeData themeData = Theme.of(context);
  return GestureDetector(
    onTap: () => ThemeProvider.controllerOf(context).nextTheme(),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.only(
            top: 10,
            right: 16.0,
          ),
          child: Container(
            width: 64,
            padding: const EdgeInsets.all(4),
            decoration: const ShapeDecoration(
              shape: StadiumBorder(),
              color: themeSwitchBgColor,
            ),
            child: Row(
              children: <Widget>[
                Image.asset(
                  'assets/icons/ic_lightmode.png',
                  height: 24,
                  width: 24,
                  color: themeData.lightThemeSwitchIconColor,
                ),
                const SizedBox(
                  height: 20,
                  width: 8,
                  child: VerticalDivider(
                    color: Colors.white30,
                  ),
                ),
                ImageIcon(
                  const AssetImage('assets/icons/ic_darkmode.png'),
                  color: themeData.darkThemeSwitchIconColor,
                  size: 24.0,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _actionTile(
  DrawerItemConfig action,
  BuildContext context,
  Function onItemSelected, {
  bool? subTile,
}) {
  final ThemeData themeData = Theme.of(context);
  TextStyle itemStyle = drawerItemTextStyle;

  Color? color;
  if (action.disabled) {
    color = themeData.disabledColor;
    itemStyle = itemStyle.copyWith(color: color);
  }
  return Padding(
    padding: EdgeInsets.only(
      right: subTile != null ? 0.0 : 16.0,
    ),
    child: Ink(
      decoration: subTile != null
          ? null
          : BoxDecoration(
              color: action.isSelected ? themeData.primaryColorLight : Colors.transparent,
              borderRadius: const BorderRadius.horizontal(
                right: Radius.circular(32),
              ),
            ),
      child: ListTile(
        key: action.key,
        shape: subTile != null
            ? null
            : const RoundedRectangleBorder(
                borderRadius: BorderRadius.horizontal(
                  right: Radius.circular(32),
                ),
              ),
        leading: Padding(
          padding: subTile != null
              ? const EdgeInsets.only(left: 28.0)
              : const EdgeInsets.symmetric(horizontal: 8.0),
          child: ImageIcon(
            AssetImage(action.icon),
            size: 26.0,
            color: color,
          ),
        ),
        title: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Text(
            action.title,
            style: itemStyle,
          ),
        ),
        trailing: action.switchWidget,
        onTap: action.disabled
            ? null
            : () {
                Navigator.pop(context);
                onItemSelected(action.name);
              },
      ),
    ),
  );
}

class _ExpansionTile extends StatelessWidget {
  final List<Widget> items;
  final String title;
  final AssetImage? icon;
  final ScrollController controller;
  final bool isExpanded;

  const _ExpansionTile({
    required this.items,
    required this.title,
    required this.icon,
    required this.controller,
    this.isExpanded = true,
  });

  @override
  Widget build(BuildContext context) {
    final ThemeData themeData = Theme.of(context);
    final ThemeData expansionTileTheme = themeData.copyWith(
      dividerColor: themeData.canvasColor,
    );
    return Theme(
      data: expansionTileTheme,
      child: ExpansionTile(
        title: Padding(
          padding: const EdgeInsets.only(left: 8.0, right: 8.0),
          child: (icon?.assetName ?? '') == ''
              ? null
              : Text(
                  title,
                  style: drawerItemTextStyle,
                ),
        ),
        initiallyExpanded: isExpanded,
        leading: Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: (icon?.assetName ?? '') == ''
              ? Text(
                  title,
                  style: drawerItemTextStyle.copyWith(
                    fontWeight: FontWeight.w500,
                  ),
                )
              : ImageIcon(
                  icon,
                  size: 26.0,
                  color: Colors.white,
                ),
        ),
        children: items
            .map(
              (Widget item) => Padding(
                padding: const EdgeInsets.only(),
                child: item,
              ),
            )
            .toList(),
        onExpansionChanged: (bool isExpanded) {
          final UserProfileCubit userProfileCubit = context.read<UserProfileCubit>();
          userProfileCubit.updateProfile(expandPreferences: isExpanded);
          if (isExpanded) {
            Timer(
              const Duration(milliseconds: 200),
              () => controller.animateTo(
                controller.position.maxScrollExtent + 28.0,
                duration: const Duration(milliseconds: 400),
                curve: Curves.ease,
              ),
            );
          }
          // 28 = bottom padding of list + intrinsic bottom padding
        },
      ),
    );
  }
}
