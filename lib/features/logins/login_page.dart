import 'dart:async';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/agreement.dart';
import '../../utils/widgets/code_field.dart';
import '../../utils/widgets/phone_field.dart';
import '../../utils/widgets/text_field.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  late final LoginViewModel _viewModel;
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _viewModel = LoginViewModel()..initialize();
    _viewModel.addListener(_syncControllers);
  }

  @override
  void dispose() {
    _viewModel.removeListener(_syncControllers);
    _viewModel.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _codeController.dispose();
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
                        '登录体验完整功能',
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
                    if (_viewModel.isCodeLogin)
                      MDCodeField(
                        controller: _codeController,
                        phone: _viewModel.phone,
                        onChanged: _viewModel.setCode,
                      )
                    else
                      MDTextField(
                        controller: _passwordController,
                        hintText: '请输入密码',
                        obscureText: true,
                        onChanged: _viewModel.setPassword,
                      ),
                    const SizedBox(height: 16),
                    MDAgreement(
                      value: _viewModel.agreed,
                      onChanged: _viewModel.setAgreed,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: PlatformElevatedButton(
                        onPressed: _viewModel.isLoading ? null : _login,
                        color: AppColors.theme,
                        child: Text(
                          _viewModel.isLoading ? '登录中...' : '登录',
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
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        PlatformTextButton(
                          onPressed: _viewModel.toggleLoginMode,
                          child: Text(
                            _viewModel.isCodeLogin ? '密码登录' : '验证码登录',
                            style: TextStyle(color: AppColors.title),
                          ),
                        ),
                      ],
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
    if (_passwordController.text != _viewModel.password) {
      _passwordController.text = _viewModel.password;
    }
  }

  Future<void> _login() async {
    final error = await _viewModel.login();
    if (!mounted) return;
    if (error != null) {
      Totast.showError(error);
      return;
    }
    AppRouter.pop(context, true);
  }
}

class LoginViewModel extends ChangeNotifier {
  bool isCodeLogin = false;
  bool agreed = false;
  bool isLoading = false;

  String phone = '';
  String password = '';
  String code = '';

  Future<void> initialize() async {
    final last = await MDUser.readLast();
    if (last == null) return;
    phone = last['phone'] ?? '';
    password = last['passwd'] ?? '';
    isCodeLogin = password.isEmpty;
    notifyListeners();
  }

  void setPhone(String value) {
    phone = value.trim();
    notifyListeners();
  }

  void setPassword(String value) {
    password = value;
    notifyListeners();
  }

  void setCode(String value) {
    code = value.trim();
    notifyListeners();
  }

  void toggleLoginMode() {
    isCodeLogin = !isCodeLogin;
    notifyListeners();
  }

  void setAgreed(bool value) {
    agreed = value;
    notifyListeners();
  }

  Future<String?> login() async {
    final validation = _validateLogin();
    if (validation != null) return validation;
    if (!agreed) return '请先同意用户协议和隐私政策';

    isLoading = true;
    notifyListeners();

    final params = <String, dynamic>{
      'login_lx': isCodeLogin ? 'code' : 'pwd',
      'phone': phone,
      if (isCodeLogin) 'yzm': code else 'password': password,
    };
    final result = await _request(MDCmd.login, params);
    if (result.state == ResultState.success) {
      await MDUser.defualt.login(result.data);
      await MDUser.saveLast(phone, password);
      isLoading = false;
      notifyListeners();
      return null;
    }

    isLoading = false;
    notifyListeners();
    return result.error ?? '登录失败，请稍后重试';
  }

  String? _validateLogin() {
    if (phone.length != 11) return '请输入11位手机号';
    if (isCodeLogin && code.isEmpty) return '请输入验证码';
    if (!isCodeLogin && password.isEmpty) return '请输入密码';
    return null;
  }

  Future<_LoginResult> _request(
    MDCmd command,
    Map<String, dynamic> params,
  ) async {
    final completer = Completer<_LoginResult>();
    await MDPost.sendApiSession(
      cmd: command,
      params: params,
      completed: (state, error, data) {
        if (!completer.isCompleted) {
          completer.complete(_LoginResult(state, error?.toString(), data));
        }
      },
    );
    return completer.future;
  }
}

class _LoginResult {
  const _LoginResult(this.state, this.error, this.data);

  final ResultState state;
  final String? error;
  final Map<String, dynamic>? data;
}
