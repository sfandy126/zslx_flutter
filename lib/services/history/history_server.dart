import 'dart:async';

import 'package:isar_community/isar.dart';
import 'package:path_provider/path_provider.dart';

import '../../utils/utils.dart';
import 'play_history.dart';

export 'play_history.dart';

/// 视频播放记录本地存储（Isar）
///
/// - 仅登录且非游客用户会写入记录，读取时只返回当前用户的数据；
/// - 写入后通过 [changes] 广播最新记录，用于刷新课程目录播放进度。
class HistoryServer {
  HistoryServer._();

  /// 学习历史分页大小
  static const pageSize = 20;

  static Future<Isar?>? _opening;
  static final StreamController<PlayHistory> _changes =
      StreamController<PlayHistory>.broadcast();

  /// 记录写入（新增或更新）后广播
  static Stream<PlayHistory> get changes => _changes.stream;

  /// 应用启动时调用，提前打开数据库；失败时不影响启动，后续访问会重试
  ///
  /// [directory] 默认为应用文档目录，测试时可指定临时目录。
  static Future<void> init({String? directory}) async {
    _directory = directory;
    await _db();
  }

  static String? _directory;

  static Future<Isar?> _db() {
    return _opening ??= _open().then((isar) {
      if (isar == null) _opening = null;
      return isar;
    });
  }

  static Future<Isar?> _open() async {
    try {
      final opened = Isar.getInstance('play_history');
      if (opened != null) return opened;
      final directory =
          _directory ?? (await getApplicationDocumentsDirectory()).path;
      return await Isar.open(
        [PlayHistorySchema],
        directory: directory,
        name: 'play_history',
        inspector: false,
      );
    } catch (error) {
      Utils.log('HistoryServer open failed: $error');
      return null;
    }
  }

  static String _keyOf(PlayHistory record, String userId) {
    return PlayHistory.makeKey(
      userId: userId,
      cId: record.cId,
      cType: record.cType,
      sId: record.sId,
      sType: record.sType,
    );
  }

  /// 当前可写入/读取记录的用户 id；未登录或游客返回 null
  static String? get _userId {
    final user = MDUser.defualt;
    if (!user.islogined || user.guest) return null;
    return user.uid;
  }

  /// 新增或更新一条记录，返回写入后的记录；条件不满足或写入失败返回 null
  ///
  /// 已存在时更新名称、封面、地址、时长与进度，保留创建时间。
  static Future<PlayHistory?> insertOrUpdate(PlayHistory record) async {
    final userId = _userId;
    if (userId == null ||
        record.cId.isEmpty ||
        record.cType.isEmpty ||
        record.sId.isEmpty ||
        record.sType.isEmpty) {
      return null;
    }
    final isar = await _db();
    if (isar == null) return null;
    final key = _keyOf(record, userId);
    try {
      final saved = await isar.writeTxn(() async {
        final now = DateTime.now();
        final existing = await isar.playHistorys.getByKey(key);
        final target =
            existing ??
            (PlayHistory()
              ..key = key
              ..cId = record.cId
              ..cType = record.cType
              ..sId = record.sId
              ..sType = record.sType
              ..userId = userId
              ..createTime = now);
        target
          ..cName = record.cName
          ..cPhoto = record.cPhoto
          ..sCid = record.sCid
          ..sName = record.sName
          ..url = record.url
          ..total = record.total
          ..time = record.time
          ..source = record.source
          ..updateTime = now;
        await isar.playHistorys.put(target);
        return target;
      });
      _changes.add(saved);
      return saved;
    } catch (error) {
      Utils.log('HistoryServer insertOrUpdate failed: $error');
      return null;
    }
  }

  /// 查询某课程下指定来源的记录，按最近更新时间倒序
  static Future<List<PlayHistory>> fetchFor({
    required String cId,
    required String cType,
    required int source,
  }) async {
    final userId = _userId;
    if (userId == null || cId.isEmpty || cType.isEmpty) return const [];
    final isar = await _db();
    if (isar == null) return const [];
    return isar.playHistorys
        .filter()
        .userIdEqualTo(userId)
        .cIdEqualTo(cId)
        .cTypeEqualTo(cType)
        .sourceEqualTo(source)
        .sortByUpdateTimeDesc()
        .findAll();
  }

  /// 分页查询当前用户的全部记录，[page] 从 1 开始，按最近更新时间倒序
  ///
  /// 传入 [offset] 时以其为准（列表删除过数据后，按页码计算会漏数据）。
  /// 数据库不可用时抛出 [StateError]，由调用方展示失败态。
  static Future<List<PlayHistory>> fetchPage(
    int page, {
    int limit = pageSize,
    int? offset,
  }) async {
    final userId = _userId;
    if (userId == null) return const [];
    final isar = await _db();
    if (isar == null) throw StateError('播放记录数据库打开失败');
    return isar.playHistorys
        .where()
        .userIdEqualToAnyUpdateTime(userId)
        .sortByUpdateTimeDesc()
        .offset(offset ?? (page < 1 ? 0 : page - 1) * limit)
        .limit(limit)
        .findAll();
  }

  /// 删除当前用户下的一条记录，返回是否删除成功
  static Future<bool> delete(PlayHistory record) async {
    final userId = _userId;
    if (userId == null) return false;
    final isar = await _db();
    if (isar == null) return false;
    try {
      return await isar.writeTxn(
        () => isar.playHistorys.deleteByKey(_keyOf(record, userId)),
      );
    } catch (error) {
      Utils.log('HistoryServer delete failed: $error');
      return false;
    }
  }
}
