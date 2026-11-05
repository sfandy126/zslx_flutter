import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

/// 刷新或加载动作的完成状态，避免业务组件依赖 easy_refresh 的结果类型。
enum RefreshCompletion { success, fail, noMore, none }

/// 刷新控制器，统一管理下拉刷新与上拉加载的状态。
class RefreshController {
  final EasyRefreshController _controller = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  void finishRefresh(RefreshCompletion result) {
    _controller.finishRefresh(_toIndicatorResult(result));
  }

  void finishLoad(RefreshCompletion result) {
    _controller.finishLoad(_toIndicatorResult(result));
  }

  void resetFooter() {
    _controller.resetFooter();
  }

  void dispose() {
    _controller.dispose();
  }

  IndicatorResult _toIndicatorResult(RefreshCompletion result) {
    return switch (result) {
      RefreshCompletion.success => IndicatorResult.success,
      RefreshCompletion.fail => IndicatorResult.fail,
      RefreshCompletion.noMore => IndicatorResult.noMore,
      RefreshCompletion.none => IndicatorResult.none,
    };
  }
}

/// 统一的下拉刷新与上拉加载容器。
///
/// 头部使用 CupertinoHeader，尾部使用 BuilderFooter。
class MDRefreshHeader extends StatelessWidget {
  const MDRefreshHeader({
    required this.controller,
    required this.child,
    this.onRefresh,
    this.onLoad,
    super.key,
  });

  final RefreshController controller;
  final Widget child;
  final Future<void> Function()? onRefresh;
  final Future<void> Function()? onLoad;

  @override
  Widget build(BuildContext context) {
    return EasyRefresh(
      controller: controller._controller,
      onRefresh: onRefresh,
      onLoad: onLoad,
      header: const CupertinoHeader(),
      footer: MDRefreshFooter._create(),
      child: child,
    );
  }
}

/// 上拉加载指示器配置，只在本文件中接触 easy_refresh 类型。
class MDRefreshFooter {
  const MDRefreshFooter._();

  static Footer _create() {
    return BuilderFooter(
      builder: (context, state) => const SizedBox.shrink(),
      triggerOffset: 60,
      clamping: false,
      processedDuration: Duration.zero,
      infiniteOffset: 60,
    );
  }
}
