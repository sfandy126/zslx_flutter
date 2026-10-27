import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:fluwx/fluwx.dart';
import 'package:zslx_flutter/utils/utils.dart';

/// 微信分享：文本、链接、图片、文件（朋友圈仅支持图片/链接/文本）
class WxShare {
  WxShare._();

  /// 与 pubspec.yaml 中 fluwx 的 app_id 保持一致
  static const String _appId = 'wx4bddc0d3d10d3d0a';
  static const String _universalLink = 'https://www.zhuoshilx.com/';

  static final Fluwx _fluwx = Fluwx();

  static bool _registered = false;

  static Future<bool> _register() async {
    if (_registered) return true;
    try {
      _registered = await _fluwx.registerApi(
        appId: _appId,
        universalLink: _universalLink,
      );
    } catch (error) {
      Utils.log('WxShare register failed: $error');
    }
    return _registered;
  }

  static Future<bool> isInstalled() async {
    try {
      if (!await _register()) return false;
      return await _fluwx.isWeChatInstalled;
    } catch (error) {
      Utils.log('WxShare check installed failed: $error');
      return false;
    }
  }

  static Future<bool> shareText(String text, WeChatScene scene) async {
    if (!await _ensureInstalled()) return false;
    return _fluwx.share(
      WeChatShareTextModel(text, scene: scene),
    );
  }

  static Future<bool> shareWebPage(
    String webPage,
    String? title,
    String? description,
    WeChatScene scene,
  ) async {
    if (!await _ensureInstalled()) return false;
    return _fluwx.share(
      WeChatShareWebPageModel(
        webPage,
        title: title ?? '',
        description: description,
        scene: scene,
      ),
    );
  }

  /// 分享图片，iOS 端要求传入图片二进制，此处统一读取/下载后再分享
  static Future<bool> shareImage({
    required Uint8List bytes,
    required WeChatScene scene,
  }) async {
    if (!await _ensureInstalled()) return false;
    return _fluwx.share(
      WeChatShareImageModel(
        WeChatImageToShare(uint8List: bytes),
        scene: scene,
      ),
    );
  }

  /// 分享文件，朋友圈不支持文件分享，会回退为发给好友
  static Future<bool> shareFile({
    required Uint8List bytes,
    required String name,
    String? title,
  }) async {
    if (!await _ensureInstalled()) return false;
    return _fluwx.share(
      WeChatShareFileModel(
        WeChatFile.binary(bytes, suffix: _suffix(name)),
        title: title ?? '',
        scene: WeChatScene.session,
      ),
    );
  }

  static Future<bool> _ensureInstalled() async {
    if (!await isInstalled()) {
      MDTotast.message('未安装微信');
      return false;
    }
    return true;
  }

  static String _suffix(String name) {
    final ext = name.contains('.') ? name.split('.').last : '';
    return ext.isEmpty ? 'dat' : ext;
  }
}

Future<Uint8List?> downloadBytes(String url) async {
  try {
    final response = await Dio().get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) return null;
    return Uint8List.fromList(bytes);
  } catch (error) {
    Utils.log('downloadBytes error: $error');
    return null;
  }
}
