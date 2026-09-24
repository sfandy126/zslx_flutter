import 'package:flutter/material.dart';
import 'package:zslx_flutter/utils/utils.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  bool _loading = true;
  String _message = '正在加载首页数据...';
  Map<String, dynamic>? _data;

  @override
  void initState() {
    super.initState();
    _loadHome();
  }

  Future<void> _loadHome() async {
    await MDPost.sendApiSession(
      cmd: MDCmd.home,
      params: const {},
      completed: (state, error, data) {
        if (!mounted) {
          return;
        }

        setState(() {
          _loading = false;
          _message = error?.toString() ?? '首页数据加载完成';
          _data = data ?? <String, dynamic>{};
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('首页'),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(Icons.home, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 16),
            Text(
              _loading ? '正在加载...' : _message,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 12),
            if (_data != null && _data!.isNotEmpty)
              Expanded(
                child: SingleChildScrollView(
                  child: Text(
                    _data.toString(),
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              )
            else if (!_loading)
              const Text('暂无首页数据'),
          ],
        ),
      ),
    );
  }
}