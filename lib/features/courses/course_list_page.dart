import 'package:flutter/material.dart';
import 'package:zslx_flutter/widgets/refresh_list_view.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';

class CourseListPage extends StatelessWidget {
  const CourseListPage({
    this.initialType = '',
    this.showBackButton = true,
    super.key,
  });

  final String initialType;
  final bool showBackButton;

  static const _types = [
    _CourseType('', '全部'),
    _CourseType('gk', '公开课'),
    _CourseType('bs', '笔试课'),
    _CourseType('ms', '面试课'),
    _CourseType('ydy', '一对一'),
    _CourseType('zx', '微课堂'),
  ];

  void _openSearch(BuildContext context) {
    AppRouter.pushNamed<void>(context, RouterNames.courseSearch);
  }

  void _openCourse(BuildContext context, CourseItem course) {
    AppRouter.pushNamed<void>(
      context,
      .courseDetail,
      queryParameters: {'id': course.id, 'type': course.type},
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _types.indexWhere((type) => type.value == initialType);
    return Scaffold(
      body: MDPageBackground(
        child: SafeArea(
          child: DefaultTabController(
            length: _types.length,
            initialIndex: index < 0 ? 0 : index,
            child: Column(
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(
                    title: '课程中心',
                    titleColor: AppColors.bigTitle,
                    centerTitle: false,
                    showBackButton: showBackButton,
                    backgroundColor: AppColors.transparent,
                    actions: [
                      IconButton(
                        tooltip: '搜索课程',
                        onPressed: () => _openSearch(context),
                        icon: Icon(Icons.search, color: AppColors.bigTitle),
                        style: IconButton.styleFrom(
                          splashFactory: NoSplash.splashFactory,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _CourseTypeBar(types: _types),
                Expanded(
                  child: TabBarView(
                    children: [
                      for (final type in _types)
                        _CoursePagedList(
                          type: type,
                          onTap: (course) => _openCourse(context, course),
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

class _CourseType {
  const _CourseType(this.value, this.title);

  final String value;
  final String title;
}

class _CourseTypeBar extends StatelessWidget {
  const _CourseTypeBar({required this.types});

  final List<_CourseType> types;

  @override
  Widget build(BuildContext context) {
    final controller = DefaultTabController.of(context);
    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) => TabBar(
        isScrollable: true,
        tabAlignment: .start,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        labelPadding: const EdgeInsets.only(right: 8),
        labelColor: AppColors.theme,
        unselectedLabelColor: AppColors.content,
        indicator: const BoxDecoration(),
        dividerHeight: 0,
        splashFactory: NoSplash.splashFactory,
        tabs: [
          for (final (index, type) in types.indexed)
            Tab(
              height: 38,
              child: DecoratedBox(
                decoration: ShapeDecoration(
                  color: index == controller.index
                      ? AppColors.lightTheme
                      : AppColors.border.withValues(alpha: .55),
                  shape: const StadiumBorder(),
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  child: Text(type.title, style: const TextStyle(fontSize: 13)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _CoursePagedList extends StatefulWidget {
  const _CoursePagedList({required this.type, required this.onTap});

  final _CourseType type;
  final ValueChanged<CourseItem> onTap;

  @override
  State<_CoursePagedList> createState() => _CoursePagedListState();
}

class _CoursePagedListState extends State<_CoursePagedList>
    with AutomaticKeepAliveClientMixin {
  int? _total;

  @override
  bool get wantKeepAlive => true;

  Future<RefreshResult<CourseItem>> _loadPage(int page) async {
    final result = await MDPost.sendApiSession(
      cmd: .courseList,
      params: {'page': page, 'course_type': widget.type.value},
    );
    if (!result.isSuccess) {
      return RefreshResult.failed(result.msg ?? '课程中心加载失败');
    }

    final data = result.data;
    final courses = CourseItem.listFromData(data);
    final paging = data?.mdAs<Map<String, dynamic>>('page_info') ?? data;
    final total = paging?.mdInt('total');
    final lastPage = paging?.mdInt('last_page') ?? paging?.mdInt('total_page');
    final hasMore = paging?.mdBool('has_more');
    final noMore =
        courses.isEmpty ||
        (hasMore != null ? !hasMore : lastPage != null && page >= lastPage);
    if (mounted && page == 1) {
      setState(() => _total = total ?? (noMore ? courses.length : null));
    }
    return RefreshResult.success(courses, noMore: noMore);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return RefreshListView<CourseItem>(
      onData: _loadPage,
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      header: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Text(
          _total == null ? '精选课程' : '精选课程 · $_total 门课程',
          style: TextStyle(color: AppColors.content, fontSize: 13),
        ),
      ),
      itemBuilder: (_, item, _) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: CompactCourseCard(course: item, onTap: () => widget.onTap(item)),
      ),
      emptyText: '暂无课程',
    );
  }
}

class CourseItem {
  const CourseItem({
    this.id = '',
    this.type = '',
    this.title = '',
    this.subtitle = '',
    this.picture = '',
    this.money = '',
    this.look = '',
    this.tags = const [],
    this.hours = '',
    this.teacher = '',
    this.isLive = false,
  });

  final String id;
  final String type;
  final String title;
  final String subtitle;
  final String picture;
  final String money;
  final String look;
  final List<String> tags;
  final String hours;
  final String teacher;
  final bool isLive;

  factory CourseItem.fromJson(Map<String, Object?> json) {
    final tags = json['tags'];
    return CourseItem(
      id: json['id'].mdToString(),
      type: json['type'].mdToString(),
      title: json['title'].mdToString(),
      subtitle: json['sub_title'].mdToString(),
      picture: json['photo'].mdToString(),
      money: json['money'].mdToString(),
      look: json['view'].mdToString(),
      tags: tags is List
          ? tags.whereType<String>().where((tag) => tag.isNotEmpty).toList()
          : const [],
      hours: json['keshi'].mdToString(),
      teacher: json['teacher_name'].mdToString(),
      isLive:
          json['live_status'].mdToInt() == 2 ||
          castTo<bool>(json['is_live']) == true,
    );
  }

  static List<CourseItem> listFromData(Map<String, Object?>? data) {
    final source = data?['list'];
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map(
          (item) => CourseItem.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}

class CompactCourseCard extends StatelessWidget {
  const CompactCourseCard({
    required this.course,
    required this.onTap,
    super.key,
  });

  final CourseItem course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(20);
    final category =
        CourseListPage._types
            .where((type) => type.value.isNotEmpty && type.value == course.type)
            .firstOrNull
            ?.title ??
        '';
    final tags = course.tags;
    final hours = course.hours;
    final teacher = course.teacher;
    final summary = [
      if (hours.isNotEmpty) '共 $hours 课时',
      if (teacher.isNotEmpty) teacher,
    ].join(' · ');
    return Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        splashFactory: NoSplash.splashFactory,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Flexible(
                  flex: 2,
                  child: Stack(
                    alignment: Alignment.bottomLeft,
                    children: [
                      AspectRatio(
                        aspectRatio: 1.72,
                        child: MDNetImage(
                          imageUrl: course.picture,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      if (course.isLive || category.isNotEmpty)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: AppColors.theme,
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(6),
                              bottomLeft: Radius.circular(8),
                            ),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            child: Text(
                              course.isLive ? '正在直播' : category,
                              style: TextStyle(
                                color: AppColors.white,
                                fontSize: 10,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: .start,
                    children: [
                      Text(
                        course.title,
                        maxLines: 1,
                        overflow: .ellipsis,
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: 14,
                          fontWeight: .w500,
                        ),
                      ),
                      if (tags.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Wrap(
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              for (final tag in tags)
                                DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: AppColors.lightTheme,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 4,
                                      vertical: 2,
                                    ),
                                    child: Text(
                                      tag,
                                      style: TextStyle(
                                        color: AppColors.theme,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (summary.isNotEmpty || course.subtitle.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 5),
                          child: Text(
                            summary.isEmpty ? course.subtitle : summary,
                            maxLines: 1,
                            overflow: .ellipsis,
                            style: TextStyle(
                              color: AppColors.content,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      if (course.money.isNotEmpty ||
                          course.look.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        const Spacer(),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (course.money.isNotEmpty)
                              Expanded(
                                child: Text(
                                  course.money.mdToPrice(),
                                  style: TextStyle(
                                    color: AppColors.price,
                                    fontSize: 16,
                                    fontWeight: .w500,
                                  ),
                                ),
                              ),
                            if (course.look.isNotEmpty)
                              Expanded(
                                child: Padding(
                                  padding: EdgeInsets.only(
                                    left: course.money.isNotEmpty ? 6 : 0,
                                  ),
                                  child: Text(
                                    '${course.look}人浏览',
                                    textAlign: TextAlign.right,
                                    style: TextStyle(
                                      color: AppColors.content,
                                      fontSize: 11,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
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
