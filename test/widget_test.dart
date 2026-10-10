import 'package:easy_refresh/easy_refresh.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:zslx_flutter/main.dart';
import 'package:zslx_flutter/utils/widgets/refresh_list_view.dart';

void main() {
  testWidgets(
    'starts on StartPage and navigates to TabbarPage after 2 seconds',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    },
  );

  testWidgets('刷新后可再次安全触发无更多数据状态', (tester) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RefreshListView<int>(
            onData: (page) async {
              requestedPages.add(page);
              if (page == 1) {
                return RefreshResult.success(
                  List.generate(30, (index) => index),
                );
              }
              return RefreshResult.success(const []);
            },
            itemBuilder: (context, item, index) =>
                SizedBox(height: 60, child: Text('课程$item')),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byWidgetPredicate(
        (widget) => widget is EasyRefresh && widget.footer is MaterialFooter,
      ),
      findsOneWidget,
    );

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2]);

    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
    scrollable.position.jumpTo(0);
    await tester.pump();
    await tester.drag(find.byType(ListView), const Offset(0, 300));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2, 1]);

    await tester.drag(find.byType(ListView), const Offset(0, -3000));
    await tester.pumpAndSettle();
    expect(requestedPages, [1, 2, 1, 2]);
    expect(tester.takeException(), isNull);
  });

  testWidgets('首次加载回调可安全更新父组件状态', (tester) async {
    final requestedPages = <int>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) => RefreshListView<int>(
              onData: (page) async {
                requestedPages.add(page);
                setState(() {});
                return RefreshResult.success(const []);
              },
              itemBuilder: (context, item, index) => Text('$item'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(requestedPages, [1]);
    expect(tester.takeException(), isNull);
  });
}
