import 'dart:async';

import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/utils.dart';
import 'package:zslx_flutter/features/courses/course_learn_page.dart';
import 'package:zslx_flutter/features/home/home_page.dart';
import 'package:zslx_flutter/features/settings/mine_page.dart';
import 'package:zslx_flutter/update/update_server.dart';

class TabbarPage extends StatefulWidget {
  const TabbarPage({super.key});

  @override
  State<TabbarPage> createState() => _TabbarPageState();
}

class _TabbarPageState extends State<TabbarPage> {
  late final PlatformTabController _tabController;

  final List<Widget> _pages = [
    const HomePage(),
    const CourseLearnPage(),
    const MinePage(),
  ];

  final List<_TabItem> _tabItems = [
    _TabItem(
      label: '首页',
      normalIcon: Assets.images.tabbar.tabbarNormal1.path,
      selectedIcon: Assets.images.tabbar.tabbarHight1.path,
    ),
    _TabItem(
      label: '学习',
      normalIcon: Assets.images.tabbar.tabbarNormal2.path,
      selectedIcon: Assets.images.tabbar.tabbarHight2.path,
    ),
    _TabItem(
      label: '我的',
      normalIcon: Assets.images.tabbar.tabbarNormal3.path,
      selectedIcon: Assets.images.tabbar.tabbarHight3.path,
    ),
  ];

  @override
  void initState() {
    super.initState();
    _tabController = PlatformTabController(initialIndex: 0);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(UpdateServer.checkAndShow(context));
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectedColor = AppColors.theme;
    final unselectedColor = AppColors.title;
    final iconSize = 24.0;

    return PlatformTabScaffold(
      tabController: _tabController,
      pageBackgroundColor: AppColors.white,
      tabsBackgroundColor: AppColors.white,
      itemChanged: (index) {},
      bodyBuilder: (context, index) => _pages[index],
      material: (context, platform) => MaterialTabScaffoldData(),
      materialTabs: (context, platform) => MaterialNavBarData(
        backgroundColor: AppColors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        type: BottomNavigationBarType.fixed,
        fixedColor: selectedColor,
        selectedItemColor: selectedColor,
        unselectedItemColor: unselectedColor,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(color: selectedColor, fontSize: 12),
        unselectedLabelStyle: TextStyle(color: unselectedColor, fontSize: 12),
      ),
      material3Tabs: (context, platform) => MaterialNavigationBarData(
        backgroundColor: AppColors.white,
        elevation: 0,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            color: selected ? selectedColor : unselectedColor,
            fontSize: 12,
          );
        }),
      ),
      cupertino: (context, platform) => CupertinoTabScaffoldData(),
      cupertinoTabs: (context, platform) => CupertinoTabBarData(
        backgroundColor: AppColors.white,
        activeColor: selectedColor,
        inactiveColor: unselectedColor,
        border: const Border(top: BorderSide.none),
      ),
      items: _tabItems.map((item) {
        return BottomNavigationBarItem(
          icon: SvgPicture.asset(
            item.normalIcon,
            width: iconSize,
            height: iconSize,
          ),
          activeIcon: SvgPicture.asset(
            item.selectedIcon,
            width: iconSize,
            height: iconSize,
          ),
          label: item.label,
        );
      }).toList(),
    );
  }
}

class _TabItem {
  const _TabItem({
    required this.label,
    required this.normalIcon,
    required this.selectedIcon,
  });

  final String label;
  final String normalIcon;
  final String selectedIcon;
}
