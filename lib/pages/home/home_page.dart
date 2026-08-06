import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.home, size: 64, color: Colors.deepPurple),
            SizedBox(height: 16),
            Text('首页内容', style: TextStyle(fontSize: 24)),
          ],
        ),
      ),
    );
  }
}