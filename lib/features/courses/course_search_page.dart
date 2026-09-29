import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/widgets/refresh_list_view.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import 'course_list_page.dart';

class CourseSearchPage extends StatefulWidget {
  const CourseSearchPage({super.key});

  @override
  State<CourseSearchPage> createState() => _CourseSearchPageState();
}

class _CourseSearchPageState extends State<CourseSearchPage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  String _keywords = '';
  Key _listKey = UniqueKey();

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(milliseconds: 250), () {
      if (mounted) _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _submit(String value) {
    final text = value.trim();
    if (text.isEmpty) {
      setState(() {
        _keywords = '';
      });
      return;
    }
    setState(() {
      _keywords = text;
      _listKey = UniqueKey();
    });
  }

  void _openCourse(CourseItem course) {
    _focusNode.unfocus();
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseDetail,
      queryParameters: {'id': course.id, 'type': course.type},
    );
  }

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: DefaultTextStyle(
        style: const TextStyle(decoration: TextDecoration.none),
        child: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      IconButton(
                        onPressed: () => AppRouter.pop(context),
                        icon: Assets.images.public.back.svg(
                          width: 24,
                          height: 24,
                        ),
                      ),
                      Expanded(
                        child: _SearchField(
                          controller: _controller,
                          focusNode: _focusNode,
                          onSubmitted: _submit,
                          onClear: () {
                            _controller.clear();
                            _submit('');
                          },
                        ),
                      ),
                      const SizedBox(width: 16),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: _buildResult(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResult() {
    if (_keywords.isEmpty) {
      return Center(
        child: Text(
          '请输入课程关键词',
          style: TextStyle(
            color: AppColors.content,
            fontSize: 14,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return RefreshListView<CourseItem>(
      key: _listKey,
      onData: (page) async {
        final result = await MDPost.sendApiSession(
          cmd: .courseList,
          params: {'page': page, 'course_type': '', 'keywords': _keywords},
        );
        if (result.isSuccess) {
          return RefreshResult.success(CourseItem.listFromData(result.data));
        }
        return RefreshResult.failed(result.msg ?? '搜索失败');
      },
      itemBuilder: (context, item, index) => CourseCard(
        course: item,
        onTap: () => _openCourse(item),
      ),
      emptyText: '未搜索到相关课程',
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.focusNode,
    required this.onSubmitted,
    required this.onClear,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 36,
      decoration: BoxDecoration(
        color: AppColors.line,
        borderRadius: BorderRadius.circular(18),
      ),
      child: TextField(
        controller: controller,
        focusNode: focusNode,
        textInputAction: TextInputAction.search,
        onSubmitted: onSubmitted,
        cursorColor: AppColors.theme,
        decoration: InputDecoration(
          hintText: '搜索课程',
          hintStyle: TextStyle(color: AppColors.grayAAA, fontSize: 14),
          prefixIcon: Icon(Icons.search, size: 20, color: AppColors.grayAAA),
          suffixIcon: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onClear,
            child: Icon(Icons.cancel, size: 18, color: AppColors.grayAAA),
          ),
          border: InputBorder.none,
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: 9),
        ),
        style: TextStyle(
          color: AppColors.title,
          fontSize: 14,
          decoration: TextDecoration.none,
        ),
      ),
    );
  }
}
