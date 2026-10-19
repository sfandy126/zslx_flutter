import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zslx_flutter/features/video/video_page.dart';
import 'package:zslx_flutter/features/video/video_player.dart';

const _videoError =
    'Failed to load video: '
    'The requested URL was not found on this server.';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('原生错误事件到达后展示失败态且可以连续重试', (tester) async {
    final platform = _MockVideoPlatform(tester);
    platform.install();
    await tester.pumpWidget(_page());
    await tester.pump();
    await platform.fail(tester, platform.created);
    await tester.pumpAndSettle();

    expect(find.text('视频加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    await _flushNativeCleanup(tester);
    expect(platform.disposed, [1], reason: platform.calls.toString());
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('重新加载'));
    await tester.pump();
    await tester.pump();
    expect(platform.created, 2);
    await platform.fail(tester, platform.created);
    await tester.pumpAndSettle();
    expect(find.text('视频加载失败'), findsOneWidget);
    await _flushNativeCleanup(tester);
    expect(platform.disposed, [1, 2]);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('setDataSource直接失败也必须展示失败态', (tester) async {
    final platform = _MockVideoPlatform(tester, failMethod: true);
    platform.install();
    await tester.pumpWidget(_page());
    await tester.pumpAndSettle();
    expect(find.text('视频加载失败'), findsOneWidget);
    expect(find.text('重新加载'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  });

  testWidgets('错误事件早于setDataSource方法回复也能退出页面', (tester) async {
    final platform = _MockVideoPlatform(tester, delayReply: true);
    platform.install();
    await tester.pumpWidget(_page());
    await tester.pump();
    await platform.fail(tester, platform.created);
    await tester.pumpAndSettle();
    expect(find.text('视频加载失败'), findsOneWidget);
    platform.reply.complete();
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('初始化成功后视频仍可以自动播放', (tester) async {
    final platform = _MockVideoPlatform(tester);
    platform.install();
    await tester.pumpWidget(_page());
    await tester.pump();
    platform.initialize(platform.created);
    await tester.pump(const Duration(milliseconds: 100));
    expect(platform.played, contains(1));
    expect(find.text('视频加载失败'), findsNothing);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _flushNativeCleanup(tester);
    expect(platform.disposed, [1], reason: platform.calls.toString());
  });

  testWidgets('加载中退出后收到方法错误不更新已销毁页面', (tester) async {
    final platform = _MockVideoPlatform(
      tester,
      delayReply: true,
      failMethod: true,
    );
    platform.install();
    await tester.pumpWidget(_page());
    await tester.pump();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    platform.reply.complete();
    await tester.pumpAndSettle();
    await _flushNativeCleanup(tester);
    expect(platform.disposed, [1], reason: platform.calls.toString());
    expect(tester.takeException(), isNull);
  });

  testWidgets('切换地址后旧请求错误不污染新播放器', (tester) async {
    final platform = _MockVideoPlatform(
      tester,
      delayReply: true,
      failMethod: true,
    );
    platform.install();
    final errors = <Object>[];
    Widget player(String source) => MaterialApp(
      home: MDVideoPlayer.network(
        source,
        onEvent: (event) {
          if (event.parameters?['exception'] case final Object error) {
            errors.add(error);
          }
        },
      ),
    );
    await tester.pumpWidget(player('https://example.com/old.mp4'));
    await tester.pump();
    await tester.pumpWidget(player('https://example.com/new.mp4'));
    await tester.pump();
    expect(platform.created, 2);
    platform.reply.complete();
    await tester.pump(const Duration(milliseconds: 1));
    expect(errors, hasLength(1));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
    await _flushNativeCleanup(tester);
    expect(platform.disposed, [1, 2]);
  });

  testWidgets('非法地址不创建原生播放器', (tester) async {
    final platform = _MockVideoPlatform(tester);
    platform.install();
    await tester.pumpWidget(_page(url: 'not a video URL'));
    await tester.pumpAndSettle();
    expect(find.text('视频地址无效'), findsOneWidget);
    expect(platform.created, 0);
    expect(tester.takeException(), isNull);
  });
}

// EventChannel取消订阅的清理需要真实事件循环，pumpAndSettle不保证完成。
Future<void> _flushNativeCleanup(WidgetTester tester) async {
  await tester.runAsync(() => Future<void>(() {}));
  await tester.pump();
}

Widget _page({String url = 'https://example.com/missing.mp4'}) => MaterialApp(
  home: VideoPage(
    url: url,
    title: '测试视频',
    courseTitle: '',
    cover: '',
    courseId: '',
    courseType: '',
    sectionId: '',
  ),
);

/// 使用真实插件的MethodChannel/EventChannel协议，不替换播放器实现。
class _MockVideoPlatform {
  _MockVideoPlatform(
    this.tester, {
    this.failMethod = false,
    this.delayReply = false,
  });

  final WidgetTester tester;
  final bool failMethod;
  final bool delayReply;
  final reply = Completer<void>();
  int created = 0;
  final disposed = <int>[];
  final played = <int>[];
  final calls = <String>[];

  void install() {
    final messenger = tester.binding.defaultBinaryMessenger;
    const channel = MethodChannel('better_player_channel');
    messenger.setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'create':
          created += 1;
          final eventChannel = MethodChannel(
            'better_player_channel/videoEvents$created',
          );
          messenger.setMockMethodCallHandler(eventChannel, (eventCall) async {
            calls.add('event:${eventCall.method}');
            return null;
          });
          addTearDown(
            () => messenger.setMockMethodCallHandler(eventChannel, null),
          );
          return {'textureId': created};
        case 'setDataSource':
          if (delayReply) await reply.future;
          if (failMethod) {
            throw PlatformException(code: 'VideoError', message: _videoError);
          }
          return null;
        case 'dispose':
          disposed.add((call.arguments as Map)['textureId'] as int);
          return null;
        case 'play':
          played.add((call.arguments as Map)['textureId'] as int);
          return null;
        case 'position':
          return 0;
        default:
          return null;
      }
    });
    addTearDown(() => messenger.setMockMethodCallHandler(channel, null));
  }

  void initialize(int textureId) {
    tester.binding.channelBuffers.push(
      'better_player_channel/videoEvents$textureId',
      const StandardMethodCodec().encodeSuccessEnvelope({
        'event': 'initialized',
        'duration': 120000,
        'width': 1280.0,
        'height': 720.0,
      }),
      (_) {},
    );
  }

  Future<void> fail(WidgetTester tester, int textureId) async {
    tester.binding.channelBuffers.push(
      'better_player_channel/videoEvents$textureId',
      const StandardMethodCodec().encodeErrorEnvelope(
        code: 'VideoError',
        message: _videoError,
      ),
      (_) {},
    );
    await tester.pump();
  }
}
