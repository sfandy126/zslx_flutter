import 'dart:io';

import 'package:flutter/cupertino.dart' show CupertinoButtonSize;
import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/utils.dart';

import '../router/app_router.dart';
import 'update_launcher.dart';
import 'update_server.dart';

class UpdateAlert {
  UpdateAlert._();

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo update,
  }) {
    return showPlatformDialog<void>(
      context: context,
      barrierDismissible: !update.isCoerce,
      barrierLabel: '应用更新',
      material: MaterialDialogData(
        barrierColor: AppColors.black.withValues(alpha: 0.55),
      ),
      builder: (context) => _UpdateDialog(update: update),
    );
  }
}

enum _UpdatePhase { ready, downloading, installing }

class _UpdateDialog extends StatefulWidget {
  const _UpdateDialog({required this.update});

  final AppUpdateInfo update;

  @override
  State<_UpdateDialog> createState() => _UpdateDialogState();
}

class _UpdateDialogState extends State<_UpdateDialog> {
  _UpdatePhase _phase = _UpdatePhase.ready;
  double _progress = 0;
  String? _error;

  bool get _isWorking => _phase != _UpdatePhase.ready;

  Future<void> _upgrade() async {
    setState(() {
      _phase = Platform.isAndroid
          ? _UpdatePhase.downloading
          : _UpdatePhase.ready;
      _error = null;
      _progress = 0;
    });

    try {
      if (Platform.isIOS) {
        final downloadUrl = widget.update.downloadUrl?.trim();
        final appStoreUrl = downloadUrl == null || downloadUrl.isEmpty
            ? MDEnv.urlAppstore
            : downloadUrl;
        await UpdateLauncher.openAppStore(appStoreUrl);
      } else {
        final downloadUrl = widget.update.downloadUrl;
        if (downloadUrl == null) throw Exception('缺少 APK 下载地址');
        await UpdateLauncher.downloadAndInstall(
          downloadUrl,
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onInstalling: () {
            if (mounted) setState(() => _phase = _UpdatePhase.installing);
          },
        );
      }
      if (mounted) {
        setState(() {
          _phase = _UpdatePhase.ready;
          _progress = 0;
        });
      }
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _phase = _UpdatePhase.ready;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final update = widget.update;
    final updateButton = _actionButton(
      label: _phase == _UpdatePhase.downloading
          ? '正在下载'
          : _phase == _UpdatePhase.installing
          ? '安装中...'
          : '立即更新',
      onPressed: _isWorking ? null : _upgrade,
      primary: true,
    );
    return PopScope(
      canPop: !update.isCoerce && !_isWorking,
      child: PlatformAlertDialog(
        material: (context, platform) => MaterialAlertDialogData(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
          contentPadding: EdgeInsets.zero,
          buttonPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.center,
          constraints: const BoxConstraints(maxWidth: 360),
          clipBehavior: Clip.antiAlias,
        ),
        title: Text(
          update.title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: AppColors.title,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: .zero,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    update.content,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.content,
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  if (_phase == _UpdatePhase.downloading) ...[
                    const SizedBox(height: 22),
                    PlatformWidget(
                      material: (context, platform) => LinearProgressIndicator(
                        value: _progress == 0 ? null : _progress,
                        color: AppColors.theme,
                        backgroundColor: AppColors.theme.withValues(
                          alpha: 0.15,
                        ),
                      ),
                      cupertino: (context, platform) => _progress == 0
                          ? const PlatformCircularProgressIndicator()
                          : ClipRRect(
                              borderRadius: BorderRadius.circular(2),
                              child: SizedBox(
                                height: 4,
                                child: ColoredBox(
                                  color: AppColors.theme.withValues(
                                    alpha: 0.15,
                                  ),
                                  child: Align(
                                    alignment: Alignment.centerLeft,
                                    child: FractionallySizedBox(
                                      widthFactor: _progress.clamp(0.0, 1.0),
                                      child: ColoredBox(color: AppColors.theme),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _progress == 0
                          ? '正在准备下载…'
                          : '正在下载 ${(100 * _progress).toStringAsFixed(0)}%',
                      style: TextStyle(color: AppColors.content, fontSize: 12),
                    ),
                  ],
                  if (_phase == _UpdatePhase.installing) ...[
                    const SizedBox(height: 22),
                    PlatformCircularProgressIndicator(
                      material: (context, platform) =>
                          MaterialProgressIndicatorData(color: AppColors.theme),
                      cupertino: (context, platform) =>
                          CupertinoProgressIndicatorData(
                            color: AppColors.theme,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '正在安装，请在系统界面完成操作',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.content, fontSize: 12),
                    ),
                  ],
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: AppColors.red, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            PlatformWidget(
              material: (context, platform) => Padding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 10),
                child: _buildActionsRow(update, updateButton, context),
              ),
              cupertino: (context, platform) => Padding(
                padding: const EdgeInsets.fromLTRB(2, 24, 2, 10),
                child: _buildActionsRow(update, updateButton, context),
              ),
            ),
          ],
        ),
        actions: const [],
      ),
    );
  }

  Widget _buildActionsRow(
    AppUpdateInfo update,
    Widget updateButton,
    BuildContext context,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (!update.isCoerce && !_isWorking) ...[
          Expanded(
            child: _actionButton(
              label: '取消',
              onPressed: () => AppRouter.pop(context),
              primary: false,
            ),
          ),
          const SizedBox(width: 16),
        ],
        if (update.isCoerce)
          SizedBox(width: 120, child: updateButton)
        else
          Expanded(child: updateButton),
      ],
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    final background = primary ? AppColors.theme : AppColors.background;
    return SizedBox(
      height: 36,
      child: PlatformElevatedButton(
        onPressed: onPressed,
        color: background,
        material: (context, platform) => MaterialElevatedButtonData(
          style: ElevatedButton.styleFrom(
            backgroundColor: background,
            foregroundColor: primary ? AppColors.white : AppColors.black,
            disabledBackgroundColor: background.withValues(alpha: 0.65),
            disabledForegroundColor: primary
                ? AppColors.white
                : AppColors.black,
            elevation: 0,
            shape: const StadiumBorder(),
          ),
        ),
        cupertino: (context, platform) => CupertinoElevatedButtonData(
          color: background,
          borderRadius: BorderRadius.circular(20),
          minimumSize: const Size(double.infinity, 40),
          sizeStyle: CupertinoButtonSize.small,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: primary ? AppColors.white : AppColors.black,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
