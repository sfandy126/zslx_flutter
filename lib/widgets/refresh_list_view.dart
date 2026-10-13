import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';

import '../gen/assets.gen.dart';
import '../utils/app_colors.dart';
import '../utils/totast.dart';

/// 列表加载状态
enum RefreshListStatus {
  /// 首次加载中
  loading,

  /// 请求成功（有数据）
  success,

  /// 请求失败
  failed,

  /// 未登录
  notLoggedIn,

  /// 请求成功但数据为空
  empty,
}

/// 数据加载结果
class RefreshResult<T> {
  /// 当前状态
  final RefreshListStatus status;

  /// 数据列表（成功时返回）
  final List<T> data;

  /// 错误信息
  final String? message;

  /// 是否已无更多数据，由业务层根据接口分页信息决定。
  final bool noMore;

  const RefreshResult({
    required this.status,
    this.data = const [],
    this.message,
    this.noMore = false,
  });

  /// 快捷构造：成功
  factory RefreshResult.success(List<T> data, {bool noMore = false}) =>
      RefreshResult(
        status: data.isEmpty
            ? RefreshListStatus.empty
            : RefreshListStatus.success,
        data: data,
        noMore: noMore,
      );

  /// 快捷构造：失败
  factory RefreshResult.failed(String? message) =>
      RefreshResult(status: RefreshListStatus.failed, message: message);

  /// 快捷构造：未登录
  factory RefreshResult.notLoggedIn([String? message]) =>
      RefreshResult(status: RefreshListStatus.notLoggedIn, message: message);
}

/// 基于 easy_refresh 封装的列表组件
///
/// 支持：
/// - 下拉刷新、上拉加载更多
/// - 内部控制页码
/// - 多种状态展示：加载中、请求失败（重新加载按钮）、未登录（去登录按钮）、空数据
class RefreshListView<T> extends StatefulWidget {
  const RefreshListView({
    required this.onData,
    required this.itemBuilder,
    this.onRetry,
    this.onLogin,
    this.loginText = '去登录',
    this.emptyText = '暂无数据',
    this.failedText = '加载失败',
    this.retryText = '重新加载',
    this.padding,
    this.header,
    this.emptyBuilder,
    this.showDividers = false,
    this.dividerColor,
    this.dividerIndent = 16.0,
    super.key,
  });

  /// 数据加载回调
  ///
  /// 返回 [RefreshResult]，包含状态、数据列表和业务判断的 [RefreshResult.noMore]。
  /// - 刷新时 page 从 1 开始
  /// - 加载更多时 page 自动递增
  final Future<RefreshResult<T>> Function(int page) onData;

  /// 列表项构建器
  final Widget Function(BuildContext context, T item, int index) itemBuilder;

  /// 失败时点击重新加载的回调
  ///
  /// 如果不设置，默认触发内部刷新。
  final VoidCallback? onRetry;

  /// 未登录时点击"去登录"的回调
  final VoidCallback? onLogin;

  /// 去登录按钮文案，默认"去登录"
  final String loginText;

  /// 空数据提示文案，默认"暂无数据"
  final String emptyText;

  /// 失败提示文案，默认"加载失败"
  final String failedText;

  /// 重新加载按钮文案，默认"重新加载"
  final String retryText;

  /// 列表内边距
  final EdgeInsetsGeometry? padding;

  /// 列表顶部的固定内容，始终位于数据和状态视图之前。
  final Widget? header;

  /// 空数据或未登录时的自定义内容。
  final Widget Function(BuildContext context)? emptyBuilder;

  /// 是否显示列表项分割线，默认 false
  final bool showDividers;

  /// 分割线颜色
  final Color? dividerColor;

  /// 分割线左侧缩进
  final double dividerIndent;

  @override
  State<RefreshListView<T>> createState() => RefreshListViewState<T>();
}

class RefreshListViewState<T> extends State<RefreshListView<T>> {
  final EasyRefreshController _refreshController = EasyRefreshController(
    controlFinishRefresh: true,
    controlFinishLoad: true,
  );

  final List<T> _items = [];
  int _page = 1;
  bool _noMore = false;
  bool _isRefreshing = false;
  bool _isLoadingMore = false;
  bool _isLoadingToastVisible = false;
  int _requestGeneration = 0;
  RefreshListStatus _status = RefreshListStatus.loading;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _initialLoad();
    });
  }

  @override
  void dispose() {
    _requestGeneration += 1;
    _hideLoadingToast();
    _refreshController.dispose();
    super.dispose();
  }

  /// 外部调用：重置并重新加载
  void refresh() {
    if (!mounted) return;
    _requestGeneration++;
    _isRefreshing = false;
    _isLoadingMore = false;
    _refreshController.resetFooter();
    _loadFirstPage(showLoading: true, finishRefresh: false);
  }

  /// 外部调用：设置状态（用于外部控制登录态等场景）
  void setStatus(RefreshListStatus status, {String? message}) {
    if (!mounted) return;
    setState(() {
      _status = status;
      _errorMessage = message;
    });
  }

  /// 当前页码
  int get currentPage => _page;

  /// 当前数据列表
  List<T> get items => List.unmodifiable(_items);

  Future<void> _initialLoad() {
    return _loadFirstPage(showLoading: true, finishRefresh: false);
  }

  Future<void> _onRefresh() {
    return _loadFirstPage(showLoading: false, finishRefresh: true);
  }

  Future<void> _loadFirstPage({
    required bool showLoading,
    required bool finishRefresh,
  }) async {
    if (_isRefreshing) return;

    _isRefreshing = true;
    final generation = ++_requestGeneration;
    _showLoadingToast();
    if (finishRefresh) _refreshController.resetFooter();

    if (showLoading) {
      setState(() {
        _status = RefreshListStatus.loading;
        _errorMessage = null;
      });
    }

    try {
      final result = await widget.onData(1);
      if (!mounted || generation != _requestGeneration) return;

      setState(() {
        _status = result.status;
        _errorMessage = result.message;
        _noMore = result.noMore;
        switch (result.status) {
          case RefreshListStatus.success:
            _items
              ..clear()
              ..addAll(result.data);
            _page = result.data.isEmpty ? 1 : 2;
          case RefreshListStatus.empty:
          case RefreshListStatus.notLoggedIn:
            _items.clear();
            _page = 1;
          case RefreshListStatus.loading:
          case RefreshListStatus.failed:
            break;
        }
      });

      if (finishRefresh) {
        final succeeded =
            result.status == RefreshListStatus.success ||
            result.status == RefreshListStatus.empty;
        _refreshController.finishRefresh(
          succeeded ? IndicatorResult.success : IndicatorResult.fail,
        );
      }
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() {
        _status = RefreshListStatus.failed;
        _errorMessage = error.toString();
      });
      if (finishRefresh) {
        _refreshController.finishRefresh(IndicatorResult.fail);
      }
    } finally {
      if (generation == _requestGeneration) {
        _isRefreshing = false;
        _hideLoadingToast();
      }
    }
  }

  Future<void> _onLoad() async {
    if (_noMore) {
      _refreshController.finishLoad(IndicatorResult.noMore);
      return;
    }
    if (_items.isEmpty || _page <= 1) {
      _refreshController.finishLoad(IndicatorResult.none);
      return;
    }
    if (_isRefreshing || _isLoadingMore) {
      _refreshController.finishLoad(IndicatorResult.none);
      return;
    }

    _isLoadingMore = true;
    final generation = _requestGeneration;
    final requestedPage = _page;

    try {
      final result = await widget.onData(requestedPage);
      if (!mounted || generation != _requestGeneration) return;

      final isSuccess = result.status == RefreshListStatus.success;
      final hasNoMore = result.noMore;

      setState(() {
        if (isSuccess) {
          _items.addAll(result.data);
          if (result.data.isNotEmpty) _page = requestedPage + 1;
        }
        _noMore = hasNoMore;
        _errorMessage = result.message;
      });

      _refreshController.finishLoad(
        hasNoMore
            ? IndicatorResult.noMore
            : isSuccess
            ? IndicatorResult.success
            : IndicatorResult.fail,
      );
    } catch (error) {
      if (!mounted || generation != _requestGeneration) return;
      setState(() => _errorMessage = error.toString());
      _refreshController.finishLoad(IndicatorResult.fail);
    } finally {
      if (generation == _requestGeneration) _isLoadingMore = false;
    }
  }

  void _handleRetry() {
    if (widget.onRetry != null) {
      widget.onRetry!();
    } else {
      refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    final stateView = _buildCurrentStateView(context);
    final hasHeader = widget.header != null;
    final hasStateView = stateView != null;
    final hasNoMoreView = _noMore && _items.isNotEmpty && !hasStateView;
    final itemCount =
        (hasHeader ? 1 : 0) +
        (hasStateView ? 1 : _items.length + (hasNoMoreView ? 1 : 0));

    return EasyRefresh(
      controller: _refreshController,
      onRefresh: _onRefresh,
      onLoad: _onLoad,
      header: const CupertinoHeader(),
      footer: BuilderFooter(
        builder: (context, state) => const SizedBox.shrink(),
        triggerOffset: 60,
        clamping: false,
        processedDuration: Duration.zero,
        infiniteOffset: 60,
      ),
      child: ListView.separated(
        padding: widget.padding ?? const EdgeInsets.only(top: 12, bottom: 16),
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: itemCount,
        separatorBuilder: (context, index) {
          if (!widget.showDividers ||
              (hasHeader && index == 0) ||
              hasStateView ||
              (hasNoMoreView && index == itemCount - 2)) {
            return const SizedBox.shrink();
          }
          return Divider(
            height: 0.5,
            thickness: 0.5,
            color: widget.dividerColor ?? AppColors.line,
            indent: widget.dividerIndent,
          );
        },
        itemBuilder: (context, index) {
          if (hasHeader && index == 0) return widget.header!;
          if (hasStateView) return stateView;
          final itemIndex = index - (hasHeader ? 1 : 0);
          if (hasNoMoreView && itemIndex == _items.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  '没有更多',
                  style: TextStyle(
                    color: AppColors.content,
                    fontSize: 13,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            );
          }
          return widget.itemBuilder(context, _items[itemIndex], itemIndex);
        },
      ),
    );
  }

  Widget? _buildCurrentStateView(BuildContext context) {
    if (_items.isNotEmpty) return null;
    switch (_status) {
      case RefreshListStatus.loading:
        return const SizedBox.shrink();
      case RefreshListStatus.failed:
        return _buildStateView(
          illustration: Assets.images.public.stateFail3x.image(
            width: 228,
            height: 188,
            fit: BoxFit.contain,
          ),
          message: _errorMessage ?? widget.failedText,
          buttonText: widget.retryText,
          onButtonTap: _handleRetry,
        );
      case RefreshListStatus.notLoggedIn:
      case RefreshListStatus.empty:
        if (widget.emptyBuilder != null) {
          return widget.emptyBuilder!(context);
        }
        if (_status == RefreshListStatus.notLoggedIn) {
          return _buildStateView(
            illustration: Assets.images.public.stateEmpty3x.image(
              width: 228,
              height: 188,
              fit: BoxFit.contain,
            ),
            message: _errorMessage ?? '请先登录',
            buttonText: widget.loginText,
            onButtonTap: widget.onLogin,
          );
        }
        return _buildStateView(
          illustration: Assets.images.public.stateEmpty3x.image(
            width: 228,
            height: 188,
            fit: BoxFit.contain,
          ),
          message: widget.emptyText,
        );
      case RefreshListStatus.success:
        return null;
    }
  }

  void _showLoadingToast() {
    if (_isLoadingToastVisible) return;
    _isLoadingToastVisible = true;
    MDTotast.showLoading();
  }

  void _hideLoadingToast() {
    if (!_isLoadingToastVisible) return;
    _isLoadingToastVisible = false;
    MDTotast.hideLoading();
  }

  Widget _buildStateView({
    required Widget illustration,
    required String message,
    String? buttonText,
    VoidCallback? onButtonTap,
  }) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          illustration,
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.content,
              fontSize: 14,
              decoration: TextDecoration.none,
            ),
          ),
          if (buttonText != null && onButtonTap != null) ...[
            const SizedBox(height: 20),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onButtonTap,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppColors.theme,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  buttonText,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    decoration: TextDecoration.none,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
