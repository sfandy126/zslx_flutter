import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

class DeviceInfo {
  static final DeviceInfoPlugin _deviceInfoPlugin = DeviceInfoPlugin();
  static String? _brandCache;

  static Future<String> getDeviceBrand() async {
    if (_brandCache != null && _brandCache!.isNotEmpty) {
      return _brandCache!;
    }

    if (Platform.isAndroid) {
      final androidInfo = await _deviceInfoPlugin.androidInfo;
      _brandCache = androidInfo.brand.trim().toLowerCase();
      return _brandCache ?? 'android';
    }

    if (Platform.isIOS || Platform.isMacOS) {
      _brandCache = 'apple';
      return _brandCache!;
    }

    _brandCache = 'unknown';
    return _brandCache!;
  }

  static String get cachedBrand => _brandCache ?? 'unknown';
}