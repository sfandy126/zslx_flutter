import 'package:flutter/foundation.dart';
import 'package:bjy_liveui_flutter/bjy_liveui_flutter.dart';
import 'package:bjy_playbackui_flutter/bjy_playbackui_flutter.dart';
import 'package:zslx_flutter/network/md_env.dart';

import '../network/md_cmd.dart';
import '../network/md_post.dart';
import '../utils/totast.dart';

class BjyServer {
  BjyServer._();

  static final BJYLiveUIFlutter _liveSdk = BJYLiveUIFlutter();
  static final BJYPlaybackUIFlutter _playbackSdk = BJYPlaybackUIFlutter();
  static final RoomListener _roomListener = _BjyRoomListener();
  static bool _initialized = false;

  static void initialize() {
    final domain = MDEnv.bjyAppId;
    if (_initialized) {
      return;
    }
    _liveSdk.setRoomListener(_roomListener);
    _liveSdk.initSDK(domain);
    _playbackSdk.initSDK(domain);
    _initialized = true;
  }

  static Future<bool> loadAndToLive({
    required Map<String, dynamic> params,
  }) async {
    _ensureInitialized();
    Totast.showLoading();
    late final MDResult result;
    try {
      result = await MDPost.sendApiSession(cmd: MDCmd.live, params: params);
    } finally {
      Totast.hideLoading();
    }
    if (!result.isSuccess) {
      Totast.showError(result.msg ?? '直播加载失败');
      return false;
    }

    final live = BjyLive.fromJson(_mapFrom(result.data?['live_data']));
    if (live.room.isEmpty) {
      Totast.showError('直播未开始～');
      return false;
    }

    _enterLive(live);
    return true;
  }

  static Future<bool> loadAndToPlayback({
    required Map<String, dynamic> params,
  }) async {
    _ensureInitialized();
    Totast.showLoading();
    late final MDResult result;
    try {
      result = await MDPost.sendApiSession(cmd: MDCmd.playback, params: params);
    } finally {
      Totast.hideLoading();
    }
    if (!result.isSuccess) {
      Totast.showError(result.msg ?? '回放加载失败');
      return false;
    }

    final playback = BjyPlayback.fromJson(_mapFrom(result.data?['hf_data']));
    if (playback.room.isEmpty) {
      Totast.showError('没有生成回放～');
      return false;
    }
    if (playback.token.isEmpty) {
      Totast.showError('token失效～');
      return false;
    }

    enterPlayback(playback);
    return true;
  }

  static void enterPlayback(BjyPlayback playback) {
    _ensureInitialized();
    if (playback.room.isEmpty || playback.token.isEmpty) {
      Totast.showError('回放信息无效');
      return;
    }

    _playbackSdk.startPlayback(playback.room, playback.token, {
      'userId': playback.number,
      'userName': playback.name,
      'supportBackgroundAudio': true,
    });
  }

  static void _enterLive(BjyLive live) {
    _liveSdk.startLiveBySignWithLayoutTemplateAndRoomIDAndSignAndUserInfo(
      live.type == 2
          ? BJYUILayoutTemplate.Professional
          : BJYUILayoutTemplate.Triple,
      live.room,
      live.sign,
      {
        'name': live.name,
        'number': live.number,
        'type': live.role,
        'avatar': live.avatar,
        'groupId': live.group,
      },
    );
  }

  static void _ensureInitialized() {
    if (!_initialized) {
      throw StateError('Call BjyServer.initialize() before entering a room.');
    }
  }
}

class _BjyRoomListener implements RoomListener {
  @override
  void onEnterRoomFail(int code, String errorDescription) {
    debugPrint('BJY live room entry failed ($code): $errorDescription');
  }

  @override
  void onEnterRoomSuccess() {}

  @override
  void onExitRoom(int code, String errorDescription) {}
}

class BjyLive {
  const BjyLive({
    this.sign = '',
    this.room = '',
    this.name = '',
    this.number = '',
    this.avatar = '',
    this.lamp,
    this.group = 0,
    this.type = 0,
    this.role = 0,
  });

  final String sign;
  final String room;
  final String name;
  final String number;
  final String avatar;
  final String? lamp;
  final int group;
  final int type;
  final int role;

  factory BjyLive.fromJson(Map<String, dynamic> json) {
    return BjyLive(
      sign: _stringFrom(json, const ['apiSign', 'sign']),
      group: _intFrom(json, const ['groupID', 'group']),
      room: _stringFrom(json, const ['roomID', 'room']),
      type: _intFrom(json, const ['bj_type', 'type']),
      role: _intFrom(json, const ['userRole', 'role']),
      name: _stringFrom(json, const ['userName', 'name']),
      number: _stringFrom(json, const ['userNumber', 'number']),
      avatar: _stringFrom(json, const ['userAvatar', 'avatar']),
      lamp: _nullableStringFrom(json, const ['customLampContent', 'lamp']),
    );
  }
}

class BjyPlayback {
  const BjyPlayback({
    this.token = '',
    this.room = '',
    this.name = '',
    this.number = '',
    this.avatar = '',
  });

  final String token;
  final String room;
  final String name;
  final String number;
  final String avatar;

  factory BjyPlayback.fromJson(Map<String, dynamic> json) {
    final room = _stringFrom(json, const ['hf_room_id', 'room']);
    return BjyPlayback(
      token: _stringFrom(json, const ['hf_token', 'token']),
      room: room.isNotEmpty ? room : _stringFrom(json, const ['room_id']),
      name: _stringFrom(json, const ['user_name', 'name']),
      number: _stringFrom(json, const ['user_number', 'number']),
      avatar: _stringFrom(json, const ['user_avatar', 'avatar']),
    );
  }
}

Map<String, dynamic> _mapFrom(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

Object? _firstValue(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    final value = json[key];
    if (value != null) return value;
  }
  return null;
}

String _stringFrom(Map<String, dynamic> json, List<String> keys) =>
    _firstValue(json, keys)?.toString() ?? '';

String? _nullableStringFrom(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  return value?.toString();
}

int _intFrom(Map<String, dynamic> json, List<String> keys) {
  final value = _firstValue(json, keys);
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
