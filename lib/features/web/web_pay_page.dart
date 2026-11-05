import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';

import '../../utils/utils.dart';

/// 未安装支付宝客户端时使用的 H5 收银台。
class WebPayPage extends StatefulWidget {
  const WebPayPage({required this.html, super.key});

  final String html;

  @override
  State<WebPayPage> createState() => _WebPayPageState();
}

class _WebPayPageState extends State<WebPayPage> {
  late final WebViewController _controller;
  int _progress = 0;
  bool _paymentHandled = false;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: (request) {
            final uri = Uri.tryParse(request.url);
            if (uri == null) return NavigationDecision.prevent;
            if (request.isMainFrame && _handlePaymentReturn(uri)) {
              return NavigationDecision.prevent;
            }
            // 无客户端时留在 H5 收银台，拦截支付宝等原生 scheme。
            return {
                  'http',
                  'https',
                  'about',
                  'data',
                }.contains(uri.scheme.toLowerCase())
                ? NavigationDecision.navigate
                : NavigationDecision.prevent;
          },
          onPageStarted: (url) {
            final uri = Uri.tryParse(url);
            if (uri != null) _handlePaymentReturn(uri);
          },
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onWebResourceError: (error) {
            if (error.isForMainFrame == true && mounted) {
              MDTotast.error('支付网页加载失败，请检查网络连接');
            }
          },
        ),
      );
    _loadPayment();
  }

  // 回跳仅用于刷新服务端订单状态，不作为到账凭据。
  bool _handlePaymentReturn(Uri uri) {
    final params = uri.queryParameters;
    final path = uri.path.toLowerCase();
    final returned =
        params['trade_status'] == 'TRADE_SUCCESS' ||
        (params['trade_no']?.isNotEmpty == true &&
            params['out_trade_no']?.isNotEmpty == true) ||
        path.contains('/pay/success') ||
        path.contains('/payment/success') ||
        path.endsWith('/success');
    if (!returned) return false;
    if (!_paymentHandled && mounted) {
      _paymentHandled = true;
      Navigator.of(context).pop(true);
    }
    return true;
  }

  Future<void> _loadPayment() async {
    try {
      if (widget.html.trim().isEmpty) {
        throw const FormatException('支付信息为空');
      }
      if (Platform.isAndroid) await _setAlipayMobileBrowserUserAgent();
      if (!mounted) return;
      final uri = Uri.tryParse(widget.html.trim());
      if (uri != null && (uri.scheme == 'https' || uri.scheme == 'http')) {
        await _controller.loadRequest(uri);
      } else {
        await _submitAlipayPaymentHtml(widget.html);
      }
    } catch (error) {
      Utils.log('WebPayPage load failed: $error');
      if (mounted) MDTotast.error('支付网页加载失败，请返回重试');
    }
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: MDAppBar(
        title: '支付宝支付',
        onBackPressed: () => Navigator.of(context).pop(false),
        bottom: _progress > 0 && _progress < 100
            ? PreferredSize(
                preferredSize: const Size.fromHeight(2),
                child: LinearProgressIndicator(value: _progress / 100),
              )
            : null,
      ),
      body: WebViewWidget(controller: _controller),
    );
  }
}
