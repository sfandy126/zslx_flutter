import 'dart:async';

import '../article/article_page.dart';

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
  int _selectedIndex = 0;

  late final List<Widget> _pages = [
    const HomePage(),
    const ArticlePage(),
    const CourseLearnPage(),
    MinePage(onOpenCourses: () => setState(() => _selectedIndex = 2)),
  ];

  final List<_TabItem> _tabItems = [
    for (final item in [
      ('首页', 'home'),
      ('资讯', 'news'),
      ('听课', 'study'),
      ('我的', 'my'),
    ])
      _TabItem(
        label: item.$1,
        normalIcon: 'assets/images/tabbar/zs_nav_${item.$2}_inactive.svg',
        selectedIcon: 'assets/images/tabbar/zs_nav_${item.$2}_active.svg',
      ),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(UpdateServer.checkAndShow(context));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashFactory: NoSplash.splashFactory,
          splashColor: AppColors.transparent,
          highlightColor: AppColors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.white,
          currentIndex: _selectedIndex,
          onTap: (index) => setState(() => _selectedIndex = index),
          selectedItemColor: AppColors.theme,
          unselectedItemColor: AppColors.title,
          items: _tabItems
              .map(
                (item) => BottomNavigationBarItem(
                  icon: SizedBox(
                    width: 56,
                    height: 30,
                    child: Center(
                      child: SvgPicture.asset(
                        item.normalIcon,
                        width: 24,
                        height: 24,
                      ),
                    ),
                  ),
                  activeIcon: Container(
                    width: 56,
                    height: 30,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.lightTheme,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: SvgPicture.asset(
                      item.selectedIcon,
                      width: 24,
                      height: 24,
                    ),
                  ),
                  label: item.label,
                ),
              )
              .toList(),
        ),
      ),
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
