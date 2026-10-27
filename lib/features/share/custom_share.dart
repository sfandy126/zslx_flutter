import 'package:fluwx/fluwx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gal/gal.dart';
import 'package:zslx_flutter/utils/utils.dart';

import 'share.dart';
import 'wx_share.dart';

class _ShareItem {
  const _ShareItem(this.icon, this.label, this.action);

  final Object icon;
  final String label;
  final void Function() action;
}

Future<void> showCustomShare(
  BuildContext context,
  MDShareData data, {
  void Function(MDShareChannel channel)? onComplete,
}) async {
  if (data.isEmpty) {
    MDTotast.message('分享内容为空');
    return;
  }

  final (platformItems, toolItems) =
      await _buildItems(context, data, onComplete);
  if (!context.mounted) return;
  if (platformItems.isEmpty && toolItems.isEmpty) {
    MDTotast.message('暂无可用的分享方式');
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => SafeArea(
      top: false,
      child: _SharePanel(
        platforms: platformItems,
        tools: toolItems,
      ),
    ),
  );
}

Future<(List<_ShareItem>, List<_ShareItem>)> _buildItems(
  BuildContext context,
  MDShareData data,
  void Function(MDShareChannel channel)? onComplete,
) async {
  final platforms = <_ShareItem>[];
  final tools = <_ShareItem>[];

  for (final channel in data.channels) {
    switch (channel) {
      case .wx:
        if (await WxShare.isInstalled()) {
          platforms.add(_ShareItem(
            Assets.images.public.wx,
            '微信好友',
            () => _executeWx(data, .session, onComplete),
          ));
        }
      case .wxzone:
        if (await WxShare.isInstalled()) {
          platforms.add(_ShareItem(
            Assets.images.public.wxzone,
            '微信朋友圈',
            () => _executeWx(data, .timeline, onComplete),
          ));
        }
      case .system:
        platforms.add(_ShareItem(
          Icons.ios_share,
          '更多',
          () => MDShare.toSystem(data),
        ));
    }
  }

  for (final tool in data.tools) {
    switch (tool) {
      case .saveImage:
        if (data.method != .image) break;
        tools.add(_ShareItem(
          Icons.save_alt,
          '保存图片',
          () => _saveImage(data),
        ));
      case .copyLink:
        if (data.method != .link) break;
        tools.add(_ShareItem(
          Icons.link,
          '复制链接',
          () => _ShareActions.copyLink(data.link!),
        ));
    }
  }
  return (platforms, tools);
}

Future<void> _executeWx(
  MDShareData data,
  WeChatScene scene, [
  void Function(MDShareChannel channel)? onComplete,
]) async {
  final ok = await _sendToWx(data, scene);
  onComplete?.call(ok ? MDShareChannel.wx : MDShareChannel.wx);
}

Future<bool> _sendToWx(MDShareData data, WeChatScene scene) async {
  MDTotast.showLoading();
  try {
    switch (data.method) {
      case .image:
        var bytes = await downloadBytes(data.url!);
        MDTotast.hideLoading();
        if (bytes == null) {
          MDTotast.message('图片获取失败，无法分享');
          return false;
        }
        // 压缩到微信原图分享大小限制内
        bytes = await WxShare.compressImage(
          bytes,
          maxBytes: WxShare.maxShareImageBytes,
        );
        return await WxShare.shareImage(bytes: bytes, scene: scene);
      case .file:
        final bytes = await downloadBytes(data.url!);
        MDTotast.hideLoading();
        if (bytes == null) {
          MDTotast.message('文件获取失败，无法分享');
          return false;
        }
        return await WxShare.shareFile(
          bytes: bytes,
          name: data.fileName.isEmpty ? 'file' : data.fileName,
          title: data.title,
        );
      case .link:
        MDTotast.hideLoading();
        // 链接缩略图：优先取资源 url 图片压缩，无资源时由 WxShare 回退默认图标
        final thumb = data.url == null
            ? null
            : await WxShare.thumbnailFromUrl(data.url!);
        return await WxShare.shareWebPage(
          data.link ?? '',
          data.title,
          data.text,
          scene,
          thumbData: thumb,
        );
    }
  } catch (error) {
    MDTotast.hideLoading();
    MDTotast.message('分享失败，请稍后重试');
    Utils.log('MDShare wx share error: $error');
    return false;
  }
}

Future<void> _saveImage(MDShareData data) async {
  MDTotast.showLoading();
  final bytes = await downloadBytes(data.url!);
  MDTotast.hideLoading();
  if (bytes == null) {
    MDTotast.message('图片获取失败，无法保存');
    return;
  }
  await _ShareActions.saveImage(bytes, data.title);
}

class _SharePanel extends StatelessWidget {
  const _SharePanel({required this.platforms, required this.tools});

  final List<_ShareItem> platforms;
  final List<_ShareItem> tools;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 24),
        _ShareRow(items: platforms),
        if (tools.isNotEmpty) ...[
          const SizedBox(height: 16),
          Container(height: 0.5, color: AppColors.line),
          const SizedBox(height: 16),
          _ShareRow(items: tools),
        ],
        const SizedBox(height: 16),
        Container(height: 8, color: AppColors.background),
        SizedBox(
          height: 52,
          width: double.infinity,
          child: TextButton(
            onPressed: () => Navigator.of(context).pop(),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.title,
              textStyle: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: AppColors.title),
            ),
            child: const Text('取消'),
          ),
        ),
      ],
    );
  }
}

class _ShareRow extends StatelessWidget {
  const _ShareRow({required this.items});

  final List<_ShareItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: [
          for (final (index, item) in items.indexed) ...[
            if (index > 0) const SizedBox(width: 24),
            _ShareCell(item: item),
          ],
        ],
      ),
    );
  }
}

class _ShareCell extends StatelessWidget {
  const _ShareCell({required this.item});

  final _ShareItem item;

  @override
  Widget build(BuildContext context) {
    final icon = item.icon;
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        item.action();
      },
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon is SvgGenImage)
              icon.svg(width: 44, height: 44)
            else if (icon is IconData)
              Icon(icon, size: 44, color: AppColors.theme)
            else
              const SizedBox(width: 44, height: 44),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                fontSize: 12,
                color: AppColors.content,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}


class _ShareActions {
  _ShareActions._();

  static Future<void> saveImage(Uint8List bytes, String? name) async {
    try {
      if (!await Gal.hasAccess()) {
        final granted = await Gal.requestAccess();
        if (!granted) {
          MDTotast.message('未获得相册权限，无法保存');
          return;
        }
      }
      await Gal.putImageBytes(
        bytes,
        name: '${name ?? DateTime.now().millisecondsSinceEpoch}.png',
      );
      MDTotast.success('已保存到相册');
    } catch (error) {
      MDTotast.message('保存失败，请稍后重试');
      Utils.log('MDShare saveImage error: $error');
    }
  }

  static Future<void> copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    MDTotast.message('链接已复制');
  }
}
