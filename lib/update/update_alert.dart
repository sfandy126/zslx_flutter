import 'dart:io';

import 'package:flutter/material.dart';

import '../network/md_env.dart';
import '../utils/app_colors.dart';
import 'update_launcher.dart';
import 'update_server.dart';

class UpdateAlert {
  UpdateAlert._();

  static Future<void> show(
    BuildContext context, {
    required AppUpdateInfo update,
  }) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: !update.isCoerce,
      barrierLabel: '应用更新',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (context, animation, secondaryAnimation) =>
          _UpdateDialog(update: update),
      transitionBuilder: (context, animation, secondaryAnimation, child) =>
          FadeTransition(opacity: animation, child: child),
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
      child: SafeArea(
        child: Center(
          child: Material(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(12),
            clipBehavior: Clip.antiAlias,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 320),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      update.title,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
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
                      const CircularProgressIndicator(),
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
                        style: const TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ],
                    const SizedBox(height: 24),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (!update.isCoerce && !_isWorking) ...[
                          Expanded(
                            child: _actionButton(
                              label: '取消',
                              onPressed: () => Navigator.of(context).pop(),
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
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _actionButton({
    required String label,
    required VoidCallback? onPressed,
    required bool primary,
  }) {
    final background = primary ? AppColors.theme : const Color(0xFFF1F2F4);
    return SizedBox(
      height: 40,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          foregroundColor: primary ? AppColors.white : AppColors.title,
          disabledBackgroundColor: background.withValues(alpha: 0.65),
          elevation: 0,
          shape: const StadiumBorder(),
        ),
        child: Text(label, style: const TextStyle(fontSize: 14)),
      ),
    );
  }
}
