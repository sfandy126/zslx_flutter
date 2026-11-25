import 'package:flutter/material.dart';

import '../web/web_page.dart';

class ArticleDetailPage extends StatelessWidget {
  const ArticleDetailPage({
    super.key,
    required this.url,
    this.special,
    this.id,
  });

  final String url;
  final String? special;
  final String? id;

  @override
  Widget build(BuildContext context) {
    return WebPage(url: url);
  }
}
