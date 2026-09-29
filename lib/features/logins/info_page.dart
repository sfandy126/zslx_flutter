import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';

class InfoPage extends StatefulWidget {
  const InfoPage({super.key});

  @override
  State<InfoPage> createState() => _InfoPageState();
}

class _InfoPageState extends State<InfoPage> {
  late final InfoViewModel _viewModel;
  final _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _viewModel = InfoViewModel()..initialize();
  }

  @override
  void dispose() {
    _viewModel.dispose();
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
                  child: CustomAppBar(title: '个人信息'),
                ),
              ),
            ),
            Expanded(
              child: ColoredBox(
                color: AppColors.background,
                child: SafeArea(
                  top: false,
                  child: ListView(
                    padding: const EdgeInsets.only(top: 16),
                    children: [
                      _HeaderCell(
                        avatar: _viewModel.avatar,
                        isUploading: _viewModel.isUploadingAvatar,
                        onTap: _pickAndUploadAvatar,
                      ),
                      const SizedBox(height: 16),
                      for (var i = 0; i < InfoDataType.values.length; i++)
                        _InfoListCell(
                          type: InfoDataType.values[i],
                          value: _viewModel.valueFor(InfoDataType.values[i]),
                          showArrow: _viewModel.canEdit(InfoDataType.values[i]),
                          isFirst: i == 0,
                          isLast: i == InfoDataType.values.length - 1,
                          onTap: () => _handleTap(InfoDataType.values[i]),
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

  Future<bool> _ensureLogin() async {
    if (_viewModel.isLoggedIn) return true;
    final result = await AppRouter.pushNamed<bool>(context, RouterNames.login);
    if (result == true) {
      await _viewModel.refresh();
      return true;
    }
    return false;
  }

  Future<void> _pickAndUploadAvatar() async {
    if (!await _ensureLogin() || !mounted || _viewModel.isUploadingAvatar) {
      return;
    }
    final image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 200,
      maxHeight: 200,
      imageQuality: 85,
    );
    if (image == null) return;

    final error = await _viewModel.uploadAvatar(image.path);
    if (!mounted) return;
    if (error != null) {
      Totast.showError(error);
    }
  }

  Future<void> _handleTap(InfoDataType type) async {
    if (!await _ensureLogin() || !mounted) return;
    switch (type) {
      case InfoDataType.nick:
        final changed = await AppRouter.pushNamed<bool>(
          context,
          RouterNames.nick,
        );
        if (changed == true) await _viewModel.refresh();
      case InfoDataType.uuid:
        break;
      case InfoDataType.phone:
        if (!_viewModel.canBindPhone) return;
        final changed = await AppRouter.pushNamed<bool>(
          context,
          RouterNames.bind,
        );
        if (changed == true) await _viewModel.refresh();
      case InfoDataType.wx:
        if (_viewModel.hasBindWx) return;
        //TODO 微信绑定功能
    }
  }
}

enum InfoDataType {
  nick('昵称'),
  uuid('用户号'),
  phone('手机号'),
  wx('微信');

  const InfoDataType(this.title);

  final String title;
}

class InfoViewModel extends ChangeNotifier {
  InfoViewModel() {
    MDUser.defualt.addListener(_handleUserChanged);
  }

  bool isUploadingAvatar = false;

  MDUser get user => MDUser.defualt;
  bool get isLoggedIn => user.islogined;
  String? get avatar => user.avatar;
  bool get canBindPhone => (user.phone ?? '').isEmpty && user.guest;
  bool get hasBindWx => (user.wxOpenid ?? '').isNotEmpty;

  Future<void> initialize() async {
    await refresh();
  }

  Future<void> refresh() async {
    if (isLoggedIn) {
      await user.updateData();
    }
    notifyListeners();
  }

  String valueFor(InfoDataType type) {
    switch (type) {
      case .nick:
        return user.nick ?? '';
      case .uuid:
        return user.uid ?? '';
      case .phone:
        final phone = user.phone ?? '';
        return phone.isEmpty ? '去绑定' : phone;
      case .wx:
        final wxName = user.wxName ?? '';
        return wxName.isEmpty ? '去绑定' : wxName;
    }
  }

  bool canEdit(InfoDataType type) {
    switch (type) {
      case .nick:
        return true;
      case .uuid:
        return false;
      case .phone:
        return canBindPhone;
      case .wx:
        return !hasBindWx;
    }
  }

  Future<String?> uploadAvatar(String imagePath) async {
    if (isUploadingAvatar) return null;
    isUploadingAvatar = true;
    notifyListeners();
    Totast.showLoading();

    final result = await MDPost.sendUploadSession(
      cmd: .modifyAvatar,
      filePath: imagePath,
      name: 'avatar',
    );

    Totast.hideLoading();
    isUploadingAvatar = false;
    notifyListeners();

    if (!result.isSuccess) return result.msg ?? '头像上传失败';
    final avatar = result.data?['avatar']?.toString();
    if (avatar == null || avatar.isEmpty) return '头像上传失败';
    await user.updateAvatar(avatar);
    return null;
  }

  void _handleUserChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    MDUser.defualt.removeListener(_handleUserChanged);
    super.dispose();
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell({
    required this.avatar,
    required this.isUploading,
    required this.onTap,
  });

  final String? avatar;
  final bool isUploading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final value = avatar?.trim();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTap,
      child: SizedBox(
        height: 180,
        child: Center(
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.lightTheme,
                  border: Border.all(color: AppColors.grayAAA),
                ),
                clipBehavior: Clip.antiAlias,
                child: value == null || value.isEmpty
                    ? Assets.images.mine.defaultProfile.svg()
                    : Image.network(
                        value,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) =>
                            Assets.images.mine.defaultProfile.svg(),
                      ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppColors.theme,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.white, width: 2),
                  ),
                  child: Icon(
                    Icons.photo_camera,
                    color: AppColors.white,
                    size: 14,
                  ),
                ),
              ),
              if (isUploading)
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: AppColors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Padding(
                      padding: EdgeInsets.all(22),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoListCell extends StatelessWidget {
  const _InfoListCell({
    required this.type,
    required this.value,
    required this.showArrow,
    required this.isFirst,
    required this.isLast,
    required this.onTap,
  });

  final InfoDataType type;
  final String value;
  final bool showArrow;
  final bool isFirst;
  final bool isLast;
  final VoidCallback onTap;

  static const _radius = Radius.circular(12);

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.vertical(
      top: isFirst ? _radius : Radius.zero,
      bottom: isLast ? _radius : Radius.zero,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: showArrow ? onTap : null,
          child: DecoratedBox(
            decoration: BoxDecoration(color: AppColors.white),
            child: Padding(
              padding: const EdgeInsets.only(left: 16, top: 16, bottom: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      type.title,
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 15,
                        fontWeight: .w600,
                        decorationColor: AppColors.transparent,
                        decoration: .none,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Align(
                      alignment: Alignment.centerRight,
                      child: Text(
                        value,
                        maxLines: 1,
                        overflow: .ellipsis,
                        textAlign: .right,
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 13,
                          fontWeight: .w500,
                          decorationColor: AppColors.transparent,
                          decoration: .none,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: showArrow ? 4 : 16),
                  if (showArrow) ...[
                    Assets.images.public.arrowRight.svg(width: 12, height: 12),
                    const SizedBox(width: 16),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
