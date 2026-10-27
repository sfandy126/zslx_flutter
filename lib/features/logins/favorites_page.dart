import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

/// 我的收藏
class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<_FavoriteCourse>>();

  Future<RefreshResult<_FavoriteCourse>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .collects,
        params: {'cate_id': 2, 'p': page},
      );
      if (result.isSuccess) {
        final courses = _FavoriteCourse.listFrom(result.data?['data']);
        return RefreshResult.success(
          courses,
          noMore: page > 1 && courses.isEmpty,
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
    if (mounted) _listKey.currentState?.refresh();
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: _plainTextStyle,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(title: '我的收藏', centerTitle: false),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: RefreshListView<_FavoriteCourse>(
                  key: _listKey,
                  onData: _loadPage,
                  emptyText: '暂无收藏',
                  failedText: '收藏加载失败，请重试',
                  onLogin: _openLogin,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, course, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _FavoriteTile(
                      course: course,
                      onTap: () => _open(course),
                    ),
                  ),
                ),
              ),
            ),
          ],
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

  static List<_FavoriteCourse> listFrom(Object? source) {
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map(
          (item) => _FavoriteCourse.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}

class _FavoriteTile extends StatelessWidget {
  const _FavoriteTile({required this.course, required this.onTap});

  final _FavoriteCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const coverWidth = 140.0;
    const coverHeight = coverWidth * 0.65;
    final hasScan = course.scan.isNotEmpty;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Padding(
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
    );
  }
}
