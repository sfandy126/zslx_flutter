import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../pay/alipay.dart';
import '../pay/wxpay.dart';

/// 待支付订单页：展示订单信息并发起支付
class CourseOrderPayPage extends StatefulWidget {
  const CourseOrderPayPage({
    this.orderId = '',
    super.key,
  });

  /// 订单 id
  final String orderId;

  @override
  State<CourseOrderPayPage> createState() => _CourseOrderPayPageState();
}

class _CourseOrderPayPageState extends State<CourseOrderPayPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  _PayOrder? _model;
  bool _loading = false;
  String? _loadError;
  bool _paying = false;
  int _request = 0;

  /// 当前选中的支付方式
  _PayType _payType = _PayType.alipay;
  Timer? _countdown;
  DateTime? _deadline;
  int _remainSeconds = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
  }

  @override
  void dispose() {
    _countdown?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    final request = ++_request;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    MDTotast.showLoading();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .coursePayment,
        params: {'order_id': widget.orderId},
      );
      if (!mounted || request != _request) return;
      if (!result.isSuccess) {
        setState(() {
          _loading = false;
          _loadError = result.msg ?? '订单信息加载失败';
        });
        MDTotast.showError(result.msg ?? '订单信息加载失败');
        return;
      }
      final model = _PayOrder.fromJson(result.data ?? const {});
      setState(() {
        _model = model;
        _loading = false;
      });
      _startCountdown(model.surplusTime);
    } catch (error) {
      Utils.log('CourseOrderPayPage load order failed: $error');
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _loadError = '订单信息加载失败，请稍后重试';
      });
      MDTotast.showError('订单信息加载失败，请稍后重试');
    } finally {
      MDTotast.hideLoading();
    }
  }

  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    return mounted && MDUser.defualt.islogined;
  }

  /// 确认支付：校验登录后调用 get_pay 拉起支付宝/微信支付
  Future<void> _toPay() async {
    if (_paying || _model == null) return;
    if (!await _requireLogin() || !mounted) return;

    setState(() => _paying = true);
    MDTotast.showLoading();
    MDResult result;
    try {
      result = await MDPost.sendApiSession(
        cmd: .courseGetPay,
        params: {'order_id': widget.orderId, 'pay_type': _payType.value},
      );
    } catch (error) {
      Utils.log('CourseOrderPayPage get pay failed: $error');
      MDTotast.hideLoading();
      if (!mounted) return;
      setState(() => _paying = false);
      MDTotast.showError('支付发起失败，请稍后重试');
      return;
    }
    MDTotast.hideLoading();
    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _paying = false);
      if (result.state == .outed) {
        await AppRouter.pushNamed<void>(context, RouterNames.login);
        return;
      }
      final msg = result.msg ?? '支付发起失败';
      // 免费购买、已购买等场景不会返回支付参数，提示后直接进入订单列表
      if (const {'购买成功', '该课程已购买', '该订单已被删除'}.contains(msg)) {
        MDTotast.showMessage(msg);
        await AppRouter.pushNamed<void>(context, RouterNames.courseOrderList);
        return;
      }
      MDTotast.showError(msg);
      return;
    }

    final message = await _launchPay(result.data?['pay']);
    if (!mounted) return;
    setState(() => _paying = false);
    if (message != null) {
      MDTotast.showError(message);
      return;
    }
    // 支付成功：进入订单列表，返回时由订单列表页过滤订单确认、待支付页面
    MDTotast.showSuccess('支付成功');
    await AppRouter.pushNamed<void>(context, RouterNames.courseOrderList);
  }

  /// 拉起支付，返回 null 表示支付成功，否则返回需要提示的文案
  Future<String?> _launchPay(Object? pay) async {
    if (_payType == _PayType.alipay) {
      final order = pay is String ? pay.trim() : '';
      if (order.isEmpty) return '支付信息返回数据错误';
      try {
        return await Alipay.pay(order);
      } catch (error) {
        Utils.log('CourseOrderPayPage alipay failed: $error');
        return '支付失败，请稍后重试';
      }
    }
    final params = pay is Map
        ? pay.map((key, value) => MapEntry(key.toString(), value))
        : const <String, dynamic>{};
    if (params.isEmpty) return '支付信息返回数据错误';
    try {
      return await WxPay.pay(params);
    } catch (error) {
      Utils.log('CourseOrderPayPage wxpay failed: $error');
      return '支付失败，请稍后重试';
    }
  }

  /// 开启订单锁定倒计时，结束后自动返回上一页
  void _startCountdown(String surplusTime) {
    _countdown?.cancel();
    final seconds = double.tryParse(surplusTime.trim())?.toInt() ?? 0;
    if (seconds <= 0) {
      if (_remainSeconds != 0) setState(() => _remainSeconds = 0);
      return;
    }
    _deadline = DateTime.now().add(Duration(seconds: seconds));
    setState(() => _remainSeconds = seconds);
    _countdown = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
  }

  void _tick() {
    if (!mounted) {
      _countdown?.cancel();
      return;
    }
    final deadline = _deadline;
    if (deadline == null) return;
    final remain = deadline.difference(DateTime.now()).inSeconds;
    if (remain > 0) {
      if (remain != _remainSeconds) setState(() => _remainSeconds = remain);
      return;
    }
    _countdown?.cancel();
    setState(() => _remainSeconds = 0);
    // 支付中或页面不在栈顶时不自动返回
    if (_paying || !(ModalRoute.of(context)?.isCurrent ?? false)) return;
    MDTotast.showMessage('订单已超时');
    _back();
  }

  /// 返回：跳过路由栈中的订单确认页，直接回到课程详情页
  void _back() => AppRouter.popOrderFlow(context);

  @override
  Widget build(BuildContext context) {
    final model = _model;
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
                      title: '待支付',
                      centerTitle: false,
                      onBackPressed: _back,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ColoredBox(
                  color: AppColors.background,
                  child: _buildBody(model),
                ),
              ),
              if (model != null) _BottomBar(model: model, onPay: _toPay),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(_PayOrder? model) {
    if (_loading && model == null) {
      return const SizedBox.expand();
    }
    if (model == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError ?? '订单信息加载失败',
              style: TextStyle(color: AppColors.content, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadData, child: const Text('重新加载')),
          ],
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: AppColors.theme,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        children: [
          if (_remainSeconds > 0) ...[
            _CountdownCard(seconds: _remainSeconds),
            const SizedBox(height: 12),
          ],
          _CourseCard(model: model),
          const SizedBox(height: 12),
          _OrderCard(model: model),
          const SizedBox(height: 12),
          _PayMethodCard(
            payType: _payType,
            onChanged: (value) => setState(() => _payType = value),
          ),
        ],
      ),
    );
  }
}

/// 支付方式
enum _PayType {
  alipay('ali', '支付宝支付'),
  wechat('wx', '微信支付');

  const _PayType(this.value, this.label);

  final String value;

  final String label;
}

/// 订单支付倒计时
class _CountdownCard extends StatelessWidget {
  const _CountdownCard({required this.seconds});

  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Text(
            '待支付：',
            style: TextStyle(color: AppColors.content, fontSize: 14),
          ),
          Text(
            _format(seconds),
            style: TextStyle(
              color: AppColors.price,
              fontSize: 14,
              fontWeight: .w600,
            ),
          ),
        ],
      ),
    );
  }

  /// 秒数格式化为 HH:mm:ss，小时不封顶（如 25:00:00）
  static String _format(int seconds) {
    String two(int value) => value.toString().padLeft(2, '0');
    final hours = seconds ~/ 3600;
    final minutes = seconds % 3600 ~/ 60;
    return '${two(hours)}:${two(minutes)}:${two(seconds % 60)}';
  }
}

/// 支付方式卡
class _PayMethodCard extends StatelessWidget {
  const _PayMethodCard({required this.payType, required this.onChanged});

  final _PayType payType;
  final ValueChanged<_PayType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          Text(
            '支付方式',
            style: TextStyle(
              color: AppColors.title,
              fontSize: 14,
              fontWeight: .w600,
            ),
          ),
          _PayMethodRow(
            label: _PayType.alipay.label,
            selected: payType == _PayType.alipay,
            onTap: () => onChanged(_PayType.alipay),
          ),
          // 微信支付在 iOS 端未开启（pubspec.yaml fluwx.no_pay），仅 Android 支持
           _PayMethodRow(
              label: _PayType.wechat.label,
              selected: payType == _PayType.wechat,
              onTap: () => onChanged(_PayType.wechat),
            ),
        ],
      ),
    );
  }
}

/// 支付方式单选行
class _PayMethodRow extends StatelessWidget {
  const _PayMethodRow({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 44,
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(color: AppColors.title, fontSize: 14),
              ),
            ),
            selected
                ? Assets.images.public.select.svg(width: 16, height: 16)
                : Assets.images.public.unselect.svg(width: 16, height: 16),
          ],
        ),
      ),
    );
  }
}

/// 课程信息卡
class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.model});

  final _PayOrder model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 140,
              height: 91,
              child: MDNetImage(imageUrl: model.photo),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: SizedBox(
              height: 91,
              child: Column(
                crossAxisAlignment: .start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    model.title,
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: TextStyle(
                      color: AppColors.title,
                      fontSize: 15,
                      fontWeight: .w600,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '共${model.keshi}课时',
                          maxLines: 1,
                          overflow: .ellipsis,
                          style: TextStyle(
                            color: AppColors.theme,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        model.money.mdToOldPrice(),
                        style: TextStyle(
                          color: AppColors.price,
                          fontSize: 13,
                          fontWeight: .w600,
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
    );
  }
}

/// 订单信息卡
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.model});

  final _PayOrder model;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        crossAxisAlignment: .start,
        children: [
          Text(
            '订单编号',
            style: TextStyle(color: AppColors.content, fontSize: 13),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              model.tradeNo,
              maxLines: 1,
              overflow: .ellipsis,
              textAlign: TextAlign.right,
              style: TextStyle(color: AppColors.title, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

/// 底部支付栏
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.model, required this.onPay});

  final _PayOrder model;
  final VoidCallback onPay;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  '合计：¥${model.realMoney}',
                  style: TextStyle(
                    color: AppColors.price,
                    fontSize: 18,
                    fontWeight: .w500,
                  ),
                ),
              ),
              FilledButton(
                onPressed: onPay,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.theme,
                  minimumSize: const Size(112, 40),
                  shape: const StadiumBorder(),
                ),
                child: Text(
                  '确认支付',
                  style: TextStyle(
                    color: AppColors.white,
                    fontSize: 15,
                    fontWeight: .w500,
                    decoration: .none,
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

/// 待支付订单数据
class _PayOrder {
  const _PayOrder({
    required this.title,
    required this.photo,
    required this.keshi,
    required this.money,
    required this.realMoney,
    required this.tradeNo,
    required this.surplusTime,
  });

  final String title;
  final String photo;
  final String keshi;
  final String money;
  final String realMoney;
  final String tradeNo;
  final String surplusTime; // 订单锁定倒计时

  factory _PayOrder.fromJson(Map<String, dynamic> json) {
    Object? value(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    String text(List<String> keys) => value(keys)?.toString() ?? '';
    return _PayOrder(
      title: text(const ['title']),
      photo: text(const ['photo']),
      keshi: text(const ['keshi']),
      money: text(const ['money']),
      realMoney: text(const ['real_money']),
      tradeNo: text(const ['out_trade_no',]),
      surplusTime: text(const ['surplus_time']),
    );
  }
}
