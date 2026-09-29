import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/logins/bind_page.dart';
import '../features/logins/forgot_page.dart';
import '../features/logins/info_page.dart';
import '../features/logins/login_page.dart';
import '../features/logins/nick_page.dart';
import '../features/logins/off_page.dart';
import '../features/logins/passward_page.dart';
import '../features/logins/safe_page.dart';
import '../features/settings/feedback_page.dart';
import '../features/settings/about_page.dart';
import '../features/settings/setup_page.dart';
import '../features/starts/start_page.dart';
import '../features/starts/tabbar_page.dart';
import '../features/web/web_page.dart';

enum RouterNames {
  home,
  main,
  login,
  forgotPassword,
  info,
  safe,
  nick,
  bind,
  off,
  passward,
  feedback,
  web,
  setup,
  about;

  String get routeName => name;
}

class AppRouter {
  static Future<T?> pushNamed<T>(
    BuildContext context,
    RouterNames name, {
    Map<String, String> queryParameters = const {},
  }) {
    return GoRouter.of(
      context,
    ).pushNamed<T>(name.routeName, queryParameters: queryParameters);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    GoRouter.of(context).pop(result);
  }

  static void goNamed(
    BuildContext context,
    RouterNames name, {
    Map<String, String> queryParameters = const {},
  }) {
    GoRouter.of(
      context,
    ).goNamed(name.routeName, queryParameters: queryParameters);
  }

  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        path: '/',
        name: RouterNames.home.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const StartPage()),
      ),
      GoRoute(
        path: '/main',
        name: RouterNames.main.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const TabbarPage()),
      ),
      GoRoute(
        path: '/login',
        name: RouterNames.login.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const LoginPage()),
      ),
      GoRoute(
        path: '/forgot-password',
        name: RouterNames.forgotPassword.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const ForgotPage()),
      ),
      GoRoute(
        path: '/info',
        name: RouterNames.info.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const InfoPage()),
      ),
      GoRoute(
        path: '/safe',
        name: RouterNames.safe.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const SafePage()),
      ),
      GoRoute(
        path: '/nick',
        name: RouterNames.nick.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const NickPage()),
      ),
      GoRoute(
        path: '/bind',
        name: RouterNames.bind.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const BindPage()),
      ),
      GoRoute(
        path: '/off',
        name: RouterNames.off.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const OffPage()),
      ),
      GoRoute(
        path: '/passward',
        name: RouterNames.passward.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const PasswardPage()),
      ),
      GoRoute(
        path: '/feedback',
        name: RouterNames.feedback.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const FeedbackPage()),
      ),
      GoRoute(
        path: '/setup',
        name: RouterNames.setup.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const SetupPage()),
      ),
      GoRoute(
        path: '/about',
        name: RouterNames.about.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const AboutPage()),
      ),
      GoRoute(
        path: '/web',
        name: RouterNames.web.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: WebPage(
            url: state.uri.queryParameters['url'],
            title: state.uri.queryParameters['title'] ?? '',
            disableFd: state.uri.queryParameters['disableFd'] == 'true',
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
