import 'dart:async';

import 'package:flutter/material.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/dialog.dart';

part 'home_alert.g.dart';

/// 首页弹窗
class HomeAlertManager with WidgetsBindingObserver {
  HomeAlertManager({required this.contextProvider});

  static const _adDateKey = 'MDAD_UNLOGIN';

  final BuildContext? Function() contextProvider;
  List<_HomeAlertTask> _tasks = [];
  bool _showingAlert = false;
  bool _disposed = false;
  int _requestId = 0;
  String _alertUuid = '';

  void start() {
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_disposed) unawaited(loadData());
    });
  }

  void dispose() {
    _disposed = true;
    _requestId++;
    _tasks.clear();
    WidgetsBinding.instance.removeObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_executeTasks());
    }
  }

  Future<void> loadData() async {
    final requestId = ++_requestId;
    final adFuture = _fetchAd();
    final expiresFuture = _fetchExpires();
    final ad = await adFuture;
    final expires = await expiresFuture;
    if (_disposed || requestId != _requestId) return;

    _tasks = <_HomeAlertTask>[
      if (ad != null) _HomeAlertTask(type: .ad, data: ad),
      ...expires.map((data) => _HomeAlertTask(type: .expire, data: data)),
    ]..sort((left, right) => left.type.index.compareTo(right.type.index));
    await _executeTasks();
  }

  Future<_HomeAlertData?> _fetchAd() async {
    final uuid = await MDUser.readForGuest() ?? '';
    _alertUuid = uuid;
    final result = await MDPost.sendApiSession(
      cmd: .popUp,
      params: {'uuid': uuid},
    );
    if (!result.isSuccess || result.data == null) return null;
    final ad = _HomeAlertData.fromJson(result.data!);
    return ad.type == '8' ? null : ad;
  }

  Future<List<_HomeAlertData>> _fetchExpires() async {
    final result = await MDPost.sendApiSession(
      cmd: .remind,
      params: const {'ver': 2},
    );
    if (!result.isSuccess) return const [];

    final source = result.data?['data'];
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map((item) => _HomeAlertData.fromJson(_stringKeyMap(item)))
        .where((item) => item.type == 'due_soon')
        .toList();
  }

  Future<void> _executeTasks() async {
    if (_showingAlert || _disposed) return;
    _showingAlert = true;
    try {
      while (!_disposed && _tasks.isNotEmpty) {
        final task = _tasks.removeAt(0);
        final didShowAdToday =
            task.type == _HomeAlertType.ad &&
            !MDUser.defualt.islogined &&
            await _didShowAdToday();
        if (_disposed) return;
        if (didShowAdToday) continue;

        if (task.type == _HomeAlertType.ad) {
          await _saveAdShownToday();
          if (_disposed) return;
          final context = contextProvider();
          if (context == null || !context.mounted) return;
          final action = await _showAdAlert(context, task.data);
          if (_disposed) return;
          if (action == _HomeAdAction.close || action == null) {
            _report(task, close: true);
          } else {
            _report(task, close: false);
            await _handleAdAction(task.data);
          }
        } else {
          final context = contextProvider();
          if (context == null || !context.mounted) return;
          await MDDialog.show(
            context,
            content: task.data.title.isEmpty ? '课程即将到期，请及时学习' : task.data.title,
            buttons: const ['我知道了'],
          );
          _report(task, close: false);
        }
      }
    } finally {
      _showingAlert = false;
    }
  }

  Future<bool> _didShowAdToday() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_adDateKey) == _todayString();
  }

  Future<void> _saveAdShownToday() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_adDateKey, _todayString());
  }

  String _todayString() {
    final now = DateTime.now();
    String twoDigits(int value) => value.toString().padLeft(2, '0');
    return '${now.year}-${twoDigits(now.month)}-${twoDigits(now.day)}';
  }

  void _report(_HomeAlertTask task, {required bool close}) {
    if (task.type == _HomeAlertType.ad) {
      unawaited(
        MDPost.sendApiSession(
          cmd: .popUpReport,
          params: {
            'type': task.data.type,
            'wz': close ? '2' : '1',
            'uuid': _alertUuid,
          },
        ),
      );
      return;
    }
    unawaited(
      MDPost.sendApiSession(
        cmd: .remindReport,
        params: {
          'type': task.data.type,
          'expiretime': task.data.expiretime,
          'course_id': task.data.courseId,
          'course_type': task.data.courseType,
        },
      ),
    );
  }

  Future<void> _handleAdAction(_HomeAlertData data) async {
    final context = contextProvider();
    if (context == null || !context.mounted) return;

    switch (data.type) {
      case '1':
        final courseId = data.courseId.isEmpty ? data.id : data.courseId;
        if (courseId.isNotEmpty && data.courseType.isNotEmpty) {
          AppRouter.pushNamed<void>(
            context,
            RouterNames.courseDetail,
            queryParameters: {'id': courseId, 'type': data.courseType},
          );
        }
        return;
      case '4':
        if (data.url.isNotEmpty) {
          AppRouter.pushNamed<void>(
            context,
            RouterNames.web,
            queryParameters: {'url': data.url},
          );
        }
        return;
      case '3':
      case '6':
      case '8':
        if (!MDUser.defualt.islogined) {
          await AppRouter.pushNamed<void>(context, RouterNames.login);
        }
        return;
      default:
        return;
    }
  }

  Future<_HomeAdAction?> _showAdAlert(
    BuildContext context,
    _HomeAlertData data,
  ) {
    return showGeneralDialog<_HomeAdAction>(
      context: context,
      barrierDismissible: false,
      barrierLabel: '首页广告',
      barrierColor: AppColors.black.withValues(alpha: 0.55),
      transitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (dialogContext, animation, secondaryAnimation) {
        return SafeArea(
          child: Center(
            child: Material(
              color: AppColors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        Navigator.of(dialogContext).pop(_HomeAdAction.open),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: SizedBox(
                        width: 280,
                        height: 336,
                        child: _AlertRemoteImage(url: data.imageUrl),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () =>
                        Navigator.of(dialogContext).pop(_HomeAdAction.close),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.white, width: 1.5),
                      ),
                      child: Icon(
                        Icons.close,
                        color: AppColors.white,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      transitionBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOut,
        );
        return FadeTransition(
          opacity: curved,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.94, end: 1).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}

class _AlertRemoteImage extends StatelessWidget {
  const _AlertRemoteImage({required this.url});

  final String url;

  @override
  Widget build(BuildContext context) {
    if (url.isEmpty) return _placeholder();
    return Image.network(
      url,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _placeholder(),
      errorBuilder: (context, error, stackTrace) => _placeholder(),
    );
  }

  Widget _placeholder() {
    return ColoredBox(
      color: AppColors.line,
      child: Center(
        child: Icon(Icons.image_outlined, color: AppColors.grayAAA, size: 28),
      ),
    );
  }
}

@JsonSerializable(createToJson: false)
class _HomeAlertData {
  const _HomeAlertData({
    this.id = '',
    this.type = '',
    this.imageUrl = '',
    this.title = '',
    this.expiretime = '',
    this.url = '',
    this.courseId = '',
    this.courseType = '',
  });

  @JsonKey(fromJson: _stringValue)
  final String id;

  @JsonKey(fromJson: _stringValue)
  final String type;

  @JsonKey(name: 'img_url', fromJson: _stringValue)
  final String imageUrl;

  @JsonKey(fromJson: _stringValue)
  final String title;

  @JsonKey(fromJson: _stringValue)
  final String expiretime;

  @JsonKey(fromJson: _stringValue)
  final String url;

  @JsonKey(name: 'course_id', fromJson: _stringValue)
  final String courseId;

  @JsonKey(name: 'course_type', fromJson: _stringValue)
  final String courseType;

  factory _HomeAlertData.fromJson(Map<String, dynamic> json) =>
      _$HomeAlertDataFromJson(json);
}

class _HomeAlertTask {
  const _HomeAlertTask({required this.type, required this.data});

  final _HomeAlertType type;
  final _HomeAlertData data;
}

enum _HomeAlertType { ad, expire }

enum _HomeAdAction { close, open }

Map<String, dynamic> _stringKeyMap(Map<dynamic, dynamic> value) {
  return value.map((key, item) => MapEntry(key.toString(), item));
}

String _stringValue(Object? value) => value?.toString() ?? '';
