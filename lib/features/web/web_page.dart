import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:zslx_flutter/features/share/system_share.dart';
import 'package:zslx_flutter/utils/utils.dart';
import 'package:zslx_flutter/extensions/string_sign.dart';

enum WebType { url, html }

enum WebShareType { system }

class WebPage extends StatefulWidget {
  const WebPage({
    super.key,
    required this.url,
    this.disableFd = false,
    this.type = WebType.url,
    this.exts,
    this.shareType,
    this.onOpenCourseDetail,
    this.onOpenAppLogin,
    this.title,
  });

  final String url;
  final String? title;
  final bool disableFd;
  final WebType type;
  final Map<String, String>? exts;
  final WebShareType? shareType;
  final ValueChanged<Map<String, dynamic>>? onOpenCourseDetail;
  final VoidCallback? onOpenAppLogin;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _canGoBack = false;
  bool _isSharing = false;
  bool _isPageReady = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setBackgroundColor(AppColors.white)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if ({
              'http',
              'https',
              'about',
              'file',
              'data',
            }.contains(uri.scheme.toLowerCase())) {
              return NavigationDecision.navigate;
            }
            return NavigationDecision.prevent;
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress / 100);
          },
          onPageFinished: (_) {
            _updateCanGoBack();
            if (mounted) setState(() => _isPageReady = true);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              if (mounted) setState(() => _isPageReady = true);
              final description = error.description.toLowerCase();
              if (description.contains('unknown_url_scheme')) return;
              _showError('网页加载失败，请检查网络连接');
              Utils.log(
                'WebPage load error: ${error.errorCode} ${error.description}',
              );
            }
          },
        ),
      )
      ..addJavaScriptChannel(
        'openCourseDetailMethod',
        onMessageReceived: (message) =>
            _receiveMessage('openCourseDetailMethod', message.message),
      )
      ..addJavaScriptChannel(
        'openAppLoginMethod',
        onMessageReceived: (message) =>
            _receiveMessage('openAppLoginMethod', message.message),
      );
    _loadData();
  }

  Future<void> _loadData() async {
    final value = widget.url;
    if (value.isEmpty) return;

    String? requestUserAgent;
    try {
      final userAgent = (await _controller.getUserAgent())?.trim();
      const prefix = 'form=zslx system-type=ios';
      final suffix = '$prefix app-version=${AppConfig.apiVersion}';
      final configuredUserAgent = userAgent == null || userAgent.isEmpty
          ? suffix
          : '$userAgent $suffix';
      await _controller.setUserAgent(configuredUserAgent);
      requestUserAgent = configuredUserAgent;
    } catch (error) {
      Utils.log('WebPage User-Agent configuration failed: $error');
    }
    if (!mounted) return;

    if (widget.type == WebType.html) {
      try {
        await _controller.loadHtmlString(value);
      } catch (error) {
        _showError('网页内容加载失败，请稍后重试');
        Utils.log('WebPage HTML load error: $error');
      }
      return;
    }

    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      _showError('网页地址无效，请稍后重试');
      return;
    }

    final query = <String, String>{
      ...?widget.exts,
      if (_shouldAppendAppQuery(uri)) ..._appQuery(),
    };
    final Uri furi = query.isEmpty
        ? uri
        : uri.replace(queryParameters: {...uri.queryParameters, ...query});
    Utils.log('WebPage load URL: $furi');
    if (requestUserAgent != null) {
      Utils.log('WebPage request header User-Agent: $requestUserAgent');
    }
    try {
      await _controller.loadRequest(furi);
    } catch (error) {
      _showError('网页加载失败，请稍后重试');
      Utils.log('WebPage URL load error: $error');
    }
  }

  bool _shouldAppendAppQuery(Uri uri) {
    if (uri.scheme != 'http' && uri.scheme != 'https') return false;
    if (uri.pathSegments.isEmpty) return true;

    final lastSegment = uri.pathSegments.last;
    final dotIndex = lastSegment.lastIndexOf('.');
    if (dotIndex == -1 || dotIndex == lastSegment.length - 1) return true;

    const webExtensions = {
      'html',
      'xml',
      'png',
      'jpg',
      'jpeg',
      'gif',
      'webp',
      'mp4',
      'wav',
      'mp3',
      'pdf',
      'txt',
      'json',
      'csv',
      'xls',
      'xlsx',
      'doc',
      'docx',
      'ppt',
      'pptx',
      'zip',
      'rar',
      '7z',
    };
    return webExtensions.contains(
      lastSegment.substring(dotIndex + 1).toLowerCase(),
    );
  }

  Map<String, String> _appQuery() => {
    'user_id': MDUser.defualt.uid ?? '',
    'sign': StringSign.mdSign({
      'user_id': MDUser.defualt.uid ?? '',
    }, MDUser.defualt.token ?? ''),
    'current_version': AppConfig.appVersion,
  };

  void _showError(String message) {
    MDTotast.error(message);
  }

  Future<void> _updateCanGoBack() async {
    final canGoBack = await _controller.canGoBack();
    if (mounted && canGoBack != _canGoBack) {
      setState(() => _canGoBack = canGoBack);
    }
  }

  void _receiveMessage(String name, String message) {
    dynamic decoded;
    try {
      decoded = jsonDecode(message);
    } on FormatException {
      decoded = <String, dynamic>{};
    }
    final params = decoded is Map
        ? decoded.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};

    if (name == 'openAppLoginMethod') {
      widget.onOpenAppLogin?.call();
    } else if (name == 'openCourseDetailMethod') {
      widget.onOpenCourseDetail?.call(params);
    }
  }

  Future<void> _goBack() async {
    if (await _controller.canGoBack()) {
      await _controller.goBack();
      await _updateCanGoBack();
    } else if (mounted) {
      Navigator.of(context).pop();
    }
  }

  Future<void> _shareToSystem() async {
    if (_isSharing || widget.shareType != WebShareType.system) return;
    setState(() => _isSharing = true);
    try {
      await SystemShare.shareFile(widget.url);
    } finally {
      if (mounted) setState(() => _isSharing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !widget.disableFd,
      child: Scaffold(
        backgroundColor: AppColors.white,
        appBar: MDAppBar(
          title: widget.title ?? '',
          onBackPressed: _goBack,
          actions: [
            if (widget.shareType == WebShareType.system)
              IconButton(
                icon: const Icon(Icons.share),
                onPressed: _isSharing ? null : _shareToSystem,
              ),
          ],
          bottom: _progress > 0 && _progress < 1
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(2),
                  child: LinearProgressIndicator(
                    value: _progress,
                    color: AppColors.theme,
                  ),
                )
              : null,
        ),
        body: Stack(
          fit: StackFit.expand,
          children: [
            ColoredBox(color: AppColors.white),
            AnimatedOpacity(
              opacity: _isPageReady ? 1 : 0,
              duration: const Duration(milliseconds: 120),
              child: WebViewWidget(controller: _controller),
            ),
          ],
        ),
      ),
    );
  }
}
