import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:umeng_apm_sdk/umeng_apm_sdk.dart';
import 'package:umeng_common_sdk/umeng_common_sdk.dart';

import '../config/app_config.dart';

/// 友盟统计 + APM 封装。
///
/// 合规要求：
/// - 隐私政策同意前不得初始化，Android 侧仅由 MainActivity 原生调用
///   `UMConfigure.preInit` 做合规预初始化；
/// - 用户同意隐私政策后调用 [init]，内部完成统计与 APM 初始化并绑定已登录用户；
/// - 登录成功时调用 [bindUserId]，退出登录时调用 [unbind]。
class UmServer {
  UmServer._();

  ///与AndroidManifest.xml必须保持一致
  static const String _androidAppKey = '6ae36ccb863270068caedee9';
  /// 与info.plist中CFBundleURLTypes必须保持一致
  static const String _iosAppKey = '6ae36ccb6545637cd628fabc';

  static bool _inited = false;

  static const MethodChannel _nativeChannel = MethodChannel('com.zs.zslx/umeng');

  /// Android 合规预初始化，应用启动即调用（隐私同意前）。
  /// 渠道从 [AppConfig.channelId] 动态传入原生侧，preInit 本身即为合规 API，
  /// 隐私同意前仅采集必要设备标识。重复调用安全。
  static Future<void> preInit() async {
    if (!Platform.isAndroid) return;
    try {
      await _nativeChannel.invokeMethod<void>(
        'preInit',
        {'channel': AppConfig.channelId},
      );
    } catch (error) {
      debugPrint('友盟预初始化失败：$error');
    }
  }

  /// 用户同意隐私政策后调用；重复调用安全
  static Future<void> init() async {
    if (_inited) return;
    _inited = true;
    // 插件原生实现（Android UmengCommonSdkPlugin.java / iOS UmengCommonSdkPlugin.m）处理完
    // initCommon 后都不回调 result，await 会永久挂起并卡死启动页，因此只发起调用、不等待返回。
    UmengCommonSdk.initCommon(
      _androidAppKey,
      _iosAppKey,
      AppConfig.channelId,
    ).then<void>(
      (_) {},
      onError: (Object error) => debugPrint('友盟初始化失败：$error'),
    );
    _installErrorHandlers();
  }

  /// 全局异常上报到友盟 APM
  static void _installErrorHandlers() {
    FlutterError.onError = (details) {
      final stack = details.stack?.toString() ?? '';
      UmengApmSdk.postException(details.exception, stack);
      UmengCommonSdk.reportError(details.exceptionAsString());
      FlutterError.presentError(details);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      UmengApmSdk.postException(error, stack.toString());
      UmengCommonSdk.reportError(error.toString());
      return true;
    };
  }

  /// 统计账号绑定（登录成功后调用）
  static void bindUserId(String? userId) {
    if (userId == null || userId.isEmpty || userId == '0') return;
    try {
      UmengCommonSdk.onProfileSignIn(userId);
    } catch (error) {
      debugPrint('友盟账号绑定失败：$error');
    }
  }

  /// 解除账号绑定（退出登录时调用）
  static void unbind() {
    try {
      UmengCommonSdk.onProfileSignOff();
    } catch (error) {
      debugPrint('友盟解除绑定失败：$error');
    }
  }

  /// 自定义事件上报
  static void onEvent(String event, [Map<String, dynamic> properties = const {}]) {
    try {
      UmengCommonSdk.onEvent(event, properties);
    } catch (error) {
      debugPrint('友盟事件上报失败：$error');
    }
  }
}
