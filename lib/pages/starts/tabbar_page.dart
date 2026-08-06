import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/exports.dart';
import 'package:zslx_flutter/pages/courses/learn_page.dart';
import 'package:zslx_flutter/pages/home/home_page.dart';
import 'package:zslx_flutter/pages/settings/mine_page.dart';

class TabbarPage extends StatefulWidget {
  const TabbarPage({super.key});

  @override
  State<TabbarPage> createState() => _TabbarPageState();
}

class _TabbarPageState extends State<TabbarPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomePage(),
    const LearnPage(),
    const MinePage(),
  ];

  final List<_TabItem> _tabItems = [
    _TabItem(
      label: '首页',
      normalIcon: Assets.images.tabbar.tabbarNormal01.path,
      selectedIcon: Assets.images.tabbar.tabbarHight01.path,
    ),
    _TabItem(
      label: '学习',
      normalIcon: Assets.images.tabbar.tabbarNormal02.path,
      selectedIcon: Assets.images.tabbar.tabbarHight02.path,
    ),
    _TabItem(
      label: '我的',
      normalIcon: Assets.images.tabbar.tabbarNormal03.path,
      selectedIcon: Assets.images.tabbar.tabbarHight03.path,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final isCupertino = Theme.of(context).platform == TargetPlatform.iOS;
    final backgroundColor = AppColors.white;
    final selectedColor = Theme.of(context).primaryColor; // AppColors.theme;
    final unselectedColor = AppColors.red;
    if (isCupertino) {
      return CupertinoTabScaffold(
        tabBar: CupertinoTabBar(
          currentIndex: _currentIndex,
          backgroundColor: backgroundColor,
          onTap: (index) => setState(() => _currentIndex = index),
          items: List.generate(_tabItems.length, (index) {
            final item = _tabItems[index];
            final isSelected = index == _currentIndex;

            return BottomNavigationBarItem(
              icon: SvgPicture.asset(
                isSelected ? item.selectedIcon : item.normalIcon,
                width: 24,
                height: 24,
              ),
              label: item.label,
              backgroundColor: isSelected ? selectedColor : unselectedColor,
            );
          }),
        ),
        tabBuilder: (context, index) => _pages[index],
      );
    } else {
      return Scaffold(
        body: IndexedStack(
          index: _currentIndex,
          children: _pages,
        ),
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: _currentIndex,
          type: BottomNavigationBarType.fixed,
          selectedItemColor: selectedColor,
          unselectedItemColor: unselectedColor,
          onTap: (index) => setState(() => _currentIndex = index),
          items: List.generate(_tabItems.length, (index) {
            final item = _tabItems[index];
            final isSelected = index == _currentIndex;

            return BottomNavigationBarItem(
              icon: SvgPicture.asset(
                isSelected ? item.selectedIcon : item.normalIcon,
                width: 24,
                height: 24,
              ),
              activeIcon: SvgPicture.asset(
                item.selectedIcon,
                width: 24,
                height: 24,
              ),
              label: item.label,
            );
          }),
        ),
      );
    }
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
