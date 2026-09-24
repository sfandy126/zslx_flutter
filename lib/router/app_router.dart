import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';

import '../features/logins/login_page.dart';
import '../features/starts/start_page.dart';
import '../features/web/web_page.dart';
import 'router_names.dart';

class AppRouter {
  static const String login = RouterNames.login;

  static Future<T?> pushNamed<T>(
    BuildContext context,
    String name, {
    Map<String, String> queryParameters = const {},
  }) {
    return GoRouter.of(
      context,
    ).pushNamed<T>(name, queryParameters: queryParameters);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    GoRouter.of(context).pop(result);
  }

  static final GoRouter router = GoRouter(
    //# TODO NoTransitionPage 关闭页面系统的手势侧滑返回功能，但没了返回动画
    routes: [
      GoRoute(
        path: '/',
        name: RouterNames.home,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: StartPage()),
      ),
      GoRoute(
        path: '/login',
        name: RouterNames.login,
        pageBuilder: (context, state) =>
            const NoTransitionPage(child: LoginPage()),
      ),
      GoRoute(
        path: '/web',
        name: RouterNames.web,
        pageBuilder: (context, state) => NoTransitionPage(
          child: WebPage(
            url: state.uri.queryParameters['url'],
            title: state.uri.queryParameters['title'] ?? '',
          ),
        ),
      ),
    ],
  );
}
