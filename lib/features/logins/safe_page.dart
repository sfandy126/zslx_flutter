import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

class SafePage extends StatelessWidget {
  const SafePage({super.key});

  static const _sections = <List<SafeDataType>>[
    [SafeDataType.phone, SafeDataType.passwd],
    [SafeDataType.logoff],
  ];

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.white,
            child: const SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: CustomAppBar(title: '账号安全'),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SafeArea(
                top: false,
                child: ListView.builder(
                  padding: const EdgeInsets.only(top: 12, bottom: 24),
                  itemCount: _sections.length,
                  itemBuilder: (context, sectionIndex) {
                    final items = _sections[sectionIndex];
                    return Padding(
                      padding: EdgeInsets.only(top: sectionIndex == 0 ? 0 : 12),
                      child: Column(
                        children: [
                          for (var i = 0; i < items.length; i++)
                            _SafeListCell(
                              type: items[i],
                              value: _valueFor(items[i]),
                              isFirst: i == 0,
                              isLast: i == items.length - 1,
                              onTap: () => _handleTap(context, items[i]),
                            ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _valueFor(SafeDataType type) {
    switch (type) {
      case SafeDataType.phone:
        return MDUser.defualt.phone ?? '';
      case SafeDataType.passwd:
        return '';
      case SafeDataType.logoff:
        return '注销后无法恢复，请谨慎操作';
    }
  }

  void _handleTap(BuildContext context, SafeDataType type) {
    switch (type) {
      case SafeDataType.phone:
        break;
      case SafeDataType.passwd:
        AppRouter.pushNamed(context, RouterNames.passward);
      case SafeDataType.logoff:
        AppRouter.pushNamed(context, RouterNames.off);
    }
  }
}

enum SafeDataType {
  phone('手机号'),
  passwd('修改密码'),
  logoff('注销账号');

  const SafeDataType(this.title);

  final String title;

  bool get isVertical => this == logoff;

  bool get showArrow => this != phone;
}

class _SafeListCell extends StatelessWidget {
  const _SafeListCell({
    required this.type,
    required this.value,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final SafeDataType type;
  final String value;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  static const _radius = Radius.circular(12);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? _radius : Radius.zero,
      bottom: isLast ? _radius : Radius.zero,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: type.showArrow ? onTap : null,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.white),
            child: type.isVertical
                ? _VerticalContent(type: type, value: value)
                : _HorizontalContent(type: type, value: value),
          ),
        ),
      ),
    );
  }
}

class _HorizontalContent extends StatelessWidget {
  const _HorizontalContent({required this.type, required this.value});

  final SafeDataType type;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Text(
              type.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.title,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.none,
                decorationColor: AppColors.transparent,
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: AppColors.content,
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  decoration: TextDecoration.none,
                  decorationColor: AppColors.transparent,
                ),
              ),
            ),
          ),
          SizedBox(width: type.showArrow ? 4 : 16),
          if (type.showArrow) ...[
            Assets.images.public.arrowRight.svg(width: 12, height: 12),
            const SizedBox(width: 16),
          ],
        ],
      ),
    );
  }
}

class _VerticalContent extends StatelessWidget {
  const _VerticalContent({required this.type, required this.value});

  final SafeDataType type;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  type.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    decoration: TextDecoration.none,
                    decorationColor: AppColors.transparent,
                  ),
                ),
                if (value.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.content,
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      decoration: TextDecoration.none,
                      decorationColor: AppColors.transparent,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 4),
          Assets.images.public.arrowRight.svg(width: 12, height: 12),
          const SizedBox(width: 16),
        ],
      ),
    );
  }
}
