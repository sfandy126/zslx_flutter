import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'channel_config.dart';
import 'device_info.dart';

class AppConfig {
  static PackageInfo? _packageInfo;
  static String? _deviceBrand;

  static Future<void> init() async {
    await ChannelConfig.init();
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
    final channelInfo = ChannelConfig.getChannelInfo();
    final channelId = channelInfo.id.trim().isEmpty
        ? 'unknown'
        : channelInfo.id.trim();

    debugPrint('''
      ╔══════════════════════════════════════════╗
      ║  App 配置信息
      ╠══════════════════════════════════════════╣
      ║  渠道 id      : $channelId
      ║  渠道名       : ${channelInfo.name}
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

  static BuildChannel get currentChannel => ChannelConfig.currentChannel;

  static String get systemType {
    final channel = currentChannel;
    if (channel.isAndroid) {
      return 'android';
    }
    if (channel.isIOS) {
      return 'ios';
    }
    if (channel.isHarmony) {
      return 'harmony';
    }
    return 'unknown';
  }
}
