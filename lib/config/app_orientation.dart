import 'dart:ui' show PlatformDispatcher;

import 'package:flutter/services.dart';

/// 全局屏幕方向：手机仅竖屏，平板（iPad 等）允许任意方向。
/// 视频全屏时由播放器临时切换为横屏，退出全屏后恢复为 [orientations]。
class AppOrientation {
  AppOrientation._();

  /// 应用全局方向，需在 WidgetsFlutterBinding.ensureInitialized() 之后调用
  static Future<void> configure() {
    return SystemChrome.setPreferredOrientations(orientations);
  }

  /// 最短边 >= 600 逻辑像素视为平板
  static bool get isTablet {
    final views = PlatformDispatcher.instance.views;
    if (views.isEmpty) return false;
    final view = views.first;
    final size = view.physicalSize / view.devicePixelRatio;
    return size.shortestSide >= 600;
  }

  /// 当前设备允许的页面方向
  static List<DeviceOrientation> get orientations => isTablet
      ? DeviceOrientation.values
      : const [DeviceOrientation.portraitUp];

}
