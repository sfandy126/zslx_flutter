import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/dialog.dart';

class OffPage extends StatefulWidget {
  const OffPage({super.key});

  @override
  State<OffPage> createState() => _OffPageState();
}

class _OffPageState extends State<OffPage> {
  bool _isAgreed = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return PlatformScaffold(
      body: Column(
        children: [
          ColoredBox(
            color: AppColors.white,
            child: const SafeArea(
              bottom: false,
              child: SizedBox(
                height: kToolbarHeight,
                child: CustomAppBar(title: '注销账号'),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
                  child: Column(
                    children: [
                      const Expanded(child: _LogoffContent()),
                      const SizedBox(height: 20),
                      _AgreementRow(isAgreed: _isAgreed, onTap: _toggleAgreed),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: PlatformElevatedButton(
                          onPressed: _isAgreed && !_isLoading ? _commit : null,
                          color: _isAgreed
                              ? AppColors.theme
                              : HexColor.fromHex('#E8E8E8'),
                          material: (_, _) => MaterialElevatedButtonData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _isAgreed
                                  ? AppColors.theme
                                  : HexColor.fromHex('#E8E8E8'),
                              disabledBackgroundColor: HexColor.fromHex(
                                '#E8E8E8',
                              ),
                              foregroundColor: _isAgreed
                                  ? AppColors.white
                                  : HexColor.fromHex('#666666'),
                              disabledForegroundColor: HexColor.fromHex(
                                '#666666',
                              ),
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
                            _isLoading ? '提交中...' : '申请注销',
                            style: TextStyle(
                              color: _isAgreed
                                  ? AppColors.white
                                  : HexColor.fromHex('#666666'),
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
          ),
        ],
      ),
    );
  }

  void _toggleAgreed() {
    setState(() => _isAgreed = !_isAgreed);
  }

  Future<void> _commit() async {
    if (!_isAgreed || _isLoading) return;
    final confirmed = await MDDialog.show(
      context,
      title: '谨慎操作',
      content: '注销后无法恢复，确定申请注销？',
      buttons: const ['放弃注销', '确定注销'],
    );
    if (!confirmed || !mounted) return;
    await _logoff();
  }

  Future<void> _logoff() async {
    setState(() => _isLoading = true);
    Totast.showLoading();
    final result = await MDPost.sendApiSession(cmd: .logoff);
    Totast.hideLoading();
    if (!mounted) return;
    setState(() => _isLoading = false);
    if (!result.isSuccess) {
      Totast.showError(result.msg ?? '注销失败');
      return;
    }

    Totast.showSuccess(result.msg ?? '注销申请已提交');
    await MDUser.defualt.logout();
    await Future<void>.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;
    AppRouter.goNamed(context, RouterNames.main);
  }
}

class _LogoffContent extends StatelessWidget {
  const _LogoffContent();

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          _Paragraph('在申请注销前，请您仔细阅读并充分理解以下条款：'),
          _SectionTitle('1. 注销的不可逆性'),
          _Paragraph('提交注销申请后，我们将对您的账号执行注销操作。此操作不可撤销，一旦完成，您将无法再通过任何方式找回该账号。'),
          _SectionTitle('2. 将被清除的数据（包括但不限于）'),
          _Paragraph(
            '• 个人基础信息（昵称、头像、手机号）；\n• 历史浏览记录、收藏夹、历史订单；\n• 账户内的积分、优惠券、会员等级及虚拟资产。',
          ),
          _SectionTitle('3. 正在进行的交易'),
          _Paragraph(
            '如您的账号下有未完结的订单、进行中的纠纷/投诉或未到账的收益，请务必在处理完毕后申请注销，否则相关权益将自动失效。',
          ),
          _SectionTitle('4. 冷静期（如适用）'),
          _Paragraph('为确保操作安全，提交申请后将有 7 天 的审核冻结期。在此期间，若您重新登录账号，注销申请将自动取消。'),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 4),
      child: Text(
        text,
        style: TextStyle(
          color: AppColors.black,
          fontSize: 14,
          fontWeight: .w600,
          height: 1.4,
          decoration: .none,
          decorationColor: AppColors.transparent,
        ),
      ),
    );
  }
}

class _Paragraph extends StatelessWidget {
  const _Paragraph(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: AppColors.black,
        fontSize: 14,
        fontWeight: .w400,
        height: 1.45,
        decoration: .none,
        decorationColor: AppColors.transparent,
      ),
    );
  }
}

class _AgreementRow extends StatelessWidget {
  const _AgreementRow({required this.isAgreed, required this.onTap});

  final bool isAgreed;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: Row(
        children: [
          isAgreed
              ? Assets.images.public.select.svg(width: 16, height: 16)
              : Assets.images.public.unselect.svg(width: 16, height: 16),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              '申请注销表示自愿放弃账号内全部数据、资产和权益',
              maxLines: 1,
              overflow: .ellipsis,
              style: TextStyle(
                color: AppColors.content,
                fontSize: 13,
                fontWeight: .w400,
                decoration: .none,
                decorationColor: AppColors.transparent,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
