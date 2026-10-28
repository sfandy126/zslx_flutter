import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../features/courses/course_detail_page.dart';
import '../features/courses/course_files_page.dart';
import '../features/courses/course_folder_page.dart';
import '../features/courses/course_ios_orderlist_page.dart';
import '../features/courses/course_ios_orderpay_page.dart';
import '../features/courses/course_list_page.dart';
import '../features/courses/course_orderconfirm_page.dart';
import '../features/courses/course_orderlist_page.dart';
import '../features/courses/course_orderpay_page.dart';
import '../features/courses/course_prebook_page.dart';
import '../features/courses/course_search_page.dart';
import '../features/courses/course_history_page.dart';
import '../features/logins/bind_page.dart';
import '../features/logins/favorites_page.dart';
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
import '../features/video/video_page.dart';
import '../features/wallet/wallet_order.dart';
import '../features/wallet/wallet_page.dart';
import '../features/web/web_page.dart';
import 'not_found_page.dart';

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
  courseList,
  courseSearch,
  courseDetail,
  courseFolder,
  courseFiles,
  coursePrebook,
  courseIosPay,
  courseOrderConfirm,
  courseOrderPay,
  courseOrderList,
  courseIosOrderList,
  learnHistory,
  favorites,
  video,
  feedback,
  web,
  setup,
  wallet,
  walletOrder,
  about;

  String get routeName => name;
}

class AppRouter {
  static Future<T?> pushNamed<T>(
    BuildContext context,
    RouterNames name, {
    Map<String, String> queryParameters = const {},
  }) {
    return GoRouter.of(context)
        .pushNamed<T>(name.routeName, queryParameters: queryParameters);
  }

  static void pop<T>(BuildContext context, [T? result]) {
    GoRouter.of(context).pop(result);
  }

  static bool maybePop<T>(BuildContext context, [T? result]) {
    final router = GoRouter.of(context);
    if (!router.canPop()) return false;
    router.pop(result);
    return true;
  }

  /// 返回上一页，并跳过路由栈中连续的订单确认页、待支付页
  ///
  /// 支付成功进入订单列表后，返回时不再回到待支付、订单确认页
  static void popOrderFlow(BuildContext context) {
    final router = GoRouter.of(context);
    if (!router.canPop()) return;
    final skipNames = {
      RouterNames.courseOrderConfirm.routeName,
      RouterNames.courseOrderPay.routeName,
    };
    final matches = router.routerDelegate.currentConfiguration.matches;
    var count = 1; // 当前页面本身
    for (final match in matches.reversed.skip(1)) {
      final route = match.route;
      if (route is! GoRoute || !skipNames.contains(route.name)) break;
      count++;
    }
    for (var index = 0; index < count; index++) {
      if (!router.canPop()) return;
      router.pop();
    }
  }

  static void goNamed(
    BuildContext context,
    RouterNames name, {
    Map<String, String> queryParameters = const {},
  }) {
    GoRouter.of(context)
        .goNamed(name.routeName, queryParameters: queryParameters);
  }

  static final GoRouter router = GoRouter(
    // 未匹配到任何路由时统一进入 404 页面
    errorBuilder: (context, state) => const NotFoundPage(),
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
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: BindPage(
            token: state.uri.queryParameters['token'],
            userId: state.uri.queryParameters['userId'],
          ),
        ),
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
        path: '/course-list',
        name: RouterNames.courseList.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseListPage(
            initialType: state.uri.queryParameters['type'] ?? 'gk',
          ),
        ),
      ),
      GoRoute(
        path: '/course-search',
        name: RouterNames.courseSearch.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const CourseSearchPage()),
      ),
      GoRoute(
        path: '/course-detail',
        name: RouterNames.courseDetail.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseDetailPage(
            id: state.uri.queryParameters['id'] ?? '',
            type: state.uri.queryParameters['type'] ?? '',
            orderId: state.uri.queryParameters['orderId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/course-folder',
        name: RouterNames.courseFolder.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseFolderPage(
            courseId: state.uri.queryParameters['courseId'] ?? '',
            courseType: state.uri.queryParameters['courseType'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/course-files',
        name: RouterNames.courseFiles.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseFilesPage(
            folderId: state.uri.queryParameters['folderId'] ?? '',
            folderName: state.uri.queryParameters['folderName'] ?? '',
            courseId: state.uri.queryParameters['courseId'] ?? '',
            courseType: state.uri.queryParameters['courseType'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/course-prebook',
        name: RouterNames.coursePrebook.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CoursePrebookPage(
            id: state.uri.queryParameters['id'] ?? '',
            orderId: state.uri.queryParameters['orderId'] ?? '',
            name: state.uri.queryParameters['name'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/course-iospay',
        name: RouterNames.courseIosPay.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseIosPayPage(
            type: state.uri.queryParameters['type'] ?? '',
            id: state.uri.queryParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/course-order-list',
        name: RouterNames.courseOrderList.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: Platform.isIOS
              ? const CourseIosOrderListPage()
              : const CourseOrderListPage(),
        ),
      ),
      GoRoute(
        path: '/course-order-confirm',
        name: RouterNames.courseOrderConfirm.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseOrderConfirmPage(
            type: state.uri.queryParameters['type'] ?? '',
            id: state.uri.queryParameters['id'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/course-order-pay',
        name: RouterNames.courseOrderPay.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: CourseOrderPayPage(
            orderId: state.uri.queryParameters['orderId'] ?? '',
          ),
        ),
      ),
      GoRoute(
        path: '/video',
        name: RouterNames.video.routeName,
        pageBuilder: (context, state) => _platformPage(
          key: state.pageKey,
          child: VideoPage(
            url: state.uri.queryParameters['url'] ?? '',
            title: state.uri.queryParameters['title'] ?? '',
            courseTitle: state.uri.queryParameters['courseTitle'] ?? '',
            cover: state.uri.queryParameters['cover'] ?? '',
            courseId: state.uri.queryParameters['courseId'] ?? '',
            courseType: state.uri.queryParameters['courseType'] ?? '',
            sectionId: state.uri.queryParameters['sectionId'] ?? '',
            sectionType: state.uri.queryParameters['sectionType'] ?? '',
            sectionCourseId: state.uri.queryParameters['sectionCourseId'] ?? '',
            seekTime:
                int.tryParse(state.uri.queryParameters['seekTime'] ?? '') ?? 0,
          ),
        ),
      ),
      GoRoute(
        path: '/learn-history',
        name: RouterNames.learnHistory.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const CourseHistoryPage()),
      ),
      GoRoute(
        path: '/favorites',
        name: RouterNames.favorites.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const FavoritesPage()),
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
        path: '/wallet',
        name: RouterNames.wallet.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const WalletPage()),
      ),
      GoRoute(
        path: '/wallet-order',
        name: RouterNames.walletOrder.routeName,
        pageBuilder: (context, state) =>
            _platformPage(key: state.pageKey, child: const WalletOrderPage()),
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
            shareType: WebShareType.values
                .asNameMap()[state.uri.queryParameters['shareType']],
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
