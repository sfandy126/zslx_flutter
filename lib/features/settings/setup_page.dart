import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/dialog.dart';

class SetupPage extends StatefulWidget {
  const SetupPage({super.key});

  @override
  State<SetupPage> createState() => _SetupPageState();
}

class _SetupPageState extends State<SetupPage> {
  late final SetupViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = SetupViewModel();
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
        final items = _viewModel.items;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: const CustomAppBar(title: '设置'),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.only(top: 16),
              children: [
                for (var i = 0; i < items.length; i++)
                  _ListCell(
                    item: items[i],
                    isFirst: i == 0,
                    isLast: i == items.length - 1,
                    onTap: () => _handleTap(items[i]),
                  ),
                if (_viewModel.isLoggedIn) _OutCell(onTap: _handleLogout),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleTap(SetupItem item) {
    switch (item.type) {
      case .info:
        AppRouter.pushNamed(context, RouterNames.info);
      case .version:
        _viewModel.openAppStore();
      case .account:
        AppRouter.pushNamed(context, RouterNames.safe);
      case .about:
        AppRouter.pushNamed(context, RouterNames.about);
      case .cache:
        _viewModel.clearAllCache();
    }
  }

  Future<void> _handleLogout() async {
    if (!_viewModel.isLoggedIn) return;
    final confirmed = await MDDialog.show(
      context,
      content: '退出后将不能查看订单，确定退出吗？',
    );
    if (!confirmed || !mounted) return;
    final success = await _viewModel.logout();
    if (!mounted || !success) return;
    AppRouter.pop(context, true);
  }
}

enum SetupType {
  version('当前版本'),
  info('个人信息'),
  account('账号安全'),
  about('关于我们'),
  cache('清除缓存');

  const SetupType(this.title);

  final String title;
}

class SetupItem {
  const SetupItem(this.type, {this.subtitle});

  final SetupType type;
  final String? subtitle;
}

class SetupViewModel extends ChangeNotifier {
  SetupViewModel() {
    MDUser.defualt.addListener(_handleUserChanged);
  }

  MDUser get user => MDUser.defualt;

  bool get isLoggedIn => user.islogined;

  /// 未登录时隐藏个人信息与账号安全
  List<SetupItem> get items {
    final info = AppConfig.packageInfo;
    return [
      SetupItem(.version, subtitle: '${info.version}(${info.buildNumber})'),
      if (isLoggedIn) ...[const SetupItem(.info), const SetupItem(.account)],
      const SetupItem(.about),
      const SetupItem(.cache),
    ];
  }

  Future<bool> logout() async {
    Totast.showLoading();
    final result = await MDPost.sendApiSession(cmd: .logout);
    Totast.hideLoading();
    if (result.isSuccess) {
      Totast.showSuccess(result.msg ?? '退出成功');
      await user.logout();
      return true;
    }

    Totast.showError(result.msg ?? '退出失败，请稍后重试');
    return false;
  }

  Future<void> openAppStore() async {
    if (!Platform.isIOS) return;
    final url = Uri.parse(MDEnv.urlAppstore);
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: .externalApplication);
    }
  }

  /// 清除图片缓存、WebView 缓存与 Cookie、临时目录文件
  Future<void> clearAllCache() async {
    Totast.showLoading('清除中...');
    PaintingBinding.instance.imageCache
      ..clear()
      ..clearLiveImages();
    try {
      final controller = WebViewController();
      await controller.clearCache();
      await controller.clearLocalStorage();
      await WebViewCookieManager().clearCookies();
    } catch (error) {
      debugPrint('SetupViewModel clear web cache error: $error');
    }
    try {
      final directory = await getTemporaryDirectory();
      if (directory.existsSync()) {
        for (final entity in directory.listSync()) {
          try {
            entity.deleteSync(recursive: true);
          } catch (_) {
            // 系统占用的文件删除失败时忽略
          }
        }
      }
    } catch (error) {
      debugPrint('SetupViewModel clear temp directory error: $error');
    }
    Totast.hideLoading();
    Totast.showSuccess('清除完成');
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

class _ListCell extends StatelessWidget {
  const _ListCell({
    required this.item,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final SetupItem item;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  static const _radius = Radius.circular(12);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? _radius : Radius.zero,
      bottom: isLast ? _radius : Radius.zero,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Material(
        color: AppColors.white,
        borderRadius: borderRadius,
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    item.type.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.title,
                      fontSize: 14,
                      fontWeight: .w500,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                if (item.subtitle?.isNotEmpty ?? false) ...[
                  Text(
                    item.subtitle!,
                    style: TextStyle(
                      color: AppColors.content,
                      fontSize: 13,
                      fontWeight: .w400,
                    ),
                  ),
                  const SizedBox(width: 4),
                ],
                Assets.images.public.arrowRight.svg(width: 12, height: 12),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _OutCell extends StatelessWidget {
  const _OutCell({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Material(
        color: AppColors.white,
        shape: const StadiumBorder(),
        clipBehavior: Clip.antiAlias,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              '退出登录',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.title,
                fontSize: 14,
                fontWeight: .w500,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
