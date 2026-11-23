import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class ArticleSummary {
  ArticleSummary(Map<String, Object?> json)
    : id = (json['article_id'] ?? json['news_id'] ?? json['id']).mdToString(),
      special = json['special'].mdToString(),
      title = (json['title'] ?? json['name']).mdToString(),
      category = (json['cate_name'] ?? json['category_name']).mdToString(),
      date = (json['date'] ?? json['add_time'] ?? json['publish_time'])
          .mdToString(),
      views = (json['view'] ?? json['scan'] ?? json['views']).mdToString(),
      recommended =
          castTo<bool>(json['is_recommend'] ?? json['recommend']) ?? false;

  final String id;
  final String special;
  final String title;
  final String category;
  final String date;
  final String views;
  final bool recommended;
}

class ArticleCard extends StatelessWidget {
  const ArticleCard({required this.article, super.key});

  final ArticleSummary article;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(14);
    final metadata = TextStyle(color: AppColors.content, fontSize: 12);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: radius,
      ),
      child: Column(
        crossAxisAlignment: .start,
        children: [
          if (article.category.isNotEmpty || article.recommended) ...[
            Wrap(
              spacing: 8,
              runSpacing: 4,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                if (article.category.isNotEmpty)
                  _badge(
                    article.category,
                    AppColors.theme,
                    AppColors.lightTheme,
                  ),
                if (article.recommended)
                  _badge(
                    '♨ 推荐',
                    AppColors.warningTitle,
                    AppColors.warningBackground,
                  ),
              ],
            ),
            const SizedBox(height: 10),
          ],
          Text(
            article.title,
            style: TextStyle(
              color: AppColors.bigTitle,
              fontSize: 16,
              fontWeight: .w700,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              if (article.date.isNotEmpty) ...[
                Icon(
                  Icons.event_available_outlined,
                  size: 14,
                  color: AppColors.content,
                ),
                const SizedBox(width: 5),
              ],
              Expanded(child: Text(article.date, style: metadata)),
              if (article.views.isNotEmpty) ...[
                Icon(
                  Icons.article_outlined,
                  size: 14,
                  color: AppColors.content,
                ),
                const SizedBox(width: 5),
                Text('${article.views} 浏览', style: metadata),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _badge(String label, Color foreground, Color background) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: Text(label, style: TextStyle(color: foreground, fontSize: 12)),
      ),
    );
  }
}
