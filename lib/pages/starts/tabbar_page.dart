import 'package:flutter/material.dart';

class TabbarPage extends StatefulWidget {
  
  const TabbarPage({super.key});

  @override
  _TabbarPageState createState() => _TabbarPageState();
}

class _TabbarPageState extends State<TabbarPage> {
  int _currentIndex = 0;

  final List<Widget> _pages = const [
    Center(child: Text('首页', style: TextStyle(fontSize: 24))),
    Center(child: Text('学习', style: TextStyle(fontSize: 24))),
    Center(child: Text('我的', style: TextStyle(fontSize: 24))),
  ];

  final List<String> _titles = ['首页', '学习', '我的'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_currentIndex]),
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        selectedItemColor: Theme.of(context).primaryColor,
        unselectedItemColor: Colors.grey,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: '首页',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.school),
            label: '学习',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: '我的',
          ),
        ],
      ),
    );
  }
}
