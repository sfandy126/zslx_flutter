import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart' show XFile;
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';

import 'package:zslx_flutter/main.dart';
import 'package:zslx_flutter/config/app_config.dart';
import 'package:zslx_flutter/features/courses/course_task_edit_page.dart';
import 'package:zslx_flutter/features/courses/course_task_list_page.dart';
import 'package:zslx_flutter/network/md_post.dart';
import 'package:zslx_flutter/network/oss.dart';
import 'package:zslx_flutter/users/md_user.dart';
import 'package:zslx_flutter/widgets/refresh_list_view.dart';

void main() {
  testWidgets(
    'starts on StartPage and navigates to TabbarPage after 2 seconds',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('业务标记无更多后停止后续分页请求', (tester) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        builder: EasyLoading.init(),
        home: Scaffold(
          body: RefreshListView<int>(
            onData: (page) async {
              requestedPages.add(page);
              if (page == 1) {
                return RefreshResult.success(
                  List.generate(30, (index) => index),
                );
              }
              return RefreshResult.success(const [], noMore: page > 1);
            },
            itemBuilder: (context, item, index) =>
                SizedBox(height: 60, child: Text('课程$item')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EasyRefresh && widget.footer is BuilderFooter,
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2]);
    expect(find.text('没有更多'), findsOneWidget);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(0);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2, 1]);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2, 1, 2]);
    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2, 1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('第一页为空时不显示没有更多，也不继续加载分页', (tester) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        builder: EasyLoading.init(),
        home: Scaffold(
          body: RefreshListView<int>(
            onData: (page) async {
              requestedPages.add(page);
              return RefreshResult.success(const []);
            },
            itemBuilder: (context, item, index) => Text('$item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首次加载回调可安全更新父组件状态', (tester) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        builder: EasyLoading.init(),
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RefreshListView<int>(
              onData: (page) async {
                requestedPages.add(page);
                setState(() {});
                return RefreshResult.success(const []);
              },
              itemBuilder: (context, item, index) => Text('$item'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);
    expect(tester.takeException(), isNull);
  });

  group('作业页面与单文件上传', () {
    late Directory directory;
    late HttpClientAdapter originalApi;
    late HttpClientAdapter originalOss;
    late FilePickerPlatform originalPicker;
    late _TaskAdapter api;
    late _TaskAdapter oss;
    late _TaskPicker picker;
    Map<String, dynamic> listData = {};
    bool publicSuccess = true;

    setUp(() async {
      SharedPreferences.setMockInitialValues({
        'MDUSER_UID': '100',
        'MDUSER_NICK': '测试用户',
      });
      await MDUser.defualt.init();
      PackageInfo.setMockInitialValues(
        appName: '测试',
        packageName: 'test.app',
        version: '1.0.0',
        buildNumber: '1',
        buildSignature: '',
      );
      await AppConfig.init();
      directory = await Directory.systemTemp.createTemp('task_test_');
      originalApi = MDPost.session.httpClientAdapter;
      originalOss = MDOss.uploadSession.httpClientAdapter;
      originalPicker = FilePickerPlatform.instance;
      listData = {};
      publicSuccess = true;
      api = _TaskAdapter((options) {
        if (options.path.endsWith('zs_oss')) {
          return _jsonResponse({
            'status': 1,
            'data': {
              'info': {
                'endpoint': 'oss-cn-test.aliyuncs.com',
                'bucket': 'test-bucket',
                'AccessKeyId': 'test-key',
                'AccessKeySecret': 'test-secret',
                'SecurityToken': 'test-token',
                'Expiration': DateTime.now()
                    .add(const Duration(hours: 1))
                    .toIso8601String(),
              },
            },
          });
        }
        if (options.path.endsWith('zs_zy_log')) {
          return _jsonResponse({'status': 1, 'data': listData});
        }
        if (options.path.endsWith('zs_zy_public')) {
          return _jsonResponse({
            'status': publicSuccess ? 1 : -1,
            'msg': '公开设置结果',
          });
        }
        return _jsonResponse({'status': -1, 'msg': '测试提交结果'});
      });
      oss = _TaskAdapter((options) => ResponseBody.fromString('', 200));
      picker = _TaskPicker();
      MDPost.session.httpClientAdapter = api;
      MDOss.uploadSession.httpClientAdapter = oss;
      FilePickerPlatform.instance = picker;
    });

    tearDown(() async {
      MDPost.session.httpClientAdapter = originalApi;
      MDOss.uploadSession.httpClientAdapter = originalOss;
      FilePickerPlatform.instance = originalPicker;
      await directory.delete(recursive: true);
      await EasyLoading.dismiss(animation: false);
    });

    Future<File> document(String name, [List<int> bytes = const [1, 2, 3]]) =>
        File('${directory.path}/$name').writeAsBytes(bytes);
    Future<void> edit(WidgetTester tester) => tester.pumpWidget(
      MaterialApp(
        builder: EasyLoading.init(),
        home: const CourseTaskEditPage(
          courseType: 'gk',
          sectionId: 's1',
          workId: 'w1',
          logId: 'l1',
          validate: '明天',
        ),
      ),
    );
    Future<void> uploadPicked(WidgetTester tester) async {
      await tester.runAsync(() async {
        await tester.tap(find.text('选择文件'));
        // 等待本地文件 I/O 与模拟上传结束，不依赖真实网络。
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
    }

    test('文件扩展名、空文件、不可读路径及大小校验在获取 STS 前完成', () async {
      final wrong = await MDOss.uploadFile((await document('a.txt')).path);
      expect(wrong.state, MDOssTaskState.failed);
      expect(wrong.error, contains('仅支持'));
      final empty = await MDOss.uploadFile((await document('a.pdf', [])).path);
      expect(empty.error, '文件内容为空');
      final missing = await MDOss.uploadFile('${directory.path}/missing.doc');
      expect(missing.state, MDOssTaskState.failed);
      final oversized = await MDOss.uploadFile(
        (await document('a.docx')).path,
        maxBytes: 2,
      );
      expect(oversized.state, MDOssTaskState.failed);
      expect(api.requests, isEmpty);
      expect(() => MDOss.uploadFile('a.pdf', maxBytes: 0), throwsArgumentError);
    });

    test('pdf/doc/docx 单文件直传保留扩展名与 MIME，进度最终到 100%', () async {
      for (final extension in MDOss.fileTypes.keys) {
        final updates = <MDOssTask>[];
        final file = await document('答案.${extension.toUpperCase()}');
        final task = await MDOss.uploadFile(file.path, progress: updates.add);
        expect(task.state, MDOssTaskState.success);
        expect(task.url, endsWith('.$extension'));
        expect(updates.first.progress, 0);
        expect(updates.last.progress, 1);
        expect(
          updates
              .where((e) => e.state != MDOssTaskState.success)
              .every((e) => e.progress < 1),
          isTrue,
        );
        expect(
          oss.requests.last.headers['content-type'],
          MDOss.fileTypes[extension],
        );
        expect(oss.requests.last.headers.containsKey('token'), isFalse);
      }
      expect(oss.requests.length, 3);
    });

    test('OSS 上传失败返回可重试任务且不提供提交地址', () async {
      oss.handle = (options) => ResponseBody.fromString('失败', 503);
      final task = await MDOss.uploadFile((await document('答案.pdf')).path);
      expect(task.state, MDOssTaskState.failed);
      expect(task.url, isNull);
      expect(task.progress, lessThan(1));
    });

    testWidgets('三种答案模式切换保留文字和公开设置', (tester) async {
      await edit(tester);
      expect(find.text('添加图片'), findsNWidgets(2));
      await tester.tap(find.text('输入文字'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), '已输入的作业');
      await tester.tap(find.byType(CupertinoSwitch));
      await tester.pump();
      await tester.tap(find.text('上传文件'));
      await tester.pump();
      expect(find.text('选择文件'), findsOneWidget);
      await tester.tap(find.text('输入文字'));
      await tester.pump();
      expect(
        tester.widget<TextField>(find.byType(TextField)).controller!.text,
        '已输入的作业',
      );
      expect(
        tester.widget<CupertinoSwitch>(find.byType(CupertinoSwitch)).value,
        isFalse,
      );
      await tester.tap(find.text('提交'));
      await tester.pump();
      expect(api.requests, isEmpty);
      expect(tester.takeException(), isNull);
    });

    testWidgets('单文件选择、上传失败重试、提交字段和删除后重新选择', (tester) async {
      picker.file = _PickedTaskFile(
        (await tester.runAsync(() => document('答案.pdf')))!.path,
      );
      oss.handle = (options) => ResponseBody.fromString('失败', 503);
      await edit(tester);
      await tester.tap(find.text('上传文件'));
      await tester.pump();
      await uploadPicked(tester);
      expect(picker.allowed, ['pdf', 'doc', 'docx']);
      expect(picker.type, FileType.custom);
      expect(find.text('选择文件'), findsNothing);
      expect(find.text('上传失败，点击重新上传'), findsOneWidget);
      await tester.tap(find.text('提交'));
      await tester.pump();
      expect(
        api.requests.where((e) => e.path.endsWith('zs_zy_submit')),
        isEmpty,
      );
      oss.handle = (options) => ResponseBody.fromString('', 200);
      unawaited(EasyLoading.dismiss(animation: false));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('上传失败，点击重新上传'));
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();
      expect(find.text('上传成功 100%'), findsOneWidget);
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      final params = api.requests.last.data as Map;
      expect(params['answer_type'], 3);
      expect(params['file_name'], '答案.pdf');
      expect(params['zy_content'], endsWith('.pdf'));
      expect(params['zy_log_id'], 'l1');
      expect(params.containsKey('photos'), isFalse);
      unawaited(EasyLoading.dismiss(animation: false));
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(CupertinoIcons.xmark_circle_fill));
      await tester.pump();
      expect(find.text('选择文件'), findsOneWidget);
      picker.file = _PickedTaskFile(
        (await tester.runAsync(() => document('新答案.docx')))!.path,
      );
      await uploadPicked(tester);
      expect(find.text('答案.pdf'), findsNothing);
      expect(find.text('新答案.docx'), findsOneWidget);
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      expect((api.requests.last.data as Map)['answer_type'], 4);
      expect(picker.calls, 2);
      expect(tester.takeException(), isNull);
    });

    testWidgets('文字至少100字，提交仅携带当前答案类型', (tester) async {
      await edit(tester);
      await tester.tap(find.text('输入文字'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField),
        '${List.filled(99, '字').join()} \n ',
      );
      await tester.tap(find.text('提交'));
      await tester.pump();
      expect(api.requests, isEmpty);
      unawaited(EasyLoading.dismiss(animation: false));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byType(TextField),
        List.filled(100, '字').join(),
      );
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      final params = api.requests.single.data as Map;
      expect(params['answer_type'], 1);
      expect(params['is_show'], 1);
      expect(params.containsKey('photos'), isFalse);
      expect(params.containsKey('file_name'), isFalse);
    });

    testWidgets('提交成功返回刷新标记，等待期间不会重复提交', (tester) async {
      api.handle = (options) => _jsonResponse({'status': 1, 'msg': '提交成功'});
      bool? returned;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  returned = await GoRouter.of(context).push<bool>('/edit');
                },
                child: const Text('打开提交'),
              ),
            ),
          ),
          GoRoute(
            path: '/edit',
            builder: (context, state) => const CourseTaskEditPage(
              courseType: 'gk',
              sectionId: 's1',
              workId: 'w1',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, builder: EasyLoading.init()),
      );
      await tester.tap(find.text('打开提交'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('输入文字'));
      await tester.pump();
      await tester.enterText(
        find.byType(TextField),
        List.filled(100, '字').join(),
      );
      await tester.tap(find.text('提交'));
      await tester.tap(find.text('提交'));
      await tester.pumpAndSettle();
      expect(api.requests.length, 1);
      await tester.pump(const Duration(milliseconds: 1500));
      await tester.pumpAndSettle();
      expect(returned, isTrue);
      expect(find.text('打开提交'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('iOS 平台可以切换到文字和文件编辑区', (tester) async {
      await edit(tester);
      await tester.tap(find.text('输入文字'));
      await tester.pump();
      await tester.enterText(find.byType(TextField), 'iOS 作业');
      await tester.tap(find.text('上传文件'));
      await tester.pump();
      expect(find.text('选择文件'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

    testWidgets('文件选择取消或不支持的类型不产生上传任务', (tester) async {
      await edit(tester);
      await tester.tap(find.text('上传文件'));
      await tester.pump();
      await uploadPicked(tester);
      expect(find.text('选择文件'), findsOneWidget);
      picker.file = _PickedTaskFile(
        (await tester.runAsync(() => document('错误.txt')))!.path,
      );
      await uploadPicked(tester);
      expect(find.text('选择文件'), findsOneWidget);
      expect(find.text('错误.txt'), findsNothing);
      expect(api.requests, isEmpty);
      expect(oss.requests, isEmpty);
    });

    testWidgets('列表兼容 Swift 字段别名，私密作业只展示状态和分数', (tester) async {
      listData = {
        'zy_log_id': 'l1',
        'is_expire': '1',
        'timu': {
          'section_name': '第一节',
          'title': '练习',
          'validate': '明天',
          'submit_count': 1,
        },
        'answer_log': {
          'is_submit': 1,
          'answer_type': 1,
          'zy_content': '我的答案',
          'zy_state': 4,
        },
        'zy_list': [
          {
            'nickname': '同学',
            'is_show': 2,
            'answer_type': 1,
            'zy_content': '秘密答案',
            'is_yue': 1,
            'score': '99',
            'yue_type': 1,
            'teacher_remark': '秘密评语',
            'zy_state': 1,
          },
        ],
      };
      tester.view.physicalSize = const Size(420, 1000);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: EasyLoading.init(),
          home: const CourseTaskListPage(
            courseType: 'gk',
            sectionId: 's1',
            workId: 'w1',
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('我的作业'), findsOneWidget);
      expect(find.text('我的答案'), findsOneWidget);
      expect(find.text('提交作业'), findsNothing);
      expect(find.text('作业不公开'), findsOneWidget);
      expect(find.text('99分'), findsOneWidget);
      expect(find.text('秘密答案'), findsNothing);
      expect(find.text('秘密评语'), findsNothing);
      final params = api.requests.single.data as Map;
      expect(params['page'], 1);
      expect(params['section_id'], 's1');
      expect(params['zy_id'], 'w1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('公开设置失败不修改状态，成功后系统返回携带刷新标记', (tester) async {
      listData = {
        'zy_log_id': 'l1',
        'answer_log': {
          'is_submit': 1,
          'is_show': 1,
          'answer_type': 1,
          'zy_content': '答案',
          'zy_state': 1,
        },
      };
      String? returned;
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (context, state) => Scaffold(
              body: TextButton(
                onPressed: () async {
                  returned =
                      '${await GoRouter.of(context).push<bool>('/task')}';
                },
                child: const Text('打开作业'),
              ),
            ),
          ),
          GoRoute(
            path: '/task',
            builder: (context, state) => const CourseTaskListPage(
              courseType: 'gk',
              sectionId: 's1',
              workId: 'w1',
            ),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(
        MaterialApp.router(routerConfig: router, builder: EasyLoading.init()),
      );
      await tester.tap(find.text('打开作业'));
      await tester.pumpAndSettle();
      publicSuccess = false;
      await tester.tap(find.text('不公开'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CupertinoSlidingSegmentedControl<int>>(
              find.byType(CupertinoSlidingSegmentedControl<int>),
            )
            .groupValue,
        1,
      );
      publicSuccess = true;
      await tester.tap(find.text('不公开'));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<CupertinoSlidingSegmentedControl<int>>(
              find.byType(CupertinoSlidingSegmentedControl<int>),
            )
            .groupValue,
        2,
      );
      expect((api.requests.last.data as Map)['zy_id'], 'l1');
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();
      expect(returned, 'true');
      expect(find.text('打开作业'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

ResponseBody _jsonResponse(Map<String, dynamic> json) =>
    ResponseBody.fromString(
      jsonEncode(json),
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class _TaskAdapter implements HttpClientAdapter {
  _TaskAdapter(this.handle);
  FutureOr<ResponseBody> Function(RequestOptions) handle;
  final List<RequestOptions> requests = [];
  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    if (requestStream != null) await requestStream.drain<void>();
    return handle(options);
  }

  @override
  void close({bool force = false}) {}
}

class _TaskPicker extends FilePickerPlatform {
  PlatformFile? file;
  List<String>? allowed;
  FileType? type;
  int calls = 0;
  @override
  Future<PlatformFile?> pickFile({
    String? dialogTitle,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Function(FilePickerStatus)? onFileLoading,
    int compressionQuality = 0,
    AndroidOptions androidOptions = const AndroidOptions(),
    DarwinOptions darwinOptions = const DarwinOptions(),
    WindowsOptions windowsOptions = const WindowsOptions(),
    LinuxOptions linuxOptions = const LinuxOptions(),
    WebOptions webOptions = const WebOptions(),
  }) async {
    calls++;
    allowed = allowedExtensions;
    this.type = type;
    return file;
  }
}

final class _PickedTaskFile extends PlatformFile {
  _PickedTaskFile(this.localPath);
  final String localPath;
  @override
  String get name => localPath.split('/').last;
  @override
  Uri get uri => File(localPath).uri;
  @override
  XFile get xFile => XFile(localPath);
  @override
  int? lengthSync() => File(localPath).lengthSync();
  @override
  Future<int?> length() => File(localPath).length();
  @override
  Future<Uint8List> readAsBytes() => File(localPath).readAsBytes();
  @override
  Stream<Uint8List> readAsByteStream() =>
      File(localPath).openRead().map(Uint8List.fromList);
}
