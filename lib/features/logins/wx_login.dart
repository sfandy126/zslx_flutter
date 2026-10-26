// 微信登录/绑定（参考 MDWx.swift）
import 'dart:async';
import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:fluwx/fluwx.dart';

import '../../utils/utils.dart';

/// 微信授权失败原因
enum WxAuthError implements Exception {
  notInstall('请先安装微信'),
  notSupport('当前微信版本过低'),
  reqFailed('授权请求失败，建议重试'),
  userCancel('用户取消了授权'),
  sendFailed('授权发送失败，建议重试'),
  authDeny('授权被拒绝'),
  authoError('授权失败'),
  tokenURLInvalid('获取token URL无效'),
  tokenJsonFailed('解析token失败'),
  userJsonFailed('解析user失败');

  const WxAuthError(this.message);

  final String message;
}

/// 微信第三方登录结果
class WxLoginResult {
  const WxLoginResult({required this.needMobile, this.data});

  /// 是否需要绑定手机号：为 true 时尚未登录，需携带 token、user_id 前往绑定页
  final bool needMobile;
  final Map<String, dynamic>? data;

  String get token => data?['token']?.toString() ?? '';
  String get userId => data?['user_id']?.toString() ?? '';
}

/// 微信登录
class WxLogin {
  WxLogin._();

  /// 与 pubspec.yaml 中 fluwx 的 app_id 保持一致
  static const String _appId = 'wx4bddc0d3d10d3d0a';
  static const String _appSecret = 'd1a3d2d6a92c3561f3dde1173eb23726';
  static const String _universalLink = 'https://www.zhuoshilx.com/';

  static final Fluwx _fluwx = Fluwx();
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      // 微信接口返回 text/plain，统一按字符串接收后自行解析
      responseType: ResponseType.plain,
    ),
  );

  static bool _registered = false;

  /// 等待微信授权回调
  static Completer<({int errCode, String? code})>? _authCompleter;

  /// 回前台兜底：在微信授权页不操作直接切回时微信不回调，需主动收尾等待
  static AppLifecycleListener? _lifecycleListener;
  static bool _leftApp = false;

  /// 后台是否开启微信登录（third_login_siqt 的 is_open），null 表示尚未获取
  static int? _wxOpen;

  /// 后台是否开启微信登录，已获取过则直接使用缓存
  static Future<bool> isOpen() async {
    if (_wxOpen != null) return _wxOpen == 1;
    final result = await MDPost.sendApiSession(cmd: .thirdSiqt);
    if (result.isSuccess) {
      final open = int.tryParse(result.data?['is_open']?.toString() ?? '');
      if (open != null) _wxOpen = open;
    }
    return _wxOpen == 1;
  }

  /// 是否已安装微信
  static Future<bool> isInstalled() async {
    try {
      await _register();
      return _registered && await _fluwx.isWeChatInstalled;
    } catch (error) {
      Utils.log('WxLogin check installed failed: $error');
      return false;
    }
  }

  /// 微信登录
  /// 返回 null 表示授权或登录失败（已提示）；
  /// needMobile 为 false 时已完成登录，为 true 时需前往绑定手机号
  static Future<WxLoginResult?> login() async {
    final params = await _authParams();
    if (params == null) return null;
    final result = await MDPost.sendApiSession(
      cmd: .thirdLogin,
      params: params,
    );
    MDTotast.hideLoading();
    final data = result.data;
    if (!result.isSuccess || data == null || data.isEmpty) {
      MDTotast.showError(result.msg ?? '微信登录失败');
      return null;
    }
    final needMobile = data['need_mobile']?.toString() == '1';
    if (!needMobile) await MDUser.defualt.login(data);
    return WxLoginResult(needMobile: needMobile, data: data);
  }

  /// 微信绑定用户，返回是否绑定成功
  static Future<bool> bind() async {
    final params = await _authParams();
    if (params == null) return false;
    final result = await MDPost.sendApiSession(cmd: .bindThird, params: params);
    MDTotast.hideLoading();
    final data = result.data;
    if (!result.isSuccess || data == null || data.isEmpty) {
      MDTotast.showError(result.msg ?? '微信绑定失败');
      return false;
    }
    await MDUser.defualt.updateWx(data);
    return true;
  }

  /// 发起微信授权并组装第三方登录/绑定的公共参数，授权失败时提示并返回 null
  /// 成功返回时 loading 仍在显示，由调用方在请求结束后关闭
  static Future<Map<String, dynamic>?> _authParams() async {
    try {
      final code = await _sendAuth();
      MDTotast.showLoading();
      final user = await _fetchUser(code);
      return {
        'type': 'wx',
        'name': _text(user['nickname']),
        'iconurl': _text(user['headimgurl']),
        'unionGender': _text(user['sex']),
        'openid': _text(user['openid']),
        'unionid': _text(user['unionid']),
      };
    } on WxAuthError catch (error) {
      MDTotast.showError(error.message);
    } catch (error) {
      Utils.log('WxLogin auth failed: $error');
      MDTotast.showError('微信授权失败，请稍后重试');
    }
    return null;
  }

  /// 发起授权并等待微信回调，返回授权 code
  static Future<String> _sendAuth() async {
    await _register();
    if (!_registered) throw WxAuthError.reqFailed;
    if (!await _fluwx.isWeChatInstalled) throw WxAuthError.notInstall;
    // 冲掉上一次未收尾的等待，避免旧等待悬挂导致后续永远无法再授权
    _cancelPendingAuth();

    final completer = Completer<({int errCode, String? code})>();
    _authCompleter = completer;
    _observeLifecycle();
    final sent = await _fluwx.authBy(
      which: NormalAuth(
        scope: 'snsapi_userinfo',
        state: DateTime.now().millisecondsSinceEpoch.toString(),
      ),
    );
    if (!sent) {
      _clearPendingAuth();
      throw WxAuthError.reqFailed;
    }

    final resp = await completer.future;
    switch (resp.errCode) {
      case 0:
        break;
      case -2:
        throw WxAuthError.userCancel;
      case -3:
        throw WxAuthError.sendFailed;
      case -4:
        throw WxAuthError.authDeny;
      case -5:
        throw WxAuthError.notSupport;
      default:
        throw WxAuthError.authoError;
    }
    final code = resp.code;
    if (code == null || code.isEmpty) throw WxAuthError.tokenURLInvalid;
    return code;
  }

  static Future<void> _register() async {
    if (_registered) return;
    _registered = await _fluwx.registerApi(
      appId: _appId,
      universalLink: _universalLink,
    );
    if (!_registered) return;
    _fluwx.addSubscriber((response) {
      if (response is! WeChatAuthResponse) return;
      _finishAuth((errCode: response.errCode ?? -1, code: response.code));
    });
  }

  /// 结束一次授权等待：恢复挂起的调用方并清理状态与监听
  static void _finishAuth(({int errCode, String? code}) resp) {
    final completer = _authCompleter;
    _clearPendingAuth();
    if (completer == null || completer.isCompleted) return;
    completer.complete(resp);
  }

  /// 以“用户取消”收尾当前等待，无等待时不做任何事
  static void _cancelPendingAuth() {
    if (_authCompleter == null) return;
    _finishAuth((errCode: -2, code: null));
  }

  static void _clearPendingAuth() {
    _authCompleter = null;
    _lifecycleListener?.dispose();
    _lifecycleListener = null;
  }

  /// 监听回前台：用户在微信授权页不点授权直接切回 App 时，微信不会回调，
  /// 若不主动收尾，等待会一直悬挂。仅在确实离开过 App 后才兜底，避免系统弹窗引起的误判
  static void _observeLifecycle() {
    _lifecycleListener?.dispose();
    _leftApp = false;
    _lifecycleListener = AppLifecycleListener(
      onHide: () => _leftApp = true,
      onResume: () async {
        if (!_leftApp) return;
        // 微信回调可能略晚于回前台到达，稍等确认仍无回调才判定为取消
        await Future<void>.delayed(const Duration(milliseconds: 500));
        _cancelPendingAuth();
      },
    );
  }

  /// 通过授权 code 换取 access_token，再获取微信用户信息
  static Future<Map<String, dynamic>> _fetchUser(String code) async {
    final tokenJson = await _getJson(
      'https://api.weixin.qq.com/sns/oauth2/access_token',
      {
        'appid': _appId,
        'secret': _appSecret,
        'code': code,
        'grant_type': 'authorization_code',
      },
      WxAuthError.tokenJsonFailed,
    );
    final accessToken = _text(tokenJson['access_token']);
    final openid = _text(tokenJson['openid']);
    if (accessToken.isEmpty || openid.isEmpty) {
      throw WxAuthError.tokenJsonFailed;
    }
    return _getJson('https://api.weixin.qq.com/sns/userinfo', {
      'access_token': accessToken,
      'openid': openid,
    }, WxAuthError.userJsonFailed);
  }

  static Future<Map<String, dynamic>> _getJson(
    String url,
    Map<String, dynamic> query,
    WxAuthError error,
  ) async {
    final response = await _dio.get<String>(url, queryParameters: query);
    final json = jsonDecode(response.data ?? '');
    if (json is! Map) throw error;
    return json.map((key, value) => MapEntry(key.toString(), value));
  }

  static String _text(Object? value) => value?.toString().trim() ?? '';
}
