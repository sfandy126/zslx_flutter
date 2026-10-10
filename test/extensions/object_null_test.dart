import 'package:flutter_test/flutter_test.dart';
import 'package:zslx_flutter/extensions/object_null.dart';
import 'package:zslx_flutter/features/courses/course_list_page.dart';

void main() {
  group('ObjectNull.mdToString', () {
    test('converts null JSON values to an empty string', () {
      final Object? value = null;

      expect(value.mdToString(), '');
    });

    test('converts non-string JSON values without throwing', () {
      expect(_convertToString(123), '123');
      expect(_convertToString(true), 'true');
    });
  });

  test('CourseItem.fromJson safely reads nullable JSON fields', () {
    final item = CourseItem.fromJson({'id': null, 'type': 3, 'title': '课程'});

    expect(item.id, '');
    expect(item.type, '3');
    expect(item.title, '课程');
  });
}

String _convertToString(Object? value) => value.mdToString();
