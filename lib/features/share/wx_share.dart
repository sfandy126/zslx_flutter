import 'dart:ui' as ui;

import 'package:dio/dio.dart';
import 'package:flutter/services.dart';
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

  /// 分享链接，未传缩略图时默认使用 App 图标压缩后的缩略图，
  /// 未传标题时默认使用 App 桌面名称
  static Future<bool> shareWebPage(
    String webPage,
    String? title,
    String? description,
    WeChatScene scene, {
    Uint8List? thumbData,
  }) async {
    if (!await _ensureInstalled()) return false;
    return _fluwx.share(
      WeChatShareWebPageModel(
        webPage,
        title: (title == null || title.isEmpty)
            ? AppConfig.appName
            : title,
        description: description,
        scene: scene,
        thumbData: thumbData ?? await defaultThumbnail(),
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

  /// 分享文件，朋友圈不支持文件分享，会回退为发给好友；
  static Future<bool> shareFile({
    required Uint8List bytes,
    required String name,
    String? title,
    Uint8List? thumbData,
  }) async {
    if (!await _ensureInstalled()) return false;
    return _fluwx.share(
      WeChatShareFileModel(
        WeChatFile.binary(bytes, suffix: _suffix(name)),
        title: title ?? '',
        scene: WeChatScene.session,
        thumbData: thumbData ?? await defaultThumbnail(),
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

  /// 微信缩略图大小限制（32KB）
  static const int maxThumbBytes = 32 * 1024;

  /// 微信原图分享大小限制（10MB）
  static const int maxShareImageBytes = 10 * 1024 * 1024;

  /// 默认缩略图源：App 桌面图标
  static const String _defaultIconAsset = 'assets/images/appLogo1024.png';

  static Uint8List? _defaultThumbCache;

  /// 加载 App 图标并压缩到低于微信缩略图限制，失败返回 null
  static Future<Uint8List?> defaultThumbnail() async {
    final cached = _defaultThumbCache;
    if (cached != null) return cached;
    try {
      final iconBytes = await rootBundle.load(_defaultIconAsset);
      final compressed = await compressImage(
        iconBytes.buffer.asUint8List(),
        maxBytes: maxThumbBytes,
        startWidth: 120,
      );
      if (compressed.lengthInBytes <= maxThumbBytes) {
        _defaultThumbCache = compressed;
        return compressed;
      }
    } catch (error) {
      Utils.log('WxShare defaultThumbnail error: $error');
    }
    return null;
  }

  /// 从资源 url 下载图片并压缩为缩略图，失败返回 null
  static Future<Uint8List?> thumbnailFromUrl(String url) async {
    try {
      final bytes = await downloadBytes(url);
      if (bytes == null) return null;
      return await compressImage(bytes, maxBytes: maxThumbBytes);
    } catch (error) {
      Utils.log('WxShare thumbnailFromUrl error: $error');
      return null;
    }
  }

  /// 压缩图片到低于 [maxBytes]：宽度逐级减半重编码，无法达标时返回最后一次结果
  static Future<Uint8List> compressImage(
    Uint8List bytes, {
    required int maxBytes,
    int startWidth = 1280,
  }) async {
    if (bytes.lengthInBytes <= maxBytes) return bytes;
    var width = startWidth;
    Uint8List? last;
    while (width >= 80) {
      final resized = await _resize(bytes, targetWidth: width);
      if (resized == null) break;
      last = resized;
      if (resized.lengthInBytes <= maxBytes) return resized;
      width ~/= 2;
    }
    return last ?? bytes;
  }

  /// 解码后缩放到指定宽度并编码为 PNG
  static Future<Uint8List?> _resize(
    Uint8List bytes, {
    required int targetWidth,
  }) async {
    final codec = await ui.instantiateImageCodec(
      bytes,
      targetWidth: targetWidth,
      targetHeight: targetWidth,
    );
    final frame = await codec.getNextFrame();
    final data = await frame.image.toByteData(format: ui.ImageByteFormat.png);
    return data?.buffer.asUint8List();
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
