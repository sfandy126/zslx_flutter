import 'package:flutter/material.dart';

import '../web/web_page.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({required this.url, super.key});

  final String url;

  @override
  Widget build(BuildContext context) {
    return WebPage(url: url, title: '公告详情', includeAppQuery: false);
  }
}
