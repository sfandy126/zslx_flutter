import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:zslx_flutter/utils/utils.dart';

class SystemShare {
  SystemShare._();

  static const _fileExtensions = {'pdf', 'doc', 'docx', 'xls', 'xlsx'};

  /// 下载远程文件到临时目录并调起系统分享面板
  static Future<void> shareFile(String? url) async {
    final uri = url == null ? null : Uri.tryParse(url);
    final segments = uri?.pathSegments ?? const <String>[];
    final name = segments.isEmpty ? '' : segments.last;
    final extension = name.split('.').last.toLowerCase();
    if (uri == null || !_fileExtensions.contains(extension)) {
      MDTotast.showError('暂不支持分享该文件格式');
      return;
    }

    try {
      final response = await Dio().get<List<int>>(
        uri.toString(),
        options: Options(responseType: ResponseType.bytes),
      );
      final bytes = response.data;
      if (bytes == null || bytes.isEmpty) {
        MDTotast.showError('文件内容为空，无法分享');
        return;
      }
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
    } on DioException catch (error) {
      MDTotast.showError('文件下载失败，请检查网络连接');
      Utils.log('SystemShare download error: ${error.message}');
    } catch (error) {
      MDTotast.showError('分享失败，请稍后重试');
      Utils.log('SystemShare error: $error');
    }
  }
}
