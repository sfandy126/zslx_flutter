import 'package:flutter/widgets.dart';
import 'package:wechat_camera_picker/wechat_camera_picker.dart';

/// 拍照入口，业务层仅接收本地图片路径。
class MDImageCamera {
  MDImageCamera._();

  /// 拍摄并确认照片后返回本地文件路径；取消时返回 null。
  static Future<String?> takePhoto(BuildContext context) async {
    final asset = await CameraPicker.pickFromCamera(
      context,
      pickerConfig: const CameraPickerConfig(enableRecording: false),
    );
    if (asset == null) return null;
    final file = await asset.originFile;
    return file?.path;
  }
}
