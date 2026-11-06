import 'package:flutter/material.dart';

/// 显示带有自定义 Widget 内容的跨平台弹窗。
Future<T?> showMDAdaptiveDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
  String? barrierLabel,
  Color? barrierColor,
}) => showAdaptiveDialog<T>(
  context: context,
  builder: builder,
  barrierDismissible: barrierDismissible,
  barrierLabel: barrierLabel,
  barrierColor: barrierColor,
);

/// 自适应弹窗内容，支持富文本和动态进度等自定义子组件。
class MDAdaptiveAlertDialog extends StatelessWidget {
  const MDAdaptiveAlertDialog({
    super.key,
    this.title,
    this.content,
    this.actions,
    this.backgroundColor,
    this.shape,
    this.titlePadding,
    this.contentPadding,
    this.actionsPadding,
    this.buttonPadding,
    this.actionsAlignment,
    this.constraints,
    this.clipBehavior = Clip.none,
  });

  final Widget? title;
  final Widget? content;
  final List<Widget>? actions;
  final Color? backgroundColor;
  final ShapeBorder? shape;
  final EdgeInsetsGeometry? titlePadding;
  final EdgeInsetsGeometry? contentPadding;
  final EdgeInsetsGeometry? actionsPadding;
  final EdgeInsetsGeometry? buttonPadding;
  final MainAxisAlignment? actionsAlignment;
  final BoxConstraints? constraints;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) => AlertDialog.adaptive(
    title: title,
    content: content,
    actions: actions,
    backgroundColor: backgroundColor,
    shape: shape,
    titlePadding: titlePadding,
    contentPadding: contentPadding,
    actionsPadding: actionsPadding,
    buttonPadding: buttonPadding,
    actionsAlignment: actionsAlignment,
    constraints: constraints,
    clipBehavior: clipBehavior,
  );
}
