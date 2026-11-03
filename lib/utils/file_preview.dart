import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:native_file_preview/native_file_preview.dart';
import 'package:path_provider/path_provider.dart';

import '../router/app_router.dart';
import 'totast.dart';

class FilePreview {
  FilePreview._();

  static Future<void> previewOnline({
    required BuildContext context,
    required String url,
    String? fileName,
  }) async {
    if (url.isEmpty) {
      MDTotast.error('资料地址无效，请稍后重试');
      return;
    }

    if (!Platform.isAndroid) {
      await AppRouter.pushNamed<void>(
        context,
        RouterNames.web,
        queryParameters: {
          'url': url,
          'title': fileName ?? '',
          'shareType': 'system',
        },
      );
      return;
    }

    MDTotast.showLoading('正在准备文件预览...');
    try {
      final uri = Uri.tryParse(url);
      if (uri == null ||
          !uri.hasAuthority ||
          !{'http', 'https'}.contains(uri.scheme)) {
        MDTotast.error('资料地址无效，请稍后重试');
        return;
      }

      final directory = await getTemporaryDirectory();
      final name = _previewFileName(url: url, fileName: fileName);
      final localFile = File('${directory.path}${Platform.pathSeparator}$name');
      await Dio().download(uri.toString(), localFile.path, deleteOnError: true);

      await NativeFilePreview().previewFile(localFile.path);
    } on PlatformException catch (error) {
      MDTotast.error(error.message ?? '无法打开文件预览');
    } catch (error) {
      if (kDebugMode) debugPrint('FilePreview online preview failed: $error');
      MDTotast.error('文件预览失败，请稍后重试');
    } finally {
      MDTotast.hideLoading();
    }
  }

  static String _previewFileName({required String url, String? fileName}) {
    final urlPath = Uri.tryParse(url)?.path ?? '';
    final urlName = urlPath.split('/').last;
    final sourceName = fileName?.trim().isNotEmpty == true
        ? fileName!.trim()
        : urlName;
    final safeName = sourceName
        .replaceAll(RegExp(r'[\\/:*?"<>|]'), '_')
        .replaceAll(RegExp(r'\s+'), ' ');
    final extension = urlName.contains('.')
        ? urlName.substring(urlName.lastIndexOf('.'))
        : '';
    if (safeName.isEmpty) return 'course_file$extension';
    if (extension.isEmpty) return safeName;
    return safeName.toLowerCase().endsWith(extension.toLowerCase())
        ? safeName
        : '$safeName$extension';
  }
}
