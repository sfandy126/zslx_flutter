import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/dialog.dart';
import '../../widgets/refresh_list_view.dart';

/// 课程订单页面
class CourseOrderListPage extends StatefulWidget {
  const CourseOrderListPage({super.key});

  @override
  State<CourseOrderListPage> createState() => _CourseOrderListPageState();
}

class _CourseOrderListPageState extends State<CourseOrderListPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<_CourseOrder>>();

  Future<RefreshResult<_CourseOrder>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseOrders,
        params: {'p': page, 'status': '1'},
      );
      if (result.isSuccess) {
        final orders = _CourseOrder.listFrom(result.data?['list']);
        return RefreshResult.success(orders, noMore: orders.isEmpty);
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '课程订单加载失败');
    } catch (error) {
      Utils.log('CourseOrderListPage load failed: $error');
      return RefreshResult.failed('课程订单加载失败，请下拉刷新重试');
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  /// 校验登录，未登录时跳转登录页
  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    return mounted && MDUser.defualt.islogined;
  }

  /// 立即支付：查询订单并跳转待支付页
  Future<void> _payOrder(_CourseOrder order) async {
    if (!await _requireLogin() || !mounted) return;

    MDTotast.showLoading();
    MDResult result;
    try {
      result = await MDPost.sendApiSession(
        cmd: .courseOrderJump,
        params: {'order_id': order.orderId},
      );
    } catch (error) {
      Utils.log('CourseOrderListPage order jump failed: $error');
      MDTotast.hideLoading();
      if (mounted) MDTotast.showError('订单信息获取失败，请稍后重试');
      return;
    }
    MDTotast.hideLoading();
    if (!mounted) return;

    if (!result.isSuccess) {
      if (result.state == .outed) {
        await _openLogin();
        return;
      }
      MDTotast.showError(result.msg ?? '订单信息获取失败');
      return;
    }
    // 返回数据带有 order_id 才能进入待支付页，否则是后端返回的提示信息
    final orderId = (result.data?['order_id'] ?? '').toString().trim();
    if (orderId.isEmpty) {
      MDTotast.showMessage(result.msg ?? '订单信息异常，请稍后重试');
      return;
    }
    await AppRouter.pushNamed<void>(
      context,
      RouterNames.courseOrderPay,
      queryParameters: {'orderId': orderId},
    );
    // 从待支付页返回后刷新订单状态
    if (mounted) _listKey.currentState?.refresh();
  }

  /// 取消订单：二次确认后调用 del_order 并刷新列表
  Future<void> _cancelOrder(_CourseOrder order) async {
    if (!await _requireLogin() || !mounted) return;

    final confirmed = await MDDialog.show(context, content: '确定取消订单？');
    if (!confirmed || !mounted) return;

    MDTotast.showLoading();
    MDResult result;
    try {
      result = await MDPost.sendApiSession(
        cmd: .courseDelOrder,
        params: {'order_id': order.orderId},
      );
    } catch (error) {
      Utils.log('CourseOrderListPage delete order failed: $error');
      MDTotast.hideLoading();
      if (mounted) MDTotast.showError('取消订单失败，请稍后重试');
      return;
    }
    MDTotast.hideLoading();
    if (!mounted) return;

    if (!result.isSuccess) {
      if (result.state == .outed) {
        await _openLogin();
        return;
      }
      MDTotast.showError(result.msg ?? '取消订单失败');
      return;
    }
    MDTotast.showMessage(result.msg ?? '订单已取消');
    _listKey.currentState?.refresh();
  }

  /// 返回：过滤栈中的订单确认页、待支付页，直接回到下单前的页面
  void _back() => AppRouter.popOrderFlow(context);

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _back();
      },
      child: PlatformScaffold(
        body: DefaultTextStyle(
          style: _plainTextStyle,
          child: Column(
            children: [
              ColoredBox(
                color: AppColors.white,
                child: SafeArea(
                  bottom: false,
                  child: SizedBox(
                    height: kToolbarHeight,
                    child: MDAppBar(
                      title: '课程订单',
                      centerTitle: false,
                      onBackPressed: _back,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: AppColors.background,
                  child: RefreshListView<_CourseOrder>(
                    key: _listKey,
                    onData: _loadPage,
                    emptyText: '暂无课程订单',
                    failedText: '课程订单加载失败',
                    onLogin: _openLogin,
                    itemBuilder: (context, order, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                      child: _OrderCard(
                        order: order,
                        onPay: () => _payOrder(order),
                        onCancel: () => _cancelOrder(order),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 订单卡
class _OrderCard extends StatelessWidget {
  const _OrderCard({
    required this.order,
    required this.onPay,
    required this.onCancel,
  });

  static const double _coverWidth = 140;
  static const double _coverHeight = _coverWidth * 0.65;

  final _CourseOrder order;
  final VoidCallback onPay;
  final VoidCallback onCancel;

  /// 是否已支付：已支付不展示支付与取消订单按钮
  bool get _paid => order.paid == 1;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _coverWidth,
                height: _coverHeight,
                child: MDNetImage(
                  imageUrl: order.photo,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: SizedBox(
                  height: _coverHeight,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        order.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            '共${order.keshi}课时',
                            style: TextStyle(
                              color: AppColors.content,
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              order.money.mdToPrice(),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                color: AppColors.price,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(height: 0.5, color: AppColors.line),
          const SizedBox(height: 12),
          _InfoRow(
            name: '实际付款',
            value: order.validate.mdToPrice(),
            valueColor: AppColors.red,
            valueBold: true,
          ),
          const SizedBox(height: 12),
          _InfoRow(name: '订单编号', value: order.tradeNo),
          const SizedBox(height: 12),
          _InfoRow(
            name: _paid ? '支付时间' : '下单时间',
            value: _paid ? order.payTime : order.addTime,
          ),
          if (!_paid) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: onCancel,
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: AppColors.line),
                    minimumSize: const Size(88, 32),
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '取消订单',
                    style: TextStyle(
                      color: AppColors.content,
                      fontSize: 13,
                      decoration: .none,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilledButton(
                  onPressed: onPay,
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.theme,
                    minimumSize: const Size(88, 32),
                    padding: EdgeInsets.zero,
                    shape: const StadiumBorder(),
                  ),
                  child: Text(
                    '立即支付',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 13,
                      decoration: .none,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// 一行「名称 + 值」，值右对齐
class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.name,
    required this.value,
    this.valueColor,
    this.valueBold = false,
  });

  final String name;
  final String value;
  final Color? valueColor;
  final bool valueBold;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          name,
          style: TextStyle(color: AppColors.content, fontSize: 12),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: valueColor ?? AppColors.title,
              fontSize: valueBold ? 14 : 12,
              fontWeight: valueBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ),
      ],
    );
  }
}

/// 订单数据
class _CourseOrder {
  const _CourseOrder({
    required this.tradeNo,
    required this.orderId,
    required this.photo,
    required this.title,
    required this.money,
    required this.keshi,
    required this.validate,
    required this.addTime,
    required this.paid,
    required this.payType,
    required this.payTime,
  });

  final String tradeNo;
  final String orderId;
  final String photo;
  final String title;
  final String money;
  final String keshi;
  final String validate;
  final String addTime;
  final int paid;
  final String payType;
  final String payTime;

  factory _CourseOrder.fromJson(Map<String, dynamic> json) {
    Object? value(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    String text(List<String> keys) => value(keys)?.toString() ?? '';
    return _CourseOrder(
      tradeNo: text(const ['trade_no']),
      orderId: text(const ['order_id']),
      photo: text(const ['photo']),
      title: text(const ['title']),
      money: text(const ['money']),
      keshi: text(const ['keshi']),
      validate: text(const ['validate']),
      addTime: text(const ['add_time']),
      paid: int.tryParse(value(const ['paid'])?.toString() ?? '') ?? 0,
      payType: text(const ['pay_type']),
      payTime: text(const ['pay_time']),
    );
  }

  static List<_CourseOrder> listFrom(Object? source) {
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map(
          (item) => _CourseOrder.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}
