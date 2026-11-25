import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';
import '../article/article_card.dart';
import 'home_alert.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key, this.onOpenNews});

  final VoidCallback? onOpenNews;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasLoadedHome = false;
  String _hotCategory = '';
  int _liveIndex = 0;
  late final HomeAlertManager _alertManager;

  @override
  void initState() {
    super.initState();
    _alertManager = HomeAlertManager(
      contextProvider: () => mounted ? context : null,
    )..start();
    unawaited(MDUser.defualt.updateData());
    unawaited(_fakeDeleteOrders());
  }

  /// 进入首页时，已登录用户清理无效订单
  Future<void> _fakeDeleteOrders() async {
    if (MDUser.defualt.uid == null) return;
    try {
      await MDPost.sendApiSession(cmd: .courseOrderFakeDel);
    } catch (error) {
      Utils.log('fake delete orders failed: $error');
    }
  }

  @override
  void dispose() {
    _alertManager.dispose();
    super.dispose();
  }

  Future<RefreshResult<_HomeData>> _loadHome() async {
    final shouldRefreshAlerts = _hasLoadedHome;
    _hasLoadedHome = true;
    final resultFuture = MDPost.sendApiSession(
      cmd: .home,
      params: {'include_news': 1, 'include_live': 1},
    );
    if (shouldRefreshAlerts) {
      await Future.wait<void>([
        resultFuture.then<void>((_) {}),
        _alertManager.loadData(),
      ]);
    }

    final result = await resultFuture;
    if (result.isSuccess) {
      _liveIndex = 0;
      return RefreshResult.success([_HomeData.fromJson(result.data)]);
    }
    return RefreshResult.failed(result.msg ?? '首页数据加载失败');
  }

  void _openCourseDetail(String id, String type) {
    if (id.isEmpty || type.isEmpty) return;
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseDetail,
      queryParameters: {'id': id, 'type': type},
    );
  }

  void _openWeb(String url) {
    if (url.isEmpty) return;
    AppRouter.pushNamed<void>(
      context,
      RouterNames.web,
      queryParameters: {'url': url},
    );
  }

  void _openCourseList([String type = '']) {
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseList,
      queryParameters: {'type': type},
    );
  }

  void _openArticle(String url) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !uri.hasAuthority ||
        !{'https', 'http'}.contains(uri.scheme)) {
      MDTotast.error('资讯地址无效');
      return;
    }
    AppRouter.pushNamed<void>(
      context,
      RouterNames.articleDetail,
      queryParameters: {'url': url},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MDPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: RefreshListView<_HomeData>(
                  padding: const EdgeInsets.only(bottom: 16),
                  enableLoadMore: false,
                  onData: (_) => _loadHome(),
                  itemBuilder: (context, data, index) =>
                      _buildHomeContent(data),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Column(
        children: [
          Row(
            children: [
              SvgPicture.asset(
                'assets/images/home/homeLogo.svg',
                height: 42,
                semanticsLabel: '卓仕遴选',
              ),
              const Spacer(),
              IconButton(
                tooltip: '收藏',
                onPressed: () =>
                    AppRouter.pushNamed<void>(context, RouterNames.favorites),
                icon: Assets.images.mine.zsFnFavorites.svg(
                  width: 24,
                  height: 24,
                ),
                style: IconButton.styleFrom(
                  splashFactory: NoSplash.splashFactory,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Material(
            color: AppColors.white,
            shape: RoundedRectangleBorder(
              side: const BorderSide(color: AppColors.paleBlue),
              borderRadius: BorderRadius.circular(14),
            ),
            child: InkWell(
              borderRadius: BorderRadius.circular(14),
              splashFactory: NoSplash.splashFactory,
              onTap: () =>
                  AppRouter.pushNamed<void>(context, RouterNames.search),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                   Icon(Icons.search, color: AppColors.title, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '搜索公告、课程相关资讯',
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    Text(
                      '去搜索',
                      style: TextStyle(color: AppColors.content, fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHomeContent(_HomeData data) {
    const hotIconFallback = Icon(
      Icons.local_fire_department_outlined,
      color: AppColors.goldenOrange,
      size: 18,
    );
    final hotCourses = data.hotCourses
        .where((course) => _hotCategory.isEmpty || course.type == _hotCategory)
        .toList();
    return Column(
      children: [
        _HomeBannerCarousel(
          banners: data.banners,
          onTap: (banner) {
            const courseTypes = {'gk', 'bs', 'ms', 'ydy', 'zx'};
            if (courseTypes.contains(banner.jumpType)) {
              _openCourseDetail(banner.jumpId, banner.jumpType);
            } else {
              _openWeb(banner.link);
            }
          },
        ),
        const SizedBox(height: 16),
        _CategorySection(onTap: _openCourseList),
        if (data.liveCourses.isNotEmpty) _buildLive(data.liveCourses),
        _SectionHeader(
          title: '热门课程',
          icon: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.paleOrange,
              borderRadius: BorderRadius.circular(8),
            ),
            child: SizedBox(
              width: 28,
              height: 28,
              child: Center(
                child: SvgPicture.asset(
                  'assets/images/home/zs_hot.svg',
                  width: 18,
                  height: 18,
                  placeholderBuilder: (_) => hotIconFallback,
                  errorBuilder: (_, _, _) => hotIconFallback,
                ),
              ),
            ),
          ),
          onAction: () => _openCourseList(_hotCategory),
        ),
        Theme(
          data: Theme.of(context)
              .copyWith(splashFactory: NoSplash.splashFactory),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Row(
              children: [
                for (final (type, title) in [('', '全部'), ..._categories])
                  Padding(
                    padding: const EdgeInsets.only(right: 6),
                    child: ChoiceChip(
                      label: Text(title),
                      labelPadding: const EdgeInsets.symmetric(horizontal: 6),
                      visualDensity: const VisualDensity(vertical: -2),
                      labelStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w400,
                      ),
                      chipAnimationStyle: ChipAnimationStyle(
                        selectAnimation: AnimationStyle.noAnimation,
                      ),
                      selected: _hotCategory == type,
                      selectedColor: AppColors.lightTheme,
                      backgroundColor: AppColors.white,
                      showCheckmark: false,
                      side: const BorderSide(color: AppColors.paleBlue),
                      onSelected: (_) => setState(() => _hotCategory = type),
                    ),
                  ),
              ],
            ),
          ),
        ),
        if (hotCourses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text(
              '暂无热门课程',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.content, fontSize: 14),
            ),
          )
        else
          ...hotCourses.map(
            (course) => _CourseCard(
              course: course,
              onTap: () => _openCourseDetail(course.id, course.type),
            ),
          ),
        if (data.news.isNotEmpty) ...[
          _SectionHeader(
            title: '近期公告',
            icon: Icon(Icons.auto_awesome, color: AppColors.theme, size: 20),
            onAction: widget.onOpenNews,
          ),
          for (final (article, url) in data.news)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
              child: Semantics(
                button: true,
                child: GestureDetector(
                  onTap: () => _openArticle(url),
                  child: ArticleCard(article: article),
                ),
              ),
            ),
        ],
        const SizedBox(height: 26),
        Text(
          '卓仕遴选  ·  专注遴选，陪伴成长',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.content,
            fontSize: 10,
            letterSpacing: 2,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLive(List<_HomeCourse> courses) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
      decoration: BoxDecoration(
        color: AppColors.lightTheme,
        border: Border.all(color: AppColors.paleBlue),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.live_tv_outlined, color: AppColors.coralOrange),
              const SizedBox(width: 6),
              const Expanded(
                child: Text(
                  '正在直播',
                  style: TextStyle(
                    color: AppColors.bigTitle,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Text(
                '● LIVE',
                style: TextStyle(
                  color: AppColors.coralOrange,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          CarouselSlider.builder(
            itemCount: courses.length,
            itemBuilder: (context, index, realIndex) {
              final course = courses[index];
              return _CourseCard(
                course: course,
                live: true,
                onTap: () => _openCourseDetail(course.id, course.type),
              );
            },
            options: CarouselOptions(
              height: 156,
              viewportFraction: 1,
              enableInfiniteScroll: courses.length > 1,
              onPageChanged: (index, _) => setState(() => _liveIndex = index),
            ),
          ),
          if (courses.length > 1)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                courses.length,
                (index) => Container(
                  width: index == _liveIndex ? 14 : 5,
                  height: 5,
                  margin: const EdgeInsets.symmetric(
                    horizontal: 2,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: index == _liveIndex
                        ? AppColors.theme
                        : AppColors.paleBlue,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _HomeBannerCarousel extends StatefulWidget {
  const _HomeBannerCarousel({required this.banners, required this.onTap});

  final List<_HomeBanner> banners;
  final ValueChanged<_HomeBanner> onTap;

  @override
  State<_HomeBannerCarousel> createState() => _HomeBannerCarouselState();
}

class _HomeBannerCarouselState extends State<_HomeBannerCarousel> {
  int _currentIndex = 0;

  @override
  void didUpdateWidget(covariant _HomeBannerCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_currentIndex >= widget.banners.length) _currentIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: LayoutBuilder(
        builder: (context, constraints) =>
            _buildBanner(constraints.maxWidth * 0.43),
      ),
    );
  }

  Widget _buildBanner(double height) {
    if (widget.banners.isEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Container(
          height: height,
          color: AppColors.white.withValues(alpha: 0.8),
          alignment: Alignment.center,
          child: Icon(Icons.image_outlined, size: 42, color: AppColors.grayAAA),
        ),
      );
    }

    return SizedBox(
      height: height,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider.builder(
            itemCount: widget.banners.length,
            itemBuilder: (context, index, realIndex) {
              final banner = widget.banners[index];
              return GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => widget.onTap(banner),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: SizedBox.expand(
                    child: MDNetImage(
                      imageUrl: banner.imageUrl,
                      fit: BoxFit.cover,
                      preserveImageAspectRatio: true,
                    ),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              height: height,
              viewportFraction: 1,
              autoPlay: widget.banners.length > 1,
              autoPlayInterval: const Duration(seconds: 3),
              enableInfiniteScroll: widget.banners.length > 1,
              onPageChanged: (index, reason) {
                if (mounted) setState(() => _currentIndex = index);
              },
            ),
          ),
          if (widget.banners.length > 1)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(widget.banners.length, (index) {
                  return Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.white.withValues(
                        alpha: index == _currentIndex ? 1 : 0.5,
                      ),
                    ),
                  );
                }),
              ),
            ),
        ],
      ),
    );
  }
}

const _categories = [
  ('gk', '公开课'),
  ('bs', '笔试课'),
  ('ms', '面试课'),
  ('ydy', '一对一'),
  ('zx', '微课堂'),
];

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.onTap});

  final ValueChanged<String> onTap;

  static final _icons = {
    'gk': Assets.images.home.courseGk,
    'bs': Assets.images.home.courseBs,
    'ms': Assets.images.home.courseMs,
    'ydy': Assets.images.home.courseYdy,
    'zx': Assets.images.home.courseZx,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          for (final (type, title) in _categories)
            Expanded(
              child: InkWell(
                splashFactory: NoSplash.splashFactory,
                onTap: () => onTap(type),
                child: Column(
                  children: [
                    _icons[type]!.svg(width: 54, height: 54),
                    const SizedBox(height: 4),
                    Text(
                      title,
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.onAction,
  });

  final String title;
  final Widget icon;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.bigTitle,
              ),
            ),
            const Spacer(),
            if (onAction != null)
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Row(
                    children: [
                      Text(
                        '更多',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.content,
                        ),
                      ),
                      const SizedBox(width: 2),
                      Assets.images.public.arrowRight.svg(
                        width: 14,
                        height: 14,
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

class _CourseCard extends StatelessWidget {
  const _CourseCard({
    required this.course,
    required this.onTap,
    this.live = false,
  });

  final _HomeCourse course;
  final VoidCallback onTap;
  final bool live;

  @override
  Widget build(BuildContext context) {
    final metadata = [
      if (course.hours.isNotEmpty) '共 ${course.hours} 课时',
      if (course.teacher.isNotEmpty) course.teacher,
      if (course.subtitle.isNotEmpty) course.subtitle,
    ].join(' · ');
    final radius = BorderRadius.circular(14);
    final content = Row(
      crossAxisAlignment: live
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.stretch,
      children: [
        Flexible(
          flex: 2,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 96),
                  child: AspectRatio(
                    aspectRatio: 1.6,
                    child: MDNetImage(imageUrl: course.picture),
                  ),
                ),
              ),
              if (live && course.time.isNotEmpty)
                Text(
                  course.time,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.content, fontSize: 11),
                ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 3,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                course.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.title,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              if (course.tags.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final (index, tag) in course.tags.indexed)
                          Padding(
                            padding: EdgeInsets.only(left: index == 0 ? 0 : 4),
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: index.isEven
                                    ? AppColors.paleOrange
                                    : AppColors.lightTheme,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 5,
                                  vertical: 1,
                                ),
                                child: Text(
                                  tag,
                                  style: TextStyle(
                                    color: index.isEven
                                        ? AppColors.warningTitle
                                        : AppColors.theme,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              if (metadata.isNotEmpty)
                Text(
                  metadata,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.content, fontSize: 10),
                ),
              if (!live) const Spacer(),
              const SizedBox(height: 6),
              if (live)
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '进入课堂 ↗',
                    style: TextStyle(color: AppColors.theme),
                  ),
                )
              else
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Wrap(
                        spacing: 6,
                        children: [
                          Text(
                            course.money.mdToPrice(),
                            style: TextStyle(
                              color: AppColors.price,
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (course.oldMoney.mdToOldPrice().isNotEmpty)
                            Text(
                              course.oldMoney.mdToOldPrice(),
                              style: TextStyle(
                                color: AppColors.content,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                        ],
                      ),
                    ),
                    if (course.look.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${course.look}人浏览',
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
            ],
          ),
        ),
      ],
    );
    return Container(
      margin: live ? EdgeInsets.zero : const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Material(
        color: AppColors.white,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: AppColors.paleBlue),
          borderRadius: radius,
        ),
        child: InkWell(
          borderRadius: radius,
          splashFactory: NoSplash.splashFactory,
          onTap: onTap,
          child: Padding(
            padding: live
                ? const EdgeInsets.all(10)
                : const EdgeInsets.fromLTRB(10, 10, 12, 10),
            child: live ? content : IntrinsicHeight(child: content),
          ),
        ),
      ),
    );
  }
}

class _HomeData {
  _HomeData.fromJson(Map<String, dynamic>? json)
    : banners = _items(
        json?['banner'] ?? json?['banner_list'] ?? json?['banners'],
      ).map(_HomeBanner.fromJson).toList(),
      hotCourses = _items(
        json?['rmk'] ?? json?['rq_course'] ?? json?['hotCourses'],
      ).map(_HomeCourse.fromJson).toList(),
      liveCourses = _items(json?['live_list'])
          .map((item) => _HomeCourse.fromJson(item, live: true))
          .toList(),
      news = [
        for (final item in _items(json?['newsList']))
          (
            ArticleSummary({
              ...item,
              'cate_name': item['sub_cat_name'] ?? item['cate_name'],
              'date': item['time'] ?? item['date'],
            }),
            item.mdString('article_link') ??
                item.mdString('url') ??
                item.mdStringOr('link'),
          ),
      ];

  final List<_HomeBanner> banners;
  final List<_HomeCourse> hotCourses;
  final List<_HomeCourse> liveCourses;
  final List<(ArticleSummary, String)> news;
}

class _HomeBanner {
  _HomeBanner.fromJson(Map<String, dynamic> json)
    : imageUrl = json.mdString('banner_url') ?? json.mdStringOr('image_url'),
      jumpType = json.mdString('behavior_type') ?? json.mdStringOr('jump_type'),
      jumpId = json.mdString('behavior_id') ?? json.mdStringOr('jump_id'),
      link = json.mdStringOr('link');

  final String imageUrl;
  final String jumpType;
  final String jumpId;
  final String link;
}

class _HomeCourse {
  _HomeCourse.fromJson(Map<String, dynamic> json, {bool live = false})
    : id = (live ? json.mdString('course_id') : null) ?? json.mdStringOr('id'),
      type =
          (live ? json.mdString('course_type') : null) ??
          json.mdStringOr('type'),
      picture =
          json.mdString('img') ??
          json.mdString('photo') ??
          json.mdStringOr('picture'),
      title = json.mdString('name') ?? json.mdStringOr('title'),
      subtitle = json.mdString('sub_title') ?? json.mdStringOr('subtitle'),
      look = json.mdString('view') ?? json.mdStringOr('look'),
      money = json.mdStringOr('money'),
      oldMoney = json.mdStringOr('old_money'),
      teacher = json.mdStringOr('teacher_name'),
      hours = json.mdStringOr('keshi'),
      time = [
        json.mdString('start_time_text') ?? json.mdStringOr('start'),
        json.mdString('end_time_text') ?? json.mdStringOr('end'),
      ].where((value) => value.isNotEmpty).join('–'),
      tags = switch (json['label_list'] ?? json['tag']) {
        List values =>
          values.whereType<String>().where((tag) => tag.isNotEmpty).toList(),
        _ => const [],
      };

  final String id;
  final String type;
  final String picture;
  final String title;
  final String subtitle;
  final String look;
  final String money;
  final String oldMoney;
  final String teacher;
  final String hours;
  final String time;
  final List<String> tags;
}

Iterable<Map<String, dynamic>> _items(Object? container) {
  final list = container is Map ? container['list'] : container;
  return list is List ? list.whereType<Map<String, dynamic>>() : const [];
}
