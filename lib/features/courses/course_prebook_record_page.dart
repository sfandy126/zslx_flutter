import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../services/bjy_server.dart';
import '../../utils/utils.dart';
import '../../widgets/page_background.dart';
import '../../widgets/refresh_list_view.dart';

class CoursePrebookRecordPage extends StatefulWidget {
  const CoursePrebookRecordPage({super.key});

  @override
  State<CoursePrebookRecordPage> createState() =>
      _CoursePrebookRecordPageState();
}

class _CoursePrebookRecordPageState extends State<CoursePrebookRecordPage> {
  final _listKey = GlobalKey<RefreshListViewState<_PrebookRecord>>();

  Future<RefreshResult<_PrebookRecord>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    final result = await MDPost.sendApiSession(
      cmd: .coursePrebookRecords,
      params: {'page': page},
    );
    if (result.state == .outed || !MDUser.defualt.islogined) {
      return RefreshResult.notLoggedIn(result.msg);
    }
    if (!result.isSuccess) {
      return RefreshResult.failed(result.msg ?? '约课记录加载失败');
    }

    final data = result.data;
    final rows = data?['list'];
    if (rows == null && data == null) {
      return RefreshResult.success([], noMore: true);
    }
    if (rows is! List) return RefreshResult.failed('约课记录数据格式错误');

    final records = rows
        .whereType<Map>()
        .map((row) => _PrebookRecord(Map<String, dynamic>.from(row)))
        .toList();
    final pageInfo = data?['page_info'];
    final pagination = pageInfo is Map<String, dynamic> ? pageInfo : data;
    final hasMore = pagination?.mdBool('has_more');
    final lastPage =
        pagination?.mdInt('last_page') ?? pagination?.mdInt('total_page');
    return RefreshResult.success(
      records,
      noMore:
          records.isEmpty ||
          (hasMore != null ? !hasMore : lastPage != null && page >= lastPage),
    );
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  Future<void> _openClassroom(_PrebookRecord record) async {
    if (!MDUser.defualt.islogined) {
      await _openLogin();
      return;
    }
    final liveState = record.liveState;
    if (liveState == .expired) {
      MDTotast.error('该课程已过期');
      return;
    }
    if (record.sectionId.isEmpty) {
      MDTotast.error('暂无课堂信息');
      return;
    }
    final params = {'type': record.type, 'section_id': record.sectionId};
    switch (liveState) {
      case .aboutToStart:
      case .live:
        await BjyServer.loadAndToLive(params: params);
      case .playback:
        await BjyServer.loadAndToPlayback(params: params);
      default:
        MDTotast.error(
          record.statusText.isNotEmpty
              ? record.statusText
              : liveState?.label ?? '暂无课堂信息',
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MDPageBackground(
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(
                height: kToolbarHeight,
                child: MDAppBar(
                  title: '约课记录',
                  centerTitle: false,
                  backgroundColor: AppColors.transparent,
                ),
              ),
              Expanded(
                child: RefreshListView<_PrebookRecord>(
                  key: _listKey,
                  onData: _loadPage,
                  onLogin: _openLogin,
                  emptyText: '暂无约课记录',
                  padding: const EdgeInsets.fromLTRB(18, 12, 18, 20),
                  itemBuilder: (_, record, _) => _RecordCard(
                    record: record,
                    onOpen: () => _openClassroom(record),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, required this.onOpen});

  final _PrebookRecord record;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final liveState = record.liveState;
    final subtitleStyle = TextStyle(color: AppColors.content, fontSize: 13);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: .stretch,
        children: [
          Text(
            record.title,
            style: TextStyle(
              color: AppColors.title,
              fontSize: 16,
              fontWeight: .w700,
            ),
          ),
          const SizedBox(height: 16),
          Text(record.time, style: subtitleStyle),
          _RecordField(label: '分配讲师', value: record.teacher),
          _RecordField(label: '剩余课时', value: record.remainingHours),
          _RecordField(label: '本次消耗课时', value: record.usedHours ?? '—'),
          Divider(height: 1, thickness: 1, color: AppColors.line),
          _RecordField(
            label: '预约状态',
            value: record.statusText,
            valueColor: liveState == .live || liveState == .aboutToStart
                ? AppColors.red
                : null,
          ),
          OutlinedButton(
            onPressed: onOpen,
            style: OutlinedButton.styleFrom(
              backgroundColor: AppColors.lightTheme,
              foregroundColor: AppColors.theme,
              side: BorderSide(color: AppColors.border),
              minimumSize: const Size(0, 42),
              splashFactory: NoSplash.splashFactory,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text('查看课堂', style: TextStyle(fontWeight: .w700)),
          ),
        ],
      ),
    );
  }
}

class _RecordField extends StatelessWidget {
  const _RecordField({
    required this.label,
    required this.value,
    this.valueColor,
  });

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Row(
        children: [
          Text(label, style: TextStyle(color: AppColors.content)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(color: valueColor ?? AppColors.title),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrebookRecord {
  _PrebookRecord(Map<String, dynamic> json)
    : title = json.mdStringOr('course_name'),
      sectionId = json.mdStringOr('classroom_section_id'),
      type = json.mdString('type') ?? json.mdStringOr('course_type', 'ydy'),
      teacher = json.mdStringOr('teacher_name'),
      remainingHours = json.mdStringOr('keshi_left', '—'),
      usedHours = json.mdStringOr('keshi_use', '—'),
      time = json.mdString('time') ?? _timeRange(json),
      status = json.mdInt('status'),
      expired = json.mdInt('expired'),
      statusText = json.mdStringOr('status_name'),
      token = json.mdStringOr('token');

  final String title;
  final String sectionId;
  final String type;
  final String teacher;
  final String remainingHours;
  final String? usedHours;
  final String time;
  final int? status;
  final int? expired;
  final String statusText;
  final String token;

  static String _timeRange(Map<String, dynamic> json) {
    final start = json.mdStringOr('start_time_text');
    final end = json.mdStringOr('end_time_text');
    return [start, end].where((part) => part.isNotEmpty).join(' ~ ');
  }

  _LiveState? get liveState {
    if (expired == 1) return _LiveState.expired;
    if (status == 3) {
      return token.isNotEmpty ? _LiveState.playback : _LiveState.ended;
    }
    return switch (status) {
      2 => _LiveState.live,
      1 => _LiveState.aboutToStart,
      0 => _LiveState.notStarted,
      _ => null,
    };
  }
}

enum _LiveState {
  expired('已过期'),
  notStarted('未开始'),
  aboutToStart('即将开始'),
  live('直播中'),
  playback('直播回放'),
  ended('已结束');

  const _LiveState(this.label);
  final String label;
}
