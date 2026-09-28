import 'package:flutter_easyloading/flutter_easyloading.dart';

class Totast {
  Totast._();

  static void showLoading([String message = '加载中...']) {
    EasyLoading.show(status: message);
  }

  static void showError(String message) {
    EasyLoading.showError(message);
  }

  static void showSuccess(String message) {
    EasyLoading.showSuccess(message);
  }

  static void hideLoading() {
    EasyLoading.dismiss();
  }
}
