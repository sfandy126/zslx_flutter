import 'package:flutter/material.dart';
import 'package:zslx_flutter/widgets/refresh_list_view.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({
    this.initialType = '',
    this.showBackButton = true,
    super.key,
  });

  final String initialType;
  final bool showBackButton;

  @override
  State<CourseListPage> createState() => _CourseListPageState();
}

class _CourseListPageState extends State<CourseListPage> {
  static const _types = [
    CourseType('', '全部'),
    CourseType('gk', '公开课'),
    CourseType('bs', '笔试课'),
    CourseType('ms', '面试课'),
    CourseType('ydy', '一对一'),
    CourseType('zx', '微课堂'),
  ];

  void _openSearch() {
    AppRouter.pushNamed<void>(context, RouterNames.courseSearch);
  }

  void _openCourse(CourseItem course) {
    AppRouter.pushNamed<void>(
      context,
      .courseDetail,
      queryParameters: {'id': course.id, 'type': course.type},
    );
  }

  @override
  Widget build(BuildContext context) {
    final index = _types.indexWhere((type) => type.value == widget.initialType);
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
                    showBackButton: widget.showBackButton,
                    backgroundColor: AppColors.transparent,
                    actions: [
                      IconButton(
                        tooltip: '搜索课程',
                        onPressed: _openSearch,
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
                        _CoursePagedList(type: type, onTap: _openCourse),
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

class CourseType {
  const CourseType(this.value, this.title);

  final String value;
  final String title;
}

class _CourseTypeBar extends StatelessWidget {
  const _CourseTypeBar({required this.types});

  final List<CourseType> types;

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
                    horizontal: 13,
                    vertical: 6,
                  ),
                  child: Text(type.title),
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

  final CourseType type;
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
    this.oldMoney = '',
    this.look = '',
    this.isHot = false,
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
  final String oldMoney;
  final String look;
  final bool isHot;
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
      oldMoney: json['y_money'].mdToString(),
      look: json['view'].mdToString(),
      isHot: json['is_hot'].mdToInt() == 1,
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

class CourseCard extends StatelessWidget {
  const CourseCard({
    required this.course,
    required this.onTap,
    this.isBig = false,
    super.key,
  });

  final CourseItem course;
  final VoidCallback onTap;
  final bool isBig;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: isBig ? EdgeInsets.zero : const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: isBig
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(12),
                        ),
                        child: AspectRatio(
                          aspectRatio: 375 / 198,
                          child: MDNetImage(imageUrl: course.picture),
                        ),
                      ),
                      if (course.isHot)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: _Tag(text: '热门', color: AppColors.red),
                        ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            decoration: TextDecoration.none,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            SvgPicture.asset(
                              'assets/images/public/scan.svg',
                              width: 12,
                              height: 12,
                            ),
                            const SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                '${course.look.isEmpty ? '100' : course.look} 人学习',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.content,
                                  fontSize: 12,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                            ),
                            _PriceView(course: course),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: SizedBox(
                          width: 140,
                          height: 91,
                          child: MDNetImage(imageUrl: course.picture),
                        ),
                      ),
                      if (course.isHot)
                        Positioned(
                          left: 4,
                          top: 4,
                          child: _Tag(text: '热门', color: AppColors.red),
                        ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: SizedBox(
                      height: 91,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            course.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.title,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.none,
                            ),
                          ),
                          if (course.subtitle.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              course.subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.content,
                                fontSize: 12,
                                decoration: TextDecoration.none,
                              ),
                            ),
                          ],
                          const Spacer(),
                          Row(
                            children: [
                              _PriceView(course: course),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    SvgPicture.asset(
                                      'assets/images/public/scan.svg',
                                      width: 12,
                                      height: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Flexible(
                                      child: Text(
                                        '${course.look.isEmpty ? '100' : course.look} 人学习',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        textAlign: TextAlign.right,
                                        style: TextStyle(
                                          color: AppColors.content,
                                          fontSize: 12,
                                          decoration: TextDecoration.none,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _PriceView extends StatelessWidget {
  const _PriceView({required this.course});

  final CourseItem course;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 116),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (course.oldMoney.mdToOldPrice().isNotEmpty) ...[
              Text(
                course.oldMoney.mdToOldPrice(),
                style: TextStyle(
                  color: AppColors.content,
                  fontSize: 12,
                  decoration: TextDecoration.lineThrough,
                  decorationColor: AppColors.content,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              course.money.mdToPrice(),
              style: TextStyle(
                color: AppColors.price,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.text, required this.color});

  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 18,
      padding: const EdgeInsets.symmetric(horizontal: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.none,
        ),
      ),
    );
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
    final category = switch (course.type) {
      'gk' => '公开课',
      'bs' => '笔试课',
      'ms' => '面试课',
      'ydy' => '一对一',
      'zx' => '微课堂',
      _ => '',
    };
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
          child: Row(
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
                      maxLines: 2,
                      overflow: .ellipsis,
                      style: TextStyle(
                        color: AppColors.bigTitle,
                        fontWeight: .w700,
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
                            fontSize: 11,
                          ),
                        ),
                      ),
                    if (course.money.isNotEmpty || course.look.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          if (course.money.isNotEmpty)
                            Text(
                              course.money.mdToPrice(),
                              style: TextStyle(
                                color: AppColors.warningTitle,
                                fontSize: 17,
                                fontWeight: .w700,
                              ),
                            ),
                          if (course.look.isNotEmpty)
                            Text(
                              '${course.look} 人浏览',
                              style: TextStyle(
                                color: AppColors.content,
                                fontSize: 11,
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
    );
  }
}
