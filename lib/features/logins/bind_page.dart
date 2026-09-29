import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/code_field.dart';
import '../../utils/widgets/phone_field.dart';

class BindPage extends StatefulWidget {
  const BindPage({super.key});

  @override
  State<BindPage> createState() => _BindPageState();
}

class _BindPageState extends State<BindPage> {
  final _phoneController = TextEditingController();
  final _codeController = TextEditingController();
  String _phone = '';
  String _code = '';
  bool _isLoading = false;

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
      appBar: const CustomAppBar(title: ''),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(40, 60, 40, 24),
          children: [
            Text(
              '绑定手机号体验完整功能',
              style: TextStyle(
                color: AppColors.black,
                fontSize: 24,
                fontWeight: FontWeight.w500,
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
    if (_phone.isEmpty) {
      Totast.showError('请输入手机号');
      return;
    }
    if (_phone.length != 11) {
      Totast.showError('请输入11位的手机号');
      return;
    }
    if (_code.isEmpty) {
      Totast.showError('请输入验证码');
      return;
    }

    setState(() => _isLoading = true);
    Totast.showLoading();
    final result = await MDPost.sendApiSession(
      cmd: .bindGuest,
      params: {'phone': _phone, 'yzm': _code},
    );
    Totast.hideLoading();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!result.isSuccess) {
      Totast.showError(result.msg ?? '绑定失败');
      return;
    }
    await MDUser.defualt.updatePhone(_phone);
    if (!mounted) return;
    Totast.showSuccess(result.msg ?? '绑定成功');
    AppRouter.pop(context, true);
  }
}
