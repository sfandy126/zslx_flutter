import 'package:flutter/material.dart';
import 'package:zslx_flutter/extensions/string_price.dart';
import 'package:zslx_flutter/utils/widgets/refresh_list_view.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

class CourseListPage extends StatefulWidget {
  const CourseListPage({
    this.initialType = 'gk',
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
    CourseType('gk', '公开课'),
    CourseType('bs', '笔试课'),
    CourseType('ms', '面试课'),
    CourseType('ydy', '一对一'),
    CourseType('zx', '微课堂'),
  ];

  late final PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = _types.indexWhere(
      (item) => item.value == widget.initialType,
    );
    if (_currentIndex < 0) _currentIndex = 0;
    _pageController = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _openSearch() {
    AppRouter.pushNamed<void>(context, RouterNames.courseSearch);
  }

  void _selectType(int index) {
    if (index == _currentIndex) return;
    setState(() => _currentIndex = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
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
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: CustomAppBar(
                    title: '课程列表',
                    centerTitle: false,
                    showBackButton: widget.showBackButton,
                    actions: [
                      IconButton(
                        tooltip: '搜索课程',
                        onPressed: _openSearch,
                        icon: Icon(
                          Icons.search,
                          size: 26,
                          color: AppColors.title,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
            ),
            _CourseTypeBar(
              types: _types,
              currentIndex: _currentIndex,
              onTap: _selectType,
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: PageView.builder(
                  controller: _pageController,
                  itemCount: _types.length,
                  onPageChanged: (index) =>
                      setState(() => _currentIndex = index),
                  itemBuilder: (context, index) {
                    return _CoursePagedList(
                      type: _types[index],
                      active: index == _currentIndex,
                      onTap: _openCourse,
                    );
                  },
                ),
              ),
            ),
          ],
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
  const _CourseTypeBar({
    required this.types,
    required this.currentIndex,
    required this.onTap,
  });

  final List<CourseType> types;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: AppColors.white,
      child: SizedBox(
        height: 44,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          itemCount: types.length,
          separatorBuilder: (_, _) => const SizedBox(width: 24),
          itemBuilder: (context, index) {
            final item = types[index];
            final selected = index == currentIndex;
            return GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(index),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    item.title,
                    style: TextStyle(
                      color: selected ? AppColors.theme : AppColors.title,
                      fontSize: 15,
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      decoration: TextDecoration.none,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    width: 18,
                    height: 3,
                    decoration: BoxDecoration(
                      color: selected ? AppColors.theme : AppColors.transparent,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CoursePagedList extends StatelessWidget {
  const _CoursePagedList({
    required this.type,
    required this.active,
    required this.onTap,
  });

  final CourseType type;
  final bool active;
  final ValueChanged<CourseItem> onTap;

  @override
  Widget build(BuildContext context) {
    return RefreshListView<CourseItem>(
      onData: (page) async {
        final result = await MDPost.sendApiSession(
          cmd: .courseList,
          params: {'page': page, 'course_type': type.value},
        );
        if (result.isSuccess) {
          return RefreshResult.success(CourseItem.listFromData(result.data));
        }
        return RefreshResult.failed(result.msg ?? '课程列表加载失败');
      },
      itemBuilder: (context, item, index) =>
          CourseCard(course: item, isBig: true, onTap: () => onTap(item)),
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

  factory CourseItem.fromJson(Map<String, dynamic> json) {
    return CourseItem(
      id: _stringValue(json['id']),
      type: _stringValue(json['type']),
      title: _stringValue(json['title']),
      subtitle: _stringValue(json['sub_title']),
      picture: _stringValue(json['photo']),
      money: _stringValue(json['money']),
      oldMoney: _stringValue(json['y_money']),
      look: _stringValue(json['view']),
      isHot: _intValue(json['is_hot']) == 1,
    );
  }

  static List<CourseItem> listFromData(Map<String, dynamic>? data) {
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
                          aspectRatio: 1 / 0.53,
                          child: _RemoteImage(url: course.picture),
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
                          child: _RemoteImage(url: course.picture),
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
            if (course.oldMoney.toOldPrice().isNotEmpty) ...[
              Text(
                course.oldMoney.toOldPrice(),
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
              course.money.toPrice(),
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

class _RemoteImage extends StatelessWidget {
  const _RemoteImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.line,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.grayAAA, size: 28),
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

String _stringValue(Object? value) => value?.toString() ?? '';

int _intValue(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
