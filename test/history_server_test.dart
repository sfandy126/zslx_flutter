import 'dart:convert';
import 'dart:ffi' show Abi;
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:isar_community/isar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:zslx_flutter/services/history/history_server.dart';
import 'package:zslx_flutter/users/md_user.dart';

PlayHistory _record(String sId, {int total = 100, int time = 10}) =>
    PlayHistory()
      ..cId = 'c1'
      ..cType = 'bs'
      ..cName = '课程'
      ..sId = sId
      ..sType = 'bs'
      ..sCid = 'c1'
      ..sName = '第 $sId 节'
      ..total = total
      ..time = time;

/// 从 package_config 中找到 isar_community_flutter_libs 自带的 macOS 动态库
Future<String?> _isarLibrary() async {
  if (!Platform.isMacOS) return null;
  final config = File('.dart_tool/package_config.json');
  if (!config.existsSync()) return null;
  final json = jsonDecode(await config.readAsString()) as Map<String, dynamic>;
  final packages = (json['packages'] as List).cast<Map<String, dynamic>>();
  final package = packages
      .where((item) => item['name'] == 'isar_community_flutter_libs')
      .firstOrNull;
  if (package == null) return null;
  final root = config.absolute.uri.resolve('${package['rootUri']}/');
  final file = File.fromUri(root.resolve('macos/libisar.dylib'));
  return file.existsSync() ? file.path : null;
}

void main() {
  late Directory dir;
  String? library;

  setUpAll(() async {
    library = await _isarLibrary();
    if (library == null) return;
    await Isar.initializeIsarCore(
      libraries: {
        Abi.macosArm64: library!,
        Abi.macosX64: library!,
      },
    );
    dir = await Directory.systemTemp.createTemp('play_history_test');
    SharedPreferences.setMockInitialValues({});
    await MDUser.defualt.login({'user_id': '1', 'is_yk': '0', 'token': 't'});
    await HistoryServer.init(directory: dir.path);
  });

  tearDownAll(() async {
    if (library == null) return;
    await Isar.getInstance('play_history')?.close(deleteFromDisk: true);
    await dir.delete(recursive: true);
  });

  test('insertOrUpdate 同一节只保留一条并保留创建时间', () async {
    if (library == null) return markTestSkipped('需要 macOS 上的 libisar');
    final first = await HistoryServer.insertOrUpdate(_record('s1'));
    expect(first, isNotNull);
    expect(first!.userId, '1');

    final changed = HistoryServer.changes.first;
    final second = await HistoryServer.insertOrUpdate(
      _record('s1', time: 60)..sName = '新名称',
    );
    expect((await changed).time, 60);
    expect(second!.id, first.id);
    expect(second.createTime, first.createTime);
    expect(second.sName, '新名称');
    expect(second.progress, 0.6);

    final list = await HistoryServer.fetchFor(
      cId: 'c1',
      cType: 'bs',
      source: PlayHistorySource.recording,
    );
    expect(list.where((item) => item.sId == 's1'), hasLength(1));
  });

  test('缺少必填字段时不写入', () async {
    if (library == null) return markTestSkipped('需要 macOS 上的 libisar');
    expect(await HistoryServer.insertOrUpdate(_record('')), isNull);
  });

  test('分页按更新时间倒序，删除后不再返回', () async {
    if (library == null) return markTestSkipped('需要 macOS 上的 libisar');
    for (var i = 0; i < 25; i++) {
      await HistoryServer.insertOrUpdate(_record('p$i'));
    }
    final page1 = await HistoryServer.fetchPage(1);
    expect(page1, hasLength(HistoryServer.pageSize));
    expect(page1.first.sId, 'p24');
    final page2 = await HistoryServer.fetchPage(2);
    expect(page2.map((e) => e.sId), isNot(contains('p24')));

    expect(await HistoryServer.delete(page1.first), isTrue);
    final again = await HistoryServer.fetchPage(1);
    expect(again.first.sId, 'p23');
  });

  test('直播回放记录与录播分开查询', () async {
    if (library == null) return markTestSkipped('需要 macOS 上的 libisar');
    await HistoryServer.insertOrUpdate(
      _record('live1', total: 0, time: 0)..source = PlayHistorySource.playback,
    );
    final recordings = await HistoryServer.fetchFor(
      cId: 'c1',
      cType: 'bs',
      source: PlayHistorySource.recording,
    );
    final playbacks = await HistoryServer.fetchFor(
      cId: 'c1',
      cType: 'bs',
      source: PlayHistorySource.playback,
    );
    expect(recordings.map((e) => e.sId), isNot(contains('live1')));
    expect(playbacks.map((e) => e.sId), ['live1']);
  });

  test('接近播完时续播位置归零', () {
    expect(_record('x', total: 100, time: 98).seekTime, 0);
    expect(_record('x', total: 100, time: 50).seekTime, 50);
  });
}
