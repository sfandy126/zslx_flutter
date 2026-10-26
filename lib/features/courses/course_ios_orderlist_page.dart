import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

/// ios课程订单页面
class CourseIosOrderListPage extends StatefulWidget {
  const CourseIosOrderListPage({super.key});

  @override
  State<CourseIosOrderListPage> createState() => _CourseIosOrderListPageState();
}

class _CourseIosOrderListPageState extends State<CourseIosOrderListPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<_CourseOrder>>();

  Future<RefreshResult<_CourseOrder>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseIosOrders,
        params: {'p': page},
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
      Utils.log('CourseIosOrderListPage load failed: $error');
      return RefreshResult.failed('课程订单加载失败，请下拉刷新重试');
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
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
                      child: _OrderCard(order: order),
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
  const _OrderCard({required this.order});

  static const double _coverWidth = 140;
  static const double _coverHeight = _coverWidth * 0.65;

  final _CourseOrder order;

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
                  imageUrl: order.picture,
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
                        order.name,
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
                            '共${order.hours}课时',
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
            value: order.realMoney.mdToPrice(),
            valueColor: AppColors.red,
            valueBold: true,
          ),
          const SizedBox(height: 12),
          _InfoRow(name: '订单编号', value: order.code),
          const SizedBox(height: 12),
          _InfoRow(name: '支付时间', value: order.payTime),
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
    required this.code,
    required this.payTime,
    required this.name,
    required this.picture,
    required this.money,
    required this.realMoney,
    required this.hours,
  });

  final String code;
  final String payTime;
  final String name;
  final String picture;
  final String money;
  final String realMoney;
  final int hours;

  factory _CourseOrder.fromJson(Map<String, dynamic> json) {
    Object? value(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    String text(List<String> keys) => value(keys)?.toString() ?? '';
    return _CourseOrder(
      code: text(const ['trade_no']),
      payTime: text(const ['zf_time']),
      name: text(const ['name']),
      picture: text(const ['img']),
      money: text(const ['jg']),
      realMoney: text(const ['r_money']),
      hours: int.tryParse(value(const ['ks'])?.toString() ?? '') ?? 0,
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
