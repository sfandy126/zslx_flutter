import 'package:fluwx/fluwx.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:zslx_flutter/utils/utils.dart';

import 'share.dart';
import 'wx_share.dart';

class _ShareItem {
  const _ShareItem(this.icon, this.label, this.action);

  final Widget icon;
  final String label;
  final void Function() action;
}

Future<void> showCustomShare(
  BuildContext context,
  MDShareData data, {
  void Function(MDShareChannel channel)? onComplete,
}) async {
  if (data.isEmpty) return;

  final items = await _buildItems(data, onComplete);
  if (!context.mounted) return;
  if (items.isEmpty) {
    MDTotast.message('暂无可用的分享方式');
    return;
  }

  await showModalBottomSheet<void>(
    context: context,
    backgroundColor: AppColors.white,
    isScrollControlled: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => SafeArea(top: false, child: _SharePanel(items: items)),
  );
}

Future<List<_ShareItem>> _buildItems(
  MDShareData data,
  void Function(MDShareChannel channel)? onComplete,
) async {
  final items = <_ShareItem>[];
  final hasWechat =
      (data.channels.contains(MDShareChannel.wx) ||
          data.channels.contains(MDShareChannel.wxzone)) &&
      await WxShare.isInstalled();

  for (final channel in data.channels) {
    switch (channel) {
      case .wx:
        if (hasWechat) {
          items.add(
            _ShareItem(
              _shareIcon('wechat', AppColors.seaGreen),
              '微信好友',
              () => _executeWx(data, .session, onComplete),
            ),
          );
        }
      case .wxzone:
        if (hasWechat) {
          items.add(
            _ShareItem(
              _shareIcon('zone', AppColors.seaGreen),
              '朋友圈',
              () => _executeWx(data, .timeline, onComplete),
            ),
          );
        }
      case .system:
        items.add(
          _ShareItem(
            Icon(Icons.ios_share, color: AppColors.theme),
            '更多',
            () => MDShare.toSystem(data),
          ),
        );
    }
  }

  for (final tool in data.tools) {
    switch (tool) {
      case .copyLink:
        if (data.method != .link) break;
        items.add(
          _ShareItem(
            _shareIcon('link', AppColors.articleCategoryIndicator),
            '复制链接',
            () => _ShareActions.copyLink(data.link!),
          ),
        );
    }
  }
  return items;
}

Widget _shareIcon(String name, Color color) {
  return SvgPicture.asset(
    'assets/images/public/zs_ui_$name.svg',
    width: 24,
    height: 24,
    colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
  );
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

class _SharePanel extends StatelessWidget {
  const _SharePanel({required this.items});

  final List<_ShareItem> items;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.paleBlue,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            '分享',
            style: TextStyle(
              color: AppColors.bigTitle,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              spacing: 24,
              children: [for (final item in items) _ShareCell(item: item)],
            ),
          ),
          const SizedBox(height: 32),
          OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.content,
              minimumSize: const Size.fromHeight(44),
              side: const BorderSide(color: AppColors.paleBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              splashFactory: NoSplash.splashFactory,
            ),
            child: const Text('关闭'),
          ),
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
    return InkWell(
      onTap: () {
        Navigator.of(context).pop();
        item.action();
      },
      splashFactory: NoSplash.splashFactory,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.paleBlue),
              borderRadius: BorderRadius.circular(16),
            ),
            child: item.icon,
          ),
          const SizedBox(height: 8),
          Text(
            item.label,
            style: TextStyle(fontSize: 12, color: AppColors.content),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _ShareActions {
  _ShareActions._();

  static Future<void> copyLink(String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    MDTotast.message('链接已复制');
  }
}
