import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';

class CoursePrebookListPage extends StatefulWidget {
  const CoursePrebookListPage({super.key});

  @override
  State<CoursePrebookListPage> createState() => _CoursePrebookListPageState();
}

class _CoursePrebookListPageState extends State<CoursePrebookListPage> {
  final _listKey = GlobalKey<RefreshListViewState<_PrebookCourse>>();

  Future<RefreshResult<_PrebookCourse>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();

    final result = await MDPost.sendApiSession(
      cmd: .coursePrebookList,
      params: {'course_type': 'ydy', 'is_type': 1, 'p': page},
    );
    if (result.state == .outed || !MDUser.defualt.islogined) {
      return RefreshResult.notLoggedIn(result.msg);
    }
    if (!result.isSuccess) {
      return RefreshResult.failed(result.msg ?? '约课列表加载失败');
    }

    final data = result.data;
    final rows = data?['ck_list'];
    if (rows is! List) return RefreshResult.failed('约课列表数据格式错误');

    final courses = rows
        .map(_readObject)
        .whereType<Map<String, dynamic>>()
        .map(_PrebookCourse.new)
        .toList();
    final pageInfo = _readObject(data?['page_info']);
    final hasMore = pageInfo?.mdBool('has_more');
    final lastPage =
        pageInfo?.mdInt('last_page') ?? pageInfo?.mdInt('total_page');
    return RefreshResult.success(
      courses,
      noMore:
          courses.isEmpty ||
          (hasMore != null ? !hasMore : lastPage != null && page >= lastPage),
    );
  }

  static Map<String, dynamic>? _readObject(Object? value) {
    if (value is! Map) return null;
    return value.map((key, value) => MapEntry(key.toString(), value));
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  Future<void> _openPrebook(_PrebookCourse course) async {
    final booked = await AppRouter.pushNamed<bool>(
      context,
      RouterNames.coursePrebook,
      queryParameters: {
        'id': course.id,
        'orderId': course.orderId,
        'name': course.title,
      },
    );
    if (mounted && booked == true) _listKey.currentState?.refresh();
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
                  title: '一对一约课',
                  centerTitle: false,
                  backgroundColor: AppColors.transparent,
                ),
              ),
              Expanded(
                child: RefreshListView<_PrebookCourse>(
                  key: _listKey,
                  onData: _loadPage,
                  onLogin: _openLogin,
                  emptyText: '暂无可预约的一对一课程',
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  header: Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Text(
                      '选择已购课程，再向该课程分配的老师约课。',
                      style: TextStyle(color: AppColors.content, fontSize: 13),
                    ),
                  ),
                  itemBuilder: (_, course, _) => _CourseCard(
                    course: course,
                    onBook: () => _openPrebook(course),
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
  const _CourseCard({required this.course, required this.onBook});

  final _PrebookCourse course;
  final VoidCallback onBook;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Row(
            children: [
              MDNetImage(
                imageUrl: course.picture,
                width: 100,
                height: 56,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: .start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 15,
                        fontWeight: .w500,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      course.teacher,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(color: AppColors.content, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColors.lightTheme,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                Text.rich(
                  TextSpan(
                    style: TextStyle(color: AppColors.theme),
                    children: [
                      TextSpan(
                        text: '剩余 ${_hours(course.remaining)}',
                        style: const TextStyle(fontSize: 20, fontWeight: .w800),
                      ),
                      const TextSpan(
                        text: ' 课时',
                        style: TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
                Text(
                  '共 ${_hours(course.total)} · 已使用 ${_hours(course.used)}',
                  style: TextStyle(color: AppColors.content, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: course.id.isEmpty || course.orderId.isEmpty
                ? null
                : onBook,
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.theme,
              foregroundColor: AppColors.white,
              minimumSize: const Size(0, 42),
              splashFactory: NoSplash.splashFactory,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('预约该课程老师', style: TextStyle(fontWeight: .w700)),
          ),
        ],
      ),
    );
  }

  static String _hours(double? hours) {
    if (hours == null || !hours.isFinite) return '—';
    return hours.toStringAsFixed(6).replaceFirst(RegExp(r'\.?0+$'), '');
  }
}

class _PrebookCourse {
  _PrebookCourse(Map<String, dynamic> json)
    : id = json.mdStringOr('c_id'),
      orderId = json.mdStringOr('o_id'),
      title = json.mdStringOr('name'),
      picture = json.mdStringOr('img'),
      teacher = json.mdStringOr('teacher_name'),
      total = json.mdDouble('ks'),
      remaining = json.mdDouble('ks_left'),
      _used = json.mdDouble('ks_used');

  final String id;
  final String orderId;
  final String title;
  final String picture;
  final String teacher;
  final double? total;
  final double? remaining;
  final double? _used;

  double? get used {
    final total = this.total;
    final remaining = this.remaining;
    return _used ??
        (total == null || remaining == null ? null : total - remaining);
  }
}
