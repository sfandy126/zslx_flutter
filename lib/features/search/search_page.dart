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

  List<Map<String, dynamic>> _popularArticles = const [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadPopularArticles();
    });
  }

  Future<void> _loadPopularArticles() async {
    MDTotast.showLoading();
    final result = await MDPost.sendApiSession(cmd: .searchRecomArticle)
        .whenComplete(MDTotast.hideLoading);
    if (!mounted) return;

    final data = result.data;
    final nested = data?['data'];
    final rows =
        data?['list'] ??
        data?['news'] ??
        (nested is Map ? nested['list'] ?? nested['news_list'] : nested);
    if (!result.isSuccess || rows is! List) return;
    setState(() {
      _popularArticles = rows
          .whereType<Map>()
          .map(
            (row) => row.map((key, value) => MapEntry(key.toString(), value)),
          )
          .toList();
    });
  }

  String _articleUrl(Map<String, dynamic> item) =>
      item.mdString('article_link') ??
      item.mdString('url') ??
      item.mdStringOr('link');

  Widget _articleCard(Map<String, dynamic> item) {
    return Semantics(
      button: true,
      child: GestureDetector(
        onTap: () => _openArticle(_articleUrl(item)),
        child: ArticleCard(article: ArticleSummary(item)),
      ),
    );
  }

  Widget _buildPopularArticles() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 16),
      children: [
        Text(
          '热门资讯',
          style: TextStyle(
            color: AppColors.bigTitle,
            fontSize: 18,
            fontWeight: .w700,
          ),
        ),
        const SizedBox(height: 10),
        for (final (index, article) in _popularArticles.indexed)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Material(
              color: AppColors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(color: AppColors.border),
              ),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => _openArticle(_articleUrl(article)),
                splashFactory: NoSplash.splashFactory,
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    crossAxisAlignment: .start,
                    children: [
                      Container(
                        constraints: const BoxConstraints(minWidth: 22),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.lightTheme,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          '${index + 1}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: AppColors.theme,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          ArticleSummary(article).title,
                          style: TextStyle(
                            color: AppColors.bigTitle,
                            fontSize: 15,
                            fontWeight: .w600,
                            height: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

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
                        card = CompactCourseCard(
                          course: course,
                          onTap: () => _openCourse(course),
                        );
                      } else {
                        card = _articleCard(item);
                      }
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: card,
                      );
                    },
                  ),
                )
              else if (_popularArticles.isNotEmpty)
                Expanded(child: _buildPopularArticles()),
            ],
          ),
        ),
      ),
    );
  }
}
