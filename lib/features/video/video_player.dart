import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../config/app_orientation.dart';
import '../../gen/assets.gen.dart';
import '../../utils/app_colors.dart';

enum _MDVideoSourceType { network, file }

class MDVideoPlayer extends StatefulWidget {
  const MDVideoPlayer.network(
    this.source, {
    this.startAt,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio,
    this.placeholder,
    this.onEvent,
    super.key,
  }) : _sourceType = _MDVideoSourceType.network;

  const MDVideoPlayer.file(
    this.source, {
    this.startAt,
    this.autoPlay = false,
    this.looping = false,
    this.aspectRatio,
    this.placeholder,
    this.onEvent,
    super.key,
  }) : _sourceType = _MDVideoSourceType.file;

  final String source;
  final _MDVideoSourceType _sourceType;
  final Duration? startAt;
  final bool autoPlay;
  final bool looping;
  final double? aspectRatio;
  final Widget? placeholder;
  final ValueChanged<BetterPlayerEvent>? onEvent;

  @override
  State<MDVideoPlayer> createState() => _MDVideoPlayerState();
}

class _MDVideoPlayerState extends State<MDVideoPlayer> {
  late BetterPlayerController _controller;
  late Zone _playerZone;
  bool _failureReported = false;
  Key _playerKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    _initializeController();
  }

  @override
  void didUpdateWidget(covariant MDVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldRecreateController =
        oldWidget.source != widget.source ||
        oldWidget._sourceType != widget._sourceType ||
        oldWidget.startAt != widget.startAt ||
        oldWidget.autoPlay != widget.autoPlay ||
        oldWidget.looping != widget.looping ||
        oldWidget.aspectRatio != widget.aspectRatio ||
        oldWidget.placeholder != widget.placeholder;

    if (shouldRecreateController) {
      _playerKey = UniqueKey();
      _disposeController();
      _initializeController();
    }
  }

  void _initializeController() {
    _failureReported = false;
    final controller = _createController();
    _controller = controller;
    controller.addEventsListener(_handlePlayerEvent);
    runZonedGuarded(
      () {
        _playerZone = Zone.current;
        unawaited(_setupController(controller, _createDataSource()));
      },
      (error, stack) {
        if (error is PlatformException && error.code == 'VideoError') {
          _reportFailure(controller, error);
        } else {
          FlutterError.reportError(
            FlutterErrorDetails(
              exception: error,
              stack: stack,
              library: 'MDVideoPlayer',
            ),
          );
        }
      },
    );
  }

  Future<void> _setupController(
    BetterPlayerController controller,
    BetterPlayerDataSource dataSource,
  ) async {
    try {
      await controller.setupDataSource(dataSource);
    } catch (error) {
      _reportFailure(controller, error);
    }
  }

  void _reportFailure(BetterPlayerController controller, Object error) {
    if (!mounted || controller != _controller || _failureReported) return;
    _failureReported = true;
    scheduleMicrotask(() {
      if (!mounted || controller != _controller) return;
      widget.onEvent?.call(
        BetterPlayerEvent(
          BetterPlayerEventType.exception,
          parameters: {'exception': error.toString()},
        ),
      );
    });
  }

  void _handlePlayerEvent(BetterPlayerEvent event) {
    if (!mounted) return;
    if (event.betterPlayerEventType == BetterPlayerEventType.exception) {
      _reportFailure(_controller, event.parameters?['exception'] ?? '视频加载失败');
    } else if (!_failureReported) {
      widget.onEvent?.call(event);
    }
  }

  void _disposeController() {
    _controller.removeEventsListener(_handlePlayerEvent);
    _playerZone.run(() => _controller.dispose(forceDispose: true));
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  BetterPlayerDataSource _createDataSource() {
    return switch (widget._sourceType) {
      _MDVideoSourceType.network => BetterPlayerDataSource.network(
        widget.source,
      ),
      _MDVideoSourceType.file => BetterPlayerDataSource.file(widget.source),
    };
  }

  BetterPlayerController _createController() {
    return BetterPlayerController(
      BetterPlayerConfiguration(
        autoPlay: widget.autoPlay,
        startAt: widget.startAt,
        looping: widget.looping,
        aspectRatio: widget.aspectRatio,
        fit: BoxFit.contain,
        placeholder: widget.placeholder,
        autoDispose: false,
        useRootNavigator: true,
        // 全屏时横屏，退出全屏（含全屏中直接返回）后恢复为 App 全局方向
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: AppOrientation.orientations,
        translations: _chineseTranslations(),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enableOverflowMenu: true,
          enablePlaybackSpeed: false,
          enableSubtitles: false, // 是否显示字幕
          enableQualities: false, // 是否显示画质
          enableAudioTracks: false, // 是否显示音频轨道
          overflowMenuCustomItems: [
            BetterPlayerOverflowMenuItem(
              Icons.speed_outlined,
              '播放速度',
              _showSpeedSheet,
            ),
          ],
          controlBarColor: const Color(0xFF000000).withValues(alpha: 0.5),
        ),
      ),
    );
  }

  Future<void> _showSpeedSheet() async {
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) {
        final currentSpeed =
            _controller.videoPlayerController?.value.speed ?? 1.0;
        const speeds = [0.75, 1.0, 1.25, 1.5, 2.0];
        return SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Text(
                  '播放倍数',
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 18,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ),
              for (final speed in speeds)
                ListTile(
                  leading: currentSpeed == speed
                      ? Assets.images.public.select.svg(width: 20, height: 20)
                      : Assets.images.public.unselect.svg(
                          width: 20,
                          height: 20,
                        ),
                  title: Text(
                    '${speed}x',
                    style: TextStyle(
                      color: currentSpeed == speed
                          ? AppColors.theme
                          : AppColors.content,
                    ),
                  ),
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _controller.setSpeed(speed);
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  List<BetterPlayerTranslations> _chineseTranslations() {
    final chinese = BetterPlayerTranslations.chinese();
    final englishKeyed = BetterPlayerTranslations(
      languageCode: 'en',
      generalDefaultError: chinese.generalDefaultError,
      generalNone: chinese.generalNone,
      generalDefault: chinese.generalDefault,
      generalRetry: chinese.generalRetry,
      playlistLoadingNextVideo: chinese.playlistLoadingNextVideo,
      controlsLive: chinese.controlsLive,
      controlsNextVideoIn: chinese.controlsNextVideoIn,
      overflowMenuPlaybackSpeed: chinese.overflowMenuPlaybackSpeed,
      overflowMenuSubtitles: chinese.overflowMenuSubtitles,
      overflowMenuQuality: chinese.overflowMenuQuality,
      overflowMenuAudioTracks: chinese.overflowMenuAudioTracks,
      qualityAuto: chinese.qualityAuto,
    );
    return [chinese, englishKeyed];
  }

  @override
  Widget build(BuildContext context) {
    return BetterPlayer(key: _playerKey, controller: _controller);
  }
}
