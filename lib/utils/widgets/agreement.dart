import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../app_colors.dart';
import '../../gen/assets.gen.dart';
import '../../network/md_env.dart';
import '../../router/app_router.dart';
import '../../router/router_names.dart';

class MDAgreement extends StatefulWidget {
  const MDAgreement({required this.value, required this.onChanged, super.key});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  State<MDAgreement> createState() => _MDAgreementState();
}

class _MDAgreementState extends State<MDAgreement> {
  late final TapGestureRecognizer _userAgreementRecognizer;
  late final TapGestureRecognizer _privateAgreementRecognizer;

  @override
  void initState() {
    super.initState();
    _userAgreementRecognizer = TapGestureRecognizer()
      ..onTap = _openUserAgreement;
      
    _privateAgreementRecognizer = TapGestureRecognizer()
    ..onTap = _openPrivateAgreement;
  }

  @override
  void dispose() {
    _userAgreementRecognizer.dispose();
    _privateAgreementRecognizer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        GestureDetector(
          onTap: () => widget.onChanged(!widget.value),
          child: widget.value
              ? Assets.images.public.select.svg(width: 16, height: 16)
              : Assets.images.public.unselect.svg(width: 16, height: 16),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 8),
            child: Text.rich(
              TextSpan(
                style: TextStyle(
                  color: AppColors.content,
                  fontSize: 13,
                  fontWeight: .w400,
                  decoration: TextDecoration.none,
                ),
                children: [
                  const TextSpan(text: '我已阅读并同意'),
                  TextSpan(
                    text: '《用户协议》',
                    style: TextStyle(
                      color: AppColors.theme,
                      decoration: TextDecoration.none,
                    ),
                    recognizer: _userAgreementRecognizer,
                  ),
                  const TextSpan(text: '和'),
                   TextSpan(
                    text: '《隐私政策》',
                    style: TextStyle(
                      color: AppColors.theme,
                      decoration: TextDecoration.none,
                    ),
                    recognizer: _privateAgreementRecognizer,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _openUserAgreement() {
    AppRouter.pushNamed(
      context,
      RouterNames.web,
      queryParameters: {'url': MDEnv.urlForUser, 'title': '用户协议'},
    );
  }

  void _openPrivateAgreement() {
    AppRouter.pushNamed(
      context,
      RouterNames.web,
      queryParameters: {'url': MDEnv.urlForPrivate, 'title': '隐私政策'},
    );
  }
}
