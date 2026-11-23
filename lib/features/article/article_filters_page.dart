import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';

class ArticleOption {
  const ArticleOption(this.id, this.label, [this.children = const []]);

  final String id;
  final String label;
  final List<ArticleOption> children;

  static List<ArticleOption> fromList(Object? value) {
    if (value is Map) {
      final rows = value['list'] ?? value['options'];
      if (rows is List) return fromList(rows);
      return [
        for (final entry in value.entries)
          if (entry.value is String || entry.value is num)
            ArticleOption(entry.key.toString(), entry.value.toString()),
      ];
    }
    if (value is! List) return const [];
    return [
          for (final item in value)
            if (item is Map)
              ArticleOption(
                castTo<String>(
                      item['id'] ??
                          item['value'] ??
                          item['sub_cate_id'] ??
                          item['cate_id'] ??
                          item['year'] ??
                          item['code'] ??
                          item['city_id'] ??
                          item['city'] ??
                          item['province_id'] ??
                          item['province'] ??
                          item['name'],
                    ) ??
                    '',
                castTo<String>(
                      item['name'] ??
                          item['label'] ??
                          item['title'] ??
                          item['cate_name'] ??
                          item['text'] ??
                          item['city_name'] ??
                          item['city'] ??
                          item['province_name'] ??
                          item['province'] ??
                          item['year'] ??
                          item['value'],
                    ) ??
                    '',
                fromList(
                  item['children'] ??
                      item['cities'] ??
                      item['city_list'] ??
                      item['city'] ??
                      item['sub_cates'],
                ),
              )
            else if (item is String || item is num)
              ArticleOption(item.toString(), item.toString()),
        ]
        .where((option) => option.id.isNotEmpty && option.label.isNotEmpty)
        .toList();
  }
}

class ArticleFilters {
  const ArticleFilters({this.province, this.year, this.city});

  final ArticleOption? province;
  final ArticleOption? year;
  final ArticleOption? city;
}

enum ArticleFilterMode { all, province, year }

class ArticleFiltersPage extends StatefulWidget {
  const ArticleFiltersPage({
    required this.initial,
    this.mode = ArticleFilterMode.all,
    super.key,
  });

  final ArticleFilters initial;
  final ArticleFilterMode mode;

  @override
  State<ArticleFiltersPage> createState() => _ArticleFiltersPageState();
}

class _ArticleFiltersPageState extends State<ArticleFiltersPage> {
  late ArticleOption? _province = widget.initial.province;
  late ArticleOption? _year = widget.initial.year;
  late ArticleOption? _city = widget.initial.city;
  List<ArticleOption> _provinces = const [];
  List<ArticleOption> _years = const [];
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    if (_loading) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    MDTotast.showLoading();
    final result = await MDPost.sendApiSession(cmd: .articleFilters)
        .whenComplete(MDTotast.hideLoading);
    if (!mounted) return;
    setState(() {
      _loading = false;
      if (!result.isSuccess) {
        _error = result.msg ?? '筛选条件加载失败';
        return;
      }
      final data = result.data;
      final provinces = _readOptions(data, const [
        'provinces',
        'province',
        'province_list',
        'regions',
        'region',
        'region_list',
      ]);
      final years = _readOptions(data, const ['years', 'year', 'year_list']);
      if ((widget.mode != .year && provinces == null) ||
          (widget.mode != .province && years == null)) {
        _error = '筛选条件数据格式错误';
        return;
      }
      _provinces = [
        for (final province in provinces ?? const <ArticleOption>[])
          ArticleOption(
            province.id,
            province.label,
            province.children.isNotEmpty
                ? province.children
                : _readCities(data, province),
          ),
      ];
      _years = years ?? const [];
      _loaded = true;
    });
  }

  static List<ArticleOption>? _readOptions(
    Map<String, dynamic>? data,
    List<String> keys,
  ) {
    final nested = data?['filters'] ?? data?['data'];
    for (final source in [data, if (nested is Map) nested]) {
      for (final key in keys) {
        final value = source?[key];
        if (value is List || value is Map) {
          return ArticleOption.fromList(value);
        }
      }
    }
    return null;
  }

  static List<ArticleOption> _readCities(
    Map<String, dynamic>? data,
    ArticleOption province,
  ) {
    for (final source in [data, data?['filters'], data?['data']]) {
      if (source is! Map) continue;
      for (final key in [
        'cities',
        'city',
        'city_list',
        'cities_by_province',
        'city_map',
      ]) {
        final cities = source[key];
        final Object? rows;
        if (cities is Map) {
          final group =
              cities[province.id] ??
              cities[int.tryParse(province.id)] ??
              cities[province.label];
          rows = group is Map
              ? group['cities'] ?? group['city_list'] ?? group
              : group;
        } else if (cities is List) {
          final matching = cities.whereType<Map>().where((city) {
            final parent = castTo<String>(
              city['province_id'] ??
                  city['province_code'] ??
                  city['parent_id'] ??
                  city['pid'] ??
                  city['province'] ??
                  city['province_name'],
            );
            return parent == province.id || parent == province.label;
          });
          rows = [
            for (final city in matching)
              ...switch (city['cities'] ??
                  city['city_list'] ??
                  city['children']) {
                final List children => children,
                _ => [city],
              },
          ];
        } else {
          continue;
        }
        final options = ArticleOption.fromList(rows);
        if (options.isNotEmpty) return options;
      }
    }
    return const [];
  }

  @override
  Widget build(BuildContext context) {
    final cities =
        _provinces
            .where((option) => option.id == _province?.id)
            .firstOrNull
            ?.children ??
        const <ArticleOption>[];
    return Scaffold(
      body: MDPageBackground(
        child: SafeArea(
          child: Column(
            crossAxisAlignment: .stretch,
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: MDAppBar(
                  title: '资讯筛选',
                  centerTitle: false,
                  backgroundColor: AppColors.transparent,
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    if (_error case final error?) ...[
                      Text(error),
                      TextButton(onPressed: _load, child: const Text('重新加载')),
                    ],
                    if (_loaded) ...[
                      if (widget.mode != .year)
                        _section('省份 / 地区', '全部地区', _provinces, _province, (
                          value,
                        ) {
                          setState(() {
                            if (_province?.id != value?.id) _city = null;
                            _province = value;
                          });
                        }),
                      if (widget.mode != .year && cities.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        _section('城市', '全部城市', cities, _city, (value) {
                          setState(() => _city = value);
                        }),
                      ],
                      if (widget.mode != .province) ...[
                        if (widget.mode == .all) const SizedBox(height: 24),
                        _section('年份', '全部年份', _years, _year, (value) {
                          setState(() => _year = value);
                        }),
                      ],
                    ],
                  ],
                ),
              ),
              ColoredBox(
                color: AppColors.white,
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                  child: FilledButton(
                    onPressed: !_loaded
                        ? null
                        : () => AppRouter.pop(
                            context,
                            ArticleFilters(
                              province: _province,
                              year: _year,
                              city: _city,
                            ),
                          ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.theme,
                      splashFactory: NoSplash.splashFactory,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text('查看筛选结果'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _section(
    String title,
    String allLabel,
    List<ArticleOption> options,
    ArticleOption? selected,
    ValueChanged<ArticleOption?> onSelected,
  ) {
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.bigTitle,
            fontSize: 18,
            fontWeight: .w700,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final option in [
              null,
              ...options.where(
                (option) => option.id != '0' && option.id != 'all',
              ),
            ])
              ChoiceChip(
                label: Text(option?.label ?? allLabel),
                selected: selected?.id == option?.id,
                showCheckmark: false,
                backgroundColor: AppColors.white,
                selectedColor: AppColors.lightTheme,
                labelStyle: TextStyle(
                  color: selected?.id == option?.id
                      ? AppColors.theme
                      : AppColors.content,
                ),
                shape: const StadiumBorder(),
                side: BorderSide(color: AppColors.border),
                onSelected: (_) => onSelected(option),
              ),
          ],
        ),
      ],
    );
  }
}
