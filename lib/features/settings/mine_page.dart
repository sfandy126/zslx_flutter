import 'dart:math' as math;

import 'package:provider/provider.dart';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zslx_flutter/router/app_router.dart';

import '../../utils/utils.dart';
import '../../widgets/refresh_header.dart';
import '../../widgets/page_background.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key, required this.onOpenCourses});

  final VoidCallback onOpenCourses;

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  late final MineViewModel _viewModel;
  final RefreshController _refreshController = RefreshController();

  @override
  void initState() {
    super.initState();
    _viewModel = MineViewModel()..initialize();
  }

  @override
  void dispose() {
    _refreshController.dispose();
    _viewModel.dispose();
    super.dispose();
  }

  Future<void> _handleRefresh() async {
    MDTotast.showLoading();
    try {
      await _viewModel.refresh();
      if (mounted) _refreshController.finishRefresh(RefreshCompletion.success);
    } catch (error) {
      if (mounted) _refreshController.finishRefresh(RefreshCompletion.fail);
      MDTotast.error(error.toString());
    } finally {
      MDTotast.hideLoading();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _viewModel,
      child: Consumer<MineViewModel>(
        builder: (context, model, child) {
          return Scaffold(
            body: MDPageBackground(
              child: SafeArea(
                child: MDRefreshHeader(
                  controller: _refreshController,
                  onRefresh: _handleRefresh,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(24, 10, 24, 28),
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '我的',
                              style: TextStyle(
                                fontSize: 30,
                                fontWeight: FontWeight.w800,
                                color: _MineColors.ink,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            height: 36,
                            child: Transform.translate(
                              offset: const Offset(6, 0),
                              child: IconButton(
                                tooltip: '设置',
                                onPressed: () => AppRouter.pushNamed(
                                  context,
                                  RouterNames.setup,
                                ),
                                style: IconButton.styleFrom(
                                  backgroundColor: AppColors.white.withValues(
                                    alpha: 0.65,
                                  ),
                                  fixedSize: const Size(32, 32),
                                  minimumSize: const Size(32, 32),
                                  padding: EdgeInsets.zero,
                                  tapTargetSize:
                                      MaterialTapTargetSize.shrinkWrap,
                                  shape: const CircleBorder(),
                                ),
                                icon: SvgPicture.asset(
                                  'assets/images/mine/zs_fn_settings.svg',
                                  width: 22,
                                  height: 22,
                                ),
                                splashColor: AppColors.transparent,
                                highlightColor: AppColors.transparent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '今天，也向前一步',
                              style: TextStyle(
                                color: AppColors.content,
                                fontSize: 14,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 32,
                            child: Transform.translate(
                              offset: const Offset(6, 0),
                              child: Center(
                                child: CustomPaint(
                                  size: const Size(16, 16),
                                  painter: _MineDecorationPainter(
                                    color: _MineColors.spark,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 26),
                      _card(
                        onTap: _handleHeaderTap,
                        transparent: true,
                        child: Row(
                          children: [
                            _Avatar(avatar: model.avatar),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '卓仕遴选 · 学员中心',
                                    style: TextStyle(
                                      color: AppColors.content,
                                      fontSize: 12,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    model.displayName,
                                    style: TextStyle(
                                      color: _MineColors.ink,
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    _maskedPhone,
                                    style: TextStyle(color: AppColors.content),
                                  ),
                                ],
                              ),
                            ),
                            Icon(Icons.chevron_right, color: AppColors.content),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      _card(
                        onTap: widget.onOpenCourses,
                        blue: true,
                        child: Stack(
                          children: [
                            Positioned(
                              right: 0,
                              top: 0,
                              child: SvgPicture.asset(
                                'assets/images/mine/zs_my_learning_orbit.svg',
                                width: 100,
                              ),
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'LEARNING SPACE',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    letterSpacing: 2,
                                    fontSize: 11,
                                  ),
                                ),
                                const SizedBox(height: 14),
                                Text(
                                  '我的学习空间',
                                  style: TextStyle(
                                    color: AppColors.white,
                                    fontSize: 27,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  '把目标，变成下一步。',
                                  style: TextStyle(color: AppColors.white),
                                ),
                                const SizedBox(height: 12),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _MineColors.gold,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '进入我的课程 ↗',
                                      style: TextStyle(
                                        color: _MineColors.learningButtonText,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w400,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _entry(
                              '课程订单',
                              'orders',
                              _openOrders,
                              subtitle: '查看购买记录',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _entry(
                              '我的收藏',
                              'favorites',
                              _openFavorites,
                              subtitle: '收藏的课程',
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              '备考工具箱',
                              style: TextStyle(
                                color: _MineColors.ink,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          CustomPaint(
                            size: const Size(10, 10),
                            painter: _MineDecorationPainter(
                              color: AppColors.deepTheme,
                              rays: true,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 18),
                      Row(
                        children: [
                          Expanded(
                            child: _entry(
                              '听课记录',
                              'history',
                              () => AppRouter.pushNamed(
                                context,
                                RouterNames.learnHistory,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _entry(
                              '讲义汇总',
                              'materials',
                              () => _pending('讲义汇总'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _entry(
                              '一对一约课',
                              'reservation',
                              () => AppRouter.pushNamed<void>(
                                context,
                                RouterNames.coursePrebookList,
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _entry(
                              '约课记录',
                              'appointments',
                              () => AppRouter.pushNamed<void>(
                                context,
                                RouterNames.coursePrebookRecords,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Column(
                          children: [
                            _entry(
                              '我的钱包',
                              'wallet',
                              _openWallet,
                              grouped: true,
                            ),
                            _toolDivider(),
                            _entry(
                              '在线客服',
                              'support',
                              _callCustomerService,
                              grouped: true,
                            ),
                            _toolDivider(),
                            _entry(
                              '意见反馈',
                              'feedback',
                              () => AppRouter.pushNamed(
                                context,
                                RouterNames.feedback,
                              ),
                              grouped: true,
                            ),
                            _toolDivider(),
                            _entry(
                              '设置',
                              'settings',
                              () => AppRouter.pushNamed(
                                context,
                                RouterNames.setup,
                              ),
                              grouped: true,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 26),
                      Text(
                        '卓仕遴选  ·  专注遴选，陪伴成长',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 10,
                          letterSpacing: 2,
                          height: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  String get _maskedPhone {
    final phone = _viewModel.user.phone ?? '';
    return phone.length == 11
        ? '${phone.substring(0, 3)}****${phone.substring(7)}'
        : '';
  }

  void _pending(String feature) {
    // #TODO: 接入新增功能的页面跳转。
    MDTotast.message('$feature，敬请期待');
  }

  Widget _card({
    required Widget child,
    required VoidCallback onTap,
    bool blue = false,
    bool transparent = false,
    double radius = 22,
  }) => Material(
    color: transparent
        ? AppColors.transparent
        : blue
        ? _MineColors.learningStart
        : AppColors.white,
    borderRadius: BorderRadius.circular(radius),
    clipBehavior: Clip.antiAlias,
    child: Ink(
      decoration: BoxDecoration(
        gradient: blue
            ? const LinearGradient(
                colors: [_MineColors.learningStart, _MineColors.learningEnd],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )
            : null,
      ),
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        highlightColor: AppColors.transparent,
        child: Padding(
          padding: EdgeInsets.all(transparent ? 0 : 18),
          child: child,
        ),
      ),
    ),
  );

  Widget _entry(
    String title,
    String icon,
    VoidCallback onTap, {
    String? subtitle,
    bool grouped = false,
  }) => _card(
    radius: grouped ? 0 : 22,
    onTap: onTap,
    child: Row(
      children: [
        Container(
          width: subtitle == null ? 40 : 24,
          height: subtitle == null ? 40 : 24,
          padding: EdgeInsets.all(subtitle == null ? 8 : 0),
          decoration: BoxDecoration(
            color: subtitle == null
                ? _toolBackground(icon)
                : AppColors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: SvgPicture.asset(
            'assets/images/mine/zs_fn_$icon.svg',
            width: 24,
            height: 24,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: _MineColors.ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: TextStyle(color: AppColors.content, fontSize: 10),
                ),
              ],
            ],
          ),
        ),
        if (grouped || subtitle != null)
          Assets.images.public.arrowRight.svg(
            width: 16,
            height: 16,
            colorFilter: grouped
                ? ColorFilter.mode(AppColors.theme, BlendMode.srcIn)
                : null,
          ),
      ],
    ),
  );

  Widget _toolDivider() => ColoredBox(
    color: AppColors.white,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Divider(height: 1, thickness: 1, color: _MineColors.divider),
    ),
  );

  Color _toolBackground(String icon) => switch (icon) {
    'history' => _MineColors.toolBlue,
    'materials' || 'support' => _MineColors.toolTeal,
    'reservation' || 'feedback' || 'wallet' => _MineColors.toolPeach,
    _ => _MineColors.toolPurple,
  };

  void _handleHeaderTap() {
    if (_viewModel.isLoggedIn) {
      AppRouter.pushNamed(context, .info).then((_) {
        _viewModel.refresh();
      });
    } else {
      AppRouter.pushNamed<bool>(context, .login).then((result) {
        if (result == true) {
          _viewModel.refresh();
        }
      });
    }
  }

  void _openOrders() {
    if (!_viewModel.isLoggedIn) {
      _handleHeaderTap();
      return;
    }
    AppRouter.pushNamed(context, RouterNames.courseOrderList);
  }

  void _openFavorites() {
    if (!_viewModel.isLoggedIn) {
      _handleHeaderTap();
      return;
    }
    AppRouter.pushNamed(context, RouterNames.favorites);
  }

  void _openWallet() {
    AppRouter.pushNamed(context, RouterNames.wallet);
  }

  Future<void> _callCustomerService() async {
    final uri = Uri(scheme: 'tel', path: MDEnv.telephone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      return;
    }
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar});

  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final value = avatar?.trim();

    return Container(
      width: 64,
      height: 64,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _MineColors.ink.withValues(alpha: 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: value == null || value.isEmpty
            ? DecoratedBox(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [_MineColors.avatarStart, _MineColors.avatarEnd],
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 23,
                    height: 23,
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: AppColors.deepTheme,
                        width: 1.5,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      Icons.person_outline_rounded,
                      size: 21,
                      color: AppColors.deepTheme,
                    ),
                  ),
                ),
              )
            : MDNetImage(imageUrl: value, isAvatar: true),
      ),
    );
  }
}

class MineViewModel extends ChangeNotifier {
  MineViewModel() {
    MDUser.defualt.addListener(_handleUserChanged);
  }

  MDUser get user => MDUser.defualt;
  bool _disposed = false;

  bool get isLoggedIn => user.islogined;

  String get displayName {
    if (!isLoggedIn) return '点击登录';
    final nickname = user.nick?.trim();
    return nickname == null || nickname.isEmpty ? '学无止境' : nickname;
  }

  String? get avatar => user.avatar;

  bool _isRefreshing = false;
  bool get isRefreshing => _isRefreshing;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    if (_isRefreshing) return;
    _isRefreshing = true;
    if (!_disposed) notifyListeners();

    try {
      await user.updateData();
    } finally {
      _isRefreshing = false;
      if (!_disposed) notifyListeners();
    }
  }

  void _handleUserChanged() {
    if (!_disposed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _isRefreshing = false;
    MDUser.defualt.removeListener(_handleUserChanged);
    super.dispose();
  }
}

/// 设计稿中的四角星和八向放射装饰。
class _MineDecorationPainter extends CustomPainter {
  const _MineDecorationPainter({required this.color, this.rays = false});
  final Color color;
  final bool rays;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final radius = size.shortestSide / 2;
    final paint = Paint()..color = color;
    if (rays) {
      paint
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round;
      for (var i = 0; i < 4; i++) {
        final angle = i * math.pi / 4;
        final delta = Offset(math.cos(angle), math.sin(angle)) * radius;
        canvas.drawLine(center - delta, center + delta, paint);
      }
    } else {
      final path = Path()..moveTo(center.dx, 0);
      path.quadraticBezierTo(
        center.dx + radius * 0.25,
        center.dy - radius * 0.25,
        size.width,
        center.dy,
      );
      path.quadraticBezierTo(
        center.dx + radius * 0.25,
        center.dy + radius * 0.25,
        center.dx,
        size.height,
      );
      path.quadraticBezierTo(
        center.dx - radius * 0.25,
        center.dy + radius * 0.25,
        0,
        center.dy,
      );
      path.quadraticBezierTo(
        center.dx - radius * 0.25,
        center.dy - radius * 0.25,
        center.dx,
        0,
      );
      canvas.drawPath(path..close(), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _MineDecorationPainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.rays != rays;
}

/// 仅供“我的”页面及其内部组件使用的颜色。
class _MineColors {
  _MineColors._();

  static const avatarStart = Color(0xFFF5F7FF);
  static const avatarEnd = Color(0xFFCCD7FF);
  static const toolBlue = Color(0xFFE6F1FF);
  static const toolTeal = Color(0xFFDCF8F2);
  static const toolPeach = Color(0xFFFFF0E8);
  static const toolPurple = Color(0xFFF0E9FF);
  static const divider = Color(0xFFD5E6FA);
  static const spark = Color(0xFFED9209);
  static const ink = Color(0xFF102D50);
  static const learningStart = Color(0xFF287FF0);
  static const learningEnd = Color(0xFF43ADF0);
  static const learningButtonText = Color(0xFF60450F);
  static const gold = Color(0xFFFFDA77);
}
