import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

/// 关于我们页
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  static const List<AboutType> _items = [.user, .private];

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
                child: CustomAppBar(title: '关于我们'),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          const _HeadCell(),
                          for (var i = 0; i < _items.length; i++)
                            _ListCell(
                              type: _items[i],
                              isFirst: i == 0,
                              isLast: i == _items.length - 1,
                              onTap: () => _openWeb(context, _items[i]),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),
                    Text(
                      MDEnv.icpLicense,
                      style: TextStyle(
                        color: AppColors.content,
                        fontSize: 12,
                        fontWeight: .w400,
                        decoration: TextDecoration.none,
                        decorationColor: AppColors.transparent,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${AppConfig.appName}v${AppConfig.packageInfo.version} Build ${AppConfig.packageInfo.buildNumber}',
                      style: TextStyle(
                        color: AppColors.content,
                        fontSize: 12,
                        fontWeight: .w400,
                        decoration: TextDecoration.none,
                        decorationColor: AppColors.transparent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWeb(BuildContext context, AboutType type) {
    AppRouter.pushNamed(
      context,
      RouterNames.web,
      queryParameters: {
        'url': type.url,
        'title': type.title,
        'disableFd': 'true',
      },
    );
  }
}

enum AboutType {
  user('用户协议', MDEnv.urlForUser),
  private('隐私政策', MDEnv.urlForPrivate);

  const AboutType(this.title, this.url);

  final String title;
  final String url;
}

class _HeadCell extends StatelessWidget {
  const _HeadCell();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 50, bottom: 50),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Assets.images.appLogo1024.image(
              width: 80,
              height: 80,
              fit: .cover,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            '遴选好帮手',
            style: TextStyle(
              color: AppColors.black,
              fontSize: 14,
              fontWeight: .w500,
              decoration: TextDecoration.none,
              decorationColor: AppColors.transparent,
            ),
          ),
        ],
      ),
    );
  }
}

class _ListCell extends StatelessWidget {
  const _ListCell({
    required this.type,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final AboutType type;
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
          onTap: onTap,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.white),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type.title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 15,
                        fontWeight: .w600,
                        decoration: TextDecoration.none,
                        decorationColor: AppColors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Assets.images.public.arrowRight.svg(width: 12, height: 12),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
