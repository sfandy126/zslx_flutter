import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';
import 'article_card.dart';
import 'article_filters_page.dart';

class ArticlePage extends StatefulWidget {
  const ArticlePage({super.key});

  @override
  State<ArticlePage> createState() => _ArticlePageState();
}

class _ArticlePageState extends State<ArticlePage> {
  static const _all = ArticleOption('0', '全部');

  List<ArticleOption> _categories = const [];
  String? _error;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadCategories();
    });
  }

  Future<void> _loadCategories() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    MDTotast.showLoading();
    final result = await MDPost.sendApiSession(cmd: .articleNewsCate)
        .whenComplete(MDTotast.hideLoading);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!result.isSuccess) {
        _error = result.msg ?? '资讯分类加载失败';
        return;
      }
      final options = _readCategories(result.data);
      _categories = [
        _all,
        ...options.where(
          (option) =>
              option.id != _all.id &&
              option.id != 'all' &&
              option.label != '全部',
        ),
      ];
    });
  }

  static List<ArticleOption> _readCategories(Map<String, dynamic>? data) {
    final nested = data?['data'];
    final payload = nested is Map ? nested : data;
    final rows = payload?['list'] ?? payload?['categories'] ?? nested;
    if (rows is! List) return ArticleOption.fromList(rows);

    final categories = rows.whereType<Map>().toList();
    final subcategories =
        payload?['sub_cates'] ??
        payload?['subcategories'] ??
        payload?['sub_cate'];
    return [
      for (final row in categories)
        if (_parentId(row) == null || _parentId(row) == '0')
          ..._readCategory(row, categories, subcategories),
    ];
  }

  static String? _parentId(Map row) {
    final id = castTo<String>(row['parent_id'] ?? row['pid']);
    return id == '' ? null : id;
  }

  static List<ArticleOption> _readCategory(
    Map row,
    List<Map> categories,
    Object? subcategories,
  ) {
    final option = ArticleOption.fromList([row]).firstOrNull;
    if (option == null) return const [];
    final nested = ArticleOption.fromList(
      row['children'] ??
          row['sub_cates'] ??
          row['sub_cate'] ??
          row['subcategories'] ??
          row['child'] ??
          row['list'],
    );
    final grouped = subcategories is Map
        ? subcategories[option.id] ?? subcategories[int.tryParse(option.id)]
        : null;
    final children = [
      ...nested,
      ...ArticleOption.fromList(grouped),
      ...ArticleOption.fromList([
        for (final child in categories)
          if (_parentId(child) == option.id && option.id != '0') child,
        if (subcategories is List)
          for (final child in subcategories.whereType<Map>())
            if ((castTo<String>(
                  child['parent_id'] ?? child['pid'] ?? child['cate_id'],
                )) ==
                option.id)
              child,
      ]),
    ];
    return [
      ArticleOption(
        option.id,
        option.label,
        {for (final child in children) child.id: child}.values.toList(),
      ),
    ];
  }

  void _openFavorites() {
    AppRouter.pushNamed<void>(
      context,
      RouterNames.favorites,
      queryParameters: {'cate_id': '1'},
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MDPageBackground(
        child: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 6, 12, 0),
                child: Row(
                  children: [
                    Text(
                      '资讯',
                      style: TextStyle(
                        color: AppColors.bigTitle,
                        fontSize: 28,
                        fontWeight: .w800,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: '资讯收藏',
                      onPressed: _openFavorites,
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
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 6),
                child: OutlinedButton.icon(
                  onPressed: () {
                    // TODO: 接入资讯搜索页。
                  },
                  icon: const Icon(Icons.search),
                  label: const Text('搜索公告、真题和学习资料'),
                  style: OutlinedButton.styleFrom(
                    alignment: Alignment.centerLeft,
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: AppColors.white,
                    foregroundColor: AppColors.bigTitle,
                    side: BorderSide(color: AppColors.border),
                    splashFactory: NoSplash.splashFactory,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              if (_error case final error?)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: .min,
                      children: [
                        Text(error),
                        TextButton(
                          onPressed: _loadCategories,
                          child: const Text('重新加载'),
                        ),
                      ],
                    ),
                  ),
                ),
              if (_categories.isNotEmpty)
                Expanded(
                  child: DefaultTabController(
                    length: _categories.length,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: TabBar(
                            isScrollable: true,
                            tabAlignment: .start,
                            labelColor: AppColors.bigTitle,
                            unselectedLabelColor: AppColors.content,
                            indicatorColor: AppColors.articleCategoryIndicator,
                            dividerColor: AppColors.border,
                            splashFactory: NoSplash.splashFactory,
                            tabs: [
                              for (final option in _categories)
                                Tab(text: option.label),
                            ],
                          ),
                        ),
                        Expanded(
                          child: TabBarView(
                            children: [
                              for (final option in _categories)
                                _ArticleCategoryPage(
                                  key: ValueKey(option.id),
                                  category: option,
                                ),
                            ],
                          ),
                        ),
                      ],
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

class _ArticleCategoryPage extends StatefulWidget {
  const _ArticleCategoryPage({required this.category, super.key});

  final ArticleOption category;

  @override
  State<_ArticleCategoryPage> createState() => _ArticleCategoryPageState();
}

class _ArticleCategoryPageState extends State<_ArticleCategoryPage>
    with AutomaticKeepAliveClientMixin {
  final _listKey = GlobalKey<RefreshListViewState<ArticleSummary>>();
  ArticleOption? _subcategory;
  ArticleFilters _filters = const ArticleFilters();

  @override
  bool get wantKeepAlive => true;

  Future<RefreshResult<ArticleSummary>> _loadPage(int page) async {
    final result = await MDPost.sendApiSession(
      cmd: .articleNewsList,
      params: {
        'page': page,
        'cate_id': widget.category.id,
        if (_subcategory case final option?) 'sub_cate_id': option.id,
        if (_filters.province case final option?) 'area_id': option.id,
        if (_filters.year case final option?) 'year_id': option.id,
        if (_filters.city case final option?) 'city_id': option.id,
      },
    );
    if (!result.isSuccess) return RefreshResult.failed(result.msg ?? '资讯加载失败');
    final data = result.data;
    final rows = data?['list'] ?? data?['data'];
    if (data != null && rows is! List) {
      return RefreshResult.failed('资讯列表数据格式错误');
    }
    final articles = [
      if (rows is List)
        for (final row in rows.whereType<Map>())
          ArticleSummary(
            row.map((key, value) => MapEntry(key.toString(), value)),
          ),
    ];
    final paging = data?.mdAs<Map<String, dynamic>>('page_info') ?? data;
    final lastPage = paging?.mdInt('last_page') ?? paging?.mdInt('total_page');
    return RefreshResult.success(
      articles,
      noMore:
          articles.isEmpty ||
          paging?.mdBool('has_more') == false ||
          (lastPage != null && page >= lastPage),
    );
  }

  Future<void> _openFilters(ArticleFilterMode mode) async {
    final filters = await AppRouter.pushNamed<ArticleFilters>(
      context,
      RouterNames.articleFilters,
      queryParameters: {'mode': mode.name},
      extra: _filters,
    );
    if (!mounted || filters == null) return;
    setState(() => _filters = filters);
    _listKey.currentState?.refresh();
  }

  void _selectSubcategory(ArticleOption? option) {
    if (_subcategory?.id == option?.id) return;
    setState(() => _subcategory = option);
    _listKey.currentState?.refresh();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final subcategories = widget.category.children.where(
      (option) =>
          option.id != '0' && option.id != 'all' && option.label != '全部栏目',
    );
    return Column(
      children: [
        if (subcategories.isNotEmpty)
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18),
              scrollDirection: Axis.horizontal,
              children: [
                for (final option in [null, ...subcategories])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(option?.label ?? '全部栏目'),
                      selected: _subcategory?.id == option?.id,
                      showCheckmark: false,
                      side: BorderSide.none,
                      backgroundColor: AppColors.lightTheme,
                      selectedColor: AppColors.theme.withValues(alpha: .14),
                      labelStyle: TextStyle(
                        color: _subcategory?.id == option?.id
                            ? AppColors.theme
                            : AppColors.content,
                        fontSize: 12,
                      ),
                      onSelected: (_) => _selectSubcategory(option),
                    ),
                  ),
              ],
            ),
          ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              _filterButton(
                _filters.province?.label ?? '全部地区',
                Icons.expand_more,
                .province,
              ),
              _filterButton(
                _filters.year?.label ?? '全部年份',
                Icons.expand_more,
                .year,
              ),
              _filterButton(
                _filters.city?.label ?? '城市 / 栏目',
                Icons.tune,
                .all,
              ),
            ],
          ),
        ),
        Expanded(
          child: RefreshListView<ArticleSummary>(
            key: _listKey,
            onData: _loadPage,
            emptyText: '暂无匹配资讯',
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
            itemBuilder: (_, article, _) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ArticleCard(article: article),
            ),
          ),
        ),
      ],
    );
  }

  Widget _filterButton(String label, IconData icon, ArticleFilterMode mode) {
    return Expanded(
      child: TextButton(
        onPressed: () => _openFilters(mode),
        style: TextButton.styleFrom(
          foregroundColor: AppColors.content,
          padding: const EdgeInsets.symmetric(horizontal: 4),
          splashFactory: NoSplash.splashFactory,
        ),
        child: Row(
          mainAxisAlignment: .center,
          children: [
            Flexible(child: Text(label, overflow: .ellipsis, maxLines: 1)),
            const SizedBox(width: 2),
            Icon(icon, size: 16),
          ],
        ),
      ),
    );
  }
}
