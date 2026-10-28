import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../utils/app_colors.dart';

/// 大图预览：左右滑动切换、双指捏合与双击缩放，打开时定位到指定下标。
///
/// ```dart
/// MDImagePreview.show(context, sources: urls, initialIndex: 2);
/// ```
class MDImagePreview extends StatefulWidget {
  const MDImagePreview({
    required this.sources,
    this.initialIndex = 0,
    super.key,
  });

  /// 图片地址，http(s) 开头按网络图加载，其余按本地文件路径加载
  final List<String> sources;

  /// 打开时定位的下标
  final int initialIndex;

  /// 弹出预览页，[sources] 为空时不做任何处理
  static Future<void> show(
    BuildContext context, {
    required List<String> sources,
    int initialIndex = 0,
  }) {
    if (sources.isEmpty) return Future<void>.value();
    return Navigator.of(context, rootNavigator: true).push<void>(
      PageRouteBuilder<void>(
        barrierColor: AppColors.black,
        transitionDuration: const Duration(milliseconds: 200),
        reverseTransitionDuration: const Duration(milliseconds: 200),
        pageBuilder: (context, animation, secondaryAnimation) => FadeTransition(
          opacity: animation,
          child: MDImagePreview(
            sources: sources,
            initialIndex: initialIndex,
          ),
        ),
      ),
    );
  }

  @override
  State<MDImagePreview> createState() => _MDImagePreviewState();
}

class _MDImagePreviewState extends State<MDImagePreview> {
  late final PageController _pageController;
  late int _index;

  /// 当前页放大后禁用翻页，避免横向拖动被 PageView 抢走
  bool _zoomed = false;

  @override
  void initState() {
    super.initState();
    _index = widget.initialIndex.clamp(0, widget.sources.length - 1);
    _pageController = PageController(initialPage: _index);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.black,
      body: Stack(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).maybePop(),
            child: PageView.builder(
              controller: _pageController,
              physics: _zoomed
                  ? const NeverScrollableScrollPhysics()
                  : const PageScrollPhysics(),
              itemCount: widget.sources.length,
              onPageChanged: (value) => setState(() {
                _index = value;
                _zoomed = false;
              }),
              itemBuilder: (context, index) => _PreviewItem(
                source: widget.sources[index],
                isActive: index == _index,
                onZoomChanged: (zoomed) {
                  if (_zoomed == zoomed) return;
                  setState(() => _zoomed = zoomed);
                },
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () => Navigator.of(context).maybePop(),
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Icon(Icons.close, size: 24, color: AppColors.white),
                ),
              ),
            ),
          ),
          if (widget.sources.length > 1)
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    '${_index + 1}/${widget.sources.length}',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// 单页图片，自持缩放矩阵，离开当前页时复位
class _PreviewItem extends StatefulWidget {
  const _PreviewItem({
    required this.source,
    required this.isActive,
    required this.onZoomChanged,
  });

  final String source;
  final bool isActive;
  final ValueChanged<bool> onZoomChanged;

  @override
  State<_PreviewItem> createState() => _PreviewItemState();
}

class _PreviewItemState extends State<_PreviewItem> {
  static const _doubleTapScale = 2.5;

  final _transformation = TransformationController();
  TapDownDetails? _doubleTapDetails;

  @override
  void initState() {
    super.initState();
    _transformation.addListener(_handleTransform);
  }

  @override
  void didUpdateWidget(covariant _PreviewItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive && !widget.isActive) _reset();
  }

  @override
  void dispose() {
    _transformation.removeListener(_handleTransform);
    _transformation.dispose();
    super.dispose();
  }

  bool get _isZoomed => _transformation.value.getMaxScaleOnAxis() > 1.01;

  void _handleTransform() {
    if (!widget.isActive) return;
    widget.onZoomChanged(_isZoomed);
  }

  void _reset() => _transformation.value = Matrix4.identity();

  /// 双击以点击位置为锚点放大，已放大时复位
  void _toggleZoom() {
    if (_isZoomed) {
      _reset();
      return;
    }
    final position = _doubleTapDetails?.localPosition;
    if (position == null) return;
    const scale = _doubleTapScale;
    _transformation.value = Matrix4.identity()
      ..setEntry(0, 0, scale)
      ..setEntry(1, 1, scale)
      ..setEntry(0, 3, -position.dx * (scale - 1))
      ..setEntry(1, 3, -position.dy * (scale - 1));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTapDown: (details) => _doubleTapDetails = details,
      onDoubleTap: _toggleZoom,
      child: InteractiveViewer(
        transformationController: _transformation,
        minScale: 1,
        maxScale: 4,
        child: SizedBox.expand(child: _buildImage(context)),
      ),
    );
  }

  Widget _buildImage(BuildContext context) {
    final source = widget.source.trim();
    if (source.isEmpty) return _buildFailed();
    // 放大后仍需清晰，但要限制解码尺寸：部分端上传的原图超过 9000px，整图解码会撑爆内存
    final cacheWidth =
        (MediaQuery.sizeOf(context).width *
                MediaQuery.devicePixelRatioOf(context) *
                2)
            .round();
    if (!source.startsWith('http')) {
      return Image.file(
        File(source),
        fit: BoxFit.contain,
        cacheWidth: cacheWidth,
        errorBuilder: (context, error, stackTrace) => _buildFailed(),
      );
    }
    return CachedNetworkImage(
      imageUrl: source,
      fit: BoxFit.contain,
      memCacheWidth: cacheWidth,
      fadeInDuration: Duration.zero,
      fadeOutDuration: Duration.zero,
      placeholder: (context, url) => Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: AppColors.white,
          ),
        ),
      ),
      errorBuilder: (context, error, stackTrace) => _buildFailed(),
    );
  }

  Widget _buildFailed() => Center(
    child: Icon(
      Icons.broken_image_outlined,
      size: 48,
      color: AppColors.white.withValues(alpha: 0.6),
    ),
  );
}
