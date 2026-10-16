import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

/// 课程资料：指定目录下的全部资料
class CourseFilesPage extends StatefulWidget {
  const CourseFilesPage({
    required this.folderId,
    required this.folderName,
    required this.courseId,
    required this.courseType,
    super.key,
  });

  final String folderId;
  final String folderName;
  final String courseId;
  final String courseType;

  @override
  State<CourseFilesPage> createState() => _CourseFilesPageState();
}

class _CourseFilesPageState extends State<CourseFilesPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<_CourseFile>>();

  Future<RefreshResult<_CourseFile>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseFiles,
        params: {
          'pid': widget.folderId,
          'course_type': widget.courseType,
          'course_id': widget.courseId,
          'page': page,
        },
      );
      if (result.isSuccess) {
        final files = _CourseFile.listFrom(result.data?['list']);
        return RefreshResult.success(files, noMore: files.isEmpty);
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '课程资料加载失败');
    } catch (error) {
      Utils.log('CourseFilesPage load failed: $error');
      return RefreshResult.failed('课程资料加载失败，请下拉刷新重试');
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  void _open(_CourseFile file) {
    if (file.fileUrl.isEmpty) {
      MDTotast.showError('资料地址无效，请稍后重试');
      return;
    }
    AppRouter.pushNamed<void>(
      context,
      RouterNames.web,
      queryParameters: {
        'url': file.fileUrl,
        'title': file.name,
        'shareType': 'system',
      },
    );
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
                  child: MDAppBar(
                    title: widget.folderName,
                    centerTitle: false,
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.white,
                child: RefreshListView<_CourseFile>(
                  key: _listKey,
                  onData: _loadPage,
                  emptyText: '暂无课程资料',
                  failedText: '课程资料加载失败',
                  onLogin: _openLogin,
                  padding: const EdgeInsets.only(top: 12, bottom: 8),
                  itemBuilder: (context, file, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                    child: _FileTile(file: file, onTap: () => _open(file)),
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

class _CourseFile {
  const _CourseFile({
    required this.id,
    required this.name,
    required this.addTime,
    required this.fileUrl,
  });

  factory _CourseFile.fromJson(Map<String, dynamic> json) => _CourseFile(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
    addTime: json['add_time']?.toString() ?? '',
    fileUrl: json['file_url']?.toString() ?? '',
  );

  final String id;
  final String name;
  final String addTime;
  final String fileUrl;

  static List<_CourseFile> listFrom(Object? source) {
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map(
          (item) => _CourseFile.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  /// 按文件扩展名匹配图标，未知类型返回 null
  SvgGenImage? get icon {
    final path = Uri.tryParse(fileUrl)?.path ?? fileUrl;
    final dot = path.lastIndexOf('.');
    final extension = dot < 0 ? '' : path.substring(dot + 1).toLowerCase();
    final images = Assets.images.course;
    return switch (extension) {
      'pdf' => images.filePdf,
      'doc' || 'docx' || 'wps' => images.fileDocx,
      'mp4' || 'm3u8' || 'mov' => images.fileVideo,
      _ => null,
    };
  }
}

class _FileTile extends StatelessWidget {
  const _FileTile({required this.file, required this.onTap});

  final _CourseFile file;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const iconSize = 36.0;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
              child: Row(
                children: [
                  SizedBox.square(
                    dimension: iconSize,
                    child: file.icon?.svg(width: iconSize, height: iconSize),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      file.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.title, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '上传时间: ${file.addTime}',
            style: TextStyle(color: AppColors.content, fontSize: 12),
          ),
        ],
      ),
    );
  }
}
