import 'package:flutter/material.dart';

import '../../utils/utils.dart';

class CourseDetailPage extends StatelessWidget {
  const CourseDetailPage({
    this.type = '',
    this.id = '',
    this.orderId = '',
    super.key,
  });

  /// 课程类型
  final String type;

  /// 课程 id
  final String id;

  final String orderId;

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
                child: CustomAppBar(title: '课程详情'),
              ),
            ),
          ),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.school, size: 64, color: Colors.orange),
                    const SizedBox(height: 16),
                    const Text('课程详情', style: TextStyle(fontSize: 24)),
                    if (id.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        '课程编号：$id',
                        style: TextStyle(color: AppColors.content),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
