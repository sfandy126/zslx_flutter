import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:zslx_flutter/gen/assets.gen.dart';

class MDNetImage extends StatelessWidget {
  const MDNetImage({
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius = BorderRadius.zero,
    this.isAvatar = false,
    super.key,
  });

  static const _placeholderColor = Color(0xFFF8F8F8);

  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry borderRadius;
  final bool isAvatar;

  @override
  Widget build(BuildContext context) {
    final url = imageUrl.trim();
    final placeholder = isAvatar
        ? Assets.images.mine.defaultProfile.svg()
        : const ColoredBox(color: _placeholderColor);

    final image = url.isEmpty
        ? SizedBox(
            width: width,
            height: height,
            child: placeholder,
          )
        : CachedNetworkImage(
            imageUrl: url,
            width: width,
            height: height,
            fit: fit,
            placeholder: (context, url) => placeholder,
            errorBuilder: (context, error, stackTrace) => placeholder,
          );

    return ClipRRect(borderRadius: borderRadius, child: image);
  }
}
