import 'package:flutter/material.dart';
import 'package:zslx_flutter/router/app_router.dart';
import '../../utils/utils.dart';

class MinePage extends StatefulWidget {
  const MinePage({super.key});

  @override
  State<MinePage> createState() => _MinePageState();
}

class _MinePageState extends State<MinePage> {
  late final MineViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = MineViewModel()..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) {
        return PlatformScaffold(
          body: Stack(
            children: [
              Positioned.fill(
                child: Image.asset(
                  'assets/images/mine/mineBg@3x.png',
                  fit: BoxFit.cover,
                ),
              ),
              SafeArea(
                child: RefreshIndicator(
                  onRefresh: _viewModel.refresh,
                  color: AppColors.theme,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 22, 16, 28),
                    children: [
                      _MineHeader(
                        name: _viewModel.displayName,
                        avatar: _viewModel.avatar,
                        onLogin: _handleLogin,
                        onOrders: () => _showMessage('课程订单功能即将开放'),
                        onWallet: () => _showMessage('钱包功能即将开放'),
                      ),
                      const SizedBox(height: 24),
                      _MineActionTile(
                        icon: 'assets/images/mine/mineFavorites.svg',
                        title: '收藏',
                        subtitle: '喜欢的课程',
                        onTap: () => _showMessage('请先登录后查看收藏'),
                      ),
                      _MineActionTile(
                        icon: 'assets/images/mine/mineFeedback.svg',
                        title: '意见反馈',
                        subtitle: '提交问题或建议',
                        onTap: () => _showMessage('意见反馈功能即将开放'),
                      ),
                      _MineActionTile(
                        icon: 'assets/images/mine/mineOnline.svg',
                        title: '在线客服',
                        subtitle: '在线解答',
                        onTap: () => _showMessage('在线客服功能即将开放'),
                      ),
                      _MineActionTile(
                        icon: 'assets/images/mine/mineSetting.svg',
                        title: '设置',
                        subtitle: '账号、隐私与设置',
                        onTap: () => _showMessage('设置功能即将开放'),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleLogin() {
    AppRouter.pushNamed<bool>(context, AppRouter.login)
        .then((result) {
          if (result == true) {
            _viewModel.refresh();
          }
        });
  }

  void _showMessage(String message) {
    Totast.showError(message);
  }
}

class _MineHeader extends StatelessWidget {
  const _MineHeader({
    required this.name,
    required this.avatar,
    required this.onLogin,
    required this.onOrders,
    required this.onWallet,
  });

  final String name;
  final String? avatar;
  final VoidCallback onLogin;
  final VoidCallback onOrders;
  final VoidCallback onWallet;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        GestureDetector(
          onTap: onLogin,
          child: Column(
            children: [
              _Avatar(avatar: avatar),
              const SizedBox(height: 12),
              Text(
                name,
                style: TextStyle(
                  color: AppColors.title,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.none,
                  decorationColor: AppColors.transparent,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _HeaderButton(label: '课程订单', onTap: onOrders),
            const SizedBox(width: 12),
            _HeaderButton(label: '钱包', onTap: onWallet),
          ],
        ),
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.avatar});

  final String? avatar;

  @override
  Widget build(BuildContext context) {
    final value = avatar?.trim();

    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.lightTheme,
      ),
      clipBehavior: Clip.antiAlias,
      child: value == null || value.isEmpty
          ? SvgPicture.asset('assets/images/mine/defaultProfile.svg')
          : Image.network(value, fit: BoxFit.cover),
    );
  }
}

class _HeaderButton extends StatelessWidget {
  const _HeaderButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 100,
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(20),
        child: PlatformTextButton(
          onPressed: onTap,
          color: AppColors.title,
          material: (context, platform) => MaterialTextButtonData(
            style: TextButton.styleFrom(
              foregroundColor: AppColors.title,
              backgroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              minimumSize: const Size(100, 0),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          cupertino: (context, platform) => CupertinoTextButtonData(
            color: AppColors.white,
            foregroundColor: AppColors.title,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            borderRadius: BorderRadius.circular(20),
            minimumSize: const Size(100, 0),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: AppColors.title,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }
}

class _MineActionTile extends StatelessWidget {
  const _MineActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final String icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppColors.lightTheme,
                    shape: BoxShape.circle,
                  ),
                  child: SvgPicture.asset(icon),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 13,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                SvgPicture.asset(
                  'assets/images/public/arrowRight.svg',
                  width: 16,
                  height: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class MineViewModel extends ChangeNotifier {
  MineViewModel() {
    MDUser.defualt.addListener(_handleUserChanged);
  }

  MDUser get user => MDUser.defualt;

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
    notifyListeners();

    await user.updateData(
      completed: () {
        _isRefreshing = false;
        notifyListeners();
      },
    );
  }

  void _handleUserChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    MDUser.defualt.removeListener(_handleUserChanged);
    super.dispose();
  }
}