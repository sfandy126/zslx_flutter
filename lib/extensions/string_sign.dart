import 'dart:convert';
import 'package:crypto/crypto.dart';

extension StringSign on String {
  /// 生成 sign：参数按 key 升序拼接 key=value，末尾追加 token，再取 32 位小写 md5
  static String mdSign(Map<String, dynamic> params, String token) {
    final keys = params.keys.where((key) => key != 'sign').toList()..sort();

    final items = <String>[];
    for (final key in keys) {
      final value = params[key];
      if (value is String || value is num) {
        items.add('$key=$value');
      } else if (value is bool) {
        items.add('$key=${value ? 1 : 0}');
      }
    }
    if (token.isNotEmpty) {
      items.add('token=$token');
    }
    if (items.isEmpty) return '';

    return md5.convert(utf8.encode(items.join('&'))).toString();
  }
}