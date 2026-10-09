import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../network/md_cmd.dart';
import '../network/md_post.dart';
import 'update_alert.dart';

part 'update_server.g.dart';

@JsonSerializable(createToJson: false)
class AppUpdateInfo {
  const AppUpdateInfo({
    required this.title,
    required this.content,
    required this.isCoerce,
    required this.downloadUrl,
  });

  final String title;
  final String content;

  @JsonKey(name: 'is_coerce', fromJson: _isCoerceFromJson)
  final bool isCoerce;

  @JsonKey(name: 'download_url')
  final String? downloadUrl;

  factory AppUpdateInfo.fromJson(Map<String, dynamic> json) =>
      _$AppUpdateInfoFromJson(json);

  static AppUpdateInfo? fromResult(MDResult result) {
    if (!result.isSuccess || result.data == null) return null;

    final data = result.data!;
    if (data.isEmpty) return null;

    return AppUpdateInfo.fromJson(data);
  }
}

bool _isCoerceFromJson(Object? value) =>
    value == 1 || value?.toString().trim() == '1';

class UpdateServer {
  UpdateServer._();

  static bool _checking = false;
  static bool _checked = false;

  static Future<void> checkAndShow(BuildContext context) async {
    if (_checking || _checked) return;
    _checking = true;
    try {
      // type =1 android, type=2 ios, type=3 harmonyOS
      // TODO: 2024-06-05 目前只支持安卓和iOS，暂不支持鸿蒙
      final String type = Theme.of(context).platform == TargetPlatform.android
          ? '1'
          : '2';
      final result = await MDPost.sendApiSession(cmd: MDCmd.version, params: {'type': type});
      if (!result.isSuccess) return;
      _checked = true;
      if (!context.mounted) return;

      final update = AppUpdateInfo.fromResult(result);
      if (update != null) {
        await UpdateAlert.show(context, update: update);
      }
    } finally {
      _checking = false;
    }
  }
}
