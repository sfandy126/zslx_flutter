import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

/// 订单确认页：确认课程信息后生成订单
class CourseOrderConfirmPage extends StatefulWidget {
  const CourseOrderConfirmPage({
    this.type = '',
    this.id = '',
    super.key,
  });

  final String type;

  final String id;

  @override
  State<CourseOrderConfirmPage> createState() => _CourseOrderConfirmPageState();
}

class _CourseOrderConfirmPageState extends State<CourseOrderConfirmPage> {
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
        cmd: .courseOrderConfirm,
        params: {'type': widget.type, 'course_id': widget.id},
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
      Utils.log('CourseOrderConfirmPage load confirm failed: $error');
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

  /// 生成订单，成功则跳转至待支付页面
  Future<void> _toSurePay() async {
    if (_paying) return;
    if (!await _requireLogin() || !mounted) return;
    if (_model == null) return;
    setState(() => _paying = true);
    MDTotast.showLoading();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseGenerateOrder,
        params: {'course_id': widget.id, 'type': widget.type},
      );
      MDTotast.hideLoading();
      if (!mounted) return;
      setState(() => _paying = false);
      if (!result.isSuccess) {
        if (result.state == .outed) {
          await AppRouter.pushNamed<void>(context, RouterNames.login);
          return;
        }
        MDTotast.error(result.msg ?? '生成订单失败');
        return;
      }
      final orderId = (result.data?['order_id'] ?? '').toString().trim();
      if (orderId.isEmpty) {
        MDTotast.error(result.msg ?? '生成订单失败');
        return;
      }
      final paid = await AppRouter.pushNamed<bool>(
        context,
        RouterNames.courseOrderPay,
        queryParameters: {'orderId': orderId},
      );
      if (!mounted) return;
      // 支付成功返回课程详情页并触发刷新
      if (paid == true) AppRouter.pop(context, true);
    } catch (error) {
      Utils.log('CourseOrderConfirmPage generate order failed: $error');
      MDTotast.hideLoading();
      if (!mounted) return;
      setState(() => _paying = false);
      MDTotast.error('生成订单失败，请稍后重试');
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
                  child: MDAppBar(title: '订单确认', centerTitle: false),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: _buildBody(model),
              ),
            ),
            if (model != null) _BottomBar(model: model, onPay: _toSurePay),
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
        children: [_CourseCard(model: model)],
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

class _PayCourse {
  const _PayCourse({
    required this.title,
    required this.photo,
    required this.keshi,
    required this.money,
    required this.realMoney,
  });

  final String title;
  final String photo;
  final String keshi;
  final String money;
  final String realMoney;

  factory _PayCourse.fromJson(Map<String, dynamic> json) {
    Object? value(List<String> keys) {
      for (final key in keys) {
        if (json[key] != null) return json[key];
      }
      return null;
    }

    String text(List<String> keys) => value(keys)?.toString() ?? '';
    return _PayCourse(
      title: text(const ['title']),
      photo: text(const ['photo']),
      keshi: text(const ['keshi']),
      money: text(const ['money']),
      realMoney: text(const ['real_money']),
    );
  }
}
