import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/refresh_list_view.dart';

/// 课程资料：资料文件目录
class CourseFolderPage extends StatefulWidget {
  const CourseFolderPage({
    required this.courseId,
    required this.courseType,
    super.key,
  });

  final String courseId;
  final String courseType;

  @override
  State<CourseFolderPage> createState() => _CourseFolderPageState();
}

class _CourseFolderPageState extends State<CourseFolderPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _listKey = GlobalKey<RefreshListViewState<_CourseFolder>>();

  Future<RefreshResult<_CourseFolder>> _loadPage(int page) async {
    if (!MDUser.defualt.islogined) return RefreshResult.notLoggedIn();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .courseFiles,
        params: {
          'course_type': widget.courseType,
          'course_id': widget.courseId,
          'page': page,
        },
      );
      if (result.isSuccess) {
        final folders = _CourseFolder.listFrom(result.data?['list']);
        return RefreshResult.success(folders, noMore: folders.isEmpty);
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '课程资料加载失败');
    } catch (error) {
      Utils.log('CourseFolderPage load failed: $error');
      return RefreshResult.failed('课程资料加载失败，请下拉刷新重试');
    }
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _listKey.currentState?.refresh();
    }
  }

  void _open(_CourseFolder folder) {
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseFiles,
      queryParameters: {
        'folderId': folder.id,
        'folderName': folder.name,
        'courseId': widget.courseId,
        'courseType': widget.courseType,
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
                  child: MDAppBar(title: '课程资料', centerTitle: false),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.white,
                child: RefreshListView<_CourseFolder>(
                  key: _listKey,
                  onData: _loadPage,
                  emptyText: '暂无课程资料',
                  failedText: '课程资料加载失败',
                  onLogin: _openLogin,
                  padding: const EdgeInsets.only(bottom: 16),
                  itemBuilder: (context, folder, index) => Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: _FolderTile(
                      folder: folder,
                      onTap: () => _open(folder),
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

class _CourseFolder {
  const _CourseFolder({required this.id, required this.name});

  factory _CourseFolder.fromJson(Map<String, dynamic> json) => _CourseFolder(
    id: json['id']?.toString() ?? '',
    name: json['name']?.toString() ?? '',
  );

  final String id;
  final String name;

  static List<_CourseFolder> listFrom(Object? source) {
    if (source is! List) return const [];
    return source
        .whereType<Map>()
        .map(
          (item) => _CourseFolder.fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }
}

class _FolderTile extends StatelessWidget {
  const _FolderTile({required this.folder, required this.onTap});

  final _CourseFolder folder;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 20),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    folder.name,
                    style: TextStyle(color: AppColors.title, fontSize: 14),
                  ),
                ),
                const SizedBox(width: 16),
                Assets.images.public.arrowRight.svg(width: 16, height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
