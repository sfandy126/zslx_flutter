import 'package:flutter_easyloading/flutter_easyloading.dart';

class MDTotast {
  MDTotast._();

  static void showLoading([String message = '加载中...']) {
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
    EasyLoading.dismiss();
  }
}
