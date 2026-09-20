import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zslx_flutter/utils/exports.dart';
import 'package:zslx_flutter/pages/starts/tabbar_page.dart';

class StartPage extends StatefulWidget {
  const StartPage({super.key});

  @override
  State<StartPage> createState() => _StartPageState();
}

class _StartPageState extends State<StartPage> {
  static const String _keyFirstStart = 'MD_APP_FIRST';

  @override
  void initState() {
    super.initState();

    // 隐藏状态栏，与 Swift 端 prefersStatusBarHidden 一致
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersive);

    _startLaunch();
  }

  Future<void> _startLaunch() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final hasAgreedPrivacy = prefs.getBool(_keyFirstStart) ?? false;

    if (!mounted) return;

    if (hasAgreedPrivacy) {
      _goToMain();
    } else {
      _showPrivacyAlert();
    }
  }

  void _goToMain() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      platformPageRoute(
        context: context,
        builder: (_) => const TabbarPage(),
      ),
    );
  }

  void _showPrivacyAlert() {
    showPlatformDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: PlatformAlertDialog(
          material: (context, platform) => MaterialAlertDialogData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '服务协议',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF18181B),
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              const Text(
                '    欢迎使用本应用！为了更好地保护您的个人信息和合法权益，请您在使用我们的产品前，认真阅读并了解《用户协议》和《隐私政策》的全部内容。\n    本应用将在您同意后，收集必要信息以提供服务。',
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF808080),
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: PlatformTextButton(
                        onPressed: _denyPrivacy,
                        color: AppColors.background,
                        material: (context, platform) =>
                            MaterialTextButtonData(
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.black,
                            backgroundColor: AppColors.background,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        cupertino: (context, platform) =>
                            CupertinoTextButtonData(
                          color: AppColors.background,
                        ),
                        child: const Text(
                          '退出应用',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: PlatformElevatedButton(
                        onPressed: _agreePrivacy,
                        color: AppColors.theme,
                        material: (context, platform) =>
                            MaterialElevatedButtonData(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.theme,
                            foregroundColor: AppColors.white,
                            elevation: 0,
                            padding: EdgeInsets.zero,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        cupertino: (context, platform) =>
                            CupertinoElevatedButtonData(
                          color: AppColors.theme,
                        ),
                        child: const Text(
                          '同意并继续',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _agreePrivacy() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyFirstStart, true);
    if (!mounted) return;
    Navigator.of(context).pop(); // 关闭弹窗
    _goToMain();
  }

  void _denyPrivacy() {
    exit(0);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 全屏背景图
          const Image(
            image: AssetImage('assets/images/launch/startBg.png'),
            fit: BoxFit.cover,
          ),
          // 中心图标 202×241
          Center(
            child: Image.asset(
              'assets/images/launch/startCent.png',
              width: 202,
              height: 241,
            ),
          ),
          // 底部图标 125×52，水平居中，距底部 54
          Positioned(
            bottom: 54,
            left: 0,
            right: 0,
            child: Center(
              child: Image.asset(
                'assets/images/launch/startBot.png',
                width: 125,
                height: 52,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
