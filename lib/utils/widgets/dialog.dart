import 'package:flutter/material.dart';

import '../app_colors.dart';

/// 弹窗显示方式
enum MDDialogMode {
  /// 从中间淡入
  face,
  /// 从底部弹出
  bottom,
}

/// 通用弹窗
///
/// ```dart
/// final confirmed = await MDDialog.show(
///   context,
///   title: '温馨提示',
///   content: '同意用户协议、隐私政策',
/// );
/// ```
class MDDialog extends StatelessWidget {
  const MDDialog({
    required this.content,
    this.title,
    this.buttons = defaultButtons,
    this.mode = .face,
    super.key,
  });

  static const defaultButtons = ['取消', '确定'];

  /// 标题，为空时正文使用标题的字体与颜色
  final String? title;

  /// 正文
  final String content;

  /// 底部按钮名称，2 个时为 [取消, 确定]，1 个时居中显示，为空时显示「确定」
  final List<String> buttons;

  /// 显示方式，默认从中间弹出
  final MDDialogMode mode;

  /// 显示弹窗，点击确定返回 true，点击取消或关闭返回 false
  static Future<bool> show(
    BuildContext context, {
    required String content,
    String? title,
    List<String> buttons = defaultButtons,
    MDDialogMode mode = .face,
    bool barrierDismissible = false,
  }) async {
    final result = await showGeneralDialog<bool>(
      context: context,
      barrierDismissible: barrierDismissible,
      barrierLabel: 'MDDialog',
      barrierColor: AppColors.black.withValues(alpha: 0.4),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => MDDialog(
        title: title,
        content: content,
        buttons: buttons,
        mode: mode,
      ),
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        if (mode == .bottom) {
          return SlideTransition(
            position: Tween(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          );
        }
        return FadeTransition(opacity: curved, child: child);
      },
    );
    return result ?? false;
  }

  static const double _minHeight = 120;
  static const double _padding = 36;
  static const double _tabletWidth = 320;

  bool get _hasTitle => title != null && title!.isNotEmpty;

  TextStyle get _titleStyle => TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.title,
  );

  TextStyle get _contentStyle => _hasTitle
      ? TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: AppColors.content,
          height: 1.4,
        )
      : _titleStyle.copyWith(height: 1.4);

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final isBottom = mode == .bottom;
    final bottomInset = isBottom ? MediaQuery.paddingOf(context).bottom : 0.0;

    final body = Material(
      color: AppColors.white,
      shape: RoundedRectangleBorder(
        borderRadius: isBottom
            ? const BorderRadius.vertical(top: Radius.circular(20))
            : BorderRadius.circular(12),
      ),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: _minHeight + bottomInset,
          maxHeight: size.height * 0.8,
        ),
        child: Padding(
          padding: EdgeInsets.only(bottom: 24 + bottomInset),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (_hasTitle)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 16),
                  child: Text(
                    title!,
                    style: _titleStyle,
                    textAlign: TextAlign.center,
                  ),
                )
              else
                const SizedBox(height: 24),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    content,
                    style: _contentStyle,
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
              const SizedBox(height: 24),
              _buildButtons(context),
            ],
          ),
        ),
      ),
    );

    if (isBottom) {
      return Align(alignment: Alignment.bottomCenter, child: body);
    }

    // 平板上固定宽度，避免弹窗被拉得过宽
    final isTablet = size.shortestSide >= 600;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: _padding),
        child: SizedBox(
          width: isTablet ? _tabletWidth : double.infinity,
          child: body,
        ),
      ),
    );
  }

  Widget _buildButtons(BuildContext context) {
    if (buttons.length < 2) {
      return _DialogButton(
        text: buttons.isEmpty ? '确定' : buttons.last,
        isConfirm: true,
        width: 80,
        onPressed: () => Navigator.of(context).pop(true),
      );
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: _DialogButton(
              text: buttons.first,
              isConfirm: false,
              onPressed: () => Navigator.of(context).pop(false),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: _DialogButton(
              text: buttons.last,
              isConfirm: true,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogButton extends StatelessWidget {
  const _DialogButton({
    required this.text,
    required this.isConfirm,
    required this.onPressed,
    this.width,
  });

  final String text;
  final bool isConfirm;
  final VoidCallback onPressed;
  final double? width;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: 36,
      child: TextButton(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          backgroundColor: isConfirm ? AppColors.theme : AppColors.background,
          foregroundColor: isConfirm ? AppColors.white : AppColors.title,
          padding: EdgeInsets.zero,
          shape: const StadiumBorder(),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        child: Text(text, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
    );
  }
}
