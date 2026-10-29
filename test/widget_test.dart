
import 'package:flutter_test/flutter_test.dart';
import 'package:zslx_flutter/main.dart';

void main() {
  testWidgets(
    'starts on StartPage and navigates to TabbarPage after 2 seconds',
    (WidgetTester tester) async {
      await tester.pumpWidget(const MyApp());
      await tester.pump(const Duration(seconds: 2));
      await tester.pumpAndSettle();
    },
  );

}
