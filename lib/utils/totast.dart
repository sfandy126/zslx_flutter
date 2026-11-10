import 'dart:async';

import 'package:flutter_easyloading/flutter_easyloading.dart';

enum MDTotastResult { success, error, message }

class MDTotast {
  MDTotast._();

  static int _loadingCount = 0;
  static int _dismissGeneration = 0;
  static void Function()? _pendingStatus;

  static void showLoading([String message = '加载中...']) {
    _loadingCount++;
    _showLoading(message);
  }

  /// 更新当前加载提示文案，不改变加载层计数。
  ///
  /// 适用于同一个连续流程在不同阶段更新状态；流程结束时仍只需调用
  /// [hideLoading] 一次。
  static void updateLoading(String message) {
    if (_loadingCount == 0) {
      showLoading(message);
      return;
    }
    _showLoading(message);
  }

  static void _showLoading(String message) {
    // EasyLoading 会更新现有提示层；透明遮罩拦截页面操作。
    EasyLoading.show(
      status: message,
      maskType: EasyLoadingMaskType.clear,
      dismissOnTap: false,
      options: const EasyLoadingOptions(userInteractions: false),
    );
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

  /// 将全局加载提示直接切换为流程终态，不等待加载计数归零。
  ///
  /// EasyLoading 只有一个提示层；内购等独占流程结束时使用，避免历史计数
  /// 或其它异步加载让终态提示一直停留在队列中。
  static void completeLoading(MDTotastResult result, String message) {
    _loadingCount = 0;
    _pendingStatus = null;
    ++_dismissGeneration;
    EasyLoading.dismiss(animation: false);
    switch (result) {
      case .success:
        EasyLoading.showSuccess(
          message,
          duration: const Duration(milliseconds: 1500),
        );
      case .error:
        EasyLoading.showError(message);
      case .message:
        EasyLoading.showToast(message);
    }
  }

  static void hideLoading() {
    if (_loadingCount > 0) {
      _loadingCount--;
    }
    if (_loadingCount != 0) return;

    if (_pendingStatus != null) {
      final status = _pendingStatus;
      _pendingStatus = null;
      final generation = _dismissGeneration;
      scheduleMicrotask(() {
        if (generation != _dismissGeneration || _loadingCount != 0) return;
        status?.call();
      });
      return;
    }

    final generation = ++_dismissGeneration;
    scheduleMicrotask(() {
      if (generation != _dismissGeneration || _loadingCount != 0) return;
      EasyLoading.dismiss(animation: false);
    });
  }

  /// 立即关闭全局加载层，供拥有独占加载流程的场景在 finally 中兜底。
  static void dismissLoading() {
    _loadingCount = 0;
    _pendingStatus = null;
    ++_dismissGeneration;
    EasyLoading.dismiss(animation: false);
  }
}
