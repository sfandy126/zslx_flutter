import 'package:flutter/material.dart';

/// 一级页面通用的浅色渐变背景。
///
/// 放在 Scaffold.body 中、SafeArea 外侧，让渐变覆盖状态栏区域。
/// 不处理安全区域或滚动，页面通过 child 自行组织内容。
class MDPageBackground extends StatelessWidget {
  const MDPageBackground({super.key, required this.child});

  static const backgroundColor = Color(0xFFF6FAFF);
  static const _blueColor = Color(0xFFDFF4FF);
  static const _warmColor = Color(0xFFFBF5ED);
  static const _blueCenter = Alignment.topRight;
  static const _warmCenter = Alignment(-1, -0.28);

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: RadialGradient(
          center: _blueCenter,
          radius: 1,
          transform: const _PageBackgroundEllipse(_blueCenter, .65, .59),
          colors: [_blueColor, _blueColor.withValues(alpha: 0)],
        ),
      ),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: _warmCenter,
            radius: 1,
            transform: const _PageBackgroundEllipse(_warmCenter, .52, .38),
            stops: const [.12, 1],
            colors: [_warmColor, _warmColor.withValues(alpha: 0)],
          ),
        ),
        child: child,
      ),
    );
  }
}

/// 用页面宽高的比例定义椭圆半径，使渐变随屏幕比例变化。
class _PageBackgroundEllipse extends GradientTransform {
  const _PageBackgroundEllipse(this.center, this.widthRatio, this.heightRatio);

  final Alignment center;
  final double widthRatio;
  final double heightRatio;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    if (bounds.isEmpty) return null;
    final origin = center.withinRect(bounds);
    final radius = bounds.shortestSide;
    return Matrix4.identity()
      ..translateByDouble(origin.dx, origin.dy, 0, 1)
      ..scaleByDouble(
        bounds.width * widthRatio / radius,
        bounds.height * heightRatio / radius,
        1,
        1,
      )
      ..translateByDouble(-origin.dx, -origin.dy, 0, 1);
  }
}
