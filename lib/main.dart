import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '/utils/utils.dart';
import 'features/pay/storekit.dart';
import 'router/app_router.dart';
import 'services/history/history_server.dart';
import 'services/um_server.dart';

import 'package:flutter_easyloading/flutter_easyloading.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // 友盟合规预初始化，隐私同意前调用；渠道从 AppChannel 动态传入
  await UmServer.preInit();
  await AppOrientation.configure();
  await AppConfig.init();
  await MDUser.defualt.init();
  await HistoryServer.init();
  await AppConfig.printInfo();  
  if (Platform.isIOS) {
    MDStoreKit.configuration();
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'zslx_flutter',
      theme: ThemeData(
        // 设置app主题颜色，自动影响 Theme.of(context).primaryColor
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.theme),
      ),
      routerConfig: AppRouter.router,
      // 打开第三方页面（如相册选择器）退出后由这里的根区域自动恢复。
      builder: EasyLoading.init(
        builder: (context, child) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle.dark,
          child: child ?? const SizedBox.shrink(),
        ),
      ),
    );
  }
}
