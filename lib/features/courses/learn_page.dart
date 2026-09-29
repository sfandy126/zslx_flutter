import 'package:flutter/material.dart';

import 'course_list_page.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.school, size: 64, color: Colors.orange),
            SizedBox(height: 16),
            Text('学习内容', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}
