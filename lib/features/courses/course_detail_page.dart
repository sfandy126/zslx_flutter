import 'dart:async';

import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../router/app_router.dart';
import '../../services/bjy_server.dart';
import '../../services/history/history_server.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

class CourseDetailPage extends StatefulWidget {
  const CourseDetailPage({
    this.type = '',
    this.id = '',
    this.orderId = '',
    super.key,
  });

  /// 课程类型
  final String type;

  /// 课程 id
  final String id;

  final String orderId;

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  late final WebViewController _htmlController;
  late String _courseId;
  late String _courseType;
  _CourseDetail? _detail;
  bool _loading = true;
  bool _isFavorite = false;
  bool _sheetOpen = false;
  bool _sheetMounted = false;
  int _mainTab = 0;
  int _directoryTab = 0;
  int _detailRequest = 0;
  int _activeDetailLoads = 0;
  double _htmlHeight = 1;
  String? _loadError;
  Key _workListKey = UniqueKey();

  /// 录播播放记录，key 见 [_historyKey]
  final Map<String, PlayHistory> _histories = {};

  /// 最近一次播放的录播节
  String? _lastPlayKey;
  StreamSubscription<PlayHistory>? _historySubscription;

  @override
  void initState() {
    super.initState();
    _courseId = widget.id;
    _courseType = widget.type;
    _historySubscription = HistoryServer.changes.listen(_onHistoryChanged);
    _htmlController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(AppColors.white)
      ..addJavaScriptChannel(
        'CourseHtmlSize',
        onMessageReceived: (message) {
          final height = double.tryParse(message.message);
          if (!mounted || height == null || height <= 0) return;
          if ((height - _htmlHeight).abs() > 1) {
            setState(() => _htmlHeight = height);
          }
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onWebResourceError: (error) {
            if (error.isForMainFrame ?? true) {
              Utils.log(
                'CourseDetailPage HTML load error: '
                '${error.errorCode} ${error.description}',
              );
            }
          },
        ),
      );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadDetail());
  }

  @override
  void dispose() {
    _historySubscription?.cancel();
    super.dispose();
  }

  static String _historyKey(String sType, String sId) => '$sType|$sId';

  /// 读取本课程的录播播放记录，用于展示播放进度与“上次播放”
  Future<void> _loadHistories() async {
    final info = _detail?.info;
    if (info == null) return;
    final histories = await HistoryServer.fetchFor(
      cId: info.id,
      cType: info.type,
      source: PlayHistorySource.recording,
    );
    if (!mounted || _detail?.info != info) return;
    setState(() {
      _histories
        ..clear()
        ..addEntries(
          histories.map((item) => MapEntry(_historyKey(item.sType, item.sId), item)),
        );
      // 结果按更新时间倒序，第一条即为最近播放
      _lastPlayKey = histories.isEmpty
          ? null
          : _historyKey(histories.first.sType, histories.first.sId);
    });
  }

  void _onHistoryChanged(PlayHistory history) {
    final info = _detail?.info;
    if (!mounted ||
        info == null ||
        history.cId != info.id ||
        history.cType != info.type ||
        history.source != PlayHistorySource.recording ||
        history.total <= 0) {
      return;
    }
    final key = _historyKey(history.sType, history.sId);
    setState(() {
      _histories[key] = history;
      _lastPlayKey = key;
    });
  }

  Future<void> _loadDetail() async {
    if (!mounted) return;
    final request = ++_detailRequest;
    setState(() {
      _loading = true;
      _loadError = null;
    });

    _activeDetailLoads++;
    if (_activeDetailLoads == 1) MDTotast.showLoading();
    String? errorToShow;
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseDetail,
        params: {
          'type': _courseType,
          'course_id': _courseId,
          'order_id': widget.orderId,
        },
      );
      if (!mounted || request != _detailRequest) return;
      if (!result.isSuccess) {
        setState(() {
          _loading = false;
          _loadError = result.msg ?? '课程详情加载失败';
        });
        if (_detail != null) {
          errorToShow = result.msg ?? '课程详情加载失败';
        }
      } else {
        final detail = _CourseDetail.fromJson(
          result.data ?? const {},
          courseId: _courseId,
          courseType: _courseType,
        );
        setState(() {
          _detail = detail;
          _isFavorite = detail.isFavorite;
          _loading = false;
          _mainTab = 0;
          _workListKey = UniqueKey();
        });
        unawaited(_loadHistories());
        await _loadDescription(detail.info.html);
      }
    } catch (error) {
      if (!mounted || request != _detailRequest) return;
      Utils.log('CourseDetailPage load detail failed: $error');
      setState(() {
        _loading = false;
        _loadError = '课程详情加载失败，请稍后重试';
      });
      if (_detail != null) {
        errorToShow = '课程详情加载失败，请稍后重试';
      }
    } finally {
      _activeDetailLoads--;
      if (_activeDetailLoads == 0) MDTotast.hideLoading();
    }
    if (errorToShow != null && mounted) {
      MDTotast.showError(errorToShow);
    }
  }

  Future<void> _loadDescription(String html) async {
    if (html.trim().isEmpty) {
      setState(() => _htmlHeight = 1);
      return;
    }
    setState(() => _htmlHeight = 1);
    final document =
        '''
<!doctype html>
<html>
<head>
<meta name="viewport" content="width=device-width,initial-scale=1,maximum-scale=1,user-scalable=no">
<style>
body { margin: 0; padding: 12px 16px; font: 14px -apple-system, BlinkMacSystemFont, sans-serif; color: #333; line-height: 1.6; word-break: break-all; }
img { max-width: 100%; height: auto; display: block; }
p { margin: 8px 0; }
</style>
</head>
<body>$html
<script>
let reportedHeight = 0;
function reportHeight() {
  const height = Math.ceil(document.documentElement.scrollHeight);
  if (height > 0 && height !== reportedHeight) {
    reportedHeight = height;
    CourseHtmlSize.postMessage(height.toString());
  }
}
window.addEventListener('load', reportHeight, {once:true});
new ResizeObserver(reportHeight).observe(document.documentElement);
</script>
</body>
</html>
''';
    await _htmlController.loadHtmlString(document);
  }

  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    return mounted && MDUser.defualt.islogined;
  }

  Future<void> _toggleFavorite() async {
    if (!await _requireLogin() || !mounted) return;
    MDTotast.showLoading();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseFavorite,
        params: {'id': _courseId, 'type': _courseType},
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        MDTotast.showError(result.msg ?? '收藏操作失败');
        return;
      }
      final state = result.data?['is_collect'].mdToInt();
      setState(() => _isFavorite = state == 1);
      MDTotast.showSuccess(result.msg ?? '操作成功');
    } catch (error) {
      Utils.log('CourseDetailPage favorite failed: $error');
      if (mounted) MDTotast.showError('收藏操作失败，请稍后重试');
    } finally {
      MDTotast.hideLoading();
    }
  }

  Future<void> _shareCourse() async {
    final info = _detail?.info;
    final url = info?.shareUrl ?? '';
    if (url.isEmpty) return;
    try {
      await SharePlus.instance.share(
        ShareParams(
          title: info?.title,
          text: info?.title,
          uri: Uri.tryParse(url),
        ),
      );
    } catch (error) {
      Utils.log('CourseDetailPage share failed: $error');
      if (mounted) MDTotast.showError('分享失败，请稍后重试');
    }
  }

  Future<void> _handleBottomAction() async {
    final info = _detail?.info;
    if (info == null || !await _requireLogin() || !mounted) return;

    switch (info.startType) {
      case _CourseStartType.join:
        MDTotast.showLoading();
        try {
          final result = await MDPost.sendApiSession(
            cmd: .joinGk,
            params: {'course_id': _courseId, 'type': _courseType},
          );
          if (!mounted) return;
          if (result.isSuccess) {
            await _loadDetail();
          } else {
            MDTotast.showError(result.msg ?? '加入学习失败');
          }
        } catch (error) {
          Utils.log('CourseDetailPage join course failed: $error');
          if (mounted) MDTotast.showError('加入学习失败，请稍后重试');
        } finally {
          MDTotast.hideLoading();
        }
      case _CourseStartType.learn:
        _openDirectorySheet();
      case _CourseStartType.buy:
      case _CourseStartType.buyAgain:
        // TODO: 接入课程下单页面。
        _showTodo('课程购买页面');
      case _CourseStartType.prebook:
        // TODO: 接入一对一预约页面。
        _showTodo('课程预约页面');
      case _CourseStartType.none:
        break;
    }
  }

  void _openCourseFiles() {
    if (!MDUser.defualt.islogined) {
      AppRouter.pushNamed<void>(context, RouterNames.login);
      return;
    }
    if (!_canAccessCourse()) return;
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseFolder,
      queryParameters: {'courseId': _courseId, 'courseType': _courseType},
    );
  }

  Future<void> _openNode(_CourseNode node, {required bool live}) async {
    if (!await _requireLogin() || !mounted) return;
    final info = _detail?.info;
    if (info == null) return;
    if (node.realType == 'gk') {
      if (info.buyed != 1) {
        MDTotast.showError('请加入学习～');
        return;
      }
    } else if (info.buyed != 1 && node.allowTry != 1) {
      MDTotast.showError('请先购买课程～');
      return;
    }

    if (live) {
      final sectionType = node.realType.isEmpty ? info.type : node.realType;
      final params = {
        'type': sectionType,
        'section_id': node.id,
        'get_hf_data_check': node.historyCheck,
      };
      if (node.isFinished) {
        final entered = await BjyServer.loadAndToPlayback(params: params);
        // 直播回放开始播放即记录，进度为 0
        if (entered) {
          final record = PlayHistory()
            ..cId = info.id
            ..cType = info.type
            ..cName = info.title
            ..cPhoto = info.picture
            ..sId = node.id
            ..sType = sectionType
            ..sCid = node.realId.isEmpty ? info.id : node.realId
            ..sName = node.title
            ..source = PlayHistorySource.playback;
          unawaited(HistoryServer.insertOrUpdate(record));
        }
      } else {
        await BjyServer.loadAndToLive(params: params);
      }
      return;
    }

    if (node.videoLink.isEmpty) {
      MDTotast.showError('url不存在，请联系客服');
      return;
    }
    MDTotast.showLoading();
    String? playbackUrl;
    try {
      final result = await MDPost.sendApiSession(
        cmd: .ossUrl,
        params: {
          'url': node.videoLink,
          'jie_id': node.id,
          'course_id': node.realId,
          'type': node.realType,
        },
      );
      if (!mounted) return;
      if (!result.isSuccess) {
        MDTotast.showError(result.msg ?? '视频加载失败');
        return;
      }
      playbackUrl = _stringFrom(result.data ?? const {}, const [
        'm3u8_url',
        'url',
      ]);
      if (playbackUrl.isEmpty) {
        MDTotast.showError('视频地址为空，请联系客服');
        return;
      }
    } catch (error) {
      Utils.log('CourseDetailPage resolve recording url failed: $error');
      if (mounted) MDTotast.showError('视频加载失败，请稍后重试');
      return;
    } finally {
      MDTotast.hideLoading();
    }
    if (!mounted) return;
    final history = _histories[_historyKey(node.realType, node.id)];
    await AppRouter.pushNamed<void>(
      context,
      RouterNames.video,
      queryParameters: {
        'url': playbackUrl,
        'title': node.title,
        'courseTitle': info.title,
        'cover': info.picture,
        'courseId': info.id,
        'courseType': info.type,
        'sectionId': node.id,
        'sectionType': node.realType,
        'sectionCourseId': node.realId,
        'seekTime': '${history?.seekTime ?? 0}',
      },
    );
  }

  Future<RefreshResult<_CourseWork>> _loadWorkPage(int page) async {
    try {
      if (!MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn();
      }
      final result = await MDPost.sendApiSession(
        cmd: .zyList,
        params: {'course_id': _courseId, 'type': _courseType, 'page': page},
      );
      if (result.isSuccess) {
        final data = result.data ?? const <String, dynamic>{};
        final works = <_CourseWork>[];
        if (page == 1) {
          works.addAll(
            _listFrom(data['zy_top_list']).map(_CourseWork.fromJson),
          );
        }
        works.addAll(_listFrom(data['zy_list']).map(_CourseWork.fromJson));
        return RefreshResult.success(
          works,
          noMore: page > 1 ? works.isEmpty : _listFrom(data['zy_list']).isEmpty,
        );
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '作业列表加载失败');
    } catch (error) {
      Utils.log('CourseDetailPage load work list failed: $error');
      return RefreshResult.failed('作业列表加载失败，请下拉刷新重试');
    }
  }

  bool _canAccessCourse({bool allowExpired = false}) {
    final info = _detail?.info;
    if (info == null) return false;
    if (info.buyed == 1 || (allowExpired && info.buyedExpired == 1)) {
      return true;
    }
    MDTotast.showError('请先购买课程～');
    return false;
  }

  void _showTodo(String name) {
    MDTotast.showError('$name待实现');
  }

  @override
  Widget build(BuildContext context) {
    final detail = _detail;
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
                  child: MDAppBar(
                    title: '详情',
                    centerTitle: false,
                    onBackPressed: () {
                      if (_sheetOpen) {
                        _closeDirectorySheet();
                        return;
                      }
                      AppRouter.maybePop<void>(context);
                    },
                    actions: [
                      if (detail?.info.shareUrl.isNotEmpty ?? false)
                        IconButton(
                          tooltip: '分享课程',
                          onPressed: _shareCourse,
                          icon: Icon(
                            Icons.share_outlined,
                            color: AppColors.title,
                            size: 22,
                          ),
                        ),
                      if (detail != null)
                        IconButton(
                          tooltip: _isFavorite ? '取消收藏' : '收藏课程',
                          onPressed: _toggleFavorite,
                          icon: Icon(
                            _isFavorite
                                ? Icons.favorite
                                : Icons.favorite_border,
                            color: _isFavorite
                                ? AppColors.red
                                : AppColors.title,
                            size: 22,
                          ),
                        ),
                      const SizedBox(width: 4),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: Stack(
                  children: [
                    Positioned.fill(child: _buildBody(detail)),
                    if (_sheetMounted) _buildDirectorySheet(detail),
                  ],
                ),
              ),
            ),
            if (detail != null) _buildBottomBar(detail.info),
          ],
        ),
      ),
    );
  }

  Widget _buildBody(_CourseDetail? detail) {
    if (_loading && detail == null) {
      return const SizedBox.expand();
    }
    if (detail == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _loadError ?? '课程详情加载失败',
              style: TextStyle(color: AppColors.content, fontSize: 14),
            ),
            const SizedBox(height: 12),
            TextButton(onPressed: _loadDetail, child: const Text('重新加载')),
          ],
        ),
      );
    }

    final info = detail.info;
    final showSkus = _shouldShowSkus(info);
    return RefreshIndicator(
      onRefresh: _loadDetail,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: 12),
        children: [
          AspectRatio(
            aspectRatio: 375 / 198,
            child: MDNetImage(imageUrl: info.picture),
          ),
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  info.title,
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '共${info.period.isEmpty ? '--' : info.period}课时',
                  style: TextStyle(color: AppColors.content, fontSize: 13),
                ),
                const SizedBox(height: 10),
                Text(
                  '有效期至:${info.validate.isEmpty ? '--' : info.validate}',
                  style: TextStyle(color: AppColors.content, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      info.money.mdToPrice(),
                      style: TextStyle(
                        color: AppColors.price,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (info.oldMoney.mdToOldPrice().isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        info.oldMoney.mdToOldPrice(),
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 12,
                          decoration: TextDecoration.lineThrough,
                        ),
                      ),
                    ],
                    const Spacer(),
                    if (info.hasFiles)
                      TextButton.icon(
                        onPressed: _openCourseFiles,
                        icon: Icon(
                          Icons.folder_open_outlined,
                          color: AppColors.theme,
                          size: 16,
                        ),
                        label: Text(
                          '课程资料',
                          style: TextStyle(
                            color: AppColors.theme,
                            fontSize: 12,
                          ),
                        ),
                        style: TextButton.styleFrom(
                          backgroundColor: AppColors.lightTheme,
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          minimumSize: const Size(0, 32),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
          if (showSkus) _buildSkuSelector(info),
          _buildMainTabs(detail),
        ],
      ),
    );
  }

  bool _shouldShowSkus(_CourseInfo info) {
    final skus = info.skus;
    if (skus.isEmpty) return false;
    return skus.length != 1 ||
        skus.first.id != info.id ||
        skus.first.type != info.type;
  }

  Widget _buildSkuSelector(_CourseInfo info) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      color: AppColors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '类型 (共${info.skus.length}种)',
            style: TextStyle(
              color: AppColors.title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: info.skus.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final sku = info.skus[index];
                final selected = sku.id == info.id && sku.type == info.type;
                return GestureDetector(
                  onTap: () {
                    if (sku.id.isEmpty || sku.type.isEmpty) return;
                    setState(() {
                      _courseId = sku.id;
                      _courseType = sku.type;
                    });
                    _loadDetail();
                  },
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      border: selected
                          ? Border.all(color: AppColors.theme, width: 2)
                          : null,
                    ),
                    child: MDNetImage(
                      imageUrl: sku.picture,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainTabs(_CourseDetail detail) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      color: AppColors.white,
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _MainTabButton(
                    title: '简介',
                    selected: _mainTab == 0,
                    onTap: () {
                      setState(() => _mainTab = 0);
                      _closeDirectorySheet();
                    },
                  ),
                  const SizedBox(width: 30),
                  _MainTabButton(
                    title: '课表',
                    selected: _mainTab == 1,
                    onTap: () => _openDirectorySheet(resetTab: true),
                  ),
                ],
              ),
            ),
          ),
          if (_mainTab == 0)
            SizedBox(
              height: _htmlHeight,
              child: detail.info.html.trim().isEmpty
                  ? Padding(
                      padding: const EdgeInsets.all(20),
                      child: Center(
                        child: Text(
                          '暂无课程简介',
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    )
                  : WebViewWidget(controller: _htmlController),
            )
          else
            const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildBottomBar(_CourseInfo info) {
    final showAction = info.startType != _CourseStartType.none;
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: Border(top: BorderSide(color: AppColors.line, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 56,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Text(
                info.money.mdToPrice(),
                style: TextStyle(
                  color: AppColors.price,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (info.oldMoney.mdToOldPrice().isNotEmpty) ...[
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    info.oldMoney.mdToOldPrice(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: AppColors.content,
                      fontSize: 12,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ),
              ],
              const Spacer(),
              if (showAction)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: FilledButton(
                    onPressed: _handleBottomAction,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.theme,
                      minimumSize: const Size(112, 40),
                      shape: const StadiumBorder(),
                    ),
                    child: Text(info.startType.title),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDirectorySheet(_CourseDetail? detail) {
    if (detail == null) return const SizedBox.shrink();
    final tabs = detail.directoryTabs;
    return Positioned.fill(
      top: 40,
      child: IgnorePointer(
        ignoring: !_sheetOpen,
        child: AnimatedSlide(
          offset: _sheetOpen ? Offset.zero : const Offset(0, 1),
          duration: const Duration(milliseconds: 260),
          curve: Curves.easeOut,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(16),
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.black.withValues(alpha: 0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _closeDirectorySheet,
                  onVerticalDragEnd: (details) {
                    if ((details.primaryVelocity ?? 0) > 250) {
                      _closeDirectorySheet();
                    }
                  },
                  child: SizedBox(
                    height: 36,
                    child: Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.grayAAA,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ),
                if (tabs.isNotEmpty)
                  SizedBox(
                    height: 44,
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          for (var index = 0; index < tabs.length; index++) ...[
                            if (index > 0) const SizedBox(width: 36),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                setState(() {
                                  _directoryTab = index;
                                  _workListKey = UniqueKey();
                                });
                              },
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    tabs[index].title,
                                    style: TextStyle(
                                      color: _directoryTab == index
                                          ? AppColors.theme
                                          : AppColors.title,
                                      fontSize: 15,
                                      fontWeight: _directoryTab == index
                                          ? FontWeight.w600
                                          : FontWeight.normal,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Container(
                                    width: 20,
                                    height: 3,
                                    decoration: BoxDecoration(
                                      color: _directoryTab == index
                                          ? AppColors.theme
                                          : AppColors.transparent,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                Expanded(child: _buildDirectoryContent(detail, tabs)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDirectoryContent(
    _CourseDetail detail,
    List<_DirectoryTab> tabs,
  ) {
    if (tabs.isEmpty || _directoryTab >= tabs.length) {
      return Center(
        child: Text('暂无课程目录', style: TextStyle(color: AppColors.content)),
      );
    }
    final tab = tabs[_directoryTab];
    if (tab.type == _DirectoryType.work) {
      return RefreshListView<_CourseWork>(
        key: _workListKey,
        onData: _loadWorkPage,
        itemBuilder: (context, item, index) =>
            _WorkCard(work: item, onTap: () => _openWork(item)),
        emptyText: '暂无作业',
        onLogin: () async {
          await AppRouter.pushNamed<void>(context, RouterNames.login);
          if (mounted && MDUser.defualt.islogined) {
            setState(() => _workListKey = UniqueKey());
          }
        },
      );
    }
    final sourceNodes = switch (tab.type) {
      _DirectoryType.live => detail.lives,
      _DirectoryType.bind => detail.bindLives,
      _DirectoryType.recorded => detail.recordings,
      _DirectoryType.work => const <_CourseNode>[],
    };
    final live =
        tab.type == _DirectoryType.live || tab.type == _DirectoryType.bind;
    final nodes = live ? _prepareLiveNodes(sourceNodes) : sourceNodes;
    if (nodes.isEmpty) {
      return Center(
        child: Text('暂无课程目录', style: TextStyle(color: AppColors.content)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
      itemCount: nodes.length,
      itemBuilder: (context, index) => _NodeGroup(
        node: nodes[index],
        live: live,
        initiallyExpanded: index == 0,
        histories: live ? const {} : _histories,
        lastPlayKey: live ? null : _lastPlayKey,
        onTap: (item) => _openNode(item, live: live),
      ),
    );
  }

  List<_CourseNode> _prepareLiveNodes(List<_CourseNode> nodes) {
    if (nodes.isEmpty) return nodes;
    if (nodes.first.children.isNotEmpty) {
      final liveNodes =
          nodes
              .expand((section) => section.children)
              .where((node) => node.isLive)
              .toList()
            ..sort((a, b) => b.startTime.compareTo(a.startTime));
      if (liveNodes.isEmpty) return nodes;
      return [liveNodes.first.asTopLive(), ...nodes];
    }

    return [...nodes]..sort((a, b) {
      if (a.isLive == b.isLive) return 0;
      return a.isLive ? -1 : 1;
    });
  }

  void _openDirectorySheet({bool resetTab = false}) {
    setState(() {
      if (resetTab) _directoryTab = 0;
      _sheetMounted = true;
      _sheetOpen = true;
    });
  }

  void _closeDirectorySheet() {
    if (!_sheetOpen) return;
    setState(() => _sheetOpen = false);
    Future<void>.delayed(const Duration(milliseconds: 280), () {
      if (mounted && !_sheetOpen && _sheetMounted) {
        setState(() => _sheetMounted = false);
      }
    });
  }

  Future<void> _openWork(_CourseWork work) async {
    if (!MDUser.defualt.islogined) {
      await AppRouter.pushNamed<void>(context, RouterNames.login);
      if (!mounted || !MDUser.defualt.islogined) return;
    }
    if (!_canAccessCourse(allowExpired: true)) return;
    // TODO: 接入作业详情/提交页面。
    _showTodo('作业详情页面');
  }
}

class _MainTabButton extends StatelessWidget {
  const _MainTabButton({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        width: 60,
        height: 48,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Text(
              title,
              style: TextStyle(
                color: selected ? AppColors.title : AppColors.content,
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Container(
              width: 24,
              height: 3,
              decoration: BoxDecoration(
                color: selected ? AppColors.theme : AppColors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Container(height: 0.5, color: AppColors.line),
          ],
        ),
      ),
    );
  }
}

class _NodeGroup extends StatelessWidget {
  const _NodeGroup({
    required this.node,
    required this.live,
    required this.initiallyExpanded,
    required this.onTap,
    this.histories = const {},
    this.lastPlayKey,
  });

  final _CourseNode node;
  final bool live;
  final bool initiallyExpanded;
  final ValueChanged<_CourseNode> onTap;

  /// 录播播放记录，仅录播目录使用
  final Map<String, PlayHistory> histories;
  final String? lastPlayKey;

  Widget _buildCard(_CourseNode item) {
    final key = _CourseDetailPageState._historyKey(item.realType, item.id);
    return _NodeCard(
      node: item,
      live: live,
      progress: histories[key]?.progress ?? 0,
      isLastPlay: key == lastPlayKey,
      onTap: () => onTap(item),
    );
  }

  @override
  Widget build(BuildContext context) {
    final children = node.children;
    if (children.isEmpty) {
      if (node.isTopLive) {
        return _TopLiveNodeCard(node: node, onTap: () => onTap(node));
      }
      return _buildCard(node);
    }
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: AppColors.white,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: AppColors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.fromLTRB(14, 0, 12, 0),
            childrenPadding: const EdgeInsets.only(bottom: 4),
            initiallyExpanded: initiallyExpanded,
            trailing: const Icon(Icons.expand_more, size: 16),
            title: Row(
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: AppColors.theme,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    node.title,
                    style: TextStyle(
                      color: AppColors.title,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            children: children.map(_buildCard).toList(),
          ),
        ),
      ),
    );
  }
}

class _NodeCard extends StatelessWidget {
  const _NodeCard({
    required this.node,
    required this.live,
    required this.onTap,
    this.progress = 0,
    this.isLastPlay = false,
  });

  final _CourseNode node;
  final bool live;
  final VoidCallback onTap;

  /// 录播播放进度 0~1
  final double progress;

  /// 是否为最近一次播放的录播
  final bool isLastPlay;

  /// 最多保留 1 位小数，如 12.5%、12%
  static String _percentText(double progress) {
    final percent = (progress * 1000).round() / 10;
    return percent == percent.truncateToDouble()
        ? percent.toStringAsFixed(0)
        : percent.toStringAsFixed(1);
  }

  @override
  Widget build(BuildContext context) {
    final canPlay = live
        ? node.liveButtonState != 0 &&
              (node.realType == 'gk' || node.isOwn == 1 || node.allowTry == 1)
        : node.isOwn == 1 || node.allowTry == 1;
    final actionTitle = live
        ? node.isLive
              ? '正在直播'
              : node.isFinished
              ? '观看回放'
              : '观看视频'
        : '观看视频';
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.theme,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.title.isEmpty ? '' : node.title,
                  style: TextStyle(color: AppColors.title, fontSize: 14),
                ),
                if (live && node.realType != 'ydy') ...[
                  const SizedBox(height: 8),
                  Text(
                    '直播时间: ${node.start}',
                    style: TextStyle(color: AppColors.content, fontSize: 12),
                  ),
                  if (node.teacher.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      node.teacher,
                      style: TextStyle(color: AppColors.content, fontSize: 12),
                    ),
                  ],
                ],
                if (!live && node.teacher.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    node.teacher,
                    style: TextStyle(color: AppColors.content, fontSize: 12),
                  ),
                ],
                if (!live && (progress > 0 || isLastPlay)) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      if (progress > 0)
                        Text(
                          '播放进度：${_percentText(progress)}%',
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 12,
                          ),
                        ),
                      if (progress > 0 && isLastPlay) const SizedBox(width: 16),
                      if (isLastPlay)
                        Text(
                          '上次播放',
                          style: TextStyle(
                            color: AppColors.theme,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          if (canPlay)
            TextButton(
              onPressed: onTap,
              style: TextButton.styleFrom(
                backgroundColor: live && node.isLive
                    ? AppColors.red
                    : AppColors.theme,
                foregroundColor: AppColors.white,
                minimumSize: const Size(64, 28),
                padding: const EdgeInsets.symmetric(horizontal: 6),
              ),
              child: Text(actionTitle, style: const TextStyle(fontSize: 10)),
            )
          else if (!live)
            SvgPicture.asset(
              'assets/images/course/lock.svg',
              width: 35,
              height: 41,
            ),
        ],
      ),
    );
  }
}

class _TopLiveNodeCard extends StatelessWidget {
  const _TopLiveNodeCard({required this.node, required this.onTap});

  final _CourseNode node;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            width: 5,
            height: 5,
            decoration: BoxDecoration(
              color: AppColors.red,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  node.title,
                  style: TextStyle(color: AppColors.title, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  '直播时间: ${node.start}',
                  style: TextStyle(color: AppColors.content, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          TextButton(
            onPressed: onTap,
            style: TextButton.styleFrom(
              backgroundColor: AppColors.red,
              foregroundColor: AppColors.white,
              minimumSize: const Size(64, 28),
              padding: const EdgeInsets.symmetric(horizontal: 6),
              shape: const StadiumBorder(),
            ),
            child: const Text('正在直播', style: TextStyle(fontSize: 10)),
          ),
        ],
      ),
    );
  }
}

class _WorkCard extends StatelessWidget {
  const _WorkCard({required this.work, required this.onTap});

  final _CourseWork work;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final status = work.statusTitle;
    final showAction =
        work.done == 0 ||
        (work.done == 1 && status.isNotEmpty && status != '未知');
    return Container(
      margin: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            work.title,
            style: TextStyle(
              color: AppColors.title,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (work.subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              work.subtitle,
              style: TextStyle(color: AppColors.content, fontSize: 12),
            ),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  '作业截止：${work.validate}',
                  style: TextStyle(
                    color: work.remind == 1 ? AppColors.red : AppColors.content,
                    fontSize: 12,
                  ),
                ),
              ),
              if (showAction)
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    backgroundColor: work.done == 0 && work.expired == 1
                        ? AppColors.grayAAA
                        : AppColors.theme,
                    foregroundColor: AppColors.white,
                    minimumSize: const Size(60, 28),
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                  ),
                  child: Text(
                    work.done == 0 ? '作业' : status,
                    style: const TextStyle(fontSize: 11),
                  ),
                ),
            ],
          ),
          if (work.teacher.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              work.teacher,
              style: TextStyle(color: AppColors.content, fontSize: 12),
            ),
          ],
        ],
      ),
    );
  }
}

enum _CourseStartType { none, join, learn, prebook, buyAgain, buy }

extension on _CourseStartType {
  String get title => switch (this) {
    .join => '加入学习',
    .learn => '开始学习',
    .prebook => '去约课',
    .buyAgain => '再次购买',
    .buy => '立即购买',
    .none => '',
  };
}

enum _DirectoryType { live, bind, work, recorded }

class _DirectoryTab {
  const _DirectoryTab(this.type, this.title);

  final _DirectoryType type;
  final String title;
}

class _CourseDetail {
  const _CourseDetail({
    required this.info,
    required this.isFavorite,
    required this.lives,
    required this.recordings,
    required this.bindLives,
  });

  final _CourseInfo info;
  final bool isFavorite;
  final List<_CourseNode> lives;
  final List<_CourseNode> recordings;
  final List<_CourseNode> bindLives;

  List<_DirectoryTab> get directoryTabs => [
    const _DirectoryTab(_DirectoryType.live, '直播'),
    if (bindLives.isNotEmpty) const _DirectoryTab(_DirectoryType.bind, '公开课'),
    if (info.hasWorks) const _DirectoryTab(_DirectoryType.work, '作业'),
    if (recordings.isNotEmpty)
      const _DirectoryTab(_DirectoryType.recorded, '录播'),
  ];

  factory _CourseDetail.fromJson(
    Map<String, dynamic> json, {
    required String courseId,
    required String courseType,
  }) {
    final course = _asMap(json['course']);
    final lessonList = _asMap(json['course_lesson_list']);
    final info = _CourseInfo.fromJson(
      course,
      fallbackId: courseId,
      fallbackType: courseType,
    );
    return _CourseDetail(
      info: info,
      isFavorite: _intFrom(json['is_collect']) == 1,
      lives: _nodeList(json['zhibo'], info: info),
      recordings: _nodeList(json['lubo'], info: info),
      bindLives: _nodeList(lessonList['list'], info: info),
    );
  }
}

class _CourseInfo {
  const _CourseInfo({
    required this.type,
    required this.id,
    required this.title,
    required this.money,
    required this.oldMoney,
    required this.validate,
    required this.picture,
    required this.period,
    required this.html,
    required this.shareUrl,
    required this.buyed,
    required this.buyedExpired,
    required this.hasFiles,
    required this.hasWorks,
    required this.refunded,
    required this.skus,
  });

  final String type;
  final String id;
  final String title;
  final String money;
  final String oldMoney;
  final String validate;
  final String picture;
  final String period;
  final String html;
  final String shareUrl;
  final int buyed;
  final int buyedExpired;
  final bool hasFiles;
  final bool hasWorks;
  final int refunded;
  final List<_CourseSku> skus;

  _CourseStartType get startType {
    if (type == 'gk') return buyed == 1 ? .learn : .join;
    if (buyed == 1) {
      return type == 'ydy' ? (refunded == 1 ? .none : .prebook) : .learn;
    }
    return buyedExpired == 1 ? .buyAgain : .buy;
  }

  factory _CourseInfo.fromJson(
    Map<String, dynamic> json, {
    required String fallbackId,
    required String fallbackType,
  }) {
    final skus = json['relevance_course'] ?? json['skus'];
    final id = _stringFrom(json, const ['id']);
    final type = _stringFrom(json, const ['type']);
    return _CourseInfo(
      type: type.isEmpty ? fallbackType : type,
      id: id.isEmpty ? fallbackId : id,
      title: _stringFrom(json, const ['title']),
      money: _stringFrom(json, const ['money']),
      oldMoney: _stringFrom(json, const ['old_money']),
      validate: _stringFrom(json, const ['validate']),
      picture: _stringFrom(json, const ['photo']),
      period: _stringFrom(json, const ['keshi']),
      html: _stringFrom(json, const ['content']),
      shareUrl: _stringFrom(json, const ['share_url']),
      buyed: _intFrom(_value(json, const ['is_buyed'])),
      buyedExpired: _intFrom(_value(json, const ['is_buyed_course'])),
      hasFiles: _intFrom(_value(json, const ['is_coures_file'])) == 1,
      hasWorks: _intFrom(_value(json, const ['is_zy'])) == 1,
      refunded: _intFrom(_value(json, const ['is_yuyue'])),
      skus: _listFrom(skus).map(_CourseSku.fromJson).toList(),
    );
  }
}

class _CourseSku {
  const _CourseSku({
    required this.id,
    required this.type,
    required this.picture,
  });

  final String id;
  final String type;
  final String picture;

  factory _CourseSku.fromJson(Object? value) {
    final json = _asMap(value);
    return _CourseSku(
      id: _stringFrom(json, const ['id']),
      type: _stringFrom(json, const ['type']),
      picture: _stringFrom(json, const ['picture']),
    );
  }
}

class _CourseNode {
  const _CourseNode({
    required this.id,
    required this.realId,
    required this.realType,
    required this.title,
    required this.teacher,
    required this.videoLink,
    required this.start,
    required this.liveButtonState,
    required this.historyCheck,
    required this.isLive,
    required this.isFinished,
    required this.allowTry,
    required this.isOwn,
    required this.isTopLive,
    required this.startTime,
    required this.children,
  });

  final String id;
  final String realId;
  final String realType;
  final String title;
  final String teacher;
  final String videoLink;
  final String start;
  final int liveButtonState;
  final String historyCheck;
  final bool isLive;
  final bool isFinished;
  final int allowTry;
  final int isOwn;
  final bool isTopLive;
  final int startTime;
  final List<_CourseNode> children;

  _CourseNode asTopLive() => _CourseNode(
    id: id,
    realId: realId,
    realType: realType,
    title: title,
    teacher: teacher,
    videoLink: videoLink,
    start: start,
    liveButtonState: liveButtonState,
    historyCheck: historyCheck,
    isLive: isLive,
    isFinished: isFinished,
    allowTry: allowTry,
    isOwn: isOwn,
    isTopLive: true,
    startTime: startTime,
    children: const [],
  );

  factory _CourseNode.fromJson(
    Object? value, {
    required int isOwn,
    required String courseId,
    required String courseType,
  }) {
    final json = _asMap(value);
    final realType = _stringFrom(json, const ['column']);
    final realId = _stringFrom(json, const ['pid']);
    final type = realType.isEmpty ? courseType : realType;
    final id = realId.isEmpty ? courseId : realId;
    final rawChildren = json['sections'];
    return _CourseNode(
      id: _stringFrom(json, const ['id']),
      realId: id,
      realType: type,
      title: _stringFrom(json, const ['title']),
      teacher: _stringFrom(json, const ['teacher_name']),
      videoLink: _stringFrom(json, const ['video_link']),
      start: _stringFrom(json, const ['start']),
      liveButtonState: _intFrom(
        _value(json, const ['zb_btn_state_zf', 'zb_btn_state']),
      ),
      historyCheck: _stringFrom(json, const [
        'get_hf_data_check',
        'hf_data_check',
      ]),
      isLive: _intFrom(json['is_zhibo']) == 1,
      isFinished: _intFrom(json['is_finish']) == 1,
      allowTry: _intFrom(json['allow_try']),
      isOwn: isOwn,
      isTopLive: false,
      startTime: _intFrom(json['start_time']),
      children: _listFrom(rawChildren)
          .map(
            (child) => _CourseNode.fromJson(
              child,
              isOwn: isOwn,
              courseId: id,
              courseType: type,
            ),
          )
          .toList(),
    );
  }
}

class _CourseWork {
  const _CourseWork({
    required this.id,
    required this.title,
    required this.teacher,
    required this.validate,
    required this.sectionId,
    required this.subtitle,
    required this.done,
    required this.expired,
    required this.remind,
    required this.state,
  });

  final String id;
  final String title;
  final String teacher;
  final String validate;
  final String sectionId;
  final String subtitle;
  final int done;
  final int expired;
  final int remind;
  final int state;

  String get statusTitle => switch (state) {
    0 => '待批阅',
    1 => '已批阅',
    2 => '已驳回',
    3 => '待审核',
    4 => '批阅中',
    _ => '未知',
  };

  factory _CourseWork.fromJson(Object? value) {
    final json = _asMap(value);
    return _CourseWork(
      id: _stringFrom(json, const ['id']),
      title: _stringFrom(json, const ['title']),
      teacher: _stringFrom(json, const ['teacher_name']),
      validate: _stringFrom(json, const ['validate']),
      sectionId: _stringFrom(json, const ['sections_id']),
      subtitle: _stringFrom(json, const ['sub_title']),
      done: _intFrom(json['zy_done']),
      expired: _intFrom(json['zy_expire']),
      remind: _intFrom(json['zy_remind']),
      state: _intFrom(json['zy_state']),
    );
  }
}

Map<String, dynamic> _asMap(Object? value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) {
    return value.map((key, value) => MapEntry(key.toString(), value));
  }
  return const {};
}

List<Object?> _listFrom(Object? value) => value is List ? value : const [];

List<_CourseNode> _nodeList(Object? value, {required _CourseInfo info}) =>
    _listFrom(value)
        .map(
          (item) => _CourseNode.fromJson(
            item,
            isOwn: info.buyed,
            courseId: info.id,
            courseType: info.type,
          ),
        )
        .toList();

Object? _value(Map<String, dynamic> json, List<String> keys) {
  for (final key in keys) {
    if (json[key] != null) return json[key];
  }
  return null;
}

String _stringFrom(Map<String, dynamic> json, List<String> keys) =>
    _value(json, keys)?.toString() ?? '';

int _intFrom(Object? value) {
  if (value is int) return value;
  return int.tryParse(value?.toString() ?? '') ?? 0;
}
