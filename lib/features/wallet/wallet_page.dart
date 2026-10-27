import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../logins/guest_login_dialog.dart';
import '../pay/storekit.dart';

/// 钱包页：iOS 内购充值
class WalletPage extends StatefulWidget {
  const WalletPage({super.key});

  @override
  State<WalletPage> createState() => _WalletPageState();
}

class _WalletPageState extends State<WalletPage> {
  _WalletData? _model;
  int _selectedIndex = 0;
  StreamSubscription<void>? _storeKitSubscription;

  _Good? get _selectedGood {
    final list = _model?.list ?? const <_Good>[];
    if (_selectedIndex < 0 || _selectedIndex >= list.length) return null;
    return list[_selectedIndex];
  }

  @override
  void initState() {
    super.initState();
    _loadData(loading: true);
    _storeKitSubscription = MDStoreKit.changes.listen((_) => _loadData());
  }

  @override
  void dispose() {
    _storeKitSubscription?.cancel();
    super.dispose();
  }

  Future<void> _loadData({bool loading = false}) async {
    if (loading) MDTotast.showLoading();
    final result = await MDPost.sendIapSession(cmd: .iapProducts);
    if (loading) MDTotast.hideLoading();
    if (!mounted) return;
    if (!result.isSuccess) {
      MDTotast.error(result.msg ?? 'ERROR：数据返回错误');
      return;
    }
    final model = _WalletData.fromJson(result.data);
    setState(() {
      _model = model;
      if (_selectedIndex >= model.list.length) _selectedIndex = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(
                    title: '钱包',
                    actions: [
                      PlatformTextButton(
                        onPressed: _openOrders,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          '消费明细',
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 14,
                            decoration: .none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: RefreshIndicator(
                  onRefresh: _loadData,
                  color: AppColors.theme,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _BalanceCard(balance: _formattedBalance(_model?.money)),
                      const SizedBox(height: 24),
                      Center(
                        child: Text(
                          '选择充值档位',
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 16,
                            fontWeight: .w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _TierGrid(
                        list: _model?.list ?? const [],
                        selectedIndex: _selectedIndex,
                        onSelected: (index) {
                          if (index == _selectedIndex) return;
                          setState(() => _selectedIndex = index);
                        },
                      ),
                      const SizedBox(height: 24),
                      const _TipCard(),
                    ],
                  ),
                ),
              ),
            ),
            _BottomBar(good: _selectedGood, onPay: _payMethod),
          ],
        ),
      ),
    );
  }

  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    return mounted && MDUser.defualt.islogined;
  }

  Future<void> _openOrders() async {
    if (!MDUser.defualt.islogined) {
      if (await _requireLogin()) _loadData();
      return;
    }
    AppRouter.pushNamed<void>(context, RouterNames.walletOrder);
  }

  Future<void> _payMethod() async {
    final good = _selectedGood;
    if (good == null) {
      MDTotast.message('请选择充值档位');
      return;
    }
    if (!MDUser.defualt.islogined) {
      if (!await GuestLoginDialog.show(context) || !mounted) return;
      _loadData();
    }
    _startPay(good);
  }

  void _startPay(_Good good) {
    if (good.pId.isEmpty) {
      MDTotast.error('商品id不存在，请联系客服');
      return;
    }
    MDStoreKit.start(good.pId);
  }

  static String _formattedBalance(String? value) {
    final number = double.tryParse(value ?? '');
    if (number == null) return (value?.isEmpty ?? true) ? '0' : value!;
    final digits = number.round().abs().toString();
    final buffer = StringBuffer(number < 0 ? '-' : '');
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(',');
      buffer.write(digits[i]);
    }
    return buffer.toString();
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.balance});

  final String balance;

  @override
  Widget build(BuildContext context) {
    final subStyle = TextStyle(
      color: AppColors.white.withValues(alpha: 0.9),
      fontSize: 14,
    );
    return Container(
      height: 120,
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.theme, AppColors.deepTheme],
        ),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text('我的学豆余额', style: subStyle),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: .baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  balance,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 34,
                    fontWeight: .bold,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text('学豆', style: subStyle),
            ],
          ),
        ],
      ),
    );
  }
}

class _TierGrid extends StatelessWidget {
  const _TierGrid({
    required this.list,
    required this.selectedIndex,
    required this.onSelected,
  });

  static const _columns = 3;
  static const _spacing = 12.0;

  final List<_Good> list;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    if (list.isEmpty) return const SizedBox.shrink();
    final rows = (list.length + _columns - 1) ~/ _columns;
    return Column(
      children: [
        for (var row = 0; row < rows; row++) ...[
          if (row > 0) const SizedBox(height: _spacing),
          Row(
            children: [
              for (var column = 0; column < _columns; column++) ...[
                if (column > 0) const SizedBox(width: _spacing),
                Expanded(child: _cell(row * _columns + column)),
              ],
            ],
          ),
        ],
      ],
    );
  }

  Widget _cell(int index) {
    if (index >= list.length) return const SizedBox(height: 84);
    return _TierCell(
      good: list[index],
      selected: index == selectedIndex,
      onTap: () => onSelected(index),
    );
  }
}

class _TierCell extends StatelessWidget {
  const _TierCell({
    required this.good,
    required this.selected,
    required this.onTap,
  });

  final _Good good;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        height: 84,
        decoration: BoxDecoration(
          color: selected
              ? AppColors.theme.withValues(alpha: 0.08)
              : AppColors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? AppColors.theme : AppColors.border,
          ),
        ),
        child: Column(
          mainAxisAlignment: .center,
          children: [
            Text(
              good.xb.isEmpty ? '0' : good.xb,
              style: TextStyle(
                color: AppColors.title,
                fontSize: 20,
                fontWeight: .bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              '学豆',
              style: TextStyle(color: AppColors.content, fontSize: 11),
            ),
            const SizedBox(height: 6),
            Text(
              good.price,
              style: TextStyle(
                color: AppColors.theme,
                fontSize: 13,
                fontWeight: .w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// 重要提示卡片（黄色边框）
class _TipCard extends StatelessWidget {
  const _TipCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.warningBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.warningBorder),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            '⚠️ 重要提示',
            style: TextStyle(
              color: AppColors.warningTitle,
              fontSize: 14,
              fontWeight: .w600,
            ),
          ),
          const SizedBox(height: 8),
          // 文案不得出现 Apple Pay/苹果支付等表述（会被审核判定为内购项目错误标注为 Apple Pay），统一使用「App 内购买项目」
          Text(
            '1. 学豆为App内购买项目，Apple收取25%的手续费，实际支付金额以App Store结算页显示为准;\n'
            '2. 学豆不支持退款、提现，仅限在iPhone/iPad上使用',
            style: TextStyle(color: AppColors.warningContent, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

/// 底部固定栏：已选档位 + 立即充值
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.good, required this.onPay});

  final _Good? good;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    final good = this.good;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: AppColors.black.withValues(alpha: 0.06),
            offset: const Offset(0, -2),
            blurRadius: 6,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Column(
            mainAxisSize: .min,
            crossAxisAlignment: .start,
            children: [
              if (good != null)
                Text.rich(
                  TextSpan(
                    text: '已选：${good.xb.isEmpty ? '0' : good.xb} 学豆 ',
                    style: TextStyle(color: AppColors.content, fontSize: 13),
                    children: [
                      TextSpan(
                        text: good.price,
                        style: TextStyle(
                          color: AppColors.theme,
                          fontSize: 18,
                          fontWeight: .bold,
                        ),
                      ),
                    ],
                  ),
                  maxLines: 1,
                ),
              const SizedBox(height: 6),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: PlatformElevatedButton(
                  onPressed: onPay,
                  color: AppColors.theme,
                  material: (_, _) => MaterialElevatedButtonData(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.theme,
                      foregroundColor: AppColors.white,
                      shape: const StadiumBorder(),
                      elevation: 0,
                      shadowColor: AppColors.transparent,
                    ),
                  ),
                  cupertino: (_, _) => CupertinoElevatedButtonData(
                    borderRadius: BorderRadius.circular(24),
                    minimumSize: const Size(double.infinity, 48),
                    sizeStyle: CupertinoButtonSize.small,
                  ),
                  child: Text(
                    '⚡ 立即充值',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 16,
                      fontWeight: .w600,
                      decoration: .none,
                      decorationColor: AppColors.transparent,
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

class _WalletData {
  const _WalletData({required this.money, required this.list});
  final String money;
  final List<_Good> list;

  factory _WalletData.fromJson(Map<String, dynamic>? json) {
    final list = json?['list'];
    return _WalletData(
      money: json?['money']?.toString() ?? '0',
      list: list is List
          ? list.whereType<Map>().map(_Good.fromJson).toList()
          : const [],
    );
  }
}

/// 充值档位
class _Good {
  const _Good({required this.pId, required this.xb, required this.money});
  final String pId;
  final String xb;
  final String money;

  String get price => money.isEmpty ? '¥0' : money.mdToPrice();

  factory _Good.fromJson(Map json) {
    return _Good(
      pId: json['p_id']?.toString() ?? '',
      xb: json['xb']?.toString() ?? '',
      money: json['money']?.toString() ?? '',
    );
  }
}
