// wxpay(仅限于android)
import 'dart:async';
import 'dart:io';
import 'package:fluwx/fluwx.dart';

/// 微信支付
class WxPay {
  WxPay._();

  /// 与 pubspec.yaml 中 fluwx 的 app_id 保持一致
  static const String _appId = 'wxd2948149a86a0237';

  static final Fluwx _fluwx = Fluwx();

  static bool _registered = false;

  /// 拉起微信支付
  /// 返回 null 表示支付成功
  static Future<String?> pay(Map<String, dynamic> params) async {
    if (Platform.isIOS) return 'iOS不支持微信支付';
    final prepayId = _text(params['prepayid']);
    final timestamp = int.tryParse(_text(params['timestamp'])) ?? 0;
    if (prepayId.isEmpty || timestamp <= 0) return '支付参数异常';

    final appId = _text(params['appid']);
    try {
      if (!_registered) {
        _registered = await _fluwx.registerApi(
          appId: appId.isEmpty ? _appId : appId,
          doOnIOS: false,
        );
      }
      if (!_registered) return '微信支付初始化失败';
      if (!await _fluwx.isWeChatInstalled) return '未安装微信，无法支付';

      final completer = Completer<String?>();
      final subscriber = _fluwx.addSubscriber((response) {
        if (response is! WeChatPaymentResponse || completer.isCompleted) {
          return;
        }
        switch (response.errCode) {
          case 0:
            completer.complete(null);
          case -2:
            completer.complete('用户取消支付');
          default:
            completer.complete('支付失败');
        }
      });
      try {
        final sent = await _fluwx.pay(
          which: Payment(
            appId: appId.isEmpty ? _appId : appId,
            partnerId: _text(params['partnerid']),
            prepayId: prepayId,
            packageValue: _text(params['package']),
            nonceStr: _text(params['noncestr']),
            timestamp: timestamp,
            sign: _text(params['sign']),
          ),
        );
        if (!sent && !completer.isCompleted) {
          completer.complete('微信支付拉起失败');
        }
        return await completer.future;
      } finally {
        subscriber.cancel();
      }
    } catch (error) {
      return '微信支付失败，请稍后重试';
    }
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}
