import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../network/oss.dart';
import '../utils/app_colors.dart';
import '../utils/totast.dart';
import 'image_picker.dart';
import 'image_preview.dart';
import 'network_image.dart';

/// 单张图片的上传状态
enum MDImageUploadState {
  /// 上传中（含压缩、排队）
  uploading,

  /// 已有可用地址（预览态传入的 url，或本地图片上传成功）
  success,

  /// 上传失败，可点击重传
  failed,
}

/// 九宫格数据源：持有图片列表，负责 OSS 上传、进度与重传。
///
/// 页面持有该控制器即可读取上传结果：
/// ```dart
/// final controller = MDImageGridController();
/// ...
/// if (!controller.allFinished) return MDTotast.message('请等待图片上传完成');
/// final urls = controller.urls;
/// ```
class MDImageGridController extends ChangeNotifier {
  MDImageGridController({List<String> urls = const []}) {
    _fill(urls);
  }

  final List<_GridItem> _items = [];
  bool _disposed = false;

  /// 当前图片数（不含「添加」占位）
  int get count => _items.length;

  bool get isEmpty => _items.isEmpty;

  /// 可用图片地址，顺序与用户添加顺序一致，不受上传完成先后影响
  List<String> get urls => List.unmodifiable(
    _items
        .where((e) => e.state == MDImageUploadState.success)
        .map((e) => e.url)
        .whereType<String>(),
  );

  /// 是否还有图片正在上传
  bool get isUploading =>
      _items.any((e) => e.state == MDImageUploadState.uploading);

  /// 上传失败的图片数
  int get failedCount =>
      _items.where((e) => e.state == MDImageUploadState.failed).length;

  /// 有图片且全部上传成功，提交前用于校验
  bool get allFinished =>
      _items.isNotEmpty &&
      _items.every((e) => e.state == MDImageUploadState.success);

  /// 重置为一组已有地址（预览态展示、编辑态回填已上传图片）
  void setUrls(List<String> urls) {
    _fill(urls);
    _notify();
  }

  void clear() {
    _items.clear();
    _notify();
  }

  /// 追加本地图片并立即上传，Future 在本批图片全部结束后完成
  Future<void> addPaths(List<String> paths) async {
    final targets = paths
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .map((e) => _GridItem(path: e, state: MDImageUploadState.uploading))
        .toList(growable: false);
    if (targets.isEmpty) return;
    _items.addAll(targets);
    _notify();
    await _upload(targets);
  }

  /// 删除图片；上传中的图片删除后其上传结果会被丢弃
  void delete(String id) {
    if (_item(id) == null) return;
    _items.removeWhere((e) => e.id == id);
    _notify();
  }

  /// 重新上传失败的图片
  Future<void> retry(String id) async {
    final item = _item(id);
    if (item == null ||
        item.path == null ||
        item.state == MDImageUploadState.uploading) {
      return;
    }
    item
      ..state = MDImageUploadState.uploading
      ..progress = 0;
    _notify();
    await _upload([item]);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }

  void _fill(List<String> urls) {
    _items
      ..clear()
      ..addAll(
        urls
            .map((e) => e.trim())
            .where((e) => e.isNotEmpty)
            .map((e) => _GridItem(url: e, state: MDImageUploadState.success)),
      );
  }

  _GridItem? _item(String id) {
    for (final item in _items) {
      if (item.id == id) return item;
    }
    return null;
  }

  Future<void> _upload(List<_GridItem> targets) async {
    // 按 id 回写而不是按位置，上传期间用户删除图片也不会把结果写到别人身上
    final ids = targets.map((e) => e.id).toList(growable: false);
    final paths = targets.map((e) => e.path!).toList(growable: false);
    final result = await MDOss.upload(
      paths,
      progress: (tasks) {
        if (_apply(ids, tasks)) _notify();
      },
    );
    _apply(ids, result.tasks);
    _notify();
    final fails = result.fails.length;
    if (fails > 0) MDTotast.message('$fails张图片上传失败，点击图片可重新上传');
  }

  /// 回写上传状态，返回界面是否需要刷新
  bool _apply(List<String> ids, List<MDOssTask> tasks) {
    var changed = false;
    for (final task in tasks) {
      if (task.index < 0 || task.index >= ids.length) continue;
      final item = _item(ids[task.index]);
      if (item == null) continue;
      final state = switch (task.state) {
        MDOssTaskState.success => MDImageUploadState.success,
        MDOssTaskState.failed => MDImageUploadState.failed,
        _ => MDImageUploadState.uploading,
      };
      final progress = switch (state) {
        MDImageUploadState.success => 1.0,
        MDImageUploadState.failed => 0.0,
        MDImageUploadState.uploading => task.progress.clamp(0.0, 1.0),
      };
      final url = task.url ?? item.url;
      // 进度回调频率远高于百分比变化，只在展示结果变化时刷新
      if (item.state == state &&
          item.percent == (progress * 100).round() &&
          item.url == url) {
        continue;
      }
      item
        ..state = state
        ..progress = progress
        ..url = url;
      changed = true;
    }
    return changed;
  }

  void _notify() {
    if (_disposed) return;
    notifyListeners();
  }
}

/// 图片九宫格，参照 iOS MDGridView：
/// 1、预览态超过 [maxLook] 张时，最后一格蒙层显示剩余张数；
/// 2、编辑态末尾为「添加」，达到 [max] 张后隐藏，删除后重新出现。
///
/// ```dart
/// MDImageGrid(controller: _controller, isEdit: true)
/// MDImageGrid(urls: model.photos)
/// ```
class MDImageGrid extends StatefulWidget {
  const MDImageGrid({
    this.controller,
    this.urls = const [],
    this.isEdit = false,
    this.max = 15,
    this.maxLook = 9,
    this.columns = 3,
    this.spacing = 10,
    this.padding = EdgeInsets.zero,
    this.itemAspectRatio = 108 / 105,
    this.onChanged,
    super.key,
  });

  /// 数据源；为空时内部自建，并跟随 [urls] 刷新
  final MDImageGridController? controller;

  /// 初始图片地址，[controller] 为空时生效
  final List<String> urls;

  /// 是否编辑态（可添加、删除、重传）
  final bool isEdit;

  /// 编辑态最多可添加的张数
  final int max;

  /// 预览态最多显示的张数，超出部分收进最后一格的蒙层
  final int maxLook;

  final int columns;
  final double spacing;
  final EdgeInsetsGeometry padding;

  /// 单格宽高比，默认对齐 iOS 的 105x108
  final double itemAspectRatio;

  /// 可用图片地址发生变化时回调
  final ValueChanged<List<String>>? onChanged;

  @override
  State<MDImageGrid> createState() => _MDImageGridState();
}

class _MDImageGridState extends State<MDImageGrid> {

  MDImageGridController? _inner;
  List<String> _lastUrls = const [];
  bool _picking = false;

  MDImageGridController get _controller => widget.controller ?? _inner!;

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _inner = MDImageGridController(urls: widget.urls);
    }
    _controller.addListener(_handleChanged);
    _lastUrls = _controller.urls;
  }

  @override
  void didUpdateWidget(covariant MDImageGrid oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      (oldWidget.controller ?? _inner)?.removeListener(_handleChanged);
      if (oldWidget.controller == null) {
        _inner?.dispose();
        _inner = null;
      }
      if (widget.controller == null) {
        _inner = MDImageGridController(urls: widget.urls);
      }
      _controller.addListener(_handleChanged);
      _lastUrls = _controller.urls;
    } else if (widget.controller == null &&
        !listEquals(widget.urls, oldWidget.urls)) {
      _inner?.setUrls(widget.urls);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_handleChanged);
    _inner?.dispose();
    super.dispose();
  }

  void _handleChanged() {
    if (!mounted) return;
    setState(() {});
    final urls = _controller.urls;
    if (listEquals(_lastUrls, urls)) return;
    _lastUrls = urls;
    widget.onChanged?.call(urls);
  }

  @override
  Widget build(BuildContext context) {
    final items = _controller._items;
    final showAdd = widget.isEdit && items.length < widget.max;
    final display = widget.isEdit
        ? items.length
        : (items.length > widget.maxLook ? widget.maxLook : items.length);
    final total = display + (showAdd ? 1 : 0);
    if (total == 0) return const SizedBox.shrink();

    return Padding(
      padding: widget.padding,
      child: GridView.builder(
        padding: EdgeInsets.zero,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: widget.columns,
          mainAxisSpacing: widget.spacing,
          crossAxisSpacing: widget.spacing,
          childAspectRatio: widget.itemAspectRatio,
        ),
        itemCount: total,
        itemBuilder: (context, index) {
          if (showAdd && index == total - 1) {
            return _AddTile(onTap: _pickImages);
          }
          final item = items[index];
          return _ImageTile(
            item: item,
            isEdit: widget.isEdit,
            // 预览态最后一格承载超出的张数，如共 15 张显示 +6
            moreCount: !widget.isEdit && index == display - 1
                ? items.length - display
                : 0,
            onTap: () => _handleTap(item),
            onDelete: () => _controller.delete(item.id),
          );
        },
      ),
    );
  }

  void _handleTap(_GridItem item) {
    if (widget.isEdit) {
      if (item.state == MDImageUploadState.failed) {
        _controller.retry(item.id);
        return;
      }
      if (item.state == MDImageUploadState.uploading) return;
    }
    final items = _controller._items;
    final index = items.indexWhere((e) => e.id == item.id);
    if (index < 0) return;
    // 预览始终展示全部图片，不受 maxLook 截断影响
    MDImagePreview.show(
      context,
      sources: items.map((e) => e.source).toList(growable: false),
      initialIndex: index,
    );
  }

  Future<void> _pickImages() async {
    if (_picking) return;
    final rest = widget.max - _controller.count;
    if (rest <= 0) return;
    _picking = true;
    try {
      // 相册权限由 picker（photo_manager）内部处理；
      // 不做压缩，交给 MDOss 在原生侧降采样压缩
      final paths = await MDImagePicker.pickImages(context, max: rest);
      if (paths.isEmpty) return;
      await _controller.addPaths(paths);
    } catch (error) {
      debugPrint('选择图片失败：$error');
      MDTotast.error('打开相册失败，请重试');
    } finally {
      _picking = false;
    }
  }
}

/// 九宫格单项数据
class _GridItem {
  _GridItem({this.path, this.url, required this.state}) : id = '${_seed++}';

  static int _seed = 0;

  final String id;

  /// 本地文件路径，编辑态选择的图片才有
  final String? path;

  /// 远端地址，上传成功后回写
  String? url;

  MDImageUploadState state;

  /// 上传进度 0-1
  double progress = 0;

  /// 展示用地址，优先远端地址
  String get source => url ?? path ?? '';

  int get percent => (progress.clamp(0.0, 1.0) * 100).round();
}

const _tileRadius = BorderRadius.all(Radius.circular(6));

class _ImageTile extends StatelessWidget {
  const _ImageTile({
    required this.item,
    required this.isEdit,
    required this.moreCount,
    required this.onTap,
    required this.onDelete,
  });

  final _GridItem item;
  final bool isEdit;

  /// 大于 0 时在本格显示 "+N" 蒙层
  final int moreCount;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final tile = GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: _tileRadius,
        child: Stack(
          fit: StackFit.expand,
          children: [
            _buildImage(),
            if (moreCount > 0)
              _buildMask(
                Text(
                  '+$moreCount',
                  style: TextStyle(
                    fontSize: 20,
                    color: AppColors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            if (isEdit && item.state == MDImageUploadState.uploading)
              _buildMask(
                Text(
                  '${item.percent}%',
                  style: TextStyle(fontSize: 14, color: AppColors.white),
                ),
              ),
            if (isEdit && item.state == MDImageUploadState.failed)
              _buildMask(
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6),
                  child: Text(
                    '上传失败，点击重新上传',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.3,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
    if (!isEdit) return tile;
    // 删除按钮压在右上角，图片内缩让出位置
    return Stack(
      children: [
        Positioned.fill(
          child: Padding(
            padding: const EdgeInsets.only(top: 6, right: 6),
            child: tile,
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onDelete,
            child: SizedBox(
              width: 30,
              height: 30,
              child: Center(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: AppColors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: Icon(
                      Icons.close,
                      size: 12,
                      color: AppColors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImage() {
    final path = item.path;
    if (path != null) {
      return LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? (constraints.maxWidth * MediaQuery.devicePixelRatioOf(context))
                    .round()
              : null;
          return Image.file(
            File(path),
            fit: BoxFit.cover,
            cacheWidth: width,
            errorBuilder: (context, error, stackTrace) =>
                ColoredBox(color: AppColors.line),
          );
        },
      );
    }
    return MDNetImage(imageUrl: item.source, fit: BoxFit.cover);
  }

  Widget _buildMask(Widget child) => ColoredBox(
    color: AppColors.black.withValues(alpha: 0.5),
    child: Center(child: child),
  );
}

class _AddTile extends StatelessWidget {
  const _AddTile({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.white,
      borderRadius: _tileRadius,
      child: InkWell(
        onTap: onTap,
        borderRadius: _tileRadius,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: _tileRadius,
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add, size: 26, color: AppColors.content),
              const SizedBox(height: 6),
              Text(
                '添加图片',
                style: TextStyle(fontSize: 13, color: AppColors.title),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
