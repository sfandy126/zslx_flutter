import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../utils/utils.dart';
import 'app_router.dart';

class NotFoundPage extends StatelessWidget {
  const NotFoundPage({super.key});

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.white,
            child: SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: MDAppBar(
                  title: '页面不存在',
                  onBackPressed: () => _backToMain(context),
                ),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                top: false,
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Assets.images.public.stateEmpty3x.image(
                        width: 228,
                        height: 188,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        '页面走丢了~',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 14,
                          decoration: TextDecoration.none,
                        ),
                      ),
                      const SizedBox(height: 20),
                      GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () => _backToMain(context),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.theme,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '回到首页',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// 404 页可能被冷启动直达（路由栈中只有当前页），返回时兜底回到首页
  void _backToMain(BuildContext context) {
    final router = GoRouter.of(context);
    if (router.canPop()) {
      router.pop();
    } else {
      router.goNamed(RouterNames.main.routeName);
    }
  }
}
