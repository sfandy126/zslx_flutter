import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MDTotast {
  MDTotast._();

  static int _loadingCount = 0;
  static int _dismissGeneration = 0;

  static void showLoading([String message = '加载中...']) {
    _loadingCount++;
    EasyLoading.show(status: message);
  }

  static void error(String message) {
    EasyLoading.showError(message);
  }

  static void success(String message) {
    EasyLoading.showSuccess(message);
  }

  static void message(String message) {
    EasyLoading.showToast(message);
  }

  static void hideLoading() {
    if (_loadingCount > 0) {
      _loadingCount--;
    }
    if (_loadingCount != 0) return;

    final generation = ++_dismissGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _dismissGeneration || _loadingCount != 0) return;
      EasyLoading.dismiss(animation: false);
    });
  }
}
