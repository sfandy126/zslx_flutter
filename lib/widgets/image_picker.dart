import 'package:flutter/widgets.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

/// 图片选择器封装。
class MDImagePicker {
  MDImagePicker._();

  static const _textDelegate = AssetPickerTextDelegate();

  /// 多选图片，返回本地文件路径；取消或未选时返回空列表
  static Future<List<String>> pickImages(
    BuildContext context, {
    int max = 9,
  }) async {
    final assets = await _pick(
      context,
      AssetPickerConfig(
        maxAssets: max,
        requestType: RequestType.image,
        textDelegate: _textDelegate,
      ),
    );
    if (assets == null || assets.isEmpty) return const [];
    final paths = <String>[];
    for (final asset in assets.take(max)) {
      final file = await asset.originFile;
      if (file != null) paths.add(file.path);
    }
    return paths;
  }

  /// 单选图片，返回本地文件路径；取消时返回 null
  static Future<String?> pickImage(BuildContext context) async {
    final assets = await _pick(
      context,
      const AssetPickerConfig(
        maxAssets: 1,
        requestType: RequestType.image,
        textDelegate: _textDelegate,
      ),
    );
    if (assets == null || assets.isEmpty) return null;
    final file = await assets.first.originFile;
    return file?.path;
  }

  static Future<List<AssetEntity>?> _pick(
    BuildContext context,
    AssetPickerConfig config,
  ) {
    return AssetPicker.pickAssets(context, pickerConfig: config);
  }
}
