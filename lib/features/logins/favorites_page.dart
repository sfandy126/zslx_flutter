import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';
import '../article/article_card.dart';

/// 我的收藏
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({this.initialCategory = 2, super.key});

  final int initialCategory;

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _courseKey = GlobalKey<RefreshListViewState<_FavoriteCourse>>();
  final _articleKey = GlobalKey<RefreshListViewState<ArticleSummary>>();
  late int _category = widget.initialCategory;

  Future<RefreshResult<T>> _loadPage<T>(
    int page,
    int category,
    T Function(Map<String, Object?>) parse,
  ) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .collects,
        params: {'cate_id': category, 'p': page},
      );
      if (result.isSuccess) {
        final rows = result.data?['data'] ?? result.data?['list'];
        final items = rows is List
            ? rows.whereType<Map>().map((item) {
                return parse(
                  item.map((key, value) => MapEntry(key.toString(), value)),
                );
              }).toList()
            : <T>[];
        final pageInfo = result.data?.mdAs<Map<String, dynamic>>('page_info');
        final hasMore = pageInfo?.mdBool('has_more');
        return RefreshResult.success(
          items,
          noMore: items.isEmpty || hasMore == false,
        );
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '收藏加载失败，请重试');
    } catch (error) {
      Utils.log('FavoritesPage load failed: $error');
      return RefreshResult.failed('收藏加载失败，请重试');
    }
  }

  Future<void> _open(_FavoriteCourse course) async {
    if (!course.isAvailable) {
      MDTotast.error('课程已下架或下线');
      return;
    }
    await AppRouter.pushNamed<void>(
      context,
      RouterNames.courseDetail,
      queryParameters: {'id': course.id, 'type': course.type},
    );
    // 详情页可能取消收藏，返回后刷新
    if (mounted) _courseKey.currentState?.refresh();
  }

  Future<void> _cancelFavorite(
    MDCmd command,
    Map<String, String> params,
    VoidCallback remove,
  ) async {
    if (!MDUser.defualt.islogined) {
      await _openLogin();
      return;
    }
    MDTotast.showLoading();
    try {
      final result = await MDPost.sendApiSession(cmd: command, params: params);
      if (!mounted) return;
      if (!result.isSuccess) {
        MDTotast.error(result.msg ?? '取消收藏失败，请重试');
        return;
      }
      remove();
      MDTotast.success(result.msg ?? '已取消收藏');
    } catch (error) {
      Utils.log('FavoritesPage cancel favorite failed: $error');
      if (mounted) MDTotast.error('取消收藏失败，请重试');
    } finally {
      MDTotast.hideLoading();
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _courseKey.currentState?.refresh();
      _articleKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MDPageBackground(
        child: DefaultTextStyle(
          style: _plainTextStyle,
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(
                    title: '我的收藏',
                    centerTitle: false,
                    backgroundColor: AppColors.transparent,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _categoryButton(2, '课程'),
                      const SizedBox(width: 24),
                      _categoryButton(1, '资讯'),
                    ],
                  ),
                ),
                Expanded(
                  child: SlidableAutoCloseBehavior(
                    child: _category == 2 ? _buildCourses() : _buildArticles(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _categoryButton(int category, String label) {
    final selected = _category == category;
    return Semantics(
      selected: selected,
      child: OutlinedButton(
        onPressed: () {
          if (!selected) setState(() => _category = category);
        },
        style: OutlinedButton.styleFrom(
          foregroundColor: selected ? AppColors.theme : AppColors.bigTitle,
          backgroundColor: selected ? AppColors.lightTheme : AppColors.white,
          side: BorderSide(
            color: selected ? AppColors.theme : AppColors.border,
          ),
          shape: const StadiumBorder(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Text(label),
      ),
    );
  }

  Widget _buildCourses() {
    return RefreshListView<_FavoriteCourse>(
      key: _courseKey,
      onData: (page) => _loadPage(page, 2, _FavoriteCourse.fromJson),
      emptyText: '暂无收藏',
      failedText: '收藏加载失败，请重试',
      onLogin: _openLogin,
      padding: const EdgeInsets.only(bottom: 16),
      itemBuilder: (_, course, _) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: _FavoriteTile(
          course: course,
          onTap: () => _open(course),
          onCancel: () => unawaited(
            _cancelFavorite(
              .courseFavorite,
              {'id': course.id, 'type': course.type},
              () => _courseKey.currentState?.removeWhere(
                (item) => item.id == course.id && item.type == course.type,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildArticles() {
    return RefreshListView<ArticleSummary>(
      key: _articleKey,
      onData: (page) => _loadPage(page, 1, ArticleSummary.new),
      emptyText: '暂无收藏',
      failedText: '收藏加载失败，请重试',
      onLogin: _openLogin,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      itemBuilder: (_, article, _) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: _FavoriteArticleTile(
          article: article,
          onCancel: () => unawaited(
            _cancelFavorite(
              .articleFavorite,
              {'special': article.special, 'id': article.id},
              () => _articleKey.currentState?.removeWhere(
                (item) =>
                    item.id == article.id && item.special == article.special,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _FavoriteCourse {
  const _FavoriteCourse({
    this.id = '',
    this.type = '',
    this.name = '',
    this.picture = '',
    this.money = '',
    this.scan = '',
    this.isHide = 0,
    this.open = 0,
  });

  final String id;
  final String type;
  final String name;
  final String picture;
  final String money;
  final String scan;
  final int isHide;
  final int open;

  /// 未隐藏且已上线的课程才可进入详情
  bool get isAvailable => isHide != 1 && open == 1;

  factory _FavoriteCourse.fromJson(Map<String, Object?> json) {
    String pick(List<String> keys) {
      for (final key in keys) {
        final value = json[key];
        if (value != null) return value.mdToString();
      }
      return '';
    }

    return _FavoriteCourse(
      id: pick(['course_id', 'id']),
      type: json['type'].mdToString(),
      name: pick(['title', 'name']),
      picture: pick(['photo', 'picture']),
      money: json['money'].mdToString(),
      scan: pick(['view', 'scan']),
      isHide: json['is_hide'].mdToInt(),
      open: json['open'].mdToInt(),
    );
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({
    required this.course,
    required this.onTap,
    required this.onCancel,
  });

  final _FavoriteCourse course;
  final VoidCallback onTap;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    const coverWidth = 140.0;
    const coverHeight = coverWidth * 0.65;
    final hasScan = course.scan.isNotEmpty;
    final radius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: Slidable(
        key: ValueKey(course.id),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) => onCancel(),
              backgroundColor: AppColors.theme,
              foregroundColor: AppColors.white,
              label: '取消收藏',
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: coverHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MDNetImage(
                    imageUrl: course.picture,
                    width: coverWidth,
                    height: coverHeight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        Row(
                          children: [
                            if (hasScan) ...[
                              SvgPicture.asset(
                                'assets/images/public/scan.svg',
                                width: 12,
                                height: 12,
                              ),
                              const SizedBox(width: 2),
                              Text(
                                '${course.scan}人',
                                maxLines: 1,
                                style: TextStyle(
                                  color: AppColors.content,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 4),
                            ],
                            Expanded(
                              child: Align(
                                alignment: Alignment.centerRight,
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerRight,
                                  child: Text(
                                    course.money.mdToPrice(),
                                    maxLines: 1,
                                    style: TextStyle(
                                      color: AppColors.red,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
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

class _FavoriteArticleTile extends StatelessWidget {
  const _FavoriteArticleTile({required this.article, required this.onCancel});

  final ArticleSummary article;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    return ClipRRect(
      borderRadius: radius,
      child: Slidable(
        key: ValueKey((article.special, article.id)),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: .24,
          children: [
            SlidableAction(
              onPressed: (_) => onCancel(),
              backgroundColor: AppColors.theme,
              foregroundColor: AppColors.white,
              label: '取消收藏',
            ),
          ],
        ),
        child: ArticleCard(article: article),
      ),
    );
  }
}
