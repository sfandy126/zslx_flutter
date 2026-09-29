import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import 'package:dio/dio.dart';

import '../users/md_user.dart';
import 'md_cmd.dart';
import 'md_env.dart';
import 'package:zslx_flutter/config/app_config.dart';
import '../extensions/string_sign.dart';

enum ResultState { unknown, success, outed, failed }

class MDResult {
  final ResultState state;
  final String? msg;
  final Map<String, dynamic>? data;

  const MDResult(this.state, {this.msg, this.data});

  bool get isSuccess => state == .success;
}

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

  static Future<MDResult> sendApiSession({
    required MDCmd cmd,
    Map<String, dynamic> params = const {},
  }) {
    return _send(cmd: cmd, params: params, isIap: false);
  }

  static Future<MDResult> sendIapSession({
    required MDCmd cmd,
    Map<String, dynamic> params = const {},
  }) {
    return _send(cmd: cmd, params: params, isIap: true);
  }

  static Future<MDResult> sendUploadSession({
    required MDCmd cmd,
    required String filePath,
    required String name,
    String format = 'png',
    Map<String, dynamic> params = const {},
  }) async {
    final headers = mdHeaders();
    var token = MDUser.defualt.token ?? '';
    final outToken = params['token'];
    if (outToken is String) {
      token = outToken;
      headers['token'] = outToken;
    }

    var uid = MDUser.defualt.uid ?? '';
    final outUid = params['user_id'];
    if (outUid is String) {
      uid = outUid;
    }

    final finalParams = <String, dynamic>{...params, 'user_id': uid};
    final finalForm = <String, dynamic>{
      ...finalParams,
      'sign': StringSign.mdSign(finalParams, token),
      name: await MultipartFile.fromFile(filePath, filename: '$name.$format'),
    };

    const MDEnv domain = .product;
    final url = '${domain.url}/${cmd.value}';
    _log(
      'upload_cmd = ${cmd.value} finalParams = $finalParams headers = $headers',
    );

    try {
      final response = await session.post(
        url,
        data: FormData.fromMap(finalForm),
        options: Options(
          headers: headers,
          followRedirects: true,
          validateStatus: (status) =>
              status != null && status >= 200 && status < 300,
        ),
      );
      _log('upload_cmd = ${cmd.value} jsonResult = ${response.data}');

      final result = _ApiResponse.fromJson(response.data, isIap: false);
      final message = result.msg;
      switch (result.status) {
        case 0:
          await MDUser.defualt.logout();
          return MDResult(.outed, msg: message ?? 'ERROR：登录已过期，请重新登录');
        case 1:
          return MDResult(
            .success,
            msg: message ?? 'success',
            data: mdSafeToDict(result.data),
          );
        case -1:
          return MDResult(.failed, msg: message ?? 'ERROR：上传失败');
        default:
          return MDResult(
            .failed,
            msg: message ?? 'ERROR：数据状态错误${result.status}',
          );
      }
    } on DioException catch (error) {
      _log(
        '❌upload_cmd = ${cmd.value} ❌ERROR = ${error.response?.data ?? error}',
      );
      return MDResult(.failed, msg: _dioErrorMessage(error));
    } catch (error) {
      _log('❌upload_cmd = ${cmd.value} ❌解析错误 = $error');
      return const MDResult(.failed, msg: 'ERROR：解析错误');
    }
  }

  static Future<MDResult> _send({
    required MDCmd cmd,
    required bool isIap,
    Map<String, dynamic> params = const {},
  }) async {
    final headers = mdHeaders();
    var token = MDUser.defualt.token ?? '';
    final outToken = params['token'];
    if (outToken is String) {
      token = outToken;
      headers['token'] = outToken;
    }

    var uid = MDUser.defualt.uid ?? '';
    final outUid = params['user_id'];
    if (outUid is String) {
      // 优先取参数中的 user_id
      uid = outUid;
    }

    final finalParams = <String, dynamic>{...params, 'user_id': uid};
    finalParams['sign'] = StringSign.mdSign(finalParams, token);

    const MDEnv domain = .product;
    final url = isIap
        ? '${domain.iapUrl}/${cmd.value}'
        : '${domain.url}/${cmd.value}';

    _log(
      'send_cmd = ${cmd.value} finalParams = $finalParams headers = $headers',
    );

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
      _log('send_cmd = ${cmd.value} jsonResult = ${response.data}');

      final result = _ApiResponse.fromJson(response.data, isIap: isIap);
      final message = result.msg;

      switch (result.status) {
        case 0:
          await MDUser.defualt.logout();
          return MDResult(.outed, msg: message ?? 'ERROR：登录已过期，请重新登录');
        case 1:
          return MDResult(
            .success,
            msg: message ?? 'success',
            data: mdSafeToDict(result.data),
          );
        case -1:
          return MDResult(.failed, msg: message ?? 'ERROR：数据返回错误');
        default:
          return MDResult(
            .failed,
            msg: message ?? 'ERROR：数据状态错误${result.status}',
          );
      }
    } on DioException catch (error) {
      _log(
        '❌send_cmd = ${cmd.value} ❌ERROR = ${error.response?.data ?? error}',
      );
      return MDResult(.failed, msg: _dioErrorMessage(error));
    } catch (error) {
      _log('❌send_cmd = ${cmd.value} ❌解析错误 = $error');
      return const MDResult(.failed, msg: 'ERROR：解析错误');
    }
  }

  static String _dioErrorMessage(DioException error) {
    final data = error.response?.data;
    if (data is String && data.isNotEmpty) return data;
    switch (error.type) {
      case .connectionTimeout:
      case .sendTimeout:
      case .receiveTimeout:
        return 'ERROR：网络超时，请稍后重试';
      default:
        return 'ERROR：网络异常，请检查网络';
    }
  }

  /// 仅在 debug 模式输出，避免 release 包日志泄露 token、密码密文
  static void _log(String message) {
    if (kDebugMode) debugPrint(message);
  }

  static Map<String, dynamic> mdHeaders() {
    final headers = <String, dynamic>{
      'system-type': AppConfig.systemType,
      'versions': _plusOneMajorMinor(AppConfig.appVersion),
      'system_version': Platform.operatingSystemVersion, // 设备系统版本号
      'flavor': AppConfig.currentChannel.name,
      'device_brand': AppConfig.deviceBrand,
      'device_model': AppConfig.deviceBrand,
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

    return '${major + 1}.$minor.$patch';
  }

  static Map<String, dynamic>? mdSafeToDict(dynamic data) {
    if (data == null) return null;
    if (data is Map<String, dynamic>) return data;
    if (data is Map) {
      return data.map((key, value) => MapEntry(key.toString(), value));
    }
    return {'data': data};
  }
}

class _ApiResponse {
  final int status;
  final String? msg;
  final Object? data;

  const _ApiResponse({required this.status, this.msg, this.data});

  /// 普通接口返回 status/msg/data，内购接口返回 code/message/res
  factory _ApiResponse.fromJson(dynamic response, {required bool isIap}) {
    final json = _toJson(response);
    if (json == null) return _invalid('ERROR：响应数据格式错误');

    if (isIap) {
      return _ApiResponse(
        status: _toInt(json['code'], -1),
        msg: json['message']?.toString(),
        data: json['res'],
      );
    }
    return _ApiResponse(
      status: _toInt(json['status'], -1),
      msg: json['msg']?.toString(),
      data: json['data'],
    );
  }

  static Map<String, dynamic>? _toJson(dynamic response) {
    var value = response;
    if (value is String) {
      try {
        value = jsonDecode(value);
      } on FormatException {
        return null;
      }
    }
    if (value is Map) {
      return value.map((key, value) => MapEntry(key.toString(), value));
    }
    return null;
  }

  static _ApiResponse _invalid(String message) {
    return _ApiResponse(status: -1, msg: message);
  }

  static int _toInt(Object? value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
