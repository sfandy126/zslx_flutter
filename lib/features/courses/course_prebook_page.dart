import 'dart:math' as math;

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../../router/app_router.dart';
import '../../utils/utils.dart';
import '../../widgets/dialog.dart';

/// 一对一课程预约上课时间
class CoursePrebookPage extends StatefulWidget {
  const CoursePrebookPage({
    this.id = '',
    this.orderId = '',
    this.name = '',
    super.key,
  });

  /// 课程 id
  final String id;

  /// 订单 id
  final String orderId;

  /// 课程名称
  final String name;

  @override
  State<CoursePrebookPage> createState() => _CoursePrebookPageState();
}

class _CoursePrebookPageState extends State<CoursePrebookPage> {
  static const _startTitle = '开始时间';
  static const _endTitle = '结束时间';

  DateTime? _start;
  DateTime? _end;
  bool _submitting = false;

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
                child: MDAppBar(title: '预约上课时间', centerTitle: false),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.white,
              child: SafeArea(
                top: false,
                child: Column(
                  crossAxisAlignment: .stretch,
                  children: [
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                        children: [
                          Text(
                            '课程: ${widget.name}',
                            maxLines: 2,
                            overflow: .ellipsis,
                            style: TextStyle(
                              color: AppColors.theme,
                              fontSize: 14,
                              fontWeight: .w500,
                              decoration: .none,
                              decorationColor: AppColors.transparent,
                            ),
                          ),
                          const SizedBox(height: 20),
                          _TimeField(
                            title: _startTitle,
                            text: _start == null ? null : _format(_start!),
                            onTap: () => _selectDate(isEnd: false),
                          ),
                          const SizedBox(height: 20),
                          _TimeField(
                            title: _endTitle,
                            text: _end == null ? null : _format(_end!),
                            onTap: () => _selectDate(isEnd: true),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                      child: SizedBox(
                        height: 48,
                        child: PlatformElevatedButton(
                          onPressed: _submitting ? null : _check,
                          color: AppColors.theme,
                          material: (_, _) => MaterialElevatedButtonData(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.theme,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.theme
                                  .withValues(alpha: 0.5),
                              disabledForegroundColor: AppColors.white,
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
                            _submitting ? '预约中...' : '立即预约',
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: .w500,
                              decoration: .none,
                              decorationColor: AppColors.transparent,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  /// 与接口约定的时间格式 yyyy-MM-dd HH:mm
  static String _format(DateTime date) =>
      '${date.year}-${_two(date.month)}-${_two(date.day)} '
      '${_two(date.hour)}:${_two(date.minute)}';

  Future<void> _selectDate({required bool isEnd}) async {
    final date = await _DateTimePickerSheet.show(
      context,
      title: '选择${isEnd ? _endTitle : _startTitle}',
      initial: isEnd ? _end : _start,
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isEnd) {
        _end = date;
      } else {
        _start = date;
      }
    });
  }

  Future<bool> _requireLogin() async {
    if (MDUser.defualt.islogined) return true;
    await AppRouter.pushNamed<void>(context, RouterNames.login);
    return mounted && MDUser.defualt.islogined;
  }

  Future<void> _check() async {
    final start = _start;
    final end = _end;
    if (start == null) {
      MDTotast.showError('选择$_startTitle');
      return;
    }
    if (end == null) {
      MDTotast.showError('选择$_endTitle');
      return;
    }
    if (!await _requireLogin() || !mounted) return;
    if (!end.isAfter(start)) {
      MDTotast.showError('结束时间必须大于开始时间');
      return;
    }
    final startText = _format(start);
    final endText = _format(end);
    final confirmed = await MDDialog.show(
      context,
      content: '开始时间: $startText\n结束时间: $endText',
    );
    if (!confirmed || !mounted) return;
    await _prebook(startText, endText);
  }

  Future<void> _prebook(String startText, String endText) async {
    setState(() => _submitting = true);
    MDTotast.showLoading();
    final result = await MDPost.sendApiSession(
      cmd: .prebokYdy,
      params: {
        'order_id': widget.orderId,
        'course_id': widget.id,
        'start_time': startText,
        'end_time': endText,
      },
    );
    MDTotast.hideLoading();
    if (!mounted) return;
    setState(() => _submitting = false);
    if (!result.isSuccess) {
      MDTotast.showError(result.msg ?? '预约失败');
      return;
    }
    MDTotast.showSuccess(result.msg ?? '预约成功');
    await Future<void>.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    AppRouter.pop(context, true);
  }
}

/// 时间选择栏
class _TimeField extends StatelessWidget {
  const _TimeField({required this.title, required this.onTap, this.text});

  final String title;
  final String? text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasText = text?.isNotEmpty ?? false;
    return Column(
      crossAxisAlignment: .start,
      children: [
        Text(
          title,
          style: TextStyle(
            color: AppColors.title,
            fontSize: 14,
            fontWeight: .w500,
            decoration: .none,
            decorationColor: AppColors.transparent,
          ),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: onTap,
          behavior: HitTestBehavior.opaque,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: SizedBox(
              height: 48,
              child: Row(
                children: [
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      hasText ? text! : '选择$title',
                      maxLines: 1,
                      overflow: .ellipsis,
                      style: TextStyle(
                        color: hasText ? AppColors.title : AppColors.content,
                        fontSize: 14,
                        fontWeight: .w500,
                        decoration: .none,
                        decorationColor: AppColors.transparent,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Assets.images.public.arrowRight.svg(width: 12, height: 12),
                  const SizedBox(width: 16),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// 日期 + 时 + 分选择弹窗，范围为当前整点至 6 个月后，分钟间隔 30
class _DateTimePickerSheet extends StatefulWidget {
  const _DateTimePickerSheet({required this.title, this.initial});

  final String title;
  final DateTime? initial;

  static Future<DateTime?> show(
    BuildContext context, {
    required String title,
    DateTime? initial,
  }) {
    return showModalBottomSheet<DateTime>(
      context: context,
      useRootNavigator: true,
      backgroundColor: AppColors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _DateTimePickerSheet(title: title, initial: initial),
    );
  }

  @override
  State<_DateTimePickerSheet> createState() => _DateTimePickerSheetState();
}

class _DateTimePickerSheetState extends State<_DateTimePickerSheet> {
  static const _minuteInterval = 30;

  late final DateTime _minimum;
  late final DateTime _maximum;
  late final List<DateTime> _days;
  late DateTime _day;
  late int _hour;
  late int _minute;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _minimum = DateTime(now.year, now.month, now.day, now.hour);
    final month = DateTime(now.year, now.month + 6);
    _maximum = DateTime(
      month.year,
      month.month,
      math.min(now.day, DateUtils.getDaysInMonth(month.year, month.month)),
      now.hour,
      now.minute,
    );
    _days = [
      for (
        var day = DateUtils.dateOnly(_minimum);
        !day.isAfter(_maximum);
        day = DateTime(day.year, day.month, day.day + 1)
      )
        day,
    ];

    var initial = widget.initial ?? _minimum;
    if (initial.isBefore(_minimum) || initial.isAfter(_maximum)) {
      initial = _minimum;
    }
    _day = DateUtils.dateOnly(initial);
    _hour = initial.hour;
    _minute = initial.minute - initial.minute % _minuteInterval;
    _clamp();
  }

  List<int> get _hours {
    final first = DateUtils.isSameDay(_day, _minimum) ? _minimum.hour : 0;
    final last = DateUtils.isSameDay(_day, _maximum) ? _maximum.hour : 23;
    return [for (var hour = first; hour <= last; hour++) hour];
  }

  List<int> get _minutes {
    final isLast =
        DateUtils.isSameDay(_day, _maximum) && _hour == _maximum.hour;
    return [
      for (var minute = 0; minute < 60; minute += _minuteInterval)
        if (!isLast || minute <= _maximum.minute) minute,
    ];
  }

  /// 切换日期或小时后，将时、分修正到可选范围内
  void _clamp() {
    final hours = _hours;
    _hour = _hour.clamp(hours.first, hours.last);
    final minutes = _minutes;
    if (!minutes.contains(_minute)) _minute = minutes.last;
  }

  static String _two(int value) => value.toString().padLeft(2, '0');

  @override
  Widget build(BuildContext context) {
    final hours = _hours;
    final minutes = _minutes;
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: .min,
        children: [
          SizedBox(
            height: 52,
            child: Row(
              children: [
                _SheetButton(
                  text: '取消',
                  color: AppColors.content,
                  onTap: () => Navigator.pop(context),
                ),
                Expanded(
                  child: Text(
                    widget.title,
                    textAlign: .center,
                    style: TextStyle(
                      color: AppColors.title,
                      fontSize: 16,
                      fontWeight: .w500,
                      decoration: .none,
                      decorationColor: AppColors.transparent,
                    ),
                  ),
                ),
                _SheetButton(
                  text: '确定',
                  color: AppColors.theme,
                  onTap: () => Navigator.pop(
                    context,
                    DateTime(_day.year, _day.month, _day.day, _hour, _minute),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height: 216,
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _WheelColumn(
                    labels: [
                      for (final day in _days)
                        '${day.year}年${_two(day.month)}月${_two(day.day)}日',
                    ],
                    selectedIndex: _days.indexWhere(
                      (day) => DateUtils.isSameDay(day, _day),
                    ),
                    onSelected: (index) => setState(() {
                      _day = _days[index];
                      _clamp();
                    }),
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _WheelColumn(
                    labels: [for (final hour in hours) '${_two(hour)}时'],
                    selectedIndex: hours.indexOf(_hour),
                    onSelected: (index) {
                      final hours = _hours;
                      if (index >= hours.length) return;
                      setState(() {
                        _hour = hours[index];
                        _clamp();
                      });
                    },
                  ),
                ),
                Expanded(
                  flex: 2,
                  child: _WheelColumn(
                    labels: [for (final minute in minutes) '${_two(minute)}分'],
                    selectedIndex: minutes.indexOf(_minute),
                    onSelected: (index) {
                      final minutes = _minutes;
                      if (index >= minutes.length) return;
                      setState(() => _minute = minutes[index]);
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SheetButton extends StatelessWidget {
  const _SheetButton({
    required this.text,
    required this.color,
    required this.onTap,
  });

  final String text;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: .w500,
            decoration: .none,
            decorationColor: AppColors.transparent,
          ),
        ),
      ),
    );
  }
}

/// 滚轮列，选项变化导致选中下标改变时自动滚动到 [selectedIndex]
class _WheelColumn extends StatefulWidget {
  const _WheelColumn({
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
  });

  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;

  @override
  State<_WheelColumn> createState() => _WheelColumnState();
}

class _WheelColumnState extends State<_WheelColumn> {
  late final FixedExtentScrollController _controller =
      FixedExtentScrollController(
        initialItem: math.max(widget.selectedIndex, 0),
      );

  @override
  void didUpdateWidget(covariant _WheelColumn oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.selectedIndex < 0) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_controller.hasClients) return;
      if (_controller.selectedItem != widget.selectedIndex) {
        _controller.jumpToItem(widget.selectedIndex);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPicker(
      scrollController: _controller,
      itemExtent: 40,
      backgroundColor: AppColors.white,
      onSelectedItemChanged: widget.onSelected,
      children: [
        for (final label in widget.labels)
          Center(
            child: Text(
              label,
              maxLines: 1,
              style: TextStyle(
                color: AppColors.title,
                fontSize: 16,
                fontWeight: .w400,
                decoration: .none,
                decorationColor: AppColors.transparent,
              ),
            ),
          ),
      ],
    );
  }
}
