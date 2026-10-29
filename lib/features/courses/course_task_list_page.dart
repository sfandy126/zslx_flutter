import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/image_grid.dart';
import '../../widgets/refresh_list_view.dart';
import 'course_task_edit_page.dart';

/// 作业列表页面
class CourseTaskListPage extends StatefulWidget {
  const CourseTaskListPage({
    required this.courseType,
    required this.sectionId,
    required this.workId,
    super.key,
  });

  final String courseType;
  final String sectionId;
  final String workId;

  @override
  State<CourseTaskListPage> createState() => _CourseTaskListPageState();
}

class _CourseTaskListPageState extends State<CourseTaskListPage> {
  final _listKey = GlobalKey<RefreshListViewState<_TaskSection>>();
  bool _changed = false;
  bool _changingPublic = false;
  bool _openingEditor = false;

  Future<RefreshResult<_TaskSection>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .zyLog,
        params: {
          'page': page,
          'type': widget.courseType,
          'section_id': widget.sectionId,
          'zy_id': widget.workId,
        },
      );
      if (!result.isSuccess) {
        if (result.state == .outed || !MDUser.defualt.islogined) {
          return RefreshResult.notLoggedIn(result.msg);
        }
        return RefreshResult.failed(result.msg ?? '作业加载失败');
      }
      final data = _TaskResult(_map(result.data));
      final sections = <_TaskSection>[];
      if (page == 1) {
        if (data.question != null) sections.add(_TaskSection(data: data));
        final mine = data.mine;
        if (mine != null && mine.number('is_submit') == 1) {
          sections.add(_TaskSection(data: data, log: mine, mine: true));
        }
      }
      final logs = _maps(result.data?['zy_list']);
      for (var i = 0; i < logs.length; i++) {
        sections.add(
          _TaskSection(
            data: data,
            log: _TaskLog(logs[i]),
            firstSquare: page == 1 && i == 0,
          ),
        );
      }
      return RefreshResult.success(sections, noMore: logs.isEmpty);
    } catch (error) {
      Utils.log('加载作业列表失败：$error');
      return RefreshResult.failed('作业加载失败，请下拉刷新重试');
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) _listKey.currentState?.refresh();
  }

  Future<void> _openEditor(_TaskResult data) async {
    if (_openingEditor || data.question == null) return;
    _openingEditor = true;
    try {
      if (!MDUser.defualt.islogined) {
        await _openLogin();
        // 登录后重新获取题目与提交权限，避免使用旧数据。
        return;
      }
      final question = data.question!;
      final changed = await AppRouter.pushNamed<bool>(
        context,
        RouterNames.courseTaskEdit,
        queryParameters: {
          'courseType': widget.courseType,
          'sectionId': widget.sectionId,
          'workId': widget.workId,
          'logId': data.logId,
          'validate': question.text('validate'),
          'bjTime': question.text('bj_time'),
          'fileName': question.text('file_name'),
          'fileUrl': question.text('zy_content'),
        },
      );
      if (!mounted || changed != true) return;
      _changed = true;
      _listKey.currentState?.refresh();
    } finally {
      _openingEditor = false;
    }
  }

  Future<void> _setPublic(_TaskSection section, int value) async {
    final log = section.log!;
    if (_changingPublic || value == log.number('is_show')) return;
    final id = section.data.logId.isNotEmpty ? section.data.logId : log.logId;
    if (id.isEmpty) {
      MDTotast.error('作业记录无效，请刷新后重试');
      return;
    }
    setState(() => _changingPublic = true);
    MDTotast.showLoading();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .zyPublic,
        params: {'is_show': value, 'zy_id': id},
      );
      MDTotast.hideLoading();
      if (!mounted) return;
      if (result.isSuccess) {
        setState(() {
          log.json['is_show'] = value;
          _changed = true;
        });
        // 同一条记录可能也在广场中，成功后同步它的公开状态。
        for (final item in _listKey.currentState?.items ?? <_TaskSection>[]) {
          if (item.log?.logId == log.logId && log.logId.isNotEmpty) {
            item.log!.json['is_show'] = value;
          }
        }
        if ((result.msg ?? '').isNotEmpty) MDTotast.message(result.msg!);
      } else {
        MDTotast.error(result.msg ?? '公开设置失败，请重试');
      }
    } catch (error) {
      MDTotast.hideLoading();
      Utils.log('作业公开设置失败：$error');
      if (mounted) MDTotast.error('公开设置失败，请检查网络');
    } finally {
      if (mounted) setState(() => _changingPublic = false);
    }
  }

  void _back() => AppRouter.pop(context, _changed);

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) _back();
    },
    child: PlatformScaffold(
      body: ColoredBox(
        color: AppColors.white,
        child: DefaultTextStyle(
          style: TextStyle(
            color: AppColors.title,
            fontSize: 13,
            decoration: TextDecoration.none,
          ),
          child: SafeArea(
            child: Column(
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(title: '作业', onBackPressed: _back),
                ),
                Expanded(
                  child: RefreshListView<_TaskSection>(
                    key: _listKey,
                    onData: _loadPage,
                    onLogin: _openLogin,
                    emptyText: '暂无作业',
                    failedText: '作业加载失败',
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, section, index) =>
                        section.log == null
                        ? _question(section.data)
                        : _submission(section),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );

  Widget _question(_TaskResult data) {
    final question = data.question!;
    final showSubmit =
        data.number('is_expire') == 1 && data.mine?.number('is_submit') != 1;
    final disabled = question.number('is_bu_end') == 1;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            '节名称：${question.text('section_name')}',
            style: TextStyle(color: AppColors.content, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            '作业名称：${question.text('title')}',
            style: TextStyle(color: AppColors.content, fontSize: 12),
          ),
          const SizedBox(height: 10),
          Text(
            '作业截止：${question.text('validate')}',
            style: TextStyle(color: AppColors.theme, fontSize: 12),
          ),
          if (question.text('bj_time').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '补交截止：${question.text('bj_time')}',
              style: TextStyle(color: AppColors.theme, fontSize: 12),
            ),
          ],
          const SizedBox(height: 10),
          CourseTaskFileView(
            name: question.text('file_name'),
            url: question.text('zy_content'),
          ),
          if (showSubmit) ...[
            const SizedBox(height: 16),
            Center(
              child: GestureDetector(
                onTap: disabled ? null : () => _openEditor(data),
                child: Container(
                  // 宽度随文案自适应，内边距左右 20、上下 6
                  padding: const EdgeInsets.symmetric(
                    horizontal: 30,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: disabled ? AppColors.content : AppColors.theme,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Text(
                    disabled
                        ? '补交已截止'
                        : question.number('expired') == 1
                        ? '补交作业'
                        : '提交作业',
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _header(String title, {bool centered = false}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    color: AppColors.background,
    child: Text(
      title,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
    ),
  );

  Widget _submission(_TaskSection section) {
    final log = section.log!;
    final private = log.number('is_show') == 2 && !section.mine;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (section.mine) _header('我的作业', centered: true),
        if (section.firstSquare)
          _header(
            '已提交: ${section.data.question?.number('submit_count') ?? 0}人',
          ),
        Padding(padding: const EdgeInsets.all(16), child: _info(section)),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (private)
                Container(
                  height: 104,
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Assets.images.course.priLock.svg(width: 28, height: 28),
                      Text(
                        '作业不公开',
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                )
              else ...[
                if (log.number('answer_type') == 1)
                  _expandText(
                    log.text('zy_content'),
                    log.expanded,
                    () => setState(() => log.expanded = !log.expanded),
                  ),
                if (log.number('answer_type') == 2)
                  MDImageGrid(urls: log.photos),
                if (const [3, 4].contains(log.number('answer_type')))
                  CourseTaskFileView(
                    name: log.text('file_name'),
                    url: log.text('zy_content'),
                  ),
                if (section.mine && !const [1, 2].contains(log.state)) ...[
                  const SizedBox(height: 16),
                  _TaskSteps(log: log),
                ],
              ],
              if (log.number('is_yue') == 1) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        private ? '' : '老师评语:',
                        style: TextStyle(
                          color: AppColors.content,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    if (log.text('score').isNotEmpty) ...[
                      const Text('得分：'),
                      Text(
                        '${log.text('score')}分',
                        style: TextStyle(
                          color: AppColors.red,
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ],
                ),
                if (!private) ...[
                  const SizedBox(height: 10),
                  _teacherReview(log),
                ],
              ],
            ],
          ),
        ),
        if (!section.mine) Container(height: 10, color: AppColors.background),
      ],
    );
  }

  Widget _info(_TaskSection section) {
    final log = section.log!;
    final nick = log.text('nickname');
    final avatar = log.text('avatar');
    return Row(
      children: [
        MDNetImage(
          imageUrl: section.mine && avatar.isEmpty
              ? (MDUser.defualt.avatar ?? '')
              : avatar,
          width: 36,
          height: 36,
          isAvatar: true,
          borderRadius: BorderRadius.circular(18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Flexible(
                    child: Text(
                      section.mine && nick.isEmpty
                          ? (MDUser.defualt.nick ?? '')
                          : nick,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                  ),
                  // 我的作业把批阅状态紧跟昵称展示。
                  if (section.mine) ...[
                    const SizedBox(width: 6),
                    Text(
                      log.stateName,
                      style: TextStyle(color: log.stateColor, fontSize: 12),
                    ),
                  ],
                ],
              ),
              if (log.submitTime.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  log.submitTime,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.content, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
        if (!section.mine) ...[
          const SizedBox(width: 8),
          Text(
            log.stateName,
            style: TextStyle(color: log.stateColor, fontSize: 12),
          ),
        ],
        if (section.mine) ...[
          const SizedBox(width: 8),
          AbsorbPointer(
            absorbing: _changingPublic,
            child: CupertinoSlidingSegmentedControl<int>(
              groupValue: log.number('is_show') == 2 ? 2 : 1,
              backgroundColor: AppColors.background,
              thumbColor: AppColors.white,
              padding: const EdgeInsets.all(2),
              children: {
                1: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Text(
                    '公开',
                    style: TextStyle(color: AppColors.title, fontSize: 12),
                  ),
                ),
                2: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 2.5),
                  child: Text(
                    '隐藏',
                    style: TextStyle(color: AppColors.title, fontSize: 12),
                  ),
                ),
              },
              onValueChanged: (value) {
                if (value != null) _setPublic(section, value);
              },
            ),
          ),
        ],
      ],
    );
  }

  Widget _expandText(String text, bool expanded, VoidCallback toggle) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final style = TextStyle(
            color: AppColors.title,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 1.5,
          );
          final painter = TextPainter(
            text: TextSpan(text: text, style: style),
            textDirection: Directionality.of(context),
            textScaler: MediaQuery.textScalerOf(context),
            maxLines: 4,
          )..layout(maxWidth: constraints.maxWidth);
          final overflow = painter.didExceedMaxLines;
          painter.dispose();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                text,
                style: style,
                maxLines: expanded ? null : 4,
                overflow: expanded
                    ? TextOverflow.visible
                    : TextOverflow.ellipsis,
              ),
              if (overflow)
                Align(
                  alignment: Alignment.centerRight,
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: toggle,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 4),
                      child: Text(
                        expanded ? '收起' : '展开',
                        style: TextStyle(color: AppColors.theme),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      );

  Widget _teacherReview(_TaskLog log) {
    switch (log.number('yue_type')) {
      case 1:
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: _expandText(
            log.text('teacher_remark'),
            log.reviewExpanded,
            () => setState(() => log.reviewExpanded = !log.reviewExpanded),
          ),
        );
      case 2:
      case 6:
        final video = log.number('yue_type') == 6;
        final videos = _strings(log.json['teacher_video']);
        return CourseTaskFileView(
          name: log.text('teacher_file_name'),
          url: video
              ? (videos.isEmpty ? '' : videos.first)
              : log.text('teacher_file'),
          isVideo: video,
        );
      case 4:
        final audios = _strings(log.json['teacher_audio']);
        return Container(
          decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            children: [
              for (var i = 0; i < audios.length; i++)
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => AppRouter.pushNamed<void>(
                    context,
                    RouterNames.web,
                    queryParameters: {
                      'url': audios[i],
                      'title': '老师语音点评 ${i + 1}',
                    },
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Assets.images.course.playMain.svg(
                          width: 24,
                          height: 24,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '老师语音点评 ${i + 1}',
                          style: TextStyle(color: AppColors.theme),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}

Map<String, dynamic> _map(Object? value) => value is Map
    ? value.map((key, value) => MapEntry(key.toString(), value))
    : {};
List<Map<String, dynamic>> _maps(Object? value) =>
    value is List ? value.whereType<Map>().map(_map).toList() : [];
List<String> _strings(Object? value) => value is List
    ? value
          .map((e) => e?.toString().trim() ?? '')
          .where((e) => e.isNotEmpty)
          .toList()
    : [];

class _TaskData {
  _TaskData(this.json);
  final Map<String, dynamic> json;
  String text(String key, [String? alias]) =>
      (json[key] ?? json[alias])?.toString() ?? '';
  int number(String key, [String? alias]) =>
      int.tryParse(text(key, alias)) ?? 0;
}

class _TaskResult extends _TaskData {
  _TaskResult(super.json) {
    if (json['timu'] is Map) question = _TaskData(_map(json['timu']));
    final source = json['answer_log'] ?? json['mine'];
    if (source is Map) mine = _TaskLog(_map(source));
  }
  _TaskData? question;
  _TaskLog? mine;
  String get logId => text('zy_log_id', 'log_id');
}

class _TaskLog extends _TaskData {
  _TaskLog(super.json);
  bool expanded = false;
  bool reviewExpanded = false;
  String get logId => text('zy_log_id', 'log_id');
  int get state => int.tryParse(text('zy_state', 'state')) ?? -1;
  String get submitTime =>
      text('add_time').isNotEmpty ? text('add_time') : text('submit_time');
  String get stateName => switch (state) {
    0 => '待批阅',
    1 => '已批阅',
    2 => '已驳回',
    3 => '补交待审核',
    4 => '批阅中',
    _ => '',
  };
  Color get stateColor => switch (state) {
    0 => AppColors.red,
    1 => AppColors.green,
    _ => AppColors.content,
  };
  List<String> get photos {
    final originals = _strings(json['photos']);
    if (originals.isNotEmpty) return originals;
    return _maps(json['photos_new'])
        .map((e) {
          final photo = e['photo']?.toString() ?? '';
          return photo.isNotEmpty
              ? photo
              : e['thumbnail_photo']?.toString() ?? '';
        })
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

class _TaskSection {
  _TaskSection({
    required this.data,
    this.log,
    this.mine = false,
    this.firstSquare = false,
  });
  final _TaskResult data;
  final _TaskLog? log;
  final bool mine;
  final bool firstSquare;
}

class _TaskSteps extends StatelessWidget {
  const _TaskSteps({required this.log});
  final _TaskLog log;

  @override
  Widget build(BuildContext context) {
    final late = log.number('is_bu') == 1;
    final steps = late ? ['补交待审核', '待批阅', '批阅中', '已批阅'] : ['待批阅', '批阅中', '已批阅'];
    final current = late
        ? switch (log.state) {
            0 => 1,
            4 => 2,
            1 => 3,
            _ => 0,
          }
        : switch (log.state) {
            4 => 1,
            1 => 2,
            _ => 0,
          };
    return Container(
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: CustomPaint(painter: _StepPainter(steps, current)),
    );
  }
}

class _StepPainter extends CustomPainter {
  _StepPainter(this.steps, this.current);
  final List<String> steps;
  final int current;

  @override
  void paint(Canvas canvas, Size size) {
    const margin = 24.0;
    const y = 29.0;
    final width = size.width - margin * 2;
    if (width <= 0) return;
    final segment = width / (steps.length + 1);
    final paint = Paint()
      ..color = AppColors.border
      ..strokeWidth = 2;
    canvas.drawLine(
      const Offset(margin, y),
      Offset(size.width - margin, y),
      paint,
    );
    paint.color = AppColors.theme;
    canvas.drawLine(
      const Offset(margin, y),
      Offset(margin + segment * (current + 1), y),
      paint,
    );
    for (var i = 0; i < steps.length; i++) {
      final x = margin + segment * (i + 1);
      paint.color = i <= current ? AppColors.theme : AppColors.border;
      canvas.drawCircle(Offset(x, y), 6, paint);
      final label = TextPainter(
        text: TextSpan(
          text: steps[i],
          style: TextStyle(
            color: i <= current ? AppColors.title : AppColors.grayAAA,
            fontSize: 12,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      label.paint(canvas, Offset(x - label.width / 2, y + 14));
      label.dispose();
    }
  }

  @override
  bool shouldRepaint(covariant _StepPainter oldDelegate) =>
      current != oldDelegate.current ||
      steps.join() != oldDelegate.steps.join();
}
