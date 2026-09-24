import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

import '../app_colors.dart';
import '../../network/md_cmd.dart';
import '../../network/md_post.dart';
import '../totast.dart';

class MDCodeField extends StatefulWidget {
  const MDCodeField({
    required this.controller,
    required this.phone,
    required this.onChanged,
    super.key,
  });

  final TextEditingController controller;
  final String phone;
  final ValueChanged<String> onChanged;

  @override
  State<MDCodeField> createState() => _MDCodeFieldState();
}

class _MDCodeFieldState extends State<MDCodeField> {
  Timer? _timer;
  int _countdown = 0;
  bool _isSending = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: widget.controller,
      onChanged: widget.onChanged,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        hintText: '请输入验证码',
        suffixIcon: PlatformTextButton(
          onPressed: _countdown > 0 || _isSending ? null : _sendCode,
          child: Text(_countdown > 0 ? '${_countdown}s' : '获取验证码'),
        ),
        filled: true,
        fillColor: AppColors.background,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }

  Future<void> _sendCode() async {
    if (widget.phone.length != 11) {
      Totast.showError('请输入11位手机号');
      return;
    }

    setState(() => _isSending = true);
    final result = await _request();
    if (!mounted) return;

    setState(() => _isSending = false);
    if (result.state != ResultState.success) {
      Totast.showError(result.error ?? '验证码发送失败');
      return;
    }

    _startCountdown();
  }

  Future<_CodeResult> _request() async {
    final completer = Completer<_CodeResult>();
    await MDPost.sendApiSession(
      cmd: MDCmd.sendCode,
      params: {'phone': widget.phone},
      completed: (state, error, data) {
        if (!completer.isCompleted) {
          completer.complete(_CodeResult(state, error?.toString()));
        }
      },
    );
    return completer.future;
  }

  void _startCountdown() {
    _timer?.cancel();
    setState(() => _countdown = 60);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      if (_countdown <= 1) {
        timer.cancel();
        setState(() => _countdown = 0);
        return;
      }
      setState(() => _countdown--);
    });
  }
}

class _CodeResult {
  const _CodeResult(this.state, this.error);

  final ResultState state;
  final String? error;
}
