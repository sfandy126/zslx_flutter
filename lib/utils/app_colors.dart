import 'package:flutter/material.dart';
import 'package:zslx_flutter/extensions/color_extensions.dart';

/// 颜色工具类, 所有颜色全部放在此处
class AppColors {
  AppColors._();
  /// 主色系 等同于 Theme.of(context).primaryColor
  static final Color theme = HexColor.fromHex('#1AAEE5');
  /// 浅主色系
  static final Color lightTheme = HexColor.fromHex('#EFF9FE');
  /// 标题色
  static final Color title = HexColor.fromHex('#18181B');
  /// 内容色、子标题色
  static final Color content = HexColor.fromHex('#808080');
  /// 红色
  static final Color red = HexColor.fromHex('#FF1E1E');
  /// 价格颜色
  static final Color price = HexColor.fromHex('#FE9565');
  /// 线条颜色
  static final Color line = HexColor.fromHex('#F8F8F8');
  /// 背景色
  static final Color background = HexColor.fromHex('#F5F4F1');
  /// 白色
  static final Color white = HexColor.fromHex('#FFFFFF');
  /// 黑色
  static final Color black = HexColor.fromHex('#000000');
}