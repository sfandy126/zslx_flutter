import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../../router/app_router.dart';
import '../../services/bjy_server.dart';
import '../../services/history/history_server.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

/// 学习历史：展示本地保存的录播/直播回放播放记录
class LearnHistoryPage extends StatefulWidget {
  const LearnHistoryPage({super.key});

  @override
  State<LearnHistoryPage> createState() => _LearnHistoryPageState();
}

class _LearnHistoryPageState extends State<LearnHistoryPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<PlayHistory>>();

  Future<RefreshResult<PlayHistory>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      // 删除过记录后按页码计算偏移会漏数据，加载更多时以已加载条数为准
      final offset = page > 1 ? _listKey.currentState?.items.length : 0;
      final histories = await HistoryServer.fetchPage(page, offset: offset);
      return RefreshResult.success(
        histories,
        noMore: histories.length < HistoryServer.pageSize,
      );
    } catch (error) {
      Utils.log('LearnHistoryPage load failed: $error');
      return RefreshResult.failed('加载失败，请重试');
    }
  }

  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (!mounted) return false;
    if (MDUser.defualt.islogined) _listKey.currentState?.refresh();
    return false;
  }

  Future<void> _delete(PlayHistory history) async {
    if (!await _requireLogin() || !mounted) return;
    final deleted = await HistoryServer.delete(history);
    if (!mounted) return;
    if (!deleted) {
      MDTotast.showError('删除失败，请重试');
      return;
    }
    _listKey.currentState?.removeWhere(
      (item) => item.isSameRecord(history),
    );
  }

  Future<void> _open(PlayHistory history) async {
    if (!await _requireLogin() || !mounted) return;
    final params = <String, dynamic>{
      'course_id': history.cId,
      'type': history.sType,
      'section_id': history.sId,
      'video_type': history.source,
    };
    // 公开课下的绑定的付费课程
    if (history.cType == 'gk' &&
        history.sId != history.cId &&
        history.cType != history.sType) {
      params['is_zk'] = 1;
      params['gk_type'] = history.cType;
      params['gk_id'] = history.cId;
    }

    MDTotast.showLoading();
    late final MDResult result;
    try {
      result = await MDPost.sendApiSession(cmd: .checkCourse, params: params);
    } catch (error) {
      Utils.log('LearnHistoryPage check course failed: $error');
      if (mounted) MDTotast.showError('资源加载异常，请稍后重试~');
      return;
    } finally {
      MDTotast.hideLoading();
    }
    if (!mounted) return;
    if (!result.isSuccess) {
      MDTotast.showError(result.msg ?? '资源加载异常，请稍后重试~');
      return;
    }

    final data = result.data ?? const <String, dynamic>{};
    if (history.source == PlayHistorySource.playback) {
      final playback = BjyPlayback.fromJson(data);
      if (playback.room.isEmpty) {
        MDTotast.showError('没有直播回放~');
        return;
      }
      if (BjyServer.enterPlayback(playback)) {
        await HistoryServer.insertOrUpdate(history);
        if (mounted) _listKey.currentState?.refresh();
      }
      return;
    }

    final url = data['url']?.toString() ?? '';
    if (url.isEmpty) {
      MDTotast.showError('资源加载异常，请稍后重试~');
      return;
    }
    await AppRouter.pushNamed<void>(
      context,
      RouterNames.video,
      queryParameters: {
        'url': url,
        'title': history.sName,
        'courseTitle': history.cName,
        'cover': history.cPhoto,
        'courseId': history.cId,
        'courseType': history.cType,
        'sectionId': history.sId,
        'sectionType': history.sType,
        'sectionCourseId': history.sCid,
        'seekTime': '${history.seekTime}',
      },
    );
    // 返回后刷新，展示最新的播放时间与排序
    if (mounted) _listKey.currentState?.refresh();
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: _plainTextStyle,
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: MDAppBar(title: '学习历史', centerTitle: true),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: SlidableAutoCloseBehavior(
                  child: RefreshListView<PlayHistory>(
                    key: _listKey,
                    onData: _loadPage,
                    emptyText: '暂无学习记录',
                    failedText: '加载失败，请重试',
                    onLogin: _openLogin,
                    padding: const EdgeInsets.only(bottom: 16),
                    itemBuilder: (context, history, index) => Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: _HistoryTile(
                        history: history,
                        onTap: () => _open(history),
                        onDelete: () => unawaited(_delete(history)),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HistoryTile extends StatelessWidget {
  const _HistoryTile({
    required this.history,
    required this.onTap,
    required this.onDelete,
  });

  final PlayHistory history;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// yyyy-MM-dd HH:mm:ss
  static String _dateText(DateTime date) {
    return '${date.year}-${_two(date.month)}-${_two(date.day)} '
        '${_two(date.hour)}:${_two(date.minute)}:${_two(date.second)}';
  }

  /// 播放进度文案：直播回放显示“直播回放”，录播显示“播放进度：xx.x%”
  static String _progressText(PlayHistory history) {
    if (history.source == PlayHistorySource.playback) return '直播回放';
    if (history.total <= 0) return '播放进度：0%';
    final percent = (history.time / history.total * 100).clamp(0, 100).toDouble();
    if (percent >= 100) return '已看完';
    // 整数百分比不显示小数位，否则保留 1 位小数
    final text = percent == percent.truncateToDouble()
        ? '${percent.toInt()}'
        : percent.toStringAsFixed(1);
    return '播放进度：$text%';
  }

  @override
  Widget build(BuildContext context) {
    const coverWidth = 140.0;
    final radius = BorderRadius.circular(12);
    return ClipRRect(
      borderRadius: radius,
      child: Slidable(
        key: ValueKey(
          '${history.cType}-${history.cId}-${history.sType}-${history.sId}',
        ),
        endActionPane: ActionPane(
          motion: const DrawerMotion(),
          extentRatio: 0.22,
          children: [
            SlidableAction(
              onPressed: (_) => onDelete(),
              backgroundColor: AppColors.theme,
              foregroundColor: AppColors.white,
              label: '删除',
            ),
          ],
        ),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: Container(
            color: AppColors.white,
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: coverWidth * 0.65,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MDNetImage(
                    imageUrl: history.cPhoto,
                    width: coverWidth,
                    height: coverWidth * 0.65,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          history.sName,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _progressText(history),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 12,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _dateText(history.updateTime),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
