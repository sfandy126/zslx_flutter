import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

/// 消费明细：学豆充值/消费记录
class WalletOrderPage extends StatefulWidget {
  const WalletOrderPage({super.key});

  @override
  State<WalletOrderPage> createState() => _WalletOrderPageState();
}

class _WalletOrderPageState extends State<WalletOrderPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<_WalletOrder>>();

  Future<RefreshResult<_WalletOrder>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendIapSession(
        cmd: .iapOrders,
        params: {'p': page},
      );
      if (result.isSuccess) {
        final orders = _WalletOrder.listFrom(result.data?['list']);
        return RefreshResult.success(orders, noMore: orders.isEmpty);
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '消费明细加载失败');
    } catch (error) {
      Utils.log('WalletOrderPage load failed: $error');
      return RefreshResult.failed('消费明细加载失败，请下拉刷新重试');
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
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
                  child: MDAppBar(title: '消费明细'),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: RefreshListView<_WalletOrder>(
                  key: _listKey,
                  onData: _loadPage,
                  emptyText: '暂无消费明细',
                  failedText: '加载失败，请重试',
                  onLogin: _openLogin,
                  itemBuilder: (context, order, index) =>
                      _OrderTile(order: order),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OrderTile extends StatelessWidget {
  const _OrderTile({required this.order});

  final _WalletOrder order;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          order.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 16,
                            fontWeight: .w600,
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          order.createTime,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    order.money,
                    style: TextStyle(
                      // type == 1 为收入（充值），其余为消费
                      color: order.type == 1 ? AppColors.green : AppColors.price,
                      fontSize: 15,
                      fontWeight: .w600,
                    ),
                  ),
                ],
              ),
            ),
            Divider(height: 1, thickness: 1, color: AppColors.line),
          ],
        ),
      ),
    );
  }
}

class _WalletOrder {
  const _WalletOrder({
    required this.title,
    required this.money,
    required this.createTime,
    required this.type,
  });

  final String title;

  /// 学豆变动数量
  final String money;
  final String createTime;

  /// 1：收入（充值），其余：消费
  final int type;

  factory _WalletOrder.fromJson(Map json) {
    return _WalletOrder(
      title: json['title']?.toString() ?? '',
      money: json['money']?.toString() ?? '',
      createTime: json['create_time']?.toString() ?? '',
      type: int.tryParse(json['type']?.toString() ?? '') ?? 0,
    );
  }

  static List<_WalletOrder> listFrom(Object? value) {
    if (value is! List) return const [];
    return value.whereType<Map>().map(_WalletOrder.fromJson).toList();
  }
}
