import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

/// 登录方式弹窗：账号登录 / 游客登录
class GuestLoginDialog extends StatefulWidget {
  const GuestLoginDialog({super.key});

  /// 显示弹窗，账号登录或游客登录成功返回 true，取消或登录失败返回 false
  static Future<bool> show(BuildContext context) async {
    final result = await showGeneralDialog<_LoginMethod>(
      context: context,
      barrierDismissible: false,
      barrierLabel: 'GuestLoginDialog',
      barrierColor: AppColors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) =>
          const GuestLoginDialog(),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: child,
          ),
    );
    if (result == .account && context.mounted) {
      await AppRouter.pushNamed<void>(context, RouterNames.login);
    }
    return context.mounted && MDUser.defualt.islogined;
  }

  @override
  State<GuestLoginDialog> createState() => _GuestLoginDialogState();
}

enum _LoginMethod { account, guest }

class _GuestLoginDialogState extends State<GuestLoginDialog> {
  static const double _padding = 36;
  static const double _tabletWidth = 320;

  bool _isLoading = false;

  Future<void> _guestLogin() async {
    if (_isLoading) return;
    _isLoading = true;
    MDTotast.showLoading();
    try {
      final uuid = await MDUser.readForGuest();
      final result = await MDPost.sendApiSession(
        cmd: .loginGuest,
        params: {'uuid': uuid ?? ''},
      );
      if (!result.isSuccess) {
        MDTotast.showError(result.msg ?? '游客登录失败');
        return;
      }
      await MDUser.defualt.login(result.data);
      await MDUser.saveForGuest(uuid);
      if (mounted) Navigator.of(context).pop(_LoginMethod.guest);
    } catch (error) {
      Utils.log('GuestLoginDialog guest login failed: $error');
      MDTotast.showError('游客登录失败，请稍后重试');
    } finally {
      MDTotast.hideLoading();
      _isLoading = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        child: SizedBox(
          width: isTablet ? _tabletWidth : double.infinity,
          child: Material(
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            clipBehavior: Clip.antiAlias,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 20),
              child: Column(
                mainAxisSize: .min,
                crossAxisAlignment: .stretch,
                children: [
                  Text(
                    '登录方式',
                    textAlign: .center,
                    style: TextStyle(
                      color: AppColors.black,
                      fontSize: 20,
                      fontWeight: .w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '使用账号登录，可享受跨平台权益；游客登录只会绑定当前设备。',
                    textAlign: .center,
                    style: TextStyle(
                      color: AppColors.content,
                      fontSize: 14,
                      fontWeight: .w500,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 20),
                  _LoginButton(
                    text: '账号登录(推荐)',
                    isPrimary: true,
                    onPressed: () =>
                        Navigator.of(context).pop(_LoginMethod.account),
                  ),
                  const SizedBox(height: 16),
                  _LoginButton(text: '游客登录', onPressed: _guestLogin),
                  const SizedBox(height: 16),
                  _LoginButton(
                    text: '取消',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LoginButton extends StatelessWidget {
  const _LoginButton({
    required this.text,
    required this.onPressed,
    this.isPrimary = false,
  });

  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isPrimary ? AppColors.theme : AppColors.background,
          foregroundColor: isPrimary ? AppColors.white : AppColors.black,
          padding: EdgeInsets.zero,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: .w500),
        ),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
