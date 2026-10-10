import 'dart:async';

import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../utils/widgets/refresh_list_view.dart';

class CourseLearnPage extends StatefulWidget {
  const CourseLearnPage({super.key});

  @override
  State<CourseLearnPage> createState() => _CourseLearnPageState();
}

class _CourseLearnPageState extends State<CourseLearnPage> {
  static const _plainTextStyle = TextStyle(decoration: TextDecoration.none);

  final _courseListKey = GlobalKey<RefreshListViewState<_LearnCourse>>();
  final List<_DateCourse> _appointments = [];

  late DateTime _selectedDate;
  _LearnFilter _filter = const _LearnFilter();
  String? _dateError;
  bool _loadingDate = true;
  int _dateRequest = 0;
  int _activeLoadingRequests = 0;
  late bool _wasLoggedIn;
  Offset _calendarOffset = const Offset(16, 80);

  void _beginLoading() {
    if (_activeLoadingRequests++ == 0) {
      Totast.showLoading();
    }
  }

  void _endLoading() {
    if (_activeLoadingRequests == 0) return;
    if (--_activeLoadingRequests == 0) {
      Totast.hideLoading();
    }
  }

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now();
    _wasLoggedIn = MDUser.defualt.islogined;
    MDUser.defualt.addListener(_onUserChanged);
  }

  @override
  void dispose() {
    MDUser.defualt.removeListener(_onUserChanged);
    super.dispose();
  }

  void _onUserChanged() {
    if (!mounted) return;
    final isLoggedIn = MDUser.defualt.islogined;
    if (isLoggedIn == _wasLoggedIn) return;
    _wasLoggedIn = isLoggedIn;
    setState(() {});
    _courseListKey.currentState?.refresh();
  }

  Future<void> _loadDateCourses() async {
    final request = ++_dateRequest;
    setState(() {
      _loadingDate = true;
      _dateError = null;
    });
    _beginLoading();
    try {
      final result = await MDPost.sendApiSession(
        cmd: .dateCourses,
        params: {'date': _dateText(_selectedDate)},
      );
      if (!mounted || request != _dateRequest) return;
      setState(() {
        if (result.isSuccess) {
          _appointments
            ..clear()
            ..addAll(
              _listFrom(result.data?['appointments']).map(_DateCourse.fromJson),
            );
          _dateError = null;
        } else {
          _dateError = result.msg ?? '课程加载失败，请下拉刷新重试';
        }
      });
    } catch (error) {
      if (!mounted || request != _dateRequest) return;
      setState(() => _dateError = '课程加载失败：$error');
    } finally {
      if (mounted && request == _dateRequest) {
        setState(() => _loadingDate = false);
      }
      _endLoading();
    }
  }

  Future<RefreshResult<_LearnCourse>> _loadCoursePage(int page) async {
    _beginLoading();
    try {
      if (page == 1) {
        await _loadDateCourses();
      }
      if (!MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn();
      }

      final result = await MDPost.sendApiSession(
        cmd: .myCourses,
        params: {
          'page': page,
          'cate_id': _filter.isFree ? 3 : 0,
          'expired': _filter.validity,
        },
      );
      if (result.isSuccess) {
        final courses = _listFrom(
          result.data?['data'],
        ).map(_LearnCourse.fromJson).toList();
        return RefreshResult.success(courses);
      }
      if (result.state == .outed || !MDUser.defualt.islogined) {
        return RefreshResult.notLoggedIn(result.msg);
      }
      return RefreshResult.failed(result.msg ?? '课程加载失败，请下拉刷新重试');
    } catch (error) {
      return RefreshResult.failed('课程加载失败：$error');
    } finally {
      _endLoading();
    }
  }

  Future<void> _openFilter() async {
    final selected = await showModalBottomSheet<_LearnFilter>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LearnFilterSheet(initialFilter: _filter),
    );
    if (!mounted || selected == null || selected == _filter) return;
    setState(() => _filter = selected);
    _courseListKey.currentState?.refresh();
  }

  Future<void> _openCalendar() async {
    final selected = await showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LearnCalendarSheet(initialDate: _selectedDate),
    );
    if (!mounted || selected == null || isSameDay(selected, _selectedDate)) {
      return;
    }
    setState(() => _selectedDate = selected);
    await _loadDateCourses();
  }

  Future<void> _openHistory() async {
    Totast.showError('学习记录功能即将开放');
  }

  Future<void> _openLogin() async {
    await AppRouter.pushNamed<bool>(context, RouterNames.login);
    if (mounted && MDUser.defualt.islogined) {
      _courseListKey.currentState?.refresh();
    }
  }

  Future<void> _openCourse(_LearnCourse course) async {
    if (!MDUser.defualt.islogined) {
      await _openLogin();
      return;
    }
    if (course.isHidden) {
      Totast.showError('该课程已下架');
      return;
    }
    if (course.id.isEmpty) return;
    await AppRouter.pushNamed<void>(
      context,
      RouterNames.courseDetail,
      queryParameters: {
        'id': course.id,
        'type': course.type,
        'orderId': course.orderId,
      },
    );
  }

  Future<void> _openAppointment(_DateCourse course) async {
    if (!MDUser.defualt.islogined) {
      await _openLogin();
      return;
    }
    Totast.showError(switch (course.liveState) {
      _LiveState.live => '直播功能即将开放',
      _LiveState.aboutToStart => '课程即将开始',
      _LiveState.playback => '回放功能即将开放',
      _ => '课程暂不可进入',
    });
  }

  Future<bool> _cancelAppointment(_DateCourse course) async {
    if (course.id.isEmpty) return false;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => DefaultTextStyle(
        style: _plainTextStyle,
        child: AlertDialog(
          title: const Text('取消约课'),
          content: const Text('确定取消这节一对一课程吗？'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('暂不取消'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('确认取消'),
            ),
          ],
        ),
      ),
    );
    if (confirmed != true || !mounted) return false;

    final result = await MDPost.sendApiSession(
      cmd: .cancelYdy,
      params: {'appointment_id': course.id},
    );
    if (!mounted) return false;
    if (!result.isSuccess) {
      Totast.showError(result.msg ?? '取消约课失败');
      return false;
    }
    setState(() {
      _appointments.removeWhere(
        (item) => item.type == 'ydy' && item.id == course.id,
      );
    });
    return true;
  }

  void _browseCourses() {
    AppRouter.pushNamed<void>(
      context,
      RouterNames.courseList,
      queryParameters: {'type': _filter.isFree ? 'gk' : 'bs'},
    );
  }

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final floatingSize = 52.0;
    final minTop = 12.0;
    final maxTop = (screen.height - floatingSize - 12).clamp(
      minTop,
      screen.height,
    );

    return PlatformScaffold(
      body: DefaultTextStyle(
        style: _plainTextStyle,
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              Column(
                children: [
                  SizedBox(
                    height: kToolbarHeight,
                    child: Row(
                      children: [
                        const SizedBox(width: 16),
                        Text(
                          '学习',
                          style: TextStyle(
                            color: AppColors.title,
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          tooltip: '学习记录',
                          onPressed: _openHistory,
                          icon: Assets.images.course.history.svg(
                            width: 24,
                            height: 24,
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                    ),
                  ),
                  Expanded(
                    child: ColoredBox(
                      color: AppColors.background,
                      child: RefreshListView<_LearnCourse>(
                        key: _courseListKey,
                        onData: _loadCoursePage,
                        itemBuilder: (context, course, index) =>
                            _LearnCourseTile(
                              course: course,
                              onTap: () => _openCourse(course),
                            ),
                        emptyBuilder: (context) => Container(
                          width: double.infinity,
                          color: AppColors.white,
                          child: _EmptyCourses(
                            isLoggedIn: MDUser.defualt.islogined,
                            onLogin: _openLogin,
                            onBrowse: _browseCourses,
                          ),
                        ),
                        header: Column(
                          children: [
                            _buildDateSection(),
                            const SizedBox(height: 12),
                            _buildCourseSectionHeader(),
                          ],
                        ),
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                      ),
                    ),
                  ),
                ],
              ),
              Positioned(
                right: _calendarOffset.dx,
                bottom: _calendarOffset.dy.clamp(12, maxTop),
                child: GestureDetector(
                  onTap: _openCalendar,
                  onPanUpdate: (details) {
                    setState(() {
                      _calendarOffset = Offset(
                        (_calendarOffset.dx - details.delta.dx).clamp(
                          12,
                          screen.width - floatingSize - 12,
                        ),
                        (_calendarOffset.dy - details.delta.dy).clamp(
                          12,
                          maxTop,
                        ),
                      );
                    });
                  },
                  child: Assets.images.course.learnCatli.svg(
                    width: floatingSize,
                    height: floatingSize,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateSection() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          SizedBox(
            height: 50,
            width: double.infinity,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  '今日课程(${_dateText(_selectedDate)})',
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
          if (_loadingDate && _appointments.isEmpty)
            const SizedBox(height: 86)
          else if (_dateError != null && _appointments.isEmpty)
            _InlineError(message: _dateError!, onRetry: _loadDateCourses)
          else if (_appointments.isEmpty)
            SizedBox(
              height: 86,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Assets.images.course.dateEmpty.svg(width: 28, height: 28),
                  const SizedBox(height: 10),
                  Text(
                    '今日暂无课程',
                    style: TextStyle(color: AppColors.title, fontSize: 14),
                  ),
                ],
              ),
            )
          else
            ..._appointments.map(_buildAppointment),
        ],
      ),
    );
  }

  Widget _buildAppointment(_DateCourse course) {
    final row = _AppointmentTile(
      course: course,
      onTap: () => _openAppointment(course),
    );
    if (course.type != 'ydy' || course.liveState != _LiveState.notStarted) {
      return row;
    }
    return Dismissible(
      key: ValueKey('appointment-${course.id}'),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) => _cancelAppointment(course),
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        color: AppColors.theme,
        child: const Text(
          '取消约课',
          style: TextStyle(color: Colors.white, fontSize: 14),
        ),
      ),
      child: row,
    );
  }

  Widget _buildCourseSectionHeader() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: SizedBox(
        height: 56,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              Text(
                '我的课程',
                style: TextStyle(
                  color: AppColors.title,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Material(
                color: const Color(0xFFF4F4F5),
                borderRadius: BorderRadius.circular(24),
                child: InkWell(
                  borderRadius: BorderRadius.circular(24),
                  onTap: _openFilter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 7,
                    ),
                    child: Row(
                      children: [
                        Assets.images.course.learnSift.svg(
                          width: 13,
                          height: 13,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '筛选',
                          style: TextStyle(
                            color: AppColors.theme,
                            fontSize: 12,
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
      ),
    );
  }
}

class _AppointmentTile extends StatelessWidget {
  const _AppointmentTile({required this.course, required this.onTap});

  final _DateCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 80,
      padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.line, width: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _CourseImage(url: course.picture, width: 100, height: 48),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  course.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        course.time,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    if (course.liveState != null)
                      _LiveStateButton(state: course.liveState!, onTap: onTap),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LiveStateButton extends StatelessWidget {
  const _LiveStateButton({required this.state, required this.onTap});

  final _LiveState state;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active =
        state == _LiveState.live ||
        state == _LiveState.aboutToStart ||
        state == _LiveState.playback;
    final color = state == _LiveState.live ? AppColors.red : AppColors.theme;
    return GestureDetector(
      onTap: state == _LiveState.expired || state == _LiveState.ended
          ? null
          : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: active ? color : AppColors.background,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          state.label,
          style: TextStyle(
            color: active ? AppColors.white : AppColors.title,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _LearnCourseTile extends StatelessWidget {
  const _LearnCourseTile({required this.course, required this.onTap});

  final _LearnCourse course;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final expired = course.expired == 1;
    final hidden = course.isHidden;
    return Material(
      color: AppColors.white,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 124,
          padding: const EdgeInsets.fromLTRB(12, 16, 12, 16),
          decoration: BoxDecoration(
            border: Border(top: BorderSide(color: AppColors.line, width: 0.7)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  _CourseImage(url: course.picture, width: 144, height: 92),
                  if (hidden || expired)
                    Positioned(
                      top: 6,
                      left: -24,
                      child: Transform.rotate(
                        angle: -0.7,
                        child: Container(
                          width: 86,
                          alignment: Alignment.center,
                          color: AppColors.content,
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            hidden ? '已下架' : '已过期',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      course.remainingHours == null
                          ? '共${course.hours}课时'
                          : '共${course.remainingHours}/${course.hours}课时',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.content, fontSize: 12),
                    ),
                    if (course.teacher.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        course.teacher,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: AppColors.content,
                          fontSize: 12,
                        ),
                      ),
                    ],
                    const Spacer(),
                    Text(
                      '有效期至:${course.validUntil.isEmpty ? '--' : course.validUntil}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: AppColors.theme, fontSize: 12),
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
}

class _CourseImage extends StatelessWidget {
  const _CourseImage({
    required this.url,
    required this.width,
    required this.height,
  });

  final String url;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox(
        width: width,
        height: height,
        child: url.isEmpty
            ? _imagePlaceholder()
            : Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, _, _) => _imagePlaceholder(),
              ),
      ),
    );
  }

  Widget _imagePlaceholder() => ColoredBox(
    color: AppColors.background,
    child: Icon(Icons.image_outlined, color: AppColors.grayAAA, size: 28),
  );
}

class _EmptyCourses extends StatelessWidget {
  const _EmptyCourses({
    required this.isLoggedIn,
    required this.onLogin,
    required this.onBrowse,
  });

  final bool isLoggedIn;
  final VoidCallback onLogin;
  final VoidCallback onBrowse;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Assets.images.course.learnEmpty.svg(width: 52, height: 52),
        const SizedBox(height: 14),
        Text(
          isLoggedIn ? '暂未购买课程' : '登录后才能查看数据',
          style: TextStyle(color: AppColors.title, fontSize: 15),
        ),
        const SizedBox(height: 8),
        Text(
          isLoggedIn ? '快去课程广场挑选适合你的课程吧' : '快去登录学习课程吧',
          style: TextStyle(color: AppColors.grayAAA, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: SizedBox(
            height: 38,
            child: FilledButton(
              onPressed: isLoggedIn ? onBrowse : onLogin,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.theme,
                padding: const EdgeInsets.symmetric(horizontal: 30),
                shape: const StadiumBorder(),
              ),
              child: Text(isLoggedIn ? '去逛逛' : '去登录'),
            ),
          ),
        ),
      ],
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 154,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.content, fontSize: 13),
            ),
            TextButton(onPressed: onRetry, child: const Text('重试')),
          ],
        ),
      ),
    );
  }
}

class _LearnFilterSheet extends StatefulWidget {
  const _LearnFilterSheet({required this.initialFilter});

  final _LearnFilter initialFilter;

  @override
  State<_LearnFilterSheet> createState() => _LearnFilterSheetState();
}

class _LearnFilterSheetState extends State<_LearnFilterSheet> {
  late bool _isFree;
  late int _validity;

  @override
  void initState() {
    super.initState();
    _isFree = widget.initialFilter.isFree;
    _validity = widget.initialFilter.validity;
  }

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomInset =
        mediaQuery.viewInsets.bottom > mediaQuery.viewPadding.bottom
        ? mediaQuery.viewInsets.bottom
        : mediaQuery.viewPadding.bottom;
    return DefaultTextStyle(
      style: _CourseLearnPageState._plainTextStyle,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _SheetTitle(title: '筛选'),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  '类型',
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Row(
                  children: [
                    _FilterOption(
                      title: '付费课',
                      selected: !_isFree,
                      onTap: () => setState(() => _isFree = false),
                    ),
                    const SizedBox(width: 12),
                    _FilterOption(
                      title: '免费课',
                      selected: _isFree,
                      onTap: () => setState(() => _isFree = true),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
                child: Text(
                  '有效期',
                  style: TextStyle(
                    color: AppColors.title,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
                child: Row(
                  children: [
                    _FilterOption(
                      title: '有效',
                      selected: _validity == 1,
                      onTap: () => setState(() => _validity = 1),
                    ),
                    const SizedBox(width: 12),
                    _FilterOption(
                      title: '过期',
                      selected: _validity == 3,
                      onTap: () => setState(() => _validity = 3),
                    ),
                    const SizedBox(width: 12),
                    _FilterOption(
                      title: '全部',
                      selected: _validity == 2,
                      onTap: () => setState(() => _validity = 2),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(
                      context,
                      _LearnFilter(isFree: _isFree, validity: _validity),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.theme,
                      shape: const StadiumBorder(),
                    ),
                    child: const Text(
                      '确认',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
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

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.title,
    required this.selected,
    required this.onTap,
  });

  final String title;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(24),
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 36),
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected ? AppColors.lightTheme : AppColors.background,
          borderRadius: BorderRadius.circular(24),
          border: selected
              ? Border.all(color: AppColors.theme, width: 1)
              : null,
        ),
        child: Text(
          title,
          style: TextStyle(
            color: selected ? AppColors.theme : AppColors.content,
            fontSize: 13,
          ),
        ),
      ),
    );
  }
}

class _LearnCalendarSheet extends StatefulWidget {
  const _LearnCalendarSheet({required this.initialDate});

  final DateTime initialDate;

  @override
  State<_LearnCalendarSheet> createState() => _LearnCalendarSheetState();
}

class _LearnCalendarSheetState extends State<_LearnCalendarSheet> {
  late DateTime _selected;
  late DateTime _focused;
  Set<DateTime> _eventDates = {};
  String? _error;
  int _request = 0;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialDate;
    _focused = widget.initialDate;
    unawaited(_loadMonth(_focused));
  }

  Future<void> _loadMonth(DateTime date) async {
    final request = ++_request;
    final result = await MDPost.sendApiSession(
      cmd: .monthDate,
      params: {'month': '${date.year}-${date.month}'},
    );
    if (!mounted || request != _request) return;
    if (!result.isSuccess) {
      setState(() {
        _eventDates = {};
        _error = result.msg ?? '日历课程标记加载失败';
      });
      return;
    }
    final rawDates = result.data?['date'];
    final dates = rawDates is List
        ? rawDates.map(_parseDate).whereType<DateTime>().toSet()
        : <DateTime>{};
    setState(() {
      _eventDates = dates;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    final height = (MediaQuery.sizeOf(context).height * 0.58).clamp(
      430.0,
      590.0,
    );
    return DefaultTextStyle(
      style: _CourseLearnPageState._plainTextStyle,
      child: SafeArea(
        top: false,
        bottom: false,
        child: Container(
          height: height + bottomInset,
          padding: EdgeInsets.only(bottom: bottomInset),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              _SheetTitle(title: '已选:${_dateText(_selected)}'),
              const Divider(height: 1, color: Color(0xFFEEEEEE)),
              SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      tooltip: '上个月',
                      onPressed: () {
                        final date = DateTime(
                          _focused.year,
                          _focused.month - 1,
                        );
                        setState(() => _focused = date);
                        unawaited(_loadMonth(date));
                      },
                      icon: const Icon(Icons.chevron_left, size: 25),
                    ),
                    Text(
                      '${_focused.year}年${_focused.month}月',
                      style: TextStyle(
                        color: AppColors.title,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    IconButton(
                      tooltip: '下个月',
                      onPressed: () {
                        final date = DateTime(
                          _focused.year,
                          _focused.month + 1,
                        );
                        setState(() => _focused = date);
                        unawaited(_loadMonth(date));
                      },
                      icon: const Icon(Icons.chevron_right, size: 25),
                    ),
                  ],
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    _error!,
                    style: TextStyle(color: AppColors.content, fontSize: 11),
                  ),
                ),
              Expanded(
                child: TableCalendar<void>(
                  firstDay: DateTime.now().subtract(
                    const Duration(days: 365 * 3),
                  ),
                  lastDay: DateTime.now().add(const Duration(days: 365 * 3)),
                  focusedDay: _focused,
                  currentDay: DateTime.now(),
                  selectedDayPredicate: (day) => isSameDay(day, _selected),
                  startingDayOfWeek: StartingDayOfWeek.sunday,
                  sixWeekMonthsEnforced: true,
                  headerVisible: false,
                  daysOfWeekHeight: 28,
                  rowHeight: 48,
                  calendarFormat: CalendarFormat.month,
                  availableGestures: AvailableGestures.horizontalSwipe,
                  onPageChanged: (focusedDay) {
                    setState(() => _focused = focusedDay);
                    unawaited(_loadMonth(focusedDay));
                  },
                  onDaySelected: (selectedDay, focusedDay) {
                    if (selectedDay.month != focusedDay.month) return;
                    Navigator.pop(context, selectedDay);
                  },
                  daysOfWeekStyle: DaysOfWeekStyle(
                    weekdayStyle: TextStyle(
                      color: AppColors.content,
                      fontSize: 13,
                    ),
                    weekendStyle: TextStyle(
                      color: AppColors.content,
                      fontSize: 13,
                    ),
                  ),
                  calendarStyle: CalendarStyle(
                    outsideDaysVisible: true,
                    defaultTextStyle: TextStyle(
                      color: AppColors.title,
                      fontSize: 14,
                    ),
                    weekendTextStyle: TextStyle(
                      color: AppColors.title,
                      fontSize: 14,
                    ),
                    outsideTextStyle: const TextStyle(
                      color: Color(0xFFCCCCCC),
                      fontSize: 14,
                    ),
                    selectedDecoration: BoxDecoration(
                      color: AppColors.theme,
                      shape: BoxShape.circle,
                    ),
                    selectedTextStyle: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    todayDecoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.transparent,
                    ),
                    todayTextStyle: TextStyle(
                      color: AppColors.title,
                      fontSize: 14,
                    ),
                    cellMargin: const EdgeInsets.all(4),
                  ),
                  calendarBuilders: CalendarBuilders(
                    dowBuilder: (context, day) {
                      const names = ['日', '一', '二', '三', '四', '五', '六'];
                      return Center(
                        child: Text(
                          names[day.weekday % 7],
                          style: TextStyle(
                            color: AppColors.content,
                            fontSize: 13,
                          ),
                        ),
                      );
                    },
                    markerBuilder: (context, day, events) {
                      if (!_eventDates.any((date) => isSameDay(date, day))) {
                        return null;
                      }
                      return Positioned(
                        bottom: 3,
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: Color(0xFF48E87A),
                            shape: BoxShape.circle,
                          ),
                        ),
                      );
                    },
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

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: Padding(
        padding: const EdgeInsets.only(left: 20, right: 8),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  color: AppColors.title,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              tooltip: '关闭',
              onPressed: () => Navigator.pop(context),
              icon: Icon(Icons.close, color: AppColors.content, size: 22),
            ),
          ],
        ),
      ),
    );
  }
}

class _LearnFilter {
  const _LearnFilter({this.isFree = false, this.validity = 1});

  final bool isFree;
  final int validity;

  @override
  bool operator ==(Object other) =>
      other is _LearnFilter &&
      other.isFree == isFree &&
      other.validity == validity;

  @override
  int get hashCode => Object.hash(isFree, validity);
}

class _DateCourse {
  const _DateCourse({
    this.type = '',
    this.id = '',
    this.title = '',
    this.picture = '',
    this.time = '',
    this.token = '',
    this.expired = 0,
    this.status = 0,
  });

  final String type;
  final String id;
  final String title;
  final String picture;
  final String time;
  final String token;
  final int expired;
  final int status;

  factory _DateCourse.fromJson(Map<String, Object?> json) {
    final hfData = json['hf_data'];
    final token =
        json['hf_token'] ??
        (hfData is Map ? hfData['hf_token'] as Object? : '');
    return _DateCourse(
      type: json['type'].mdToString(),
      id: json['id'].mdToString(),
      title: (json['course_name'] ?? json['title']).mdToString(),
      picture: (json['photo'] ?? json['picture']).mdToString(),
      time: json['time'].mdToString(),
      token: token.mdToString(),
      expired: json['expired'].mdToInt(),
      status: json['status'].mdToInt(),
    );
  }

  _LiveState? get liveState {
    if (expired == 1) return _LiveState.expired;
    if (status == 3) {
      return token.isNotEmpty ? _LiveState.playback : _LiveState.ended;
    }
    return switch (status) {
      2 => _LiveState.live,
      1 => _LiveState.aboutToStart,
      0 => _LiveState.notStarted,
      _ => null,
    };
  }
}

enum _LiveState {
  expired('已过期'),
  notStarted('未开始'),
  aboutToStart('即将开始'),
  live('直播中'),
  playback('直播回放'),
  ended('已结束');

  const _LiveState(this.label);
  final String label;
}

class _LearnCourse {
  const _LearnCourse({
    this.id = '',
    this.type = '',
    this.title = '',
    this.picture = '',
    this.validUntil = '',
    this.teacher = '',
    this.orderId = '',
    this.hours = 0,
    this.remainingHours,
    this.expired = 0,
    this.isHidden = false,
  });

  final String id;
  final String type;
  final String title;
  final String picture;
  final String validUntil;
  final String teacher;
  final String orderId;
  final int hours;
  final int? remainingHours;
  final int expired;
  final bool isHidden;

  factory _LearnCourse.fromJson(Map<String, Object?> json) {
    return _LearnCourse(
      id: (json['course_id'] ?? json['id']).mdToString(),
      type: json['type'].mdToString(),
      title: json['title'].mdToString(),
      picture: json['photo'].mdToString(),
      validUntil: json['validate'].mdToString(),
      teacher: json['teacher_name'].mdToString(),
      orderId: json['order_id'].mdToString(),
      hours: json['keshi'].mdToInt(),
      remainingHours: json['keshi_left'].mdIntOrNull,
      expired: json['expired'].mdToInt(),
      isHidden: json['is_hide'].mdToInt() == 1,
    );
  }
}

List<Map<String, dynamic>> _listFrom(Object? source) {
  if (source is! List) return const [];
  return source
      .whereType<Map>()
      .map((item) => item.map((key, value) => MapEntry(key.toString(), value)))
      .toList();
}

String _dateText(DateTime date) => '${date.year}-${date.month}-${date.day}';

DateTime? _parseDate(Object? raw) {
  final value = raw?.toString();
  if (value == null) return null;
  final parts = value.split(RegExp(r'[-/]'));
  if (parts.length < 3) return DateTime.tryParse(value);
  final year = int.tryParse(parts[0]);
  final month = int.tryParse(parts[1]);
  final day = int.tryParse(parts[2]);
  if (year == null || month == null || day == null) return null;
  return DateTime(year, month, day);
}
