import 'dart:io';

enum BuildChannel {
  xiaomi,
  huawei,
  oppo,
  vivo,
  meizu,
  tengxun,
  honor,
  companywebsite, // 公司渠道
  appStore,
  harmony,
  unknown;

  bool get isAndroid {
    switch (this) {
      case BuildChannel.xiaomi:
      case BuildChannel.huawei:
      case BuildChannel.oppo:
      case BuildChannel.vivo:
      case BuildChannel.meizu:
      case BuildChannel.tengxun:
      case BuildChannel.honor:
      case BuildChannel.companywebsite:
        return true;
      default:
        return false;
    }
  }

  bool get isIOS {
    switch (this) {
      case BuildChannel.appStore:
        return true;
      default:
        return false;
    }
  }

  bool get isHarmony {
    switch (this) {
      case BuildChannel.harmony:
        return true;
      default:
        return false;
    }
  }
}

class ChannelInfo {
  final BuildChannel channel;
  final String id;
  final String name;
  const ChannelInfo({
    required this.channel,
    required this.id, // 渠道标识（小写），用于 --dart-define 传值
    required this.name,
  });
}

class ChannelConfig {
  static const String _rawChannel = String.fromEnvironment(
    'CHANNEL',
    defaultValue: '',
  );

  static Future<void> init() async {
    await Future<void>.value();
  }

  static List<ChannelInfo> get allChannels => _all.values.toList();
  static const Map<BuildChannel, ChannelInfo> _all = {
    BuildChannel.xiaomi: ChannelInfo(
      channel: BuildChannel.xiaomi,
      id: 'xiaomi',
      name: '小米应用商店',
    ),
    BuildChannel.huawei: ChannelInfo(
      channel: BuildChannel.huawei,
      id: 'huawei',
      name: '华为应用商店',
    ),
    BuildChannel.oppo: ChannelInfo(
      channel: BuildChannel.oppo,
      id: 'oppo',
      name: 'OPPO应用商店',
    ),
    BuildChannel.vivo: ChannelInfo(
      channel: BuildChannel.vivo,
      id: 'vivo',
      name: 'vivo应用商店',
    ),
    BuildChannel.meizu: ChannelInfo(
      channel: BuildChannel.meizu,
      id: 'meizu',
      name: '魅族应用商店',
    ),
    BuildChannel.tengxun: ChannelInfo(
      channel: BuildChannel.tengxun,
      id: 'tengxun',
      name: '腾讯应用商店',
    ),
    BuildChannel.honor: ChannelInfo(
      channel: BuildChannel.honor,
      id: 'honor',
      name: '荣耀应用商店',
    ),
    BuildChannel.companywebsite: ChannelInfo(
      channel: BuildChannel.companywebsite,
      id: 'companywebsite',
      name: '公司官网',
    ),
    BuildChannel.appStore: ChannelInfo(
      channel: BuildChannel.appStore,
      id: 'appstore',
      name: 'App Store',
    ),
    BuildChannel.harmony: ChannelInfo(
      channel: BuildChannel.harmony,
      id: 'harmony',
      name: 'HarmonyOS应用商店',
    ),
    BuildChannel.unknown: ChannelInfo(
      channel: BuildChannel.unknown,
      id: 'unknown',
      name: '未知渠道',
    ),
  };

  /// 当前渠道（编译期确定）
  static BuildChannel get currentChannel {
    final configuredChannel = _rawChannel.trim().toLowerCase();
    final channelId = configuredChannel.isNotEmpty
        ? configuredChannel
        : _platformDefaultChannelId;
    return _all.entries
        .firstWhere(
          (entry) => entry.value.id == channelId,
          orElse: () => const MapEntry(
            BuildChannel.unknown,
            ChannelInfo(
              channel: BuildChannel.unknown,
              id: 'unknown',
              name: '未知渠道',
            ),
          ),
        )
        .key;
  }

  static String get _platformDefaultChannelId {
    if (Platform.isIOS) return 'appstore';
    if (Platform.isAndroid) return 'companywebsite';
    return 'unknown';
  }

  /// 当前渠道信息
  static ChannelInfo getChannelInfo() {
    return _all[currentChannel] ??
        const ChannelInfo(
          channel: BuildChannel.unknown,
          id: 'unknown',
          name: '未知渠道',
        );
  }
}
