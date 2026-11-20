import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';

/// 讲义汇总页面
class CourseFilesetsPage extends StatefulWidget {
  const CourseFilesetsPage({super.key});

  @override
  State<CourseFilesetsPage> createState() => _CourseFilesetsPageState();
}

class _CourseFilesetsPageState extends State<CourseFilesetsPage> {
  static const _pageSize = 30;
  final _listKey = GlobalKey<RefreshListViewState<_CourseFileset>>();

  String? _userId = MDUser.defualt.uid;

  @override
  void initState() {
    super.initState();
    MDUser.defualt.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    MDUser.defualt.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    final userId = MDUser.defualt.uid;
    if (_userId == userId) return;
    _userId = userId;
    final list = _listKey.currentState;
    list?.removeWhere((_) => true);
    list?.refresh();
  }

  Future<RefreshResult<_CourseFileset>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    final result = await MDPost.sendApiSession(
      cmd: .courseFiles,
      params: {
        'scope': 'purchased',
        'view': 'courses',
        'page': page,
        'page_size': _pageSize,
      },
    );
    if (result.state == .outed || !MDUser.defualt.islogined) {
      return RefreshResult.notLoggedIn(result.msg);
    }
    if (!result.isSuccess) {
      return RefreshResult.failed(result.msg ?? '讲义加载失败');
    }

    final data = result.data;
    final rows = data?['list'] ?? data?['courses'] ?? data?['data'];
    if (data != null && rows is! List) return RefreshResult.failed('讲义数据格式错误');
    final items = _objects(rows).map(_CourseFileset.new).toList();
    final pagination = data?.mdAs<Map<String, dynamic>>('page_info') ?? data;
    final hasMore = pagination?.mdBool('has_more');
    final lastPage =
        pagination?.mdInt('last_page') ?? pagination?.mdInt('total_page');
    final total = pagination?.mdInt('total');
    final pageSize = pagination?.mdInt('page_size') ?? _pageSize;
    final noMore = switch ((hasMore, lastPage, total)) {
      (final bool more, _, _) => !more,
      (_, final int last, _) => page >= last,
      (_, _, final int count) => page * pageSize >= count,
      _ => false,
    };
    return RefreshResult.success(items, noMore: items.isEmpty || noMore);
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
  }

  void _openCourse(_CourseFileset course) {
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseFolder,
      queryParameters: {'courseId': course.id, 'courseType': course.type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MDPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: MDAppBar(
                  title: '讲义汇总',
                  centerTitle: false,
                  backgroundColor: AppColors.transparent,
                ),
              ),
              Expanded(
                child: RefreshListView<_CourseFileset>(
                  key: _listKey,
                  onData: _loadPage,
                  onLogin: _openLogin,
                  emptyText: '暂无讲义',
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
                  header: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.lightTheme,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: .start,
                      children: [
                        Text(
                          '我的课程讲义',
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 19,
                            fontWeight: .w800,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '汇总已购课程中有权查看的讲义，按课程与章节分组。',
                          style: TextStyle(color: AppColors.content),
                        ),
                      ],
                    ),
                  ),
                  itemBuilder: (_, course, _) => _CourseCard(
                    course: course,
                    onTap: () => _openCourse(course),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CourseCard extends StatelessWidget {
  const _CourseCard({required this.course, required this.onTap});

  final _CourseFileset course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          side: BorderSide(color: AppColors.border),
          borderRadius: BorderRadius.circular(22),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          splashFactory: NoSplash.splashFactory,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                MDNetImage(
                  imageUrl: course.photo,
                  width: 96,
                  height: 54,
                  borderRadius: BorderRadius.circular(8),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      if (course.typeName.isNotEmpty)
                        Text(
                          course.typeName,
                          style: TextStyle(
                            color: AppColors.theme,
                            fontSize: 11,
                          ),
                        ),
                      Text(
                        course.title,
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: 15,
                          fontWeight: .w500,
                        ),
                      ),
                      const SizedBox(height: 5),
                      if (course.fileCount != null)
                        Text(
                          '${course.fileCount} 份讲义',
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Assets.images.public.arrowRight.svg(width: 16, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _CourseFileset {
  _CourseFileset(Map<String, dynamic> json)
    : id = json.mdStringOr('course_id'),
      title = json.mdStringOr('course_name'),
      photo = json.mdStringOr('course_photo'),
      type = json.mdStringOr('course_type'),
      _typeName = json.mdStringOr('course_type_name'),
      fileCount = json.mdInt('file_count');

  final String id;
  final String title;
  final String photo;
  final String type;
  final String _typeName;
  final int? fileCount;

  String get typeName => _typeName.isNotEmpty
      ? _typeName
      : switch (type) {
          'gk' => '公开课',
          'bs' => '笔试课',
          'ms' => '面试课',
          'ydy' => '一对一',
          'zx' => '微课堂',
          _ => '',
        };
}

Iterable<Map<String, dynamic>> _objects(Object? source) {
  if (source is! List) return const [];
  return source.whereType<Map>().map(
    (item) => item.map((key, value) => MapEntry(key.toString(), value)),
  );
}
