import 'dart:async';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';
import 'home_alert.dart';

part 'home_page.g.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _hasLoadedHome = false;
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

  Future<RefreshResult<_HomeData>> _loadHome(int page) async {
    if (page > 1) return RefreshResult.success(const [], noMore: true);

    final shouldRefreshAlerts = _hasLoadedHome;
    _hasLoadedHome = true;
    final resultFuture = MDPost.sendApiSession(cmd: .home);
    if (shouldRefreshAlerts) {
      await Future.wait<void>([
        resultFuture.then<void>((_) {}),
        _alertManager.loadData(),
      ]);
    }

    final result = await resultFuture;
    if (result.isSuccess) {
      return RefreshResult.success([
        _HomeData.fromJson(result.data),
      ], noMore: true);
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

  void _openCourseList([String type = 'gk']) {
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseList,
      queryParameters: {'type': type},
    );
  }

  void _openCourseSearch() {
    AppRouter.pushNamed<void>(context, RouterNames.courseSearch);
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFFD6EEF8), Color(0xFFEAF4FB), Color(0xFFF0F4F8)],
              stops: [0, 0.3, 1],
            ),
          ),
          child: Column(
            children: [
              SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(
                    title: '学无止境',
                    titleFontSize: 22,
                    titleFontWeight: FontWeight.w600,
                    backgroundColor: AppColors.transparent,
                    centerTitle: false,
                    showBackButton: false,
                    actions: [
                      IconButton(
                        tooltip: '搜索课程',
                        onPressed: _openCourseSearch,
                        icon: Icon(
                          Icons.search,
                          color: AppColors.title,
                          size: 28,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: RefreshListView<_HomeData>(
                  padding: const EdgeInsets.only(bottom: 16),
                  onData: _loadHome,
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

  Widget _buildHomeContent(_HomeData data) {
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
        _SectionHeader(
          title: '热门课程',
          actionText: '查看全部',
          onAction: _openCourseList,
        ),
        if (data.hotCourses.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 36),
            child: Text(
              '暂无热门课程',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.content, fontSize: 14),
            ),
          )
        else
          ...data.hotCourses.map(
            (course) => _CourseCard(
              course: course,
              onTap: () => _openCourseDetail(course.id, course.type),
            ),
          ),
      ],
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
    const height = 180.0;
    if (widget.banners.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Container(
            height: height,
            color: AppColors.white.withValues(alpha: 0.8),
            alignment: Alignment.center,
            child: Icon(
              Icons.image_outlined,
              size: 42,
              color: AppColors.grayAAA,
            ),
          ),
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
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => widget.onTap(banner),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: SizedBox.expand(
                      child: MDNetImage(imageUrl: banner.imageUrl),
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

class _CategorySection extends StatelessWidget {
  const _CategorySection({required this.onTap});

  final ValueChanged<String> onTap;
  static final _items = [
    _CategoryItem('gk', '公开课', Assets.images.home.courseGk3x),
    _CategoryItem('bs', '笔试课', Assets.images.home.courseBs3x),
    _CategoryItem('ms', '面试课', Assets.images.home.courseMs3x),
    _CategoryItem('ydy', '一对一', Assets.images.home.courseYdy3x),
    _CategoryItem('zx', '微课堂', Assets.images.home.courseZx3x),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '课程分类',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.title,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              for (var index = 0; index < _items.length; index++) ...[
                if (index > 0) const SizedBox(width: 8),
                Expanded(
                  key: ValueKey(_items[index].icon.path),
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => onTap(_items[index].type),
                    child: Container(
                      height: 76,
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _items[index].icon.image(
                            key: ValueKey(_items[index].icon.path),
                            width: 36,
                            height: 36,
                          ),
                          const SizedBox(height: 5),
                          Text(
                            _items[index].title,
                            maxLines: 1,
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.title,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionText,
    required this.onAction,
  });

  final String title;
  final String actionText;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppColors.title,
              ),
            ),
            const Spacer(),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onAction,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Text(
                      actionText,
                      style: TextStyle(fontSize: 13, color: AppColors.theme),
                    ),
                    const SizedBox(width: 2),
                    Icon(Icons.chevron_right, size: 18, color: AppColors.theme),
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
  const _CourseCard({required this.course, required this.onTap});

  final _HomeCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                width: 120,
                height: 78,
                child: MDNetImage(imageUrl: course.picture),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SizedBox(
                height: 78,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColors.title,
                      ),
                    ),
                    if (course.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        course.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.content,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Row(
                      children: [
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  course.money.mdToPrice(),
                                  style: TextStyle(
                                    color: AppColors.price,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (course.oldMoney
                                    .mdToOldPrice()
                                    .isNotEmpty) ...[
                                  const SizedBox(width: 6),
                                  Text(
                                    course.oldMoney.mdToOldPrice(),
                                    style: TextStyle(
                                      color: AppColors.content,
                                      fontSize: 12,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: AppColors.content,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                        if (course.look.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: Text(
                              '${course.look} 人学习',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              textAlign: TextAlign.right,
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.content,
                              ),
                            ),
                          ),
                        ],
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

@JsonSerializable(createToJson: false)
class _HomeData {
  const _HomeData({this.banners = const [], this.hotCourses = const []});

  @JsonKey(readValue: _readBannerList)
  final List<_HomeBanner> banners;

  @JsonKey(readValue: _readHotCourseList)
  final List<_HomeCourse> hotCourses;

  factory _HomeData.fromJson(Map<String, dynamic>? json) =>
      _$HomeDataFromJson(json ?? const <String, dynamic>{});
}

@JsonSerializable(createToJson: false)
class _HomeBanner {
  const _HomeBanner({
    this.imageUrl = '',
    this.jumpType = '',
    this.jumpId = '',
    this.link = '',
  });

  @JsonKey(readValue: _readBannerImage, fromJson: _stringValue)
  final String imageUrl;

  @JsonKey(readValue: _readBannerJumpType, fromJson: _stringValue)
  final String jumpType;

  @JsonKey(readValue: _readBannerJumpId, fromJson: _stringValue)
  final String jumpId;

  @JsonKey(fromJson: _stringValue)
  final String link;

  factory _HomeBanner.fromJson(Map<String, dynamic> json) =>
      _$HomeBannerFromJson(json);
}

@JsonSerializable(createToJson: false)
class _HomeCourse {
  const _HomeCourse({
    this.id = '',
    this.type = '',
    this.picture = '',
    this.title = '',
    this.subtitle = '',
    this.look = '',
    this.money = '',
    this.oldMoney = '',
  });

  @JsonKey(fromJson: _stringValue)
  final String id;

  @JsonKey(fromJson: _stringValue)
  final String type;

  @JsonKey(readValue: _readCoursePicture, fromJson: _stringValue)
  final String picture;

  @JsonKey(fromJson: _stringValue)
  final String title;

  @JsonKey(fromJson: _stringValue)
  final String subtitle;

  @JsonKey(readValue: _readCourseLook, fromJson: _stringValue)
  final String look;

  @JsonKey(fromJson: _stringValue)
  final String money;

  @JsonKey(name: 'old_money', fromJson: _stringValue)
  final String oldMoney;

  factory _HomeCourse.fromJson(Map<String, dynamic> json) =>
      _$HomeCourseFromJson(json);
}

class _CategoryItem {
  const _CategoryItem(this.type, this.title, this.icon);

  final String type;
  final String title;
  final AssetGenImage icon;
}

Object? _readBannerList(Map<dynamic, dynamic> json, String _) {
  final container = json['banner_list'];
  return container is Map ? container['list'] : json['banners'];
}

Object? _readHotCourseList(Map<dynamic, dynamic> json, String _) {
  final container = json['rq_course'];
  return container is Map ? container['list'] : json['hotCourses'];
}

Object? _readBannerImage(Map<dynamic, dynamic> json, String _) =>
    json['banner_url'] ?? json['image_url'];

Object? _readBannerJumpType(Map<dynamic, dynamic> json, String _) =>
    json['behavior_type'] ?? json['jump_type'];

Object? _readBannerJumpId(Map<dynamic, dynamic> json, String _) =>
    json['behavior_id'] ?? json['jump_id'];

Object? _readCoursePicture(Map<dynamic, dynamic> json, String _) =>
    json['photo'] ?? json['picture'];

Object? _readCourseLook(Map<dynamic, dynamic> json, String _) =>
    json['view'] ?? json['look'];

String _stringValue(Object? value) => value?.toString() ?? '';
