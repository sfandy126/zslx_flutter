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
  /// 绿色（收入金额）
  static final Color green = HexColor.fromHex('#2ED425');
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
  /// 透明色,对应clear
  static final Color transparent = Colors.transparent;
  /// #AAAAAA
  static final Color grayAAA = HexColor.fromHex('#AAAAAA');
  /// 边框灰 #E5E7EB
  static final Color border = HexColor.fromHex('#E5E7EB');
  /// 深蓝色，与主色系组成渐变
  static final Color deepTheme = HexColor.fromHex('#1A6FE5');
  /// 警告提示背景色
  static final Color warningBackground = HexColor.fromHex('#FFFBEB');
  /// 警告提示边框色
  static final Color warningBorder = HexColor.fromHex('#FBBF24');
  /// 警告提示标题色
  static final Color warningTitle = HexColor.fromHex('#B45309');
  /// 警告提示内容色
  static final Color warningContent = HexColor.fromHex('#92400E');
}