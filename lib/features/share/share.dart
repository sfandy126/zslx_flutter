import 'package:flutter/material.dart';
import 'custom_share.dart';
import 'system_share.dart';

enum MDShareChannel {
  wx,
  wxzone,
  system,
}

enum MDShareTool {
  /// 保存图片到相册（仅图片内容可保存）
  saveImage,
  /// 复制链接（仅链接内容可复制）
  copyLink,
}

/// 分享内容
class MDShareData {
  const MDShareData({
    this.title,
    this.text,
    this.link,
    this.url,
    this.channels = const [.wx, .wxzone],
    this.tools = const [],
  });

  /// 标题（链接分享时展示，保存图片时的文件名）
  final String? title;

  /// 文字内容（链接分享时作为描述）
  final String? text;

  /// 链接地址
  final String? link;

  /// 文件/图片资源地址，内容类型由扩展名识别
  final String? url;

  /// 配置的分享渠道，实际展示以是否安装微信为准
  final List<MDShareChannel> channels;

  /// 配置的面板工具，默认为空；实际展示以内容类型为准
  final List<MDShareTool> tools;

  static const _imageExtensions = {
    'png', 'jpg', 'jpeg', 'gif', 'webp', 'bmp', 'heic',
  };

  bool get _hasUrl => url != null && url!.isNotEmpty;

  bool get _hasLink => link != null && link!.isNotEmpty;

  bool get _hasText => text != null && text!.isNotEmpty;

  bool get isImage => _hasUrl && _imageExtensions.contains(_extension);

  bool get isFile => _hasUrl && !isImage;

  bool get isLink => !_hasUrl && _hasLink;

  bool get isEmpty => !_hasUrl && !_hasLink && !_hasText;

  String get _extension {
    final path = Uri.tryParse(url ?? '')?.path ?? url ?? '';
    final name = path.split('/').last;
    return name.contains('.') ? name.split('.').last.toLowerCase() : '';
  }

  String get fileName {
    if (title != null && title!.isNotEmpty) return title!;
    final path = Uri.tryParse(url ?? '')?.path ?? url ?? '';
    final name = path.split('/').last;
    return name.contains('.') ? name : '';
  }
}

class MDShare {
  MDShare._();

  static Future<void> toShare(
    BuildContext context,
    MDShareData data, {
    void Function(MDShareChannel channel)? onComplete,
  }) {
    return showCustomShare(context, data, onComplete: onComplete);
  }

  static Future<void> toSystem(MDShareData data) {
    return SystemShare.share(data);
  }
}
