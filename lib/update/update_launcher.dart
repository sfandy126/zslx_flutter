import 'dart:io';

import 'package:dio/dio.dart';
import 'package:install_plugin_v3/install_plugin_v3.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';

class UpdateLauncher {
  UpdateLauncher._();

  static Future<void> openAppStore(String appStoreUrl) async {
    final uri = Uri.tryParse(appStoreUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        !{'https', 'itms-apps'}.contains(uri.scheme)) {
      throw Exception('App Store 跳转链接无效');
    }
    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched) throw Exception('无法打开 App Store');
  }

  static Future<void> downloadAndInstall(
    String downloadUrl, {
    required void Function(double progress) onProgress,
    required void Function() onInstalling,
  }) async {
    final uri = Uri.tryParse(downloadUrl);
    if (uri == null ||
        !uri.hasAuthority ||
        !{'http', 'https'}.contains(uri.scheme)) {
      throw Exception('升级地址无效');
    }

    final directory = await getTemporaryDirectory();
    final apkPath = '${directory.path}${Platform.pathSeparator}app_update.apk';
    await Dio().download(
      uri.toString(),
      apkPath,
      deleteOnError: true,
      onReceiveProgress: (received, total) {
        if (total > 0) onProgress((received / total).clamp(0.0, 1.0));
      },
    );

    onInstalling();
    final result = await InstallPlugin.installApk(apkPath);
    if (result is Map && result['isSuccess'] != true) {
      throw Exception(result['errorMessage']?.toString() ?? '安装失败');
    }
  }
}
