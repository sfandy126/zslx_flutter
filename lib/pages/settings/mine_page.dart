import 'package:flutter/material.dart';

class MinePage extends StatelessWidget {
  const MinePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('我的'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            CircleAvatar(
              radius: 40,
              child: Icon(Icons.person, size: 48),
            ),
            SizedBox(height: 16),
            Text('我的页面', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}