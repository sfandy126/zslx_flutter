import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

class NickPage extends StatefulWidget {
  const NickPage({super.key});

  @override
  State<NickPage> createState() => _NickPageState();
}

class _NickPageState extends State<NickPage> {
  late final TextEditingController _controller;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: MDUser.defualt.nick ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.white,
      appBar: const CustomAppBar(title: '修改昵称'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(30, 60, 30, 24),
          children: [
            TextField(
              controller: _controller,
              maxLength: 15,
              cursorColor: AppColors.theme,
              decoration: InputDecoration(
                counterText: '',
                hintText: '请输入昵称',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.theme,
                  foregroundColor: AppColors.white,
                  shape: const StadiumBorder(),
                ),
                child: Text(_isLoading ? '保存中...' : '保存'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    final nick = _controller.text.replaceAll(RegExp(r'\s+'), '');
    if (nick.isEmpty) {
      Totast.showError('请输入昵称');
      return;
    }
    if (nick == MDUser.defualt.nick) {
      Totast.showSuccess('昵称修改成功');
      AppRouter.pop(context, true);
      return;
    }

    setState(() => _isLoading = true);
    Totast.showLoading();
    final result = await MDPost.sendApiSession(
      cmd: .modifyNick,
      params: {'nickname': nick},
    );
    Totast.hideLoading();
    if (!mounted) return;
    setState(() => _isLoading = false);

    if (!result.isSuccess) {
      Totast.showError(result.msg ?? '昵称修改失败');
      return;
    }
    await MDUser.defualt.updateNick(nick);
    if (!mounted) return;
    Totast.showSuccess('昵称修改成功');
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (mounted) AppRouter.pop(context, true);
  }
}
