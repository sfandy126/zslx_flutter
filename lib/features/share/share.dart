import 'package:flutter/material.dart';
import 'custom_share.dart';
import 'system_share.dart';

enum MDShareChannel {
  wx,
  wxzone,
  system,
}

enum MDShareMethod {
  /// 分享链接
  link,
  /// 分享图片
  image,
  /// 分享文件
  file,
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
    this.method = .link,
    this.title,
    this.text,
    this.link,
    this.url,
    this.channels = const [.wx, .wxzone],
    this.tools = const [],
  });

  /// 分享内容类型
  final MDShareMethod method;

  /// 标题（链接分享时展示，图片/文件保存时的文件名）
  final String? title;

  /// 文字内容（链接分享时作为描述）
  final String? text;

  /// 链接地址（method 为 link 时需传）
  final String? link;

  /// 资源地址：image/file 为图片/文件地址；link 时可作为缩略图来源（可选）
  final String? url;

  /// 配置的分享渠道，实际展示以是否安装微信为准
  final List<MDShareChannel> channels;

  /// 配置的面板工具，默认为空；实际展示以内容类型为准
  final List<MDShareTool> tools;

  /// 内容是否为空：link 需要链接，image/file 需要资源地址
  bool get isEmpty => switch (method) {
    .link => link == null || link!.isEmpty,
    _ => url == null || url!.isEmpty,
  };

  bool get isLink => method == .link;

  bool get isImage => method == .image;

  bool get isFile => method == .file;

  /// 资源文件名（优先 title，否则取 url 路径末段，无则返回空字符串）
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
