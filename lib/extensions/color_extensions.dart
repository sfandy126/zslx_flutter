import 'package:flutter/material.dart';

/// 扩展 Color 类，提供从十六进制字符串创建 Color 的方法
extension HexColor on Color {
  /// 从十六进制字符串创建 Color，支持格式：'#FFFFFF' 或 'FFFFFF'
  static Color fromHex(String hexString) {
    final buffer = StringBuffer();
    if (hexString.length == 6 || hexString.length == 7) {
      buffer.write('FF'); // 如果没有透明度，默认为不透明 (FF)
    }
    buffer.write(hexString.replaceFirst('#', ''));
    return Color(int.parse(buffer.toString(), radix: 16));
  }

  /// 将 Color 转换为十六进制字符串
  String toHex({bool leadingHashSign = true}) {
    final hex = '${alpha.toRadixString(16).padLeft(2, '0')}'
        '${red.toRadixString(16).padLeft(2, '0')}'
        '${green.toRadixString(16).padLeft(2, '0')}'
        '${blue.toRadixString(16).padLeft(2, '0')}';
    return '${leadingHashSign ? '#' : ''}$hex';
  }
}

extension HexColorExtension on String {
  /// 将十六进制字符串转换为 Color 对象
  Color toColor() {
    return HexColor.fromHex(this);
  }
}