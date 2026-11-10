import 'package:flutter/material.dart';
import 'package:flutter_easyloading/flutter_easyloading.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:zslx_flutter/utils/totast.dart';

void main() {
  testWidgets('purchase result replaces loading even with a stale count', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(builder: EasyLoading.init(), home: const Scaffold()),
    );

    MDTotast.showLoading('商品购买中...');
    MDTotast.showLoading('商品购买中...');
    await tester.pump();
    expect(find.text('商品购买中...'), findsOneWidget);

    MDTotast.completeLoading(.success, '购买成功');
    await tester.pump();

    expect(find.text('商品购买中...'), findsNothing);
    expect(find.text('购买成功'), findsOneWidget);
  });
}
