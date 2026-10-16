import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../../config/app_orientation.dart';

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
        // 全屏时横屏，退出全屏（含全屏中直接返回）后恢复为 App 全局方向
        deviceOrientationsOnFullScreen: const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ],
        deviceOrientationsAfterFullScreen: AppOrientation.orientations,
        translations: _chineseTranslations(),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enablePlaybackSpeed: true, // 是否显示播放速度
          enableSubtitles: false, // 是否显示字幕
          enableQualities: false, // 是否显示画质
          enableAudioTracks: false, // 是否显示音频轨道
          overflowMenuCustomItems: [],
          controlBarColor: const Color(0xFF000000).withValues(alpha: 0.5),
        ),
      ),
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
