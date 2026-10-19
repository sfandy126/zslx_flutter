// ios内购StoreKit
import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';

import '../../utils/utils.dart';

typedef _Verify = ({bool ok, String? msg});

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

  final Map<int, Future<_Verify>> _verifying = {};

  final Set<int> _finishedIds = {};

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
          _isSameToken(message.appAccountToken, _purchasingToken)) {
        continue;
      }
      unawaited(
        _verifyAndFinish(
          _Transaction(
            id: message.id,
            originalId: message.originalId,
            productId: message.productId,
            token: message.appAccountToken,
          ),
        ),
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
      MDTotast.showMessage('正在处理交易，请稍候');
      return;
    }
    _isProcessing = true;
    try {
      MDTotast.showLoading('检查历史订单...');
      final unfinished = await _resolveUnfinished(productId);
      if (unfinished != null) {
        if (unfinished.ok) {
          MDTotast.showSuccess('购买成功');
        } else {
          MDTotast.showError(unfinished.msg ?? 'ERROR：存在未完成的订单，请稍后重试');
        }
        return;
      }

      MDTotast.showLoading('商品查询中...');
      final product = await _loadProduct(productId);
      if (product == null) {
        MDTotast.showError('ERROR：未获取到商品信息，请检查网络后重试');
        return;
      }

      MDTotast.showLoading('创建订单中...');
      final order = await _createOrder(productId);
      Utils.log('MDStoreKit 订单uuid=${order.uuid}, order_id=${order.id}');
      if (order.uuid.isEmpty || order.id.isEmpty) {
        MDTotast.showError('ERROR：创建订单失败(${order.msg})');
        return;
      }
      // 插件会静默忽略非法 UUID 的 appAccountToken，导致交易无法关联订单，必须提前校验
      if (!_uuidReg.hasMatch(order.uuid)) {
        MDTotast.showError('ERROR：创建UUID失败=${order.uuid}');
        return;
      }

      MDTotast.showLoading('商品购买中...');
      _purchasingToken = order.uuid;
      final result = await SK2Product.purchase(
        product.id,
        options: SK2ProductPurchaseOptions(
          appAccountToken: order.uuid,
          quantity: 1,
        ),
      );
      switch (result) {
        case .success:
          final transaction = await _findUnfinished(productId, order.uuid);
          if (transaction == null) {
            MDTotast.showError('ERROR：未查询到交易信息，请稍后查看');
            return;
          }
          final verify = await _verifyAndFinish(transaction);
          if (verify.ok) {
            MDTotast.showSuccess('购买成功');
          } else {
            MDTotast.showError(verify.msg ?? 'ERROR：订单校验失败，请稍后重试');
          }
        case .unverified:
          MDTotast.showError('ERROR：交易校验失败，请联系客服');
        case .userCancelled:
          MDTotast.showMessage('用户取消了支付');
        case .pending:
          MDTotast.showMessage('交易正在处理中，请稍后查看');
      }
    } on PlatformException catch (error) {
      MDTotast.showError('ERROR：购买失败：${error.message ?? error.code}');
    } catch (error) {
      MDTotast.showError('ERROR：购买失败：$error');
    } finally {
      _purchasingToken = null;
      _isProcessing = false;
    }
  }

  Future<SK2Product?> _loadProduct(String productId, {int retries = 2}) async {
    final cached = _productCache[productId];
    if (cached != null) return cached;
    for (var attempt = 0; attempt <= retries; attempt++) {
      try {
        final products = await SK2Product.products([
          productId,
        ]).timeout(const Duration(seconds: 15));
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
      return Future.value((ok: true, msg: null));
    }
    return _verifying[transaction.id] ??= _doVerifyAndFinish(
      transaction,
    ).whenComplete(() => _verifying.remove(transaction.id));
  }

  Future<_Verify> _doVerifyAndFinish(_Transaction transaction) async {
    final verify = await _serverForVerifyOrder(transaction);
    if (verify.ok) {
      try {
        await SK2Transaction.finish(transaction.id);
      } catch (error) {
        Utils.log('MDStoreKit finish交易失败 id=${transaction.id} error=$error');
      }
      _finishedIds.add(transaction.id);
      _changes.add(null);
    }
    return verify;
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
