import 'dart:io';

import 'package:flutter/material.dart';
import 'package:zslx_flutter/adaptive/md_adaptive.dart';
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
    return showMDAdaptiveDialog<void>(
      context: context,
      barrierDismissible: !update.isCoerce,
      barrierLabel: '应用更新',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          minWidth: 290,
          maxWidth: 290,
          minHeight: 140,
          maxHeight: 320,
        ),
        child: MDAdaptiveAlertDialog(
          backgroundColor: AppColors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          titlePadding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          contentPadding: EdgeInsets.zero,
          buttonPadding: EdgeInsets.zero,
          actionsAlignment: MainAxisAlignment.center,
          constraints: const BoxConstraints(minWidth: 290, maxWidth: 290),
          clipBehavior: Clip.antiAlias,
          title: Text(
            update.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.title,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          content: SizedBox(
            width: 290,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 180),
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_error == null)
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
                            LinearProgressIndicator(
                              value: _progress == 0 ? null : _progress,
                              color: AppColors.theme,
                              backgroundColor: AppColors.theme.withValues(
                                alpha: 0.15,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _progress == 0
                                  ? '正在准备下载…'
                                  : '正在下载 ${(100 * _progress).toStringAsFixed(0)}%',
                              style: TextStyle(
                                color: AppColors.content,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (_phase == _UpdatePhase.installing) ...[
                            const SizedBox(height: 22),
                            CircularProgressIndicator.adaptive(
                              valueColor: AlwaysStoppedAnimation(
                                AppColors.theme,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '正在安装，请在系统界面完成操作',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.content,
                                fontSize: 12,
                              ),
                            ),
                          ],
                          if (_error != null) ...[
                            const SizedBox(height: 12),
                            Text(
                              _error!,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: AppColors.red,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 10),
                    child: _buildActionsRow(update, updateButton, context),
                  ),
                ],
              ),
            ),
          ),
          actions: const [],
        ),
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
      child: MDAdaptiveElevatedButton(
        borderRadius: BorderRadius.circular(24),
        size: MDAdaptiveButtonSize.small,
        onPressed: onPressed,
        color: background,
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
