import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zslx_flutter/utils/utils.dart';

import 'share.dart';
import 'wx_share.dart';

class SystemShare {
  SystemShare._();

  static const _fileExtensions = {'pdf', 'doc', 'docx', 'xls', 'xlsx'};

  static Future<void> share(MDShareData data) async {
    if (data.isEmpty) {
      MDTotast.message('分享内容为空');
      return;
    }
    try {
      if (data.isImage || data.isFile) {
        final file = await _resolveFile(
          data.url!,
          data.fileName,
          defaultName: data.isImage ? 'image.png' : 'file',
        );
        if (file == null) return;
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path)], text: data.text),
        );
        return;
      }

      final text = data.isLink
          ? [
              if (data.text?.isNotEmpty == true) data.text!,
              data.link!,
            ].join(' ')
          : data.text ?? '';
      await SharePlus.instance.share(
        ShareParams(
          text: text,
          title: data.title,
          uri: data.link == null ? null : Uri.tryParse(data.link!),
        ),
      );
    } catch (error) {
      MDTotast.message('分享失败，请稍后重试');
      Utils.log('SystemShare error: $error');
    }
  }

  /// 下载远程文件到临时目录并调起系统分享面板（兼容旧调用）
  static Future<void> shareFile(String? url) async {
    final uri = url == null ? null : Uri.tryParse(url);
    final segments = uri?.pathSegments ?? const <String>[];
    final name = segments.isEmpty ? '' : segments.last;
    final extension = name.split('.').last.toLowerCase();
    if (uri == null || !_fileExtensions.contains(extension)) {
      MDTotast.message('暂不支持分享该文件格式');
      return;
    }

    final file = await _resolveFile(uri.toString(), name, defaultName: 'file');
    if (file == null) return;
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }

  /// 下载远程资源到临时目录，返回可分享的本地文件
  static Future<File?> _resolveFile(
    String remoteUrl,
    String name, {
    required String defaultName,
  }) async {
    final bytes = await downloadBytes(remoteUrl);
    if (bytes == null) {
      MDTotast.message('文件下载失败，请检查网络连接');
      return null;
    }
    final directory = await getTemporaryDirectory();
    final fileName =
        (name.isEmpty || !name.contains('.')) ? defaultName : name;
    final file = File('${directory.path}/$fileName');
    await file.writeAsBytes(bytes, flush: true);
    return file;
  }
}
