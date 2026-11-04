import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:zslx_flutter/features/share/system_share.dart';
import 'package:zslx_flutter/utils/utils.dart';
import 'package:zslx_flutter/extensions/string_sign.dart';

enum WebType { url, html }

enum WebShareType { system }

class WebPage extends StatefulWidget {
  const WebPage({
    super.key,
    this.url,
    this.disableFd = false,
    this.type = WebType.url,
    this.exts,
    this.shareType,
    this.onOpenCourseDetail,
    this.onOpenAppLogin,
    this.isPaymentSuccessUrl,
    this.onPaymentSuccess,
    this.isPaymentPage = false,
    required this.title,
  });

  final String? url;
  final String title;
  final bool disableFd;
  final WebType type;
  final Map<String, String>? exts;
  final WebShareType? shareType;
  final ValueChanged<Map<String, dynamic>>? onOpenCourseDetail;
  final VoidCallback? onOpenAppLogin;
  final bool Function(Uri uri)? isPaymentSuccessUrl;
  final ValueChanged<Uri>? onPaymentSuccess;
  final bool isPaymentPage;

  @override
  State<WebPage> createState() => _WebPageState();
}

class _WebPageState extends State<WebPage> {
  late final WebViewController _controller;
  double _progress = 0;
  bool _canGoBack = false;
  bool _isSharing = false;
  bool _isPageReady = false;
  bool _paymentHandled = false;

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
            if (widget.isPaymentPage) {
              _launchExternalPaymentScheme(uri);
            }
            return NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            final uri = Uri.tryParse(url);
            if (uri != null && widget.isPaymentSuccessUrl?.call(uri) == true) {
              if (_paymentHandled) return;
              _paymentHandled = true;
              widget.onPaymentSuccess?.call(uri);
            }
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
    _prepareAndLoad();
  }

  Future<void> _prepareAndLoad() async {
    if (widget.isPaymentPage && Platform.isAndroid) {
      await _setAlipayMobileBrowserUserAgent();
    }
    if (mounted) await _loadData();
  }

  Future<void> _setAlipayMobileBrowserUserAgent() async {
    var androidVersion = '13';
    var deviceModel = 'Android Mobile';
    try {
      final info = await DeviceInfoPlugin().androidInfo;
      androidVersion = info.version.release;
      deviceModel = info.model.trim().isNotEmpty
          ? info.model.trim()
          : 'Android Mobile';
    } catch (_) {}

    final userAgent =
        'Mozilla/5.0 (Linux; Android $androidVersion; $deviceModel) '
        'AppleWebKit/537.36 (KHTML, like Gecko) '
        'Chrome/131.0.0.0 Mobile Safari/537.36';
    try {
      final platformController =
          _controller.platform as AndroidWebViewController;
      await platformController.setMixedContentMode(
        MixedContentMode.alwaysAllow,
      );

      final cookieManager = AndroidWebViewCookieManager(
        const PlatformWebViewCookieManagerCreationParams(),
      );
      await cookieManager.setAcceptThirdPartyCookies(platformController, true);

      await _controller.setUserAgent(userAgent);
      final actualUserAgent = await platformController.getUserAgent();
      Utils.log('Alipay WebView mobile UA requested: $userAgent');
      Utils.log('Alipay WebView mobile UA actual: $actualUserAgent');
    } catch (error) {
      Utils.log('Alipay WebView set mobile UA failed: $error');
    }
  }

  Future<void> _submitAlipayPaymentHtml(String html) async {
    final normalizedHtml = html.replaceAll(r'\/', '/');
    final formMatch = RegExp(
      r"""<form\b[^>]*>[\s\S]*?</form>""",
      caseSensitive: false,
    ).firstMatch(normalizedHtml);
    final formHtml = formMatch?.group(0) ?? normalizedHtml;

    final actionMatch = RegExp(
      r"""action\s*=\s*(["'])(.*?)\1""",
      caseSensitive: false,
      dotAll: true,
    ).firstMatch(formHtml);
    if (actionMatch == null) {
      throw const FormatException('支付宝支付表单缺少 action');
    }

    var action = _decodeHtmlAttribute(actionMatch.group(2) ?? '').trim();
    if (!action.contains('://')) {
      action = 'https://openapi.alipay.com/$action';
    }
    final actionUri = Uri.tryParse(action);
    if (actionUri == null || !actionUri.hasScheme) {
      throw const FormatException('支付宝支付表单 action 无效');
    }

    final fields = <String, String>{};
    final inputPattern = RegExp(
      r"""<input\b[^>]*>""",
      caseSensitive: false,
      dotAll: true,
    );
    for (final inputMatch in inputPattern.allMatches(formHtml)) {
      final input = inputMatch.group(0) ?? '';
      final nameMatch = RegExp(
        r"""name\s*=\s*(["'])(.*?)\1""",
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(input);
      final valueMatch = RegExp(
        r"""value\s*=\s*(["'])(.*?)\1""",
        caseSensitive: false,
        dotAll: true,
      ).firstMatch(input);
      if (nameMatch == null) continue;
      final name = _decodeHtmlAttribute(nameMatch.group(2) ?? '').trim();
      final value = _decodeHtmlAttribute(valueMatch?.group(2) ?? '');
      if (name.isNotEmpty) fields[name] = value;
    }
    if (fields.isEmpty) {
      throw const FormatException('支付宝支付表单缺少提交字段');
    }

    final body = fields.entries
        .map(
          (entry) =>
              '${Uri.encodeQueryComponent(entry.key)}=${Uri.encodeQueryComponent(entry.value)}',
        )
        .join('&');
    final origin = Uri(
      scheme: actionUri.scheme,
      host: actionUri.host,
      port: actionUri.hasPort ? actionUri.port : null,
    );

    await _controller.loadRequest(
      actionUri,
      method: LoadRequestMethod.post,
      headers: {
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept':
            'text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8',
        'Accept-Language': 'zh-CN,zh;q=0.9,en;q=0.8',
        'Referer': origin.toString(),
      },
      body: Uint8List.fromList(utf8.encode(body)),
    );
  }

  String _decodeHtmlAttribute(String value) {
    return value
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>');
  }

  Future<void> _loadData() async {
    final value = widget.url;
    if (value == null || value.isEmpty) return;

    if (widget.type == WebType.html) {
      try {
        if (widget.isPaymentPage) {
          await _submitAlipayPaymentHtml(value);
          return;
        }
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
      'user_id': MDUser.defualt.uid ?? '',
      'sign': StringSign.mdSign({
        'user_id': MDUser.defualt.uid ?? '',
      }, MDUser.defualt.token ?? ''),
      'current_version': AppConfig.appVersion,
    };
    try {
      await _controller.loadRequest(
        uri.replace(queryParameters: {...uri.queryParameters, ...query}),
      );
    } catch (error) {
      _showError('网页加载失败，请稍后重试');
      Utils.log('WebPage URL load error: $error');
    }
  }

  Future<void> _launchExternalPaymentScheme(Uri uri) async {
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched) {
        Utils.log('WebPage external payment scheme not handled: $uri');
      }
    } catch (error) {
      Utils.log('WebPage external payment scheme launch failed: $error');
    }
  }

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
          title: widget.title,
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
