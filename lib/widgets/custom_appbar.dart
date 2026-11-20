import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../gen/assets.gen.dart';
import '../router/app_router.dart';
import '../utils/app_colors.dart';

/// 项目通用导航栏，统一标题样式、背景色和返回按钮，支持添加自定义按钮。
class MDAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MDAppBar({
    required this.title,
    this.titleFontSize = 16,
    this.titleColor,
    this.titleFontWeight = FontWeight.w500,
    this.backgroundColor,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.bottom,
    this.centerTitle = true,
    super.key,
  });

  final String title;
  final double titleFontSize;
  final Color? titleColor;
  final FontWeight titleFontWeight;
  final Color? backgroundColor;
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final bool centerTitle;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    const leadingWidth = 56.0;
    const backIconSize = 24.0;
    const backTitleGap = 10.0;
    final navColor = backgroundColor ?? AppColors.white;
    return AppBar(
      backgroundColor: navColor,
      foregroundColor: AppColors.black,
      surfaceTintColor: navColor,
      shadowColor: AppColors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      leadingWidth: showBackButton ? leadingWidth : null,
      titleSpacing: showBackButton && !centerTitle
          ? backTitleGap - (leadingWidth - backIconSize) / 2
          : null,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      title: Text(
        title,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: titleColor ?? AppColors.title,
          fontSize: titleFontSize,
          fontWeight: titleFontWeight,
        ),
      ),
      leading: showBackButton
          ? IconButton(
              onPressed: onBackPressed ?? () => AppRouter.pop(context),
              icon: Assets.images.public.back.svg(
                width: backIconSize,
                height: backIconSize,
              ),
            )
          : null,
      automaticallyImplyLeading: showBackButton,
      actions: actions,
      bottom: bottom,
    );
  }
}
