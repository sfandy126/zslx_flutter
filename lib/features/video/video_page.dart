import 'dart:async';

import 'package:better_player_plus/better_player_plus.dart';
import 'package:flutter/material.dart';

import '../../services/history/history_server.dart';
import '../../utils/utils.dart';
import 'video_player.dart';

class VideoPage extends StatefulWidget {
  const VideoPage({
    required this.url,
    required this.title,
    required this.courseTitle,
    required this.cover,
    required this.courseId,
    required this.courseType,
    required this.sectionId,
    this.sectionType = '',
    this.sectionCourseId = '',
    this.seekTime = 0,
    super.key,
  });

  final String url;
  final String title;
  final String courseTitle;
  final String cover;
  final String courseId;
  final String courseType;
  final String sectionId;

  /// 节所属课程类型（real_type）
  final String sectionType;

  /// 节所属课程 id（real_id）
  final String sectionCourseId;

  /// 续播位置（秒）
  final int seekTime;

  @override
  State<VideoPage> createState() => _VideoPageState();
}

class _VideoPageState extends State<VideoPage> with WidgetsBindingObserver {
  Timer? _heart;
  DateTime? _lastReportAt;
  bool _isPlaying = false;
  double _durationSeconds = 0;

  /// 当前播放位置（秒），由 progress 事件更新
  late double _positionSeconds = widget.seekTime.toDouble();

  /// 播放器起播位置（秒），重新加载时从当前位置继续
  late int _startSeconds = widget.seekTime;

  /// 最近一次写入播放记录的 (total, time)，避免重复写入
  (int, int)? _lastSavedProgress;

  /// 播放器加载失败（如视频地址失效、网络异常）时展示错误态
  bool _playFailed = false;

  /// 重新加载时自增，用于强制重建播放器
  int _playerSeed = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    Utils.log('VideoPage play url = ${widget.url}');
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.detached) {
      _reportElapsedTime();
      _saveHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _stopHeart();
    _reportElapsedTime();
    _saveHistory();
    super.dispose();
  }

  void _onPlayerEvent(BetterPlayerEvent event) {
    switch (event.betterPlayerEventType) {
      case BetterPlayerEventType.play:
        _startHeart();
      case BetterPlayerEventType.pause:
      case BetterPlayerEventType.finished:
        if (event.betterPlayerEventType == BetterPlayerEventType.finished &&
            _durationSeconds > 0) {
          _positionSeconds = _durationSeconds;
        }
        _stopHeart();
        _reportElapsedTime();
        _saveHistory();
      case BetterPlayerEventType.progress:
        final duration = _secondsFrom(event.parameters?['duration']);
        if (duration != null) _durationSeconds = duration;
        final position = _secondsFrom(event.parameters?['progress']);
        if (position != null) _positionSeconds = position;
      case BetterPlayerEventType.exception:
        _stopHeart();
        _reportElapsedTime();
        Utils.log(
          'VideoPage play failed: url=${widget.url} ${event.parameters}',
        );
        if (mounted && !_playFailed) {
          setState(() => _playFailed = true);
        }
      default:
        break;
    }
  }

  void _startHeart() {
    if (_isPlaying) return;
    _isPlaying = true;
    _lastReportAt = DateTime.now();
    _heart = Timer.periodic(
      const Duration(seconds: 30),
      (_) => _reportElapsedTime(),
    );
  }

  void _stopHeart() {
    _isPlaying = false;
    _heart?.cancel();
    _heart = null;
  }

  void _reportElapsedTime() {
    final lastReportAt = _lastReportAt;
    if (lastReportAt == null) return;
    final seconds = DateTime.now().difference(lastReportAt).inSeconds;
    if (seconds <= 0) return;
    _lastReportAt = _isPlaying ? DateTime.now() : null;
    unawaited(_sendDurationReport(seconds));
  }

  Future<void> _sendDurationReport(int hearTime) async {
    if (_durationSeconds <= 0 ||
        !MDUser.defualt.islogined ||
        MDUser.defualt.guest ||
        widget.courseId.isEmpty ||
        widget.courseType.isEmpty ||
        widget.sectionId.isEmpty) {
      return;
    }
    try {
      final result = await MDPost.sendApiSession(
        cmd: .videoDurationReport,
        params: {
          'course_type': widget.courseType,
          'course_id': widget.courseId,
          'section_id': widget.sectionId,
          'hear_time': hearTime,
          'duration': _durationSeconds,
        },
      );
      if (!result.isSuccess) {
        Utils.log('VideoPage duration report failed: ${result.msg}');
      }
    } catch (error) {
      Utils.log('VideoPage duration report error: $error');
    }
  }

  void _retryPlay() {
    _stopHeart();
    _reportElapsedTime();
    setState(() {
      _playFailed = false;
      if (_positionSeconds > 0) _startSeconds = _positionSeconds.floor();
      _playerSeed += 1;
    });
  }

  static double? _secondsFrom(Object? value) {
    if (value is Duration) return value.inMilliseconds / 1000;
    if (value is num) return value.toDouble();
    return null;
  }

  /// 保存录播播放进度：暂停/播完、离开页面、App 退到后台时调用
  void _saveHistory() {
    // 播放器未就绪（未拿到时长）时不记录
    if (_durationSeconds <= 0) return;
    final total = _durationSeconds.round();
    final time = _positionSeconds.clamp(0, _durationSeconds).round();
    if (_lastSavedProgress == (total, time)) return;
    _lastSavedProgress = (total, time);
    final record = PlayHistory()
      ..cId = widget.courseId
      ..cType = widget.courseType
      ..cName = widget.courseTitle
      ..cPhoto = widget.cover
      ..sId = widget.sectionId
      ..sType = widget.sectionType
      ..sCid = widget.sectionCourseId
      ..sName = widget.title
      ..url = widget.url
      ..total = total
      ..time = time
      ..source = PlayHistorySource.recording;
    unawaited(HistoryServer.insertOrUpdate(record));
  }

  Widget _buildPlayer() {
    final source = widget.url.trim();
    final uri = Uri.tryParse(source);
    final isValidUrl =
        uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
    if (!isValidUrl) {
      return Center(
        child: Text('视频地址无效', style: TextStyle(color: AppColors.white)),
      );
    }
    if (_playFailed) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '视频加载失败',
              style: TextStyle(color: AppColors.white, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              '请检查网络后重试',
              style: TextStyle(color: AppColors.grayAAA, fontSize: 12),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: _retryPlay,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.white),
                ),
                child: Text(
                  '重新加载',
                  style: TextStyle(color: AppColors.white, fontSize: 12),
                ),
              ),
            ),
          ],
        ),
      );
    }
    return MDVideoPlayer.network(
      source,
      key: ValueKey(_playerSeed),
      startAt: _startSeconds > 0 ? Duration(seconds: _startSeconds) : null,
      autoPlay: true,
      looping: false,
      aspectRatio: 16 / 9,
      placeholder: MDNetImage(imageUrl: widget.cover),
      onEvent: _onPlayerEvent,
    );
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title.isEmpty ? '视频播放' : widget.courseTitle;
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(title: title, centerTitle: true),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    AspectRatio(
                      aspectRatio: 16 / 9,
                      child: ColoredBox(
                        color: AppColors.black,
                        child: _buildPlayer(),
                      ),
                    ),
                    Container(
                      color: AppColors.white,
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              color: AppColors.content,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
