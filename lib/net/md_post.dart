import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';

import '../users/md_user.dart';
import 'md_cmd.dart';
import 'md_env.dart';
import 'package:zslx_flutter/config/app_config.dart';

typedef ApiCallback =
    void Function(
      ResultState state,
      Exception? error,
      Map<String, dynamic>? data,
    );

enum ResultState { unknown, success, outed, failed }

class MDPost {
  MDPost._();

  static final Dio session = _createSession();

  static Dio _createSession() {
    final dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
      ),
    );
    // flutter 代理不走系统的代理，要抓包需要单独处理
    return dio;
  }

  static Future<void> sendApiSession({
    required MDCmd cmd,
    Map<String, dynamic> params = const {},
    ApiCallback? completed,
  }) async {
    await _send(cmd: cmd, params: params, isIap: false, completed: completed);
  }

  static Future<void> sendIapSession({
    required MDCmd cmd,
    Map<String, dynamic> params = const {},
    ApiCallback? completed,
  }) async {
    await _send(cmd: cmd, params: params, isIap: true, completed: completed);
  }

  static Future<void> _send({
    required MDCmd cmd,
    required bool isIap,
    Map<String, dynamic> params = const {},
    ApiCallback? completed,
  }) async {
    final headers = await mdHeaders();
    var token = headers['token'] ?? '';
    if (params['token'] is String) {
      token = params['token'];
      headers['token'] = token;
    }

    var uid = MDUser.defualt.uid ?? '';
    if (params['user_id'] is String) { // 优先取参数中的 user_id
      uid = params['user_id'];
    }

    final finalParams = <String, dynamic>{...params, 'user_id': uid};
    finalParams['sign'] = mdSign(finalParams, token);

    MDEnv domain = .product;
    final url = isIap
        ? '${domain.iapUrl}/${cmd.value}'
        : '${domain.url}/${cmd.value}';

    debugPrint('Cmd: ${cmd.value}, Params: $finalParams, Headers: $headers');

    try {
      final response = await session.post(
        url,
        data: finalParams,
        options: Options(
          headers: headers,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );

      final _ApiResponse result = _ApiResponse.fromJson(response.data);
      final code = result.code;
      final message = result.message;
      final status = result.status;

      if (status == 0 || code == 0) {
        await MDUser.defualt.logout();
        completed?.call(
          ResultState.outed,
          Exception(message ?? 'ERROR：登录已过期，请重新登录'),
          null,
        );
        return;
      }

      if (status == 1 || code == 1) {
        final payload = result.data;
        completed?.call(
          ResultState.success,
          Exception(message ?? 'success'),
          payload is Map<String, dynamic> ? payload : mdSafeToDict(payload),
        );
        return;
      }

      if (status == -1 || code == -1) {
        completed?.call(
          ResultState.failed,
          Exception(message ?? 'ERROR：数据返回错误'),
          null,
        );
        return;
      }

      completed?.call(
        ResultState.failed,
        Exception(message ?? 'ERROR：数据状态错误'),
        null,
      );
    } on DioException catch (error) {
      final message =
          error.response?.data is String &&
              (error.response?.data as String).isNotEmpty
          ? error.response!.data.toString()
          : 'ERROR：网络异常，请检查网络';
      completed?.call(ResultState.failed, Exception(message), null);
    } catch (error) {
      completed?.call(ResultState.failed, Exception('ERROR：解析错误'), null);
    }
  }

  static Future<Map<String, dynamic>> mdHeaders() async {
    final systemType = AppConfig.systemType;
    final systemVersion = Platform.operatingSystemVersion;
    final flavor = AppConfig.currentChannel.name;
    final currentVersion = AppConfig.appVersion;
    final versions = _plusOneMajorMinor(currentVersion);
    final deviceBrand = AppConfig.deviceBrand;

    final headers = <String, dynamic>{
      'system-type': systemType,
      'versions': versions,
      'system_version': systemVersion, // 设备系统版本号
      'flavor': flavor,
      'device_brand': deviceBrand,
      'device_model': deviceBrand,
    };
    final token = MDUser.defualt.token;
    if (token != null && token.isNotEmpty) {
      headers['token'] = token;
    }
    return headers;
  }

  static String _plusOneMajorMinor(String version) {
    final parts = version.split('.');
    if (parts.length < 3) {
      return version;
    }

    final major = int.tryParse(parts[0]) ?? 0;
    final minor = int.tryParse(parts[1]) ?? 0;
    final patch = int.tryParse(parts[2]) ?? 0;

    final nextMajor = major + 1;
    final nextMinor = minor;
    final nextPatch = patch;

    return '$nextMajor.$nextMinor.$nextPatch';
  }

  static Map<String, dynamic>? mdSafeToDict(dynamic data) {
    if (data == null) return null;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    if (data is List) {
      return {'data': data};
    }
    return {'data': data};
  }

  static String mdSign(Map<String, dynamic> params, String token) {
    final filtered = <String, dynamic>{};
    for (final entry in params.entries) {
      if (entry.key == 'sign') {
        continue;
      }
      filtered[entry.key] = entry.value;
    }

    final sorted = Map.fromEntries(
      filtered.entries.toList()..sort((a, b) => a.key.compareTo(b.key)),
    );

    final items = <String>[];
    for (final entry in sorted.entries) {
      items.add('${entry.key}=${entry.value}');
    }
    if (token.isNotEmpty) {
      items.add('token=$token');
    }

    final raw = items.join('&');
    return sha1.convert(utf8.encode(raw)).toString();
  }
}

class _ApiResponse {
  final int code;
  final String? msg;
  final int status;
  final String? message;
  final Object? data;

  const _ApiResponse({
    required this.code,
    this.msg,
    required this.status,
    this.message,
    this.data,
  });

  factory _ApiResponse.fromJson(dynamic response) {
    Map<String, dynamic> json;

    if (response is Map) {
      json = response.map((key, value) => MapEntry(key.toString(), value));
    } else if (response is String) {
      try {
        final decoded = jsonDecode(response);
        if (decoded is Map) {
          json = decoded.map((key, value) => MapEntry(key.toString(), value));
        } else {
          return _invalid('ERROR：响应数据格式错误');
        }
      } on FormatException {
        return _invalid('ERROR：响应数据格式错误');
      }
    } else {
      return _invalid('ERROR：响应数据格式错误');
    }

    return _ApiResponse(
      code: _toInt(json['code'], -1),
      msg: json['msg']?.toString(),
      status: _toInt(json['status'], -1),
      message: json['message']?.toString(),
      data: json['data'],
    );
  }

  static _ApiResponse _invalid(String message) {
    return _ApiResponse(code: -1, msg: message, status: -1, message: message);
  }

  static int _toInt(Object? value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
