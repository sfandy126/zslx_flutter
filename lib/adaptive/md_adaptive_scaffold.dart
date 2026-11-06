import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as adaptive;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

/// 项目统一的跨平台页面容器。页面只依赖本文件中的配置类型。
class MDAdaptiveScaffold extends StatelessWidget {
  const MDAdaptiveScaffold({
    super.key,
    this.appBar,
    this.bottomNavigationBar,
    this.body,
    this.resizeToAvoidBottomInset,
    this.floatingActionButton,
    this.minimizeBehavior = MDTabBarMinimizeBehavior.automatic,
    this.enableBlur = true,
    this.extendBodyBehindAppBar = false,
    this.extendBody = false,
    this.backgroundColor,
    this.drawer,
    this.endDrawer,
    this.drawerScrimColor,
    this.onDrawerChanged,
    this.onEndDrawerChanged,
    this.drawerEnableOpenDragGesture = true,
    this.endDrawerEnableOpenDragGesture = true,
    this.scaffoldKey,
    this.useHeroBackButton = true,
    this.useFixedToolbar = true,
    this.tabBarHidden = false,
  });

  final MDAdaptiveAppBar? appBar;
  final MDAdaptiveBottomNavigationBar? bottomNavigationBar;
  final Widget? body;
  final bool? resizeToAvoidBottomInset;
  final Widget? floatingActionButton;
  final MDTabBarMinimizeBehavior minimizeBehavior;
  final bool enableBlur;
  final bool extendBodyBehindAppBar;
  final bool extendBody;
  final Color? backgroundColor;
  final Widget? drawer;
  final Widget? endDrawer;
  final Color? drawerScrimColor;
  final DrawerCallback? onDrawerChanged;
  final DrawerCallback? onEndDrawerChanged;
  final bool drawerEnableOpenDragGesture;
  final bool endDrawerEnableOpenDragGesture;
  final GlobalKey<ScaffoldState>? scaffoldKey;
  final bool useHeroBackButton;
  final bool useFixedToolbar;
  final bool tabBarHidden;

  @override
  Widget build(BuildContext context) => adaptive.AdaptiveScaffold(
    appBar: appBar?._toAdaptive(),
    bottomNavigationBar: bottomNavigationBar?._toAdaptive(),
    body: body,
    resizeToAvoidBottomInset: resizeToAvoidBottomInset,
    floatingActionButton: floatingActionButton,
    minimizeBehavior: switch (minimizeBehavior) {
      MDTabBarMinimizeBehavior.automatic =>
        adaptive.TabBarMinimizeBehavior.automatic,
      MDTabBarMinimizeBehavior.never => adaptive.TabBarMinimizeBehavior.never,
      MDTabBarMinimizeBehavior.onScrollDown =>
        adaptive.TabBarMinimizeBehavior.onScrollDown,
      MDTabBarMinimizeBehavior.onScrollUp =>
        adaptive.TabBarMinimizeBehavior.onScrollUp,
    },
    enableBlur: enableBlur,
    extendBodyBehindAppBar: extendBodyBehindAppBar,
    extendBody: extendBody,
    backgroundColor: backgroundColor,
    drawer: drawer,
    endDrawer: endDrawer,
    drawerScrimColor: drawerScrimColor,
    onDrawerChanged: onDrawerChanged,
    onEndDrawerChanged: onEndDrawerChanged,
    drawerEnableOpenDragGesture: drawerEnableOpenDragGesture,
    endDrawerEnableOpenDragGesture: endDrawerEnableOpenDragGesture,
    scaffoldKey: scaffoldKey,
    useHeroBackButton: useHeroBackButton,
    useFixedToolbar: useFixedToolbar,
    tabBarHidden: tabBarHidden,
  );
}

enum MDTabBarMinimizeBehavior { automatic, never, onScrollDown, onScrollUp }

/// 顶部导航栏配置；不传入时不显示顶部栏。
class MDAdaptiveAppBar {
  const MDAdaptiveAppBar({
    this.title,
    this.subtitle,
    this.actions,
    this.leading,
    this.useNativeToolbar = true,
    this.tintColor,
    this.titleWidget,
    this.cupertinoNavigationBar,
    this.appBar,
  });

  final String? title;
  final String? subtitle;
  final List<MDAdaptiveAppBarAction>? actions;
  final Widget? leading;
  final bool useNativeToolbar;
  final Color? tintColor;
  final Widget? titleWidget;
  final PreferredSizeWidget? cupertinoNavigationBar;
  final PreferredSizeWidget? appBar;

  adaptive.AdaptiveAppBar _toAdaptive() => adaptive.AdaptiveAppBar(
    title: title,
    subtitle: subtitle,
    actions: actions?.map((action) => action._toAdaptive()).toList(),
    leading: leading,
    useNativeToolbar: useNativeToolbar,
    tintColor: tintColor,
    titleWidget: titleWidget,
    cupertinoNavigationBar: cupertinoNavigationBar,
    appBar: appBar,
  );
}

class MDAdaptiveAppBarAction {
  const MDAdaptiveAppBarAction({
    this.iosSymbol,
    this.icon,
    this.iconWidget,
    this.title,
    this.label,
    this.onPressed,
    this.prominent = false,
    this.tintColor,
  });

  final String? iosSymbol;
  final IconData? icon;
  final Widget? iconWidget;
  final String? title;
  final String? label;
  final VoidCallback? onPressed;
  final bool prominent;
  final Color? tintColor;

  adaptive.AdaptiveAppBarAction _toAdaptive() => adaptive.AdaptiveAppBarAction(
    iosSymbol: iosSymbol,
    icon: icon,
    iconWidget: iconWidget,
    title: title,
    label: label,
    onPressed: onPressed ?? () {},
    prominent: prominent,
    tintColor: tintColor,
  );
}

/// 底部导航栏配置；不传入时不显示底部栏。
class MDAdaptiveBottomNavigationBar {
  const MDAdaptiveBottomNavigationBar({
    this.items,
    this.selectedIndex,
    this.onTap,
    this.useNativeBottomBar = true,
    this.cupertinoTabBar,
    this.bottomNavigationBar,
    this.selectedItemColor,
    this.unselectedItemColor,
  });

  final List<MDAdaptiveNavigationDestination>? items;
  final int? selectedIndex;
  final ValueChanged<int>? onTap;
  final bool useNativeBottomBar;
  final CupertinoTabBar? cupertinoTabBar;
  final Widget? bottomNavigationBar;
  final Color? selectedItemColor;
  final Color? unselectedItemColor;

  adaptive.AdaptiveBottomNavigationBar _toAdaptive() =>
      adaptive.AdaptiveBottomNavigationBar(
        items: items?.map((item) => item._toAdaptive()).toList(),
        selectedIndex: selectedIndex,
        onTap: onTap,
        useNativeBottomBar: useNativeBottomBar,
        cupertinoTabBar: cupertinoTabBar,
        bottomNavigationBar: bottomNavigationBar,
        selectedItemColor: selectedItemColor,
        unselectedItemColor: unselectedItemColor,
      );
}

class MDAdaptiveNavigationDestination {
  const MDAdaptiveNavigationDestination({
    required this.icon,
    required this.label,
    this.selectedIcon,
    this.isSearch = false,
    this.badgeCount,
    this.badgeText,
    this.badgeColor,
    this.badgeTextColor,
    this.addSpacerAfter = false,
  });

  /// 图标可传入 [IconData]、图标名称或 [Widget]。
  final Object icon;
  final String label;
  final Object? selectedIcon;
  final bool isSearch;
  final int? badgeCount;
  final String? badgeText;
  final Color? badgeColor;
  final Color? badgeTextColor;
  final bool addSpacerAfter;

  adaptive.AdaptiveNavigationDestination _toAdaptive() =>
      adaptive.AdaptiveNavigationDestination(
        icon: icon,
        label: label,
        selectedIcon: selectedIcon,
        isSearch: isSearch,
        badgeCount: badgeCount,
        badgeText: badgeText,
        badgeColor: badgeColor,
        badgeTextColor: badgeTextColor,
        addSpacerAfter: addSpacerAfter,
      );
}
