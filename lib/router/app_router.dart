import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/logins/login_page.dart';
import '../features/starts/start_page.dart';
import '../features/starts/tabbar_page.dart';
import '../features/web/web_page.dart';
import 'router_names.dart';

class AppRouter {
  static const String login = RouterNames.login;
  static const String main = RouterNames.main;

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

  static void goNamed(
    BuildContext context,
    String name, {
    Map<String, String> queryParameters = const {},
  }) {
    GoRouter.of(context).goNamed(name, queryParameters: queryParameters);
  }

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: RouterNames.home,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const StartPage()),
      ),
      GoRoute(
        path: '/main',
        name: RouterNames.main,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const TabbarPage()),
      ),
      GoRoute(
        path: '/login',
        name: RouterNames.login,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/web',
        name: RouterNames.web,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: WebPage(
            url: state.uri.queryParameters['url'],
            title: state.uri.queryParameters['title'] ?? '',
          ),
        ),
      ),
    ],
  );

  static Page<T> _platformPage<T>({
    required LocalKey key,
    required Widget child,
  }) {
    if (defaultTargetPlatform == TargetPlatform.iOS) {
      return _NoBackGestureCupertinoPage<T>(key: key, child: child);
    }
    return MaterialPage<T>(key: key, child: child);
  }
}

class _NoBackGestureCupertinoPage<T> extends Page<T> {
  const _NoBackGestureCupertinoPage({required super.key, required this.child});

  final Widget child;

  @override
  Route<T> createRoute(BuildContext context) {
    return _NoBackGestureCupertinoPageRoute<T>(
      settings: this,
      builder: (_) => child,
    );
  }
}

class _NoBackGestureCupertinoPageRoute<T> extends CupertinoPageRoute<T> {
  _NoBackGestureCupertinoPageRoute({
    required super.builder,
    required super.settings,
  });

  @override
  bool get popGestureEnabled => false;
}
