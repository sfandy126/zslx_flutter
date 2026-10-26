// alipay(仅限于android)
import 'dart:async';
import 'dart:io';

import 'package:alipay_kit_new/alipay_kit.dart';

/// 支付宝支付
/// 基于 alipay_kit_new + alipay_kit_android_new（原生支付宝 SDK）实现
class Alipay {
  Alipay._();

  static final AlipayKitPlatform _platform = AlipayKitPlatform.instance;

  /// 拉起支付宝支付
  static Future<String?> pay(String order) async {
    if (Platform.isIOS) return 'iOS不支持支付宝支付';
    if (!await _platform.isInstalled()) return '未安装支付宝，无法支付';

    final completer = Completer<String?>();
    final subscription = _platform.payResp().listen((resp) {
      if (completer.isCompleted) return;
      switch (resp.resultStatus) {
        case 9000:
          completer.complete(null);
        case 8000:
          completer.complete('订单正在处理中');
        case 4000:
          completer.complete('订单支付失败');
        case 5000:
          completer.complete('重复请求，请稍后重试');
        case 6001:
          completer.complete('用户取消支付');
        case 6002:
          completer.complete('网络连接错误');
        default:
          completer.complete('支付失败');
      }
    });
    try {
      await _platform.pay(orderInfo: order, isShowLoading: true);
      return await completer.future;
    } catch (error) {
      return '支付宝支付发起失败，请稍后重试';
    } finally {
      await subscription.cancel();
    }
  }
}
