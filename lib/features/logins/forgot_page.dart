import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/code_field.dart';
import '../../utils/widgets/phone_field.dart';
import '../../utils/widgets/text_field.dart';
import '../../extensions/string_rsa.dart';

class ForgotPage extends StatefulWidget {
  const ForgotPage({super.key});

  @override
  State<ForgotPage> createState() => _ForgotPageState();
}

class _ForgotPageState extends State<ForgotPage> {
  late final ForgotViewModel _viewModel;
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = ForgotViewModel();
    _viewModel.addListener(_syncControllers);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_syncControllers);
    _viewModel.dispose();
    _phoneController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _viewModel,
      builder: (context, child) => PlatformScaffold(
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 32, 16, 24),
            children: [
              SizedBox.square(
                dimension: 40,
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: PlatformIconButton(
                    onPressed: () => AppRouter.pop(context),
                    icon: Assets.images.public.back.svg(width: 24, height: 24),
                    padding: EdgeInsets.zero,
                    material: (_, _) => MaterialIconButtonData(
                      constraints: const BoxConstraints.tightFor(
                        width: 40,
                        height: 40,
                      ),
                      padding: EdgeInsets.zero,
                      iconSize: 24,
                    ),
                    cupertino: (_, _) => CupertinoIconButtonData(
                      sizeStyle: CupertinoButtonSize.small,
                      minimumSize: const Size(40, 40),
                      padding: EdgeInsets.zero,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 48),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '忘记密码',
                        style: TextStyle(
                          color: AppColors.title,
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          decoration: .none,
                          decorationColor: AppColors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(height: 40),
                    MDPhoneField(
                      controller: _phoneController,
                      onChanged: _viewModel.setPhone,
                    ),
                    const SizedBox(height: 10),
                    MDCodeField(
                      controller: _codeController,
                      phone: _viewModel.phone,
                      onChanged: _viewModel.setCode,
                    ),
                    const SizedBox(height: 10),
                    MDTextField(
                      controller: _passwordController,
                      hintText: '请输入新密码',
                      obscureText: true,
                      onChanged: _viewModel.setPassword,
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: PlatformElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _submit,
                        color: AppColors.theme,
                        child: Text(
                          _viewModel.isLoading ? '提交中...' : '确定',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: .w500,
                          ),
                        ),
                        material: (_, _) => MaterialElevatedButtonData(
                          style: ButtonStyle(
                            minimumSize: const WidgetStatePropertyAll(
                              Size.fromHeight(48),
                            ),
                            shape: WidgetStatePropertyAll(
                              RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ),
                        cupertino: (_, _) => CupertinoElevatedButtonData(
                          borderRadius: BorderRadius.circular(24),
                          sizeStyle: CupertinoButtonSize.small,
                          minimumSize: const Size(double.infinity, 48),
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
    );
  }

  void _syncControllers() {
    if (_phoneController.text != _viewModel.phone) {
      _phoneController.text = _viewModel.phone;
    }
    if (_codeController.text != _viewModel.code) {
      _codeController.text = _viewModel.code;
    }
    if (_passwordController.text != _viewModel.password) {
      _passwordController.text = _viewModel.password;
    }
  }

  Future<void> _submit() async {
    final error = await _viewModel.resetPassword();
    if (!mounted) return;
    if (error != null) {
      Totast.showError(error);
      return;
    }

    Totast.showSuccess('密码设置成功');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    AppRouter.pop(context);
  }
}

class ForgotViewModel extends ChangeNotifier {
  bool isLoading = false;

  String phone = '';
  String code = '';
  String password = '';

  void setPhone(String value) {
    phone = value.trim();
    notifyListeners();
  }

  void setCode(String value) {
    code = value.trim();
    notifyListeners();
  }

  void setPassword(String value) {
    password = value.trim();
    notifyListeners();
  }

  Future<String?> resetPassword() async {
    final validation = _validateReset();
    if (validation != null) return validation;

    isLoading = true;
    notifyListeners();

    final encryptedPassword = password.rsaPassword();
    if (encryptedPassword.isEmpty) {
      isLoading = false;
      notifyListeners();
      return '密码加密失败，请稍后重试';
    }

    final result = await _request(.forgotPwd, {
      'phone': phone,
      'yzm': code,
      'pwd': encryptedPassword,
    });

    isLoading = false;
    notifyListeners();

    if (result.state == ResultState.success) return null;
    return result.error ?? '密码设置失败，请稍后重试';
  }

  String? _validateReset() {
    if (phone.isEmpty) return '请输入手机号';
    if (phone.length != 11) return '请输入11位的手机号';
    if (code.isEmpty) return '请输入验证码';
    if (password.isEmpty) return '请输入新密码';
    if (password.length < 6) return '请设置6位以上密码，包含数字、字母组合';
    return null;
  }

  Future<_ForgotResult> _request(
    MDCmd command,
    Map<String, dynamic> params,
  ) async {
    final completer = Completer<_ForgotResult>();
    await MDPost.sendApiSession(
      cmd: command,
      params: params,
      completed: (state, error, data) {
        if (!completer.isCompleted) {
          completer.complete(_ForgotResult(state, error?.toString()));
        }
      },
    );
    return completer.future;
  }
}

class _ForgotResult {
  const _ForgotResult(this.state, this.error);

  final ResultState state;
  final String? error;
}
