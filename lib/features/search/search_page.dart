import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';
import '../article/article_card.dart';
import '../courses/course_list_page.dart';

class SearchPage extends StatefulWidget {
  const SearchPage({super.key});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();
  final _resultsKey = GlobalKey<RefreshListViewState<Map<String, dynamic>>>();
  String _keywords = '';

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _search() {
    final keywords = _controller.text.trim();
    if (keywords.isEmpty) {
      return;
    }
    FocusScope.of(context).unfocus();
    setState(() => _keywords = keywords);
    _resultsKey.currentState?.refresh();
  }

  void _clearSearch() {
    _controller.clear();
    setState(() => _keywords = '');
  }

  Future<RefreshResult<Map<String, dynamic>>> _loadResults(int page) async {
    final result = await MDPost.sendApiSession(
      cmd: .search,
      params: {'keywords': _keywords, 'include_news': 1, 'page': page},
    );
    if (!result.isSuccess) {
      return RefreshResult.failed(result.msg ?? '搜索失败，请重试');
    }
    final data = result.data;
    final nested = data?['data'];
    final rows =
        data?['list'] ??
        data?['results'] ??
        (nested is Map
            ? nested['list'] ?? nested['results'] ?? nested['data']
            : nested);
    if (data != null && rows is! List) {
      return RefreshResult.failed('搜索结果数据格式错误');
    }
    final items = [
      if (rows is List)
        for (final item in rows.whereType<Map>())
          if (item['result_type'] == 'course' || item['result_type'] == 'news')
            item.map((key, value) => MapEntry(key.toString(), value)),
    ];
    final payload = nested is Map<String, dynamic> ? nested : data;
    final paging =
        payload?.mdAs<Map<String, dynamic>>('page_info') ??
        data?.mdAs<Map<String, dynamic>>('page_info') ??
        payload;
    final hasMore = paging?.mdBool('has_more');
    final lastPage = paging?.mdInt('last_page') ?? paging?.mdInt('total_page');
    return RefreshResult.success(
      items,
      noMore:
          rows is! List ||
          rows.isEmpty ||
          (hasMore != null ? !hasMore : lastPage != null && page >= lastPage),
    );
  }

  void _openCourse(CourseItem course) {
    if (course.id.isEmpty || course.type.isEmpty) {
      MDTotast.error('暂无课程详情');
      return;
    }
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseDetail,
      queryParameters: {'type': course.type, 'id': course.id},
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
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: MDAppBar(
                  title: '综合搜索',
                  centerTitle: false,
                  backgroundColor: AppColors.transparent,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        focusNode: _focusNode,
                        onTapOutside: (_) => _focusNode.unfocus(),
                        textInputAction: TextInputAction.search,
                        onSubmitted: (_) => _search(),
                        decoration: InputDecoration(
                          prefixIcon: Icon(
                            Icons.search,
                            color: AppColors.bigTitle,
                          ),
                          suffixIcon: TextFieldTapRegion(
                            child: ListenableBuilder(
                              listenable: Listenable.merge([
                                _controller,
                                _focusNode,
                              ]),
                              builder: (context, _) {
                                if (!_focusNode.hasFocus ||
                                    _controller.text.isEmpty) {
                                  return const SizedBox.shrink();
                                }
                                return IconButton(
                                  tooltip: '清空搜索',
                                  onPressed: _clearSearch,
                                  icon: Icon(
                                    Icons.cancel_outlined,
                                    color: AppColors.content,
                                    size: 16,
                                  ),
                                  style: IconButton.styleFrom(
                                    splashFactory: NoSplash.splashFactory,
                                  ),
                                );
                              },
                            ),
                          ),
                          hintText: '搜索资讯和课程',
                          filled: true,
                          fillColor: AppColors.white,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: AppColors.border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton(
                      onPressed: _search,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.theme,
                        splashFactory: NoSplash.splashFactory,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9),
                        ),
                      ),
                      child: const Text('搜索'),
                    ),
                  ],
                ),
              ),
              if (_keywords.isNotEmpty)
                Expanded(
                  child: RefreshListView<Map<String, dynamic>>(
                    key: _resultsKey,
                    onData: _loadResults,
                    emptyText: '暂无相关搜索结果',
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
                    header: Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Text(
                        '搜索结果',
                        style: TextStyle(
                          color: AppColors.bigTitle,
                          fontSize: 18,
                          fontWeight: .w700,
                        ),
                      ),
                    ),
                    itemBuilder: (_, item, _) {
                      final Widget card;
                      if (item['result_type'] == 'course') {
                        final course = CourseItem.fromJson(item);
                        card = _SearchCourseCard(
                          course: course,
                          data: item,
                          onTap: () => _openCourse(course),
                        );
                      } else {
                        card = Semantics(
                          button: true,
                          child: GestureDetector(
                            onTap: () =>
                                _openArticle(item.mdStringOr('article_link')),
                            child: ArticleCard(article: ArticleSummary(item)),
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: card,
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchCourseCard extends StatelessWidget {
  const _SearchCourseCard({
    required this.course,
    required this.data,
    required this.onTap,
  });

  final CourseItem course;
  final Map<String, dynamic> data;
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
    final tags = data['tags'];
    final hours = data.mdStringOr('keshi');
    final teacher = data.mdStringOr('teacher_name');
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
                    if (category.isNotEmpty)
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
                            category,
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
                    if (tags is List && tags.whereType<String>().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            for (final tag in tags.whereType<String>().where(
                              (tag) => tag.isNotEmpty,
                            ))
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
