import 'package:flutter/material.dart';

import '../../utils/utils.dart';
import '../share/share.dart';
import '../web/web_page.dart';

class ArticleDetailPage extends StatefulWidget {
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
  State<ArticleDetailPage> createState() => _ArticleDetailPageState();
}

class _ArticleDetailPageState extends State<ArticleDetailPage> {
  late Future<MDShareData> _shareData;

  @override
  void initState() {
    super.initState();
    _shareData = _loadShareData();
  }

  @override
  void didUpdateWidget(covariant ArticleDetailPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.url != widget.url ||
        oldWidget.special != widget.special ||
        oldWidget.id != widget.id) {
      _shareData = _loadShareData();
    }
  }

  Future<MDShareData> _loadShareData() async {
    final url = widget.url.trim();
    final query =
        Uri.tryParse(url)?.queryParameters ?? const <String, String>{};
    final String sp = widget.special?.trim() ?? '';
    final String id = widget.id?.trim() ?? '';

    Map<String, dynamic>? details;
    try {
        final result = await MDPost.sendApiSession(
          cmd: .articleNewsDetail,
          params: {'special': sp, 'news_id': id},
        );
        if (result.isSuccess) details = result.data;
      } catch (error) {
        Utils.log('Article share details load failed: $error');
      }

    return MDShareData(
      title: details?.mdString('title'),
      text: details?.mdString('share_content'),
      link: url,
      tools: const [.copyLink],
    );
  }

  @override
  Widget build(BuildContext context) {
    return WebPage(url: widget.url, shareType: .custom, shareData: _shareData);
  }
}
