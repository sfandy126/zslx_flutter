import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/code_field.dart';
import '../../widgets/phone_field.dart';

/// 绑定手机号
/// - 游客绑定：不传 token、userId
/// - 第三方登录绑定：必传 token、userId，绑定成功即完成登录
/// 返回 true 表示绑定成功
class BindPage extends StatefulWidget {
  const BindPage({this.token, this.userId, super.key});

  final String? token;
  final String? userId;

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String _phone = '';
  String _code = '';
  bool _isLoading = false;

  /// 是否为游客绑定手机号
  bool get _isGuest => (widget.token ?? '').isEmpty;

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const MDAppBar(title: ''),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 24),
          children: [
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                '绑定手机号体验完整功能',
                style: TextStyle(
                  color: AppColors.black,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 40),
            MDPhoneField(
              controller: _phoneController,
              onChanged: (value) => setState(() => _phone = value.trim()),
            ),
            const SizedBox(height: 10),
            MDCodeField(
              controller: _codeController,
              phone: _phone,
              onChanged: (value) => _code = value.trim(),
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.theme,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(_isLoading ? '绑定中...' : '绑定'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (_phone.isEmpty) {
      MDTotast.error('请输入手机号');
      return;
    }
    if (_phone.length != 11) {
      MDTotast.error('请输入11位的手机号');
      return;
    }
    if (_code.isEmpty) {
      MDTotast.error('请输入验证码');
      return;
    }

    setState(() => _isLoading = true);
    MDTotast.showLoading();
    final result = _isGuest
        ? await MDPost.sendApiSession(
            cmd: .bindGuest,
            params: {'phone': _phone, 'yzm': _code},
          )
        : await MDPost.sendApiSession(
            cmd: .bindMobile,
            params: {
              'mobile': _phone,
              'code': _code,
              'user_id': widget.userId ?? '',
              'token': widget.token ?? '',
            },
          );
    MDTotast.hideLoading();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!result.isSuccess) {
      MDTotast.error(result.msg ?? '绑定失败');
      return;
    }
    if (_isGuest) {
      await MDUser.defualt.updatePhone(_phone);
    } else {
      await MDUser.defualt.login(result.data);
    }
    if (!mounted) return;
    MDTotast.success(result.msg ?? '绑定成功');
    AppRouter.pop(context, true);
  }
}
