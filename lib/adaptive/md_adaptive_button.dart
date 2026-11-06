import 'package:adaptive_platform_ui/adaptive_platform_ui.dart' as adaptive;
import 'package:flutter/widgets.dart';

/// 按钮外观由项目定义，避免页面依赖第三方枚举。
enum MDAdaptiveButtonStyle {
  filled,
  tinted,
  gray,
  bordered,
  plain,
  glass,
  prominentGlass,
}

enum MDAdaptiveButtonSize { small, medium, large }

/// 通用自适应按钮。通过 [style] 选择平台对应的外观。
class MDAdaptiveButton extends StatelessWidget {
  const MDAdaptiveButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.style = MDAdaptiveButtonStyle.filled,
    this.size = MDAdaptiveButtonSize.medium,
    this.padding,
    this.borderRadius,
    this.minSize,
    this.useSmoothRectangleBorder = true,
    this.useNative = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final MDAdaptiveButtonStyle style;
  final MDAdaptiveButtonSize size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Size? minSize;
  final bool useSmoothRectangleBorder;
  final bool useNative;

  @override
  Widget build(BuildContext context) => adaptive.AdaptiveButton.child(
    onPressed: onPressed,
    color: color,
    style: switch (style) {
      MDAdaptiveButtonStyle.filled => adaptive.AdaptiveButtonStyle.filled,
      MDAdaptiveButtonStyle.tinted => adaptive.AdaptiveButtonStyle.tinted,
      MDAdaptiveButtonStyle.gray => adaptive.AdaptiveButtonStyle.gray,
      MDAdaptiveButtonStyle.bordered => adaptive.AdaptiveButtonStyle.bordered,
      MDAdaptiveButtonStyle.plain => adaptive.AdaptiveButtonStyle.plain,
      MDAdaptiveButtonStyle.glass => adaptive.AdaptiveButtonStyle.glass,
      MDAdaptiveButtonStyle.prominentGlass =>
        adaptive.AdaptiveButtonStyle.prominentGlass,
    },
    size: switch (size) {
      MDAdaptiveButtonSize.small => adaptive.AdaptiveButtonSize.small,
      MDAdaptiveButtonSize.medium => adaptive.AdaptiveButtonSize.medium,
      MDAdaptiveButtonSize.large => adaptive.AdaptiveButtonSize.large,
    },
    padding: padding,
    borderRadius: borderRadius,
    minSize: minSize,
    enabled: onPressed != null,
    useSmoothRectangleBorder: useSmoothRectangleBorder,
    useNative: useNative,
    child: child,
  );
}

/// 与 PlatformIconButton 的 `icon: Widget` 用法对应，支持 SVG 等自定义图标。
class MDAdaptiveIconButton extends StatelessWidget {
  const MDAdaptiveIconButton({
    super.key,
    required this.onPressed,
    required this.icon,
    this.color,
    this.size = MDAdaptiveButtonSize.medium,
    this.padding,
    this.borderRadius,
    this.minSize,
    this.useNative = true,
  });

  final VoidCallback? onPressed;
  final Widget icon;
  final Color? color;
  final MDAdaptiveButtonSize size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Size? minSize;
  final bool useNative;

  @override
  Widget build(BuildContext context) => MDAdaptiveButton(
    onPressed: onPressed,
    color: color,
    style: MDAdaptiveButtonStyle.plain,
    size: size,
    padding: padding,
    borderRadius: borderRadius,
    minSize: minSize,
    useNative: useNative,
    child: icon,
  );
}

/// 与 PlatformElevatedButton 对应的强调按钮。
class MDAdaptiveElevatedButton extends StatelessWidget {
  const MDAdaptiveElevatedButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.size = MDAdaptiveButtonSize.medium,
    this.padding,
    this.borderRadius,
    this.minSize,
    this.useNative = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final MDAdaptiveButtonSize size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Size? minSize;
  final bool useNative;

  @override
  Widget build(BuildContext context) => MDAdaptiveButton(
    onPressed: onPressed,
    color: color,
    size: size,
    padding: padding,
    borderRadius: borderRadius,
    minSize: minSize,
    useNative: useNative,
    child: child,
  );
}

/// 与 PlatformTextButton 对应的无背景按钮。
class MDAdaptiveTextButton extends StatelessWidget {
  const MDAdaptiveTextButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.color,
    this.size = MDAdaptiveButtonSize.medium,
    this.padding,
    this.borderRadius,
    this.minSize,
    this.useNative = true,
  });

  final VoidCallback? onPressed;
  final Widget child;
  final Color? color;
  final MDAdaptiveButtonSize size;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final Size? minSize;
  final bool useNative;

  @override
  Widget build(BuildContext context) => MDAdaptiveButton(
    onPressed: onPressed,
    color: color,
    style: MDAdaptiveButtonStyle.plain,
    size: size,
    padding: padding,
    borderRadius: borderRadius,
    minSize: minSize,
    useNative: useNative,
    child: child,
  );
}
