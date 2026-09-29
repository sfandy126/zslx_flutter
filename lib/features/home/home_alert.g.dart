// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_alert.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeAlertData _$HomeAlertDataFromJson(Map<String, dynamic> json) =>
    _HomeAlertData(
      id: json['id'] == null ? '' : _stringValue(json['id']),
      type: json['type'] == null ? '' : _stringValue(json['type']),
      imageUrl: json['img_url'] == null ? '' : _stringValue(json['img_url']),
      title: json['title'] == null ? '' : _stringValue(json['title']),
      expiretime: json['expiretime'] == null
          ? ''
          : _stringValue(json['expiretime']),
      url: json['url'] == null ? '' : _stringValue(json['url']),
      courseId: json['course_id'] == null
          ? ''
          : _stringValue(json['course_id']),
      courseType: json['course_type'] == null
          ? ''
          : _stringValue(json['course_type']),
    );
