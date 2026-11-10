// ios内购StoreKit
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../../utils/utils.dart';

typedef _Verify = ({bool ok, String? msg});
typedef _PurchaseOutcome = ({
  SK2ProductPurchaseResult? result,
  _Verify? verify,
});

/// iOS 内购（StoreKit 2）
/// - 服务端校验失败的交易不 finish，待下次启动/交易更新/再次购买时重试，避免丢单。
class MDStoreKit implements InAppPurchase2CallbackAPI {
  MDStoreKit._();

  static final MDStoreKit _default = MDStoreKit._();

  static final StreamController<void> _changes =
      StreamController<void>.broadcast();
  static Stream<void> get changes => _changes.stream;
  static final RegExp _uuidReg = RegExp(
    r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
  );

  bool _configured = false;

  final Map<String, SK2Product> _productCache = {};

  /// 购买流程进行中标记，防止重复触发导致 HUD 叠加/重复下单
  bool _isProcessing = false;

  String? _purchasingToken;
  Completer<_Verify>? _purchaseVerification;

  final Map<int, Future<_Verify>> _verifying = {};

  final Set<int> _finishedIds = {};

  /// 校验成功后异步结束的交易，避免 finish 阻塞购买结果提示。
  final Set<int> _finishingIds = {};

  static void configuration() {
    if (!Platform.isIOS) return;
    _default._configure();
  }

  /// 购买完成通过 [changes] 广播
  static Future<void> start(String productId) async {
    if (!Platform.isIOS) return;
    await _default._start(productId);
  }

  @override
  void onTransactionsUpdated(List<SK2TransactionMessage> newTransactions) {
    for (final message in newTransactions) {
      // pending/cancelled 为购买结果通知（id 为 0），由购买主流程处理
      if (message.status != .purchased || message.id <= 0) continue;
      if (_finishedIds.contains(message.id) ||
          _finishingIds.contains(message.id)) {
        continue;
      }
      final transaction = _Transaction(
        id: message.id,
        originalId: message.originalId,
        productId: message.productId,
        token: message.appAccountToken,
      );
      final currentPurchase =
          _isSameToken(message.appAccountToken, _purchasingToken)
          ? _purchaseVerification
          : null;
      final verification = _verifyAndFinish(transaction);
      if (currentPurchase == null) {
        unawaited(verification);
        continue;
      }
      verification.then(
        (result) {
          if (identical(_purchaseVerification, currentPurchase) &&
              !currentPurchase.isCompleted) {
            currentPurchase.complete(result);
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (identical(_purchaseVerification, currentPurchase) &&
              !currentPurchase.isCompleted) {
            currentPurchase.completeError(error, stackTrace);
          }
        },
      );
    }
  }

  void _configure() {
    if (_configured) return;
    _configured = true;
    InAppPurchase2CallbackAPI.setUp(this);
    unawaited(_processUnfinished());
    SK2Transaction.startListeningToTransactions();
  }

  Future<void> _start(String productId) async {
    if (_isProcessing) {
      MDTotast.message('正在处理交易，请稍候');
      return;
    }
    _isProcessing = true;
    var loadingCompleted = false;
    void completeLoading(MDTotastResult result, String message) {
      MDTotast.completeLoading(result, message);
      loadingCompleted = true;
    }

    try {
      MDTotast.showLoading('检查历史订单...');
      final unfinished = await _resolveUnfinished(productId);
      if (unfinished != null) {
        if (unfinished.ok) {
          completeLoading(.success, '购买成功');
        } else {
          completeLoading(.error, unfinished.msg ?? 'ERROR：存在未完成的订单，请稍后重试');
        }
        return;
      }

      MDTotast.updateLoading('商品查询中...');
      final product = await _loadProduct(productId);
      if (product == null) {
        completeLoading(.error, 'ERROR：未获取到商品信息，请检查网络后重试');
        return;
      }

      MDTotast.updateLoading('创建订单中...');
      final order = await _createOrder(productId);
      Utils.log('MDStoreKit 订单uuid=${order.uuid}, order_id=${order.id}');
      if (order.uuid.isEmpty || order.id.isEmpty) {
        completeLoading(.error, 'ERROR：创建订单失败(${order.msg})');
        return;
      }
      // 插件会静默忽略非法 UUID 的 appAccountToken，导致交易无法关联订单，必须提前校验
      if (!_uuidReg.hasMatch(order.uuid)) {
        completeLoading(.error, 'ERROR：创建UUID失败=${order.uuid}');
        return;
      }

      MDTotast.updateLoading('商品购买中...');
      _purchasingToken = order.uuid;
      final currentPurchase = Completer<_Verify>();
      _purchaseVerification = currentPurchase;
      final purchase = _purchaseAndVerify(
        product.id,
        order.uuid,
        currentPurchase.future,
      );
      final outcome = await Future.any<_PurchaseOutcome>([
        purchase,
        currentPurchase.future.then((verify) => (result: null, verify: verify)),
      ]);
      Utils.log(
        'MDStoreKit 购买终态 result=${outcome.result} verify=${outcome.verify?.ok}',
      );
      final verify = outcome.verify;
      if (verify != null) {
        if (verify.ok) {
          Utils.log('MDStoreKit 校验成功，结束购买加载');
          completeLoading(.success, '购买成功');
        } else {
          completeLoading(.error, verify.msg ?? 'ERROR：订单校验失败，请稍后重试');
        }
        return;
      }
      if (outcome.result == null) {
        completeLoading(.error, 'ERROR：未查询到交易信息，请稍后查看');
        return;
      }
      switch (outcome.result!) {
        case .success:
          // success 已在 _purchaseAndVerify 中校验，并以 verify 返回。
          break;
        case .unverified:
          completeLoading(.error, 'ERROR：交易校验失败，请联系客服');
        case .userCancelled:
          completeLoading(.message, '用户取消了支付');
        case .pending:
          completeLoading(.message, '交易正在处理中，请稍后查看');
      }
    } on PlatformException catch (error) {
      completeLoading(.error, 'ERROR：购买失败：${error.message ?? error.code}');
    } catch (error) {
      completeLoading(.error, 'ERROR：购买失败：$error');
    } finally {
      // 购买流程结束时直接关闭共享 EasyLoading，避免 success 状态切换
      // 或其他并发 loading 计数导致“商品购买中...”遮罩残留。
      if (!loadingCompleted) MDTotast.dismissLoading();
      _purchaseVerification = null;
      _purchasingToken = null;
      _isProcessing = false;
    }
  }

  Future<_PurchaseOutcome> _purchaseAndVerify(
    String productId,
    String token,
    Future<_Verify> callbackVerification,
  ) async {
    final result = await SK2Product.purchase(
      productId,
      options: SK2ProductPurchaseOptions(appAccountToken: token, quantity: 1),
    );
    if (result != .success) return (result: result, verify: null);
    final transaction = await _findUnfinished(productId, token);
    if (transaction == null) {
      // 交易回调可能已先拿到交易并完成校验，不能把它误报为“未查询到交易”。
      try {
        final verify = await callbackVerification.timeout(
          const Duration(seconds: 10),
        );
        return (result: null, verify: verify);
      } on TimeoutException {
        return (result: null, verify: null);
      }
    }
    return (result: null, verify: await _verifyAndFinish(transaction));
  }

  Future<SK2Product?> _loadProduct(String productId, {int retries = 2}) async {
    final cached = _productCache[productId];
    if (cached != null) return cached;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final products = await SK2Product.products([productId])
            .timeout(const Duration(seconds: 15));
        for (final product in products) {
          if (product.id == productId) {
            _productCache[productId] = product;
            return product;
          }
        }
      } catch (error) {
        Utils.log('MDStoreKit 查询商品超时或异常，进入重试 error=$error');
      }
      if (attempt < retries) {
        await Future<void>.delayed(Duration(milliseconds: (attempt + 1) * 600));
      }
    }
    return null;
  }

  Future<List<_Transaction>> _unfinished() async {
    try {
      final transactions = await SK2Transaction.unfinishedTransactions();
      final results = <_Transaction>[];
      for (final transaction in transactions) {
        final id = int.tryParse(transaction.id);
        if (id == null || id <= 0) continue;
        results.add(
          _Transaction(
            id: id,
            originalId: int.tryParse(transaction.originalId) ?? id,
            productId: transaction.productId,
            token: transaction.appAccountToken,
          ),
        );
      }
      return results;
    } catch (error) {
      Utils.log('MDStoreKit 查询未完成交易失败 error=$error');
      return const [];
    }
  }

  Future<_Transaction?> _findUnfinished(String productId, String token) async {
    for (final transaction in await _unfinished()) {
      if (transaction.productId == productId &&
          _isSameToken(transaction.token, token)) {
        return transaction;
      }
    }
    return null;
  }

  Future<_Verify?> _resolveUnfinished(String productId) async {
    _Verify? result;
    for (final transaction in await _unfinished()) {
      if (transaction.productId != productId) continue;
      result = await _verifyAndFinish(transaction);
      if (!result.ok) return result;
    }
    return result;
  }

  Future<void> _processUnfinished() async {
    for (final transaction in await _unfinished()) {
      await _verifyAndFinish(transaction);
    }
  }

  Future<({String uuid, String id, String msg})> _createOrder(
    String productId,
  ) async {
    try {
      final result = await MDPost.sendIapSession(
        cmd: .iapCreateOrder,
        params: {'p_id': productId},
      ).timeout(const Duration(seconds: 20));
      if (!result.isSuccess) {
        return (uuid: '', id: '', msg: result.msg ?? '创建订单失败');
      }
      final data = result.data;
      return (
        uuid: data?['uuid']?.toString() ?? '',
        id: data?['o_id']?.toString() ?? '',
        msg: result.msg ?? '',
      );
    } on TimeoutException {
      return (uuid: '', id: '', msg: '创建订单超时，请稍后重试');
    }
  }

  Future<_Verify> _serverForVerifyOrder(_Transaction transaction) async {
    try {
      final result = await MDPost.sendIapSession(
        cmd: .iapVerifyOrder,
        params: {
          'uuid': transaction.token ?? '',
          'transaction_id': '${transaction.id}',
          'transaction_original_id': '${transaction.originalId}',
        },
      ).timeout(const Duration(seconds: 20));
      return (ok: result.isSuccess, msg: result.msg);
    } on TimeoutException {
      return (ok: false, msg: '订单校验超时，请稍后重试');
    }
  }

  Future<_Verify> _verifyAndFinish(_Transaction transaction) {
    if (transaction.token?.isEmpty ?? true) {
      return Future.value((ok: false, msg: 'ERROR：交易缺少订单关联信息，请联系客服'));
    }
    if (_finishedIds.contains(transaction.id)) {
      const result = (ok: true, msg: null);
      _completePurchaseVerification(transaction, result);
      return Future.value(result);
    }
    if (_finishingIds.contains(transaction.id)) {
      const result = (ok: true, msg: null);
      _completePurchaseVerification(transaction, result);
      return Future.value(result);
    }
    return _verifying[transaction.id] ??= _doVerifyAndFinish(transaction)
        .whenComplete(() => _verifying.remove(transaction.id));
  }

  Future<_Verify> _doVerifyAndFinish(_Transaction transaction) async {
    final verify = await _serverForVerifyOrder(transaction);
    if (verify.ok) {
      _finishingIds.add(transaction.id);
      _completePurchaseVerification(transaction, verify);
      unawaited(_finishVerifiedTransaction(transaction.id));
      _changes.add(null);
    }
    return verify;
  }

  void _completePurchaseVerification(
    _Transaction transaction,
    _Verify verification,
  ) {
    final currentPurchase = _purchaseVerification;
    if (currentPurchase == null ||
        !_isSameToken(transaction.token, _purchasingToken) ||
        currentPurchase.isCompleted) {
      return;
    }
    currentPurchase.complete(verification);
  }

  Future<void> _finishVerifiedTransaction(int transactionId) async {
    try {
      await SK2Transaction.finish(transactionId);
      _finishedIds.add(transactionId);
    } catch (error) {
      Utils.log('MDStoreKit finish交易失败 id=$transactionId error=$error');
    } finally {
      _finishingIds.remove(transactionId);
    }
  }

  static bool _isSameToken(String? lhs, String? rhs) {
    if (lhs == null || rhs == null || lhs.isEmpty || rhs.isEmpty) return false;
    return lhs.toLowerCase() == rhs.toLowerCase();
  }
}

class _Transaction {
  final int id;
  final int originalId;
  final String productId;

  final String? token;

  const _Transaction({
    required this.id,
    required this.originalId,
    required this.productId,
    this.token,
  });
}
