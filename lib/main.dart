import 'package:flutter/material.dart';
import '/utils/utils.dart';
import '../pages/starts/start_page.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppConfig.init();
  await AppConfig.printInfo();
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
      builder: EasyLoading.init(),
    );
  }
}
