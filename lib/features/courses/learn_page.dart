import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/widgets/custom_appbar.dart';

class LearnPage extends StatelessWidget {
  const LearnPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(title: '学习', showBackButton: false),
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
