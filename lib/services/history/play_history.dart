import 'package:isar_community/isar.dart';

part 'play_history.g.dart';

/// 播放记录来源
abstract final class PlayHistorySource {
  /// 录播视频
  static const recording = 0;

  /// 直播回放
  static const playback = 1;
}

/// 视频播放记录
///
/// 同一用户下以 [cId] + [cType] + [sId] + [sType] 唯一确定一条记录。
@collection
class PlayHistory {
  Id id = Isar.autoIncrement;

  /// 唯一键，见 [makeKey]；Isar 组合索引最多 3 个属性，故拼接为单个字段
  @Index(unique: true)
  String key = '';

  /// 用户 id，由 [HistoryServer] 写入时自动填充
  @Index(composite: [CompositeIndex('updateTime')])
  String userId = '';

  /// 课程 id
  String cId = '';

  /// 课程类型
  String cType = '';

  /// 课程名称
  String cName = '';

  /// 课程封面
  String cPhoto = '';

  /// 节 id
  String sId = '';

  /// 节所属课程类型
  String sType = '';

  /// 节所属课程 id
  String sCid = '';

  /// 节名称
  String sName = '';

  /// 播放地址（直播回放为空）
  String url = '';

  /// 视频总时长（秒），直播回放为 0
  int total = 0;

  /// 已播放位置（秒），直播回放为 0
  int time = 0;

  /// 来源，见 [PlayHistorySource]
  int source = PlayHistorySource.recording;

  /// 创建时间
  DateTime createTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// 最近一次更新时间
  DateTime updateTime = DateTime.fromMillisecondsSinceEpoch(0);

  /// 播放进度 0~1，没有时长时为 0
  @ignore
  double get progress => total > 0 ? (time / total).clamp(0, 1).toDouble() : 0;

  /// 续播位置（秒）；已接近播完时从头开始
  @ignore
  int get seekTime => total > 0 && time >= total - 3 ? 0 : time;

  /// 由用户与课程、节信息生成唯一键
  static String makeKey({
    required String userId,
    required String cId,
    required String cType,
    required String sId,
    required String sType,
  }) => [userId, cType, cId, sType, sId].join('\u0001');

  /// 是否为同一条记录（与 [userId] 无关）
  bool isSameRecord(PlayHistory other) =>
      cId == other.cId &&
      cType == other.cType &&
      sId == other.sId &&
      sType == other.sType;
}
