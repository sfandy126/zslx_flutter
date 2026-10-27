import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/dialog.dart';

/// iOS 课程下单支付页
class CourseIosPayPage extends StatefulWidget {
  const CourseIosPayPage({
    this.type = '',
    this.id = '',
    super.key,
  });

  final String type;

  final String id;

  @override
  State<CourseIosPayPage> createState() => _CourseIosPayPageState();
}

class _CourseIosPayPageState extends State<CourseIosPayPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  _PayCourse? _model;
  bool _loading = false;
  String? _loadError;
  bool _paying = false;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadData());
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
        cmd: .courseConfirmIos,
        params: {'type': widget.type, 'c_id': widget.id},
      );
      if (!mounted || request != _request) return;
      if (!result.isSuccess) {
        setState(() {
          _loading = false;
          _loadError = result.msg ?? '订单信息加载失败';
        });
        MDTotast.error(result.msg ?? '订单信息加载失败');
        return;
      }
      setState(() {
        _model = _PayCourse.fromJson(result.data ?? const {});
        _loading = false;
      });
    } catch (error) {
      Utils.log('CourseIosPayPage load confirm failed: $error');
      if (!mounted || request != _request) return;
      setState(() {
        _loading = false;
        _loadError = '订单信息加载失败，请稍后重试';
      });
      MDTotast.error('订单信息加载失败，请稍后重试');
    } finally {
      MDTotast.hideLoading();
    }
  }

  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    return mounted && MDUser.defualt.islogined;
  }

  /// 前往钱包充值，返回后刷新订单信息
  Future<void> _toRecharge() async {
    await AppRouter.pushNamed<void>(context, RouterNames.wallet);
    if (mounted) _loadData();
  }

  Future<void> _check() async {
    if (!await _requireLogin() || !mounted) return;
    final model = _model;
    if (model == null) return;
    final pay = double.tryParse(model.payMoney) ?? 0;
    final iap = double.tryParse(model.iap) ?? 0;
    if (iap <= 0 || iap < pay) {
      final toRecharge = await MDDialog.show(
        context,
        content: '余额不足，是否前往充值?',
      );
      if (toRecharge && mounted) _toRecharge();
      return;
    }
    final confirmed = await MDDialog.show(
      context,
      content: '确定购买课程:【${model.name}】,\n支付:¥${model.payMoney}？',
      contentSpan: TextSpan(
        children: [
          TextSpan(text: '确定购买课程:【${model.name}】,\n支付:'),
          TextSpan(
            text: '¥${model.payMoney}',
            style: TextStyle(color: AppColors.price),
          ),
          const TextSpan(text: '？'),
        ],
      ),
    );
    if (confirmed && mounted) _pay();
  }

  Future<void> _pay() async {
    final model = _model;
    if (model == null || _paying) return;
    setState(() => _paying = true);
    MDTotast.showLoading();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .coursPay,
        params: {'type': widget.type, 'c_id': widget.id},
      );
      MDTotast.hideLoading();
      if (!mounted) return;
      setState(() => _paying = false);
      MDTotast.message(result.msg ?? (result.isSuccess ? '支付成功' : '支付失败'));
      if (result.isSuccess) {
        await Future<void>.delayed(const Duration(milliseconds: 150));
        if (!mounted) return;
        // 返回课程详情页并触发刷新
        AppRouter.pop(context, true);
      }
    } catch (error) {
      Utils.log('CourseIosPayPage pay failed: $error');
      MDTotast.hideLoading();
      if (!mounted) return;
      setState(() => _paying = false);
      MDTotast.error('支付失败，请稍后重试');
    }
  }

  @override
  Widget build(BuildContext context) {
    final model = _model;
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
                  child: MDAppBar(title: '支付订单', centerTitle: false),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: _buildBody(model),
              ),
            ),
            if (model != null) _BottomBar(model: model, onPay: _check),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_PayCourse? model) {
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
          _CourseCard(model: model),
          const SizedBox(height: 12),
          _WalletCard(model: model, onRecharge: _toRecharge),
        ],
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.model});

  final _PayCourse model;

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
              child: MDNetImage(imageUrl: model.picture),
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
                    model.name,
                    maxLines: 2,
                    overflow: .ellipsis,
                    style: TextStyle(
                      color: AppColors.title,
                      fontSize: 15,
                      fontWeight: .w600,
                    ),
                  ),
                  Text(
                    '共${model.hour}课时',
                    style: TextStyle(color: AppColors.theme, fontSize: 13),
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

class _WalletCard extends StatelessWidget {
  const _WalletCard({required this.model, required this.onRecharge});

  final _PayCourse model;
  final VoidCallback onRecharge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            '钱包支付',
            style: TextStyle(
              color: AppColors.title,
              fontSize: 15,
              fontWeight: .bold,
            ),
          ),
          const SizedBox(height: 16),
          Container(height: 0.8, color: AppColors.line),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '余额: ${model.iap.isEmpty ? '--' : model.iap}',
                  style: TextStyle(color: AppColors.title, fontSize: 14),
                ),
              ),
              TextButton(
                onPressed: onRecharge,
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.theme,
                  side: BorderSide(color: AppColors.theme),
                  shape: const StadiumBorder(),
                  minimumSize: const Size(0, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                ),
                child: const Text('去充值', style: TextStyle(fontSize: 12)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// 底部支付栏
class _BottomBar extends StatelessWidget {
  const _BottomBar({required this.model, required this.onPay});

  final _PayCourse model;
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
                  '合计：¥${model.payMoney}',
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
                  '确定支付',
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

class _PayCourse {
  const _PayCourse({
    required this.name,
    required this.picture,
    required this.hour,
    required this.payMoney,
    required this.iap,
  });

  final String name;
  final String picture;
  final String hour;
  final String payMoney;
  final String iap;

  factory _PayCourse.fromJson(Map<String, dynamic> json) {
    Object? value(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    String text(List<String> keys) => value(keys)?.toString() ?? '';
    return _PayCourse(
      name: text(const ['name']),
      picture: text(const ['img']),
      hour: text(const ['ks']),
      payMoney: text(const ['real_money']),
      iap: text(const ['iap_money']),
    );
  }
}
