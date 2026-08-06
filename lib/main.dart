import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/exports.dart';
import 'package:zslx_flutter/pages/starts/start_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'zslx_flutter',
      theme: ThemeData(
        // 设置app主题颜色，自动影响 Theme.of(context).primaryColor
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.theme),
      ),
      home: const StartPage(),
    );
  }
}