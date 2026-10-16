import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

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
    // 插件的初始化Completer可能在setDataSource方法回复之前收到错误事件。
    // 该时序下Future尚未被监听，局部Zone负责接住VideoError并通知失败态；
    // 不能只记日志或空catch，否则页面仍会停留在加载中。
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
      // 方法本身也可能直接失败而不派发exception事件，必须显式通知页面。
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
    // 由封装层独占释放；让插件释放阶段的异步任务沿用初始化的错误边界。
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
        translations: _chineseTranslations(),
        controlsConfiguration: BetterPlayerControlsConfiguration(
          enablePlaybackSpeed: true, // 是否显示播放速度
          enableSubtitles: false, // 是否显示字幕
          enableQualities: false, // 是否显示画质
          enableAudioTracks: false, // 是否显示音频轨道
          overflowMenuCustomItems: [],
        ),
      ),
    );
  }

  /// 播放器控件文案（溢出菜单"播放速度"等）统一中文。
  /// 插件按系统 locale 的 languageCode 精确匹配 translations.languageCode，
  /// 'zh-CN' 这类带地区后缀的代码永远匹配不上，未命中时回退内置翻译
  /// （英文系统会显示英文），因此同时提供 'zh' 与 'en' 两份中文文案。
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
