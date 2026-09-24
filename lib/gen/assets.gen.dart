// dart format width=80

/// GENERATED CODE - DO NOT MODIFY BY HAND
/// *****************************************************
///  FlutterGen
/// *****************************************************

// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: deprecated_member_use,directives_ordering,implicit_dynamic_list_literal,unnecessary_import

import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart' as _svg;
import 'package:vector_graphics/vector_graphics.dart' as _vg;

class $AssetsImagesGen {
  const $AssetsImagesGen();

  /// File path: assets/images/appLogo1024.png
  AssetGenImage get appLogo1024 =>
      const AssetGenImage('assets/images/appLogo1024.png');

  /// Directory path: assets/images/launch
  $AssetsImagesLaunchGen get launch => const $AssetsImagesLaunchGen();

  /// Directory path: assets/images/mine
  $AssetsImagesMineGen get mine => const $AssetsImagesMineGen();

  /// Directory path: assets/images/public
  $AssetsImagesPublicGen get public => const $AssetsImagesPublicGen();

  /// Directory path: assets/images/tabbar
  $AssetsImagesTabbarGen get tabbar => const $AssetsImagesTabbarGen();

  /// List of all assets
  List<AssetGenImage> get values => [appLogo1024];
}

class $AssetsImagesLaunchGen {
  const $AssetsImagesLaunchGen();

  /// File path: assets/images/launch/startBg.png
  AssetGenImage get startBg =>
      const AssetGenImage('assets/images/launch/startBg.png');

  /// File path: assets/images/launch/startBot.png
  AssetGenImage get startBot =>
      const AssetGenImage('assets/images/launch/startBot.png');

  /// File path: assets/images/launch/startCent.png
  AssetGenImage get startCent =>
      const AssetGenImage('assets/images/launch/startCent.png');

  /// List of all assets
  List<AssetGenImage> get values => [startBg, startBot, startCent];
}

class $AssetsImagesMineGen {
  const $AssetsImagesMineGen();

  /// File path: assets/images/mine/defaultProfile.svg
  SvgGenImage get defaultProfile =>
      const SvgGenImage('assets/images/mine/defaultProfile.svg');

  /// File path: assets/images/mine/mineBg@2x.png
  AssetGenImage get mineBg2x =>
      const AssetGenImage('assets/images/mine/mineBg@2x.png');

  /// File path: assets/images/mine/mineBg@3x.png
  AssetGenImage get mineBg3x =>
      const AssetGenImage('assets/images/mine/mineBg@3x.png');

  /// File path: assets/images/mine/mineDonwloads.svg
  SvgGenImage get mineDonwloads =>
      const SvgGenImage('assets/images/mine/mineDonwloads.svg');

  /// File path: assets/images/mine/mineFavorites.svg
  SvgGenImage get mineFavorites =>
      const SvgGenImage('assets/images/mine/mineFavorites.svg');

  /// File path: assets/images/mine/mineFeedback.svg
  SvgGenImage get mineFeedback =>
      const SvgGenImage('assets/images/mine/mineFeedback.svg');

  /// File path: assets/images/mine/mineOnline.svg
  SvgGenImage get mineOnline =>
      const SvgGenImage('assets/images/mine/mineOnline.svg');

  /// File path: assets/images/mine/mineSetting.svg
  SvgGenImage get mineSetting =>
      const SvgGenImage('assets/images/mine/mineSetting.svg');

  /// List of all assets
  List<dynamic> get values => [
    defaultProfile,
    mineBg2x,
    mineBg3x,
    mineDonwloads,
    mineFavorites,
    mineFeedback,
    mineOnline,
    mineSetting,
  ];
}

class $AssetsImagesPublicGen {
  const $AssetsImagesPublicGen();

  /// File path: assets/images/public/arrowRight.svg
  SvgGenImage get arrowRight =>
      const SvgGenImage('assets/images/public/arrowRight.svg');

  /// File path: assets/images/public/back.svg
  SvgGenImage get back => const SvgGenImage('assets/images/public/back.svg');

  /// File path: assets/images/public/select.svg
  SvgGenImage get select =>
      const SvgGenImage('assets/images/public/select.svg');

  /// File path: assets/images/public/unselect.svg
  SvgGenImage get unselect =>
      const SvgGenImage('assets/images/public/unselect.svg');

  /// List of all assets
  List<SvgGenImage> get values => [arrowRight, back, select, unselect];
}

class $AssetsImagesTabbarGen {
  const $AssetsImagesTabbarGen();

  /// File path: assets/images/tabbar/tabbar_hight_1.svg
  SvgGenImage get tabbarHight1 =>
      const SvgGenImage('assets/images/tabbar/tabbar_hight_1.svg');

  /// File path: assets/images/tabbar/tabbar_hight_2.svg
  SvgGenImage get tabbarHight2 =>
      const SvgGenImage('assets/images/tabbar/tabbar_hight_2.svg');

  /// File path: assets/images/tabbar/tabbar_hight_3.svg
  SvgGenImage get tabbarHight3 =>
      const SvgGenImage('assets/images/tabbar/tabbar_hight_3.svg');

  /// File path: assets/images/tabbar/tabbar_normal_1.svg
  SvgGenImage get tabbarNormal1 =>
      const SvgGenImage('assets/images/tabbar/tabbar_normal_1.svg');

  /// File path: assets/images/tabbar/tabbar_normal_2.svg
  SvgGenImage get tabbarNormal2 =>
      const SvgGenImage('assets/images/tabbar/tabbar_normal_2.svg');

  /// File path: assets/images/tabbar/tabbar_normal_3.svg
  SvgGenImage get tabbarNormal3 =>
      const SvgGenImage('assets/images/tabbar/tabbar_normal_3.svg');

  /// List of all assets
  List<SvgGenImage> get values => [
    tabbarHight1,
    tabbarHight2,
    tabbarHight3,
    tabbarNormal1,
    tabbarNormal2,
    tabbarNormal3,
  ];
}

abstract final class Assets {
  static const $AssetsImagesGen images = $AssetsImagesGen();
}

class AssetGenImage {
  const AssetGenImage(
    this._assetName, {
    this.size,
    this.flavors = const {},
    this.animation,
  });

  final String _assetName;

  final Size? size;
  final Set<String> flavors;
  final AssetGenImageAnimation? animation;

  Image image({
    Key? key,
    AssetBundle? bundle,
    ImageFrameBuilder? frameBuilder,
    ImageErrorWidgetBuilder? errorBuilder,
    String? semanticLabel,
    bool excludeFromSemantics = false,
    double? scale,
    double? width,
    double? height,
    Color? color,
    Animation<double>? opacity,
    BlendMode? colorBlendMode,
    BoxFit? fit,
    AlignmentGeometry alignment = Alignment.center,
    ImageRepeat repeat = ImageRepeat.noRepeat,
    Rect? centerSlice,
    bool matchTextDirection = false,
    bool gaplessPlayback = true,
    bool isAntiAlias = false,
    String? package,
    FilterQuality filterQuality = FilterQuality.medium,
    int? cacheWidth,
    int? cacheHeight,
  }) {
    return Image.asset(
      _assetName,
      key: key,
      bundle: bundle,
      frameBuilder: frameBuilder,
      errorBuilder: errorBuilder,
      semanticLabel: semanticLabel,
      excludeFromSemantics: excludeFromSemantics,
      scale: scale,
      width: width,
      height: height,
      color: color,
      opacity: opacity,
      colorBlendMode: colorBlendMode,
      fit: fit,
      alignment: alignment,
      repeat: repeat,
      centerSlice: centerSlice,
      matchTextDirection: matchTextDirection,
      gaplessPlayback: gaplessPlayback,
      isAntiAlias: isAntiAlias,
      package: package,
      filterQuality: filterQuality,
      cacheWidth: cacheWidth,
      cacheHeight: cacheHeight,
    );
  }

  ImageProvider provider({AssetBundle? bundle, String? package}) {
    return AssetImage(_assetName, bundle: bundle, package: package);
  }

  String get path => _assetName;

  String get keyName => _assetName;
}

class AssetGenImageAnimation {
  const AssetGenImageAnimation({
    required this.isAnimation,
    required this.duration,
    required this.frames,
  });

  final bool isAnimation;
  final Duration duration;
  final int frames;
}

class SvgGenImage {
  const SvgGenImage(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = false;

  const SvgGenImage.vec(this._assetName, {this.size, this.flavors = const {}})
    : _isVecFormat = true;

  final String _assetName;
  final Size? size;
  final Set<String> flavors;
  final bool _isVecFormat;

  _svg.SvgPicture svg({
    Key? key,
    bool matchTextDirection = false,
    AssetBundle? bundle,
    String? package,
    double? width,
    double? height,
    BoxFit fit = BoxFit.contain,
    AlignmentGeometry alignment = Alignment.center,
    bool allowDrawingOutsideViewBox = false,
    WidgetBuilder? placeholderBuilder,
    String? semanticsLabel,
    bool excludeFromSemantics = false,
    _svg.SvgTheme? theme,
    _svg.ColorMapper? colorMapper,
    ColorFilter? colorFilter,
    Clip clipBehavior = Clip.hardEdge,
    @deprecated Color? color,
    @deprecated BlendMode colorBlendMode = BlendMode.srcIn,
    @deprecated bool cacheColorFilter = false,
  }) {
    final _svg.BytesLoader loader;
    if (_isVecFormat) {
      loader = _vg.AssetBytesLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
      );
    } else {
      loader = _svg.SvgAssetLoader(
        _assetName,
        assetBundle: bundle,
        packageName: package,
        theme: theme,
        colorMapper: colorMapper,
      );
    }
    return _svg.SvgPicture(
      loader,
      key: key,
      matchTextDirection: matchTextDirection,
      width: width,
      height: height,
      fit: fit,
      alignment: alignment,
      allowDrawingOutsideViewBox: allowDrawingOutsideViewBox,
      placeholderBuilder: placeholderBuilder,
      semanticsLabel: semanticsLabel,
      excludeFromSemantics: excludeFromSemantics,
      colorFilter:
          colorFilter ??
          (color == null ? null : ColorFilter.mode(color, colorBlendMode)),
      clipBehavior: clipBehavior,
      cacheColorFilter: cacheColorFilter,
    );
  }

  String get path => _assetName;

  String get keyName => _assetName;
}
