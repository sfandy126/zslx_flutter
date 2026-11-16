import 'package:flutter/material.dart';

/// 一级页面通用的浅色渐变背景。
///
/// 放在 Scaffold.body 中、SafeArea 外侧，让渐变覆盖状态栏区域。
/// 不处理安全区域或滚动，页面通过 child 自行组织内容。
class MDPageBackground extends StatelessWidget {
  const MDPageBackground({super.key, required this.child});

  static const backgroundColor = Color(0xFFF4F9FF);
  static const _blueColor = Color(0xFFD9F2FF);
  static const _warmColor = Color(0xFFFAF8F5);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: RadialGradient(
          // 附件的蓝色从右上延伸到学习卡片附近，使用椭圆光晕。
          center: const Alignment(1, -0.9),
          radius: 1.1,
          transform: const _PageBackgroundStretch(),
          stops: const [0, 1],
          colors: [_blueColor, _blueColor.withValues(alpha: 0)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: const Alignment(-1, -0.2),
            radius: 1.0,
            stops: const [0, 1],
            colors: [
              _warmColor.withValues(alpha: 0.7),
              _warmColor.withValues(alpha: 0),
            ],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 拉长纵向渐变，避免径向渐变按短边计算导致蓝色局限于右上角。
class _PageBackgroundStretch extends GradientTransform {
  const _PageBackgroundStretch();

  @override
  Matrix4 transform(Rect bounds, {TextDirection? textDirection}) {
    final center = Alignment(1, -0.9).withinRect(bounds);
    return Matrix4.identity()
      ..translateByDouble(center.dx, center.dy, 0, 1)
      ..scaleByDouble(1, 1.65, 1, 1)
      ..translateByDouble(-center.dx, -center.dy, 0, 1);
  }
}
