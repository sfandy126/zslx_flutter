import 'package:flutter/material.dart';

import '../../utils/app_colors.dart';
import '../../widgets/custom_appbar.dart';
import '../../widgets/page_background.dart';

class ArticlePage extends StatelessWidget {
  const ArticlePage({super.key});

  @override
  Widget build(BuildContext context) {
    // #TODO: 接入资讯列表数据及详情页面跳转。
    return Scaffold(
      backgroundColor: MDPageBackground.backgroundColor,
      appBar: const MDAppBar(title: '资讯', showBackButton: false),
      body: Center(
        child: Text('暂无资讯', style: TextStyle(color: AppColors.content)),
      ),
    );
  }
}
