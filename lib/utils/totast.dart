import 'package:flutter/widgets.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

class MDTotast {
  MDTotast._();

  static int _loadingCount = 0;
  static int _dismissGeneration = 0;
  static void Function()? _pendingStatus;

  static void showLoading([String message = '加载中...']) {
    _loadingCount++;
    EasyLoading.show(status: message);
  }

  static void error(String message) {
    ++_dismissGeneration;
    if (_loadingCount > 0) {
      _pendingStatus = () => EasyLoading.showError(message);
      return;
    }
    EasyLoading.showError(message);
  }

  static void success(String message) {
    ++_dismissGeneration;
    if (_loadingCount > 0) {
      _pendingStatus = () => EasyLoading.showSuccess(message);
      return;
    }
    EasyLoading.showSuccess(message);
  }

  static void message(String message) {
    ++_dismissGeneration;
    if (_loadingCount > 0) {
      _pendingStatus = () => EasyLoading.showToast(message);
      return;
    }
    EasyLoading.showToast(message);
  }

  static void hideLoading() {
    if (_loadingCount > 0) {
      _loadingCount--;
    }
    if (_loadingCount != 0) return;

    if (_pendingStatus != null) {
      final status = _pendingStatus;
      _pendingStatus = null;
      WidgetsBinding.instance.addPostFrameCallback((_) => status?.call());
      return;
    }

    final generation = ++_dismissGeneration;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (generation != _dismissGeneration || _loadingCount != 0) return;
      EasyLoading.dismiss(animation: false);
    });
  }
}
