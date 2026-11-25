import 'dart:io';

import 'package:flutter/services.dart' show appFlavor;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:zslx_flutter/utils/utils.dart';

import '../flavors.dart';
import 'device_info.dart';

class AppConfig {
  static PackageInfo? _packageInfo;
  static String? _deviceBrand;

  static Future<void> init() async {
    _packageInfo = await PackageInfo.fromPlatform();
    _deviceBrand = await DeviceInfo.getDeviceBrand();
  }

  static PackageInfo get packageInfo {
    if (_packageInfo == null) {
      throw StateError(
        'AppConfig.init() must be called before accessing packageInfo.',
      );
    }
    return _packageInfo!;
  }

  /// 一键打印配置信息（调试用）
  static Future<void> printInfo() async {
    final pkg = packageInfo;

    Utils.log('''
      ╔══════════════════════════════════════════╗
      ║  App 配置信息
      ╠══════════════════════════════════════════╣
      ║  渠道         : $channelId
      ║  设备品牌     : $deviceBrand
      ║  版本号       : ${pkg.version}
      ║  Build Number : ${pkg.buildNumber}
      ║  App 名称     : ${pkg.appName}
      ║  包名         : ${pkg.packageName}
      ╚══════════════════════════════════════════╝
    ''');
  }

  static String get appVersion => packageInfo.version;

  static String get appFullVersion =>
      '${packageInfo.version} (${packageInfo.buildNumber})';

  static String get appName => packageInfo.appName;

  static String get packageName => packageInfo.packageName;

  static String get deviceBrand => _deviceBrand ?? DeviceInfo.cachedBrand;

  /// 当前渠道（渠道定义见 flavorizr.yaml），不依赖 [init]，可在启动最早期读取
  static final Flavor channel = _resolveChannel();

  static String get channelId => channel.name;

  /// Android 由 `--flavor` 编译期确定；iOS 固定 AppStore，
  /// 未带 `--flavor` 运行（如直接 flutter run）时按平台回退
  static Flavor _resolveChannel() {
    for (final flavor in Flavor.values) {
      if (flavor.name == appFlavor) return flavor;
    }
    return Platform.isIOS ? Flavor.appstore : Flavor.companywebsite;
  }

  static String get systemType {
    if (Platform.isAndroid) {
      return 'android';
    }
    if (Platform.isIOS) {
      return 'ios';
    }
    if (Platform.operatingSystem == 'ohos') {
      return 'harmony';
    }
    return 'unknown';
  }

  static String get apiVersion => _plusOneMajorMinor(appVersion);

   static String _plusOneMajorMinor(String version) {
    final parts = version.split('.');
    if (parts.length < 3) {
      return version;
    }

    final major = int.tryParse(parts[0]) ?? 0;
    final minor = int.tryParse(parts[1]) ?? 0;
    final patch = int.tryParse(parts[2]) ?? 0;

    return '${major + 4}.$minor.$patch';
  }
}
