import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  late final _FeedbackViewModel _viewModel;
  final _contactController = TextEditingController();
  final _contentController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = _FeedbackViewModel();
    _viewModel.addListener(_syncControllers);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_syncControllers);
    _viewModel.dispose();
    _contactController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) => PlatformScaffold(
        body: Column(
          children: [
            ColoredBox(
              color: AppColors.white,
              child: const SafeArea(
                bottom: false,
                child: SizedBox(
                  height: kToolbarHeight,
                  child: CustomAppBar(title: '意见反馈'),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.white,
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                    children: [
                      _SectionTitle('联系方式'),
                      const SizedBox(height: 16),
                      _ContactField(
                        controller: _contactController,
                        hintText: '请输入手机号或微信',
                        onChanged: _viewModel.setContact,
                      ),
                      const SizedBox(height: 16),
                      _SectionTitle('请描述您的问题'),
                      const SizedBox(height: 16),
                      _ContentField(
                        controller: _contentController,
                        hintText: '请描述您的问题',
                        onChanged: _viewModel.setContent,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: PlatformElevatedButton(
                          onPressed: _viewModel.isLoading ? null : _submit,
                          color: AppColors.theme,
                          material: (_, _) => MaterialElevatedButtonData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.theme,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.theme
                                  .withValues(alpha: 0.5),
                              disabledForegroundColor: AppColors.white,
                              shape: const StadiumBorder(),
                              elevation: 0,
                              shadowColor: AppColors.transparent,
                            ),
                          ),
                          cupertino: (_, _) => CupertinoElevatedButtonData(
                            borderRadius: BorderRadius.circular(24),
                            minimumSize: const Size(double.infinity, 48),
                            sizeStyle: CupertinoButtonSize.small,
                          ),
                          child: Text(
                            _viewModel.isLoading ? '提交中...' : '保存',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 16,
                              fontWeight: .w500,
                              decoration: .none,
                              decorationColor: AppColors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _syncControllers() {
    if (_contactController.text != _viewModel.contact) {
      _contactController.text = _viewModel.contact;
    }
    if (_contentController.text != _viewModel.content) {
      _contentController.text = _viewModel.content;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final error = await _viewModel.submitFeedback();
    if (!mounted) return;
    if (error != null) {
      Totast.showError(error);
      return;
    }

    Totast.showSuccess('反馈提交成功');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    AppRouter.pop(context, true);
  }
}

class _FeedbackViewModel extends ChangeNotifier {
  bool isLoading = false;
  String contact = '';
  String content = '';

  void setContact(String value) {
    contact = value.replaceAll(RegExp(r'\s+'), '');
    notifyListeners();
  }

  void setContent(String value) {
    content = value;
    notifyListeners();
  }

  Future<String?> submitFeedback() async {
    final validation = _validateFeedback();
    if (validation != null) return validation;

    isLoading = true;
    notifyListeners();
    Totast.showLoading();

    final result = await MDPost.sendApiSession(
      cmd: .feedback,
      params: {'contact': contact, 'content': content},
    );

    Totast.hideLoading();
    isLoading = false;
    notifyListeners();

    if (!result.isSuccess) return result.msg ?? '反馈提交失败';
    return null;
  }

  String? _validateFeedback() {
    if (content.trim().isEmpty) return '请描述您的问题';
    return null;
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.black,
        fontSize: 16,
        fontWeight: FontWeight.w600,
        decoration: TextDecoration.none,
        decorationColor: AppColors.transparent,
      ),
    );
  }
}

class _ContactField extends StatelessWidget {
  const _ContactField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        cursorColor: AppColors.theme,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 16,
          fontWeight: .w400,
          decoration: .none,
          decorationColor: AppColors.transparent,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.content,
            fontSize: 16,
            fontWeight: .w400,
            decoration: .none,
            decorationColor: AppColors.transparent,
          ),
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 10),
        ),
      ),
    );
  }
}

class _ContentField extends StatelessWidget {
  const _ContentField({
    required this.controller,
    required this.hintText,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String hintText;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextField(
        controller: controller,
        onChanged: onChanged,
        maxLines: null,
        expands: true,
        textAlignVertical: TextAlignVertical.top,
        cursorColor: AppColors.theme,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 16,
          fontWeight: .w400,
          decoration: .none,
          decorationColor: AppColors.transparent,
        ),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(
            color: AppColors.content,
            fontSize: 16,
            fontWeight: .w400,
            decoration: .none,
            decorationColor: AppColors.transparent,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.all(6),
        ),
      ),
    );
  }
}
