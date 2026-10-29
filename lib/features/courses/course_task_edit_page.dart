import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../network/oss.dart';
import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/image_grid.dart';

/// 作业提交页面
class CourseTaskEditPage extends StatefulWidget {
  const CourseTaskEditPage({
    required this.courseType,
    required this.sectionId,
    required this.workId,
    this.logId = '',
    this.validate = '',
    this.bjTime = '',
    this.fileName = '',
    this.fileUrl = '',
    super.key,
  });

  final String courseType;
  final String sectionId;
  final String workId;
  final String logId;
  final String validate;
  final String bjTime;
  final String fileName;
  final String fileUrl;

  @override
  State<CourseTaskEditPage> createState() => _CourseTaskEditPageState();
}

enum _AnswerMode { image, text, file }

class _CourseTaskEditPageState extends State<CourseTaskEditPage> {
  static const _maxFileBytes = 50 * 1024 * 1024;
  final _images = MDImageGridController();
  final _text = TextEditingController();
  _AnswerMode _mode = _AnswerMode.image;
  _TaskFile? _file;
  CancelToken? _fileCancel;
  bool _picking = false;
  bool _submitting = false;
  bool _public = true;

  @override
  void dispose() {
    _fileCancel?.cancel('离开提交页面');
    _images.dispose();
    _text.dispose();
    // 不清空选择器的全局缓存，避免影响仍在读取文件的上传任务。
    super.dispose();
  }

  Future<void> _pickFile() async {
    if (_picking || _submitting || _file != null) return;
    setState(() => _picking = true);
    try {
      final picked = await FilePicker.pickFile(
        type: FileType.custom,
        allowedExtensions: MDOss.fileTypes.keys.toList(),
      );
      if (!mounted || picked == null) return;
      final extension = (picked.extension ?? '').toLowerCase();
      if (!MDOss.fileTypes.containsKey(extension)) {
        MDTotast.message('仅支持 pdf、doc、docx 文件');
        return;
      }
      final path = picked.path;
      if (path == null || path.isEmpty) {
        MDTotast.error('无法读取文件，请重新选择');
        return;
      }
      final size = await File(path).length();
      if (!mounted) return;
      if (size <= 0 || size > _maxFileBytes) {
        MDTotast.message(size <= 0 ? '文件内容为空' : '文件不能超过 50MB');
        return;
      }
      final file = _TaskFile(
        name: picked.name,
        path: path,
        size: size,
        extension: extension,
      );
      setState(() => _file = file);
      unawaited(_uploadFile(file));
    } catch (error) {
      Utils.log('选择作业文件失败：$error');
      if (mounted) MDTotast.error('选择文件失败，请重试');
    } finally {
      if (mounted) setState(() => _picking = false);
    }
  }

  Future<void> _uploadFile(_TaskFile file) async {
    _fileCancel?.cancel('重新上传文件');
    final cancel = CancelToken();
    _fileCancel = cancel;
    setState(() {
      file.task = MDOssTask(index: 0, imagePath: file.path);
    });
    void apply(MDOssTask task) {
      // 删除或更换文件后，旧任务不再回写当前附件。
      if (!mounted || _file != file || _fileCancel != cancel) return;
      setState(() => file.task = task);
    }

    final task = await MDOss.uploadFile(
      file.path,
      maxBytes: _maxFileBytes,
      cancelToken: cancel,
      progress: apply,
    );
    apply(task);
  }

  void _removeFile() {
    if (_submitting) return;
    _fileCancel?.cancel('删除文件');
    _fileCancel = null;
    setState(() => _file = null);
  }

  Future<void> _submit() async {
    if (_submitting || _picking) return;
    FocusScope.of(context).unfocus();
    final params = <String, dynamic>{
      'type': widget.courseType,
      'section_id': widget.sectionId,
      'zy_id': widget.workId,
      'zy_log_id': widget.logId,
      'is_show': _public ? 1 : 2,
    };
    switch (_mode) {
      case _AnswerMode.image:
        if (_images.isEmpty) {
          MDTotast.message('请添加图片~');
          return;
        }
        if (_images.isUploading) {
          MDTotast.message('图片上传中，请耐心等待~');
          return;
        }
        if (!_images.allFinished) {
          MDTotast.message('有图片上传失败，请点击图片重新上传');
          return;
        }
        params.addAll({'answer_type': 2, 'photos': _images.urls.join(',')});
      case _AnswerMode.text:
        final text = _text.text.trim();
        if (text.replaceAll(RegExp(r'\s'), '').characters.length < 100) {
          MDTotast.message('请输入文字，字数100以上');
          return;
        }
        params.addAll({'answer_type': 1, 'zy_content': text});
      case _AnswerMode.file:
        final file = _file;
        if (file == null) {
          MDTotast.message('请选择一个 pdf 或 word 文件');
          return;
        }
        if (file.uploading) {
          MDTotast.message('文件上传中，请耐心等待~');
          return;
        }
        if (file.task.state != MDOssTaskState.success ||
            (file.task.url ?? '').isEmpty) {
          MDTotast.message('文件上传失败，请点击重新上传');
          return;
        }
        // 与作业列表的文档回显字段保持一致。
        params.addAll({
          'answer_type': file.extension == 'pdf' ? 3 : 4,
          'zy_content': file.task.url!,
          'file_name': file.name,
        });
    }
    setState(() => _submitting = true);
    var loading = false;
    try {
      if (!MDUser.defualt.islogined) {
        await AppRouter.pushNamed<void>(context, RouterNames.login);
        if (!mounted || !MDUser.defualt.islogined) return;
      }
      MDTotast.showLoading('提交中...');
      loading = true;
      final result = await MDPost.sendApiSession(
        cmd: .zySubmit,
        params: params,
      );
      MDTotast.hideLoading();
      loading = false;
      if (!mounted) return;
      if (!result.isSuccess) {
        MDTotast.error(result.msg ?? '提交失败，请重试');
        return;
      }
      MDTotast.success(result.msg ?? '提交成功');
      await Future<void>.delayed(const Duration(milliseconds: 1500));
      if (mounted) AppRouter.pop(context, true);
    } catch (error) {
      Utils.log('提交作业失败：$error');
      if (loading) MDTotast.hideLoading();
      loading = false;
      if (mounted) MDTotast.error('提交失败，请检查网络后重试');
    } finally {
      if (loading) MDTotast.hideLoading();
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 键盘弹出时不压缩页面，底部操作区固定贴屏幕底部
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: !_submitting,
      child: PlatformScaffold(
        material: (_, _) =>
            MaterialScaffoldData(resizeToAvoidBottomInset: false),
        cupertino: (_, _) =>
            CupertinoPageScaffoldData(resizeToAvoidBottomInset: false),
        body: ColoredBox(
          color: AppColors.white,
          child: DefaultTextStyle(
            style: TextStyle(
              color: AppColors.title,
              fontSize: 13,
              decoration: TextDecoration.none,
            ),
            child: GestureDetector(
              // 点击空白处收起键盘
              behavior: HitTestBehavior.opaque,
              onTap: () => FocusScope.of(context).unfocus(),
              child: SafeArea(
                child: Column(
                  children: [
                    SizedBox(
                      height: kToolbarHeight,
                      child: MDAppBar(
                        title: '提交作业',
                        onBackPressed: () {
                          if (!_submitting) AppRouter.pop(context);
                        },
                      ),
                    ),
                    Expanded(
                      child: AbsorbPointer(
                        absorbing: _submitting,
                        child: SingleChildScrollView(
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          // 键盘遮挡时补足底部留白，保证输入区可滚动到键盘上方
                          padding: EdgeInsets.fromLTRB(
                            16,
                            16,
                            16,
                            16 + keyboard,
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Text(
                                widget.bjTime.isNotEmpty
                                    ? '补交截止：${widget.bjTime}'
                                    : '作业截止：${widget.validate}',
                                style: TextStyle(
                                  color: AppColors.theme,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 10),
                              CourseTaskFileView(
                                name: widget.fileName,
                                url: widget.fileUrl,
                              ),
                              const SizedBox(height: 16),
                              Row(
                                children: [
                                  _menu(_AnswerMode.image, '添加图片'),
                                  const SizedBox(width: 24),
                                  _menu(_AnswerMode.text, '输入文字'),
                                  const SizedBox(width: 24),
                                  _menu(_AnswerMode.file, '上传文件'),
                                ],
                              ),
                              const SizedBox(height: 12),
                              _answerEditor(),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              const Expanded(child: Text('作业是否公开')),
                              SizedBox(
                                width: 50,
                                height: 33,
                                child: FittedBox(
                                  child: CupertinoSwitch(
                                    value: _public,
                                    activeTrackColor: AppColors.theme,
                                    onChanged: _submitting
                                        ? null
                                        : (value) =>
                                              setState(() => _public = value),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          GestureDetector(
                            onTap: _submit,
                            child: Container(
                              height: 48,
                              width: double.infinity,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _submitting
                                    ? AppColors.content
                                    : AppColors.theme,
                                borderRadius: BorderRadius.circular(24),
                              ),
                              child: Text(
                                _submitting ? '提交中...' : '提交',
                                style: TextStyle(
                                  color: AppColors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
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
      ),
    );
  }

  Widget _menu(_AnswerMode mode, String title) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: () {
      FocusScope.of(context).unfocus();
      setState(() => _mode = mode);
    },
    child: Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        title,
        style: TextStyle(
          color: _mode == mode ? AppColors.theme : AppColors.content,
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
      ),
    ),
  );

  Widget _answerEditor() {
    final decoration = BoxDecoration(
      border: Border.all(color: AppColors.border),
      borderRadius: BorderRadius.circular(4),
    );
    switch (_mode) {
      case _AnswerMode.image:
        return Container(
          constraints: const BoxConstraints(minHeight: 220),
          decoration: decoration,
          padding: const EdgeInsets.all(10),
          child: MDImageGrid(controller: _images, isEdit: true),
        );
      case _AnswerMode.text:
        return Container(
          height: 220,
          decoration: decoration,
          child: Material(
            color: AppColors.transparent,
            child: TextField(
              controller: _text,
              expands: true,
              maxLines: null,
              textAlignVertical: TextAlignVertical.top,
              style: TextStyle(color: AppColors.title, fontSize: 13),
              decoration: InputDecoration(
                hintText: '输入内容~（至少100字）',
                hintStyle: TextStyle(color: AppColors.content),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.all(10),
              ),
            ),
          ),
        );
      case _AnswerMode.file:
        return Container(
          constraints: const BoxConstraints(minHeight: 220),
          decoration: decoration,
          padding: const EdgeInsets.all(12),
          child: _fileEditor(),
        );
    }
  }

  Widget _fileEditor() {
    final file = _file;
    if (file == null) {
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _pickFile,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 40),
            Icon(CupertinoIcons.doc, color: AppColors.theme, size: 36),
            const SizedBox(height: 12),
            Text(
              _picking ? '正在读取文件...' : '选择文件',
              style: TextStyle(color: AppColors.theme),
            ),
            const SizedBox(height: 10),
            Text(
              '仅支持 pdf、doc、docx\n限 1 个，不超过 50MB',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.content, fontSize: 12),
            ),
          ],
        ),
      );
    }
    final failed = file.task.state == MDOssTaskState.failed;
    final percent = (file.task.progress * 100).floor();
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            (file.extension == 'pdf'
                    ? Assets.images.course.filePdf
                    : Assets.images.course.fileDocx)
                .svg(width: 36, height: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text(
                    '${(file.size / (1024 * 1024)).toStringAsFixed(2)} MB',
                    style: TextStyle(color: AppColors.content, fontSize: 12),
                  ),
                ],
              ),
            ),
            CupertinoButton(
              padding: const EdgeInsets.all(8),
              onPressed: _removeFile,
              child: Icon(
                CupertinoIcons.xmark_circle_fill,
                color: AppColors.content,
                size: 22,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (file.uploading) ...[
          LinearProgressIndicator(
            value: file.task.progress,
            color: AppColors.theme,
            backgroundColor: AppColors.border,
          ),
          const SizedBox(height: 8),
        ],
        GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: failed ? () => _uploadFile(file) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              failed
                  ? '上传失败，点击重新上传'
                  : file.uploading
                  ? '上传中 $percent%'
                  : '上传成功 100%',
              style: TextStyle(
                color: failed ? AppColors.red : AppColors.theme,
                fontSize: 13,
              ),
            ),
          ),
        ),
        if (failed && file.task.error != null)
          Text(
            file.task.error!,
            style: TextStyle(color: AppColors.content, fontSize: 12),
          ),
      ],
    );
  }
}

class _TaskFile {
  _TaskFile({
    required this.name,
    required this.path,
    required this.size,
    required this.extension,
  }) : task = MDOssTask(index: 0, imagePath: path);

  final String name;
  final String path;
  final int size;
  final String extension;
  MDOssTask task;
  bool get uploading =>
      task.state != MDOssTaskState.success &&
      task.state != MDOssTaskState.failed;
}

/// 作业题目、答案附件与老师批阅文件共用的文件卡片。
class CourseTaskFileView extends StatelessWidget {
  const CourseTaskFileView({
    required this.name,
    required this.url,
    this.isVideo = false,
    super.key,
  });

  final String name;
  final String url;
  final bool isVideo;

  String get _extension {
    final path = Uri.tryParse(url)?.path ?? url;
    final source = path.contains('.') ? path : name;
    return source.split('.').last.toLowerCase();
  }

  bool get _video =>
      isVideo || const ['mp4', 'm3u8', 'mov'].contains(_extension);

  void _open(BuildContext context) {
    final uri = Uri.tryParse(url);
    if (uri == null ||
        !const ['http', 'https'].contains(uri.scheme) ||
        uri.host.isEmpty) {
      MDTotast.error('文件地址无效，请稍后重试');
      return;
    }
    AppRouter.pushNamed<void>(
      context,
      _video ? RouterNames.video : RouterNames.web,
      queryParameters: {
        'url': url,
        'title': name,
        if (!_video) 'shareType': 'system',
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final images = Assets.images.course;
    final icon = _video
        ? images.fileVideo
        : switch (_extension) {
            'pdf' => images.filePdf,
            'doc' || 'docx' || 'wps' => images.fileDocx,
            _ => images.fileFolder,
          };
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: url.isEmpty ? null : () => _open(context),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            icon.svg(width: 36, height: 36),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                name.isEmpty ? (_video ? '老师视频点评' : '作业文件') : name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: AppColors.title, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
