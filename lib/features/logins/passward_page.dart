import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../extensions/string_rsa.dart';
import '../../router/app_router.dart';
import '../../utils/utils.dart';

class PasswardPage extends StatefulWidget {
  const PasswardPage({super.key});

  @override
  State<PasswardPage> createState() => _PasswardPageState();
}

class _PasswardPageState extends State<PasswardPage> {
  late final PasswardViewModel _viewModel;
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = PasswardViewModel();
    _viewModel.addListener(_syncControllers);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_syncControllers);
    _viewModel.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
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
                  child: CustomAppBar(title: '修改密码'),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.white,
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(40, 60, 40, 24),
                    children: [
                      _PasswordField(
                        controller: _passwordController,
                        hintText: '请输入新密码',
                        onChanged: _viewModel.setPassword,
                      ),
                      const SizedBox(height: 10),
                      _PasswordField(
                        controller: _confirmPasswordController,
                        hintText: '请再次输入密码',
                        onChanged: _viewModel.setConfirmPassword,
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
                            _viewModel.isLoading ? '提交中...' : '确定',
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
    if (_passwordController.text != _viewModel.password) {
      _passwordController.text = _viewModel.password;
    }
    if (_confirmPasswordController.text != _viewModel.confirmPassword) {
      _confirmPasswordController.text = _viewModel.confirmPassword;
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    final error = await _viewModel.modifyPassword();
    if (!mounted) return;
    if (error != null) {
      Totast.showError(error);
      return;
    }

    Totast.showSuccess('密码修改成功');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    AppRouter.pop(context, true);
  }
}

class PasswardViewModel extends ChangeNotifier {
  bool isLoading = false;
  String password = '';
  String confirmPassword = '';

  void setPassword(String value) {
    password = value.replaceAll(RegExp(r'\s+'), '');
    notifyListeners();
  }

  void setConfirmPassword(String value) {
    confirmPassword = value.replaceAll(RegExp(r'\s+'), '');
    notifyListeners();
  }

  Future<String?> modifyPassword() async {
    final validation = _validateModify();
    if (validation != null) return validation;

    isLoading = true;
    notifyListeners();
    Totast.showLoading();

    final encryptedPassword = password.mdRsaPassword();
    final encryptedConfirmPassword = confirmPassword.mdRsaPassword();
    if (encryptedPassword.isEmpty || encryptedConfirmPassword.isEmpty) {
      Totast.hideLoading();
      isLoading = false;
      notifyListeners();
      return '密码加密失败，请稍后重试';
    }

    final result = await MDPost.sendApiSession(
      cmd: .modifyPwd,
      params: {'pwd': encryptedPassword, 're_pwd': encryptedConfirmPassword},
    );

    Totast.hideLoading();
    isLoading = false;
    notifyListeners();

    if (!result.isSuccess) return result.msg ?? '密码修改失败';
    await MDUser.defualt.updateToken(result.data?['token'] as String?);
    await MDUser.updateLastPasswd(password);
    return null;
  }

  String? _validateModify() {
    if (password.isEmpty) return '请输入新密码';
    if (confirmPassword.isEmpty) return '请再次输入密码';
    if (password.length < 6) return '请设置6位以上密码，包含数字、字母组合';
    if (password != confirmPassword) return '两次输入的密码不一致，请重新输入';
    return null;
  }
}

class _PasswordField extends StatelessWidget {
  const _PasswordField({
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
        obscureText: true,
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
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(24),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    );
  }
}
