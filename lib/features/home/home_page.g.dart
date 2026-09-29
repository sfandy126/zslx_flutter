// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'home_page.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HomeData _$HomeDataFromJson(Map<String, dynamic> json) => _HomeData(
  banners:
      (_readBannerList(json, 'banners') as List<dynamic>?)
          ?.map((e) => _HomeBanner.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  hotCourses:
      (_readHotCourseList(json, 'hotCourses') as List<dynamic>?)
          ?.map((e) => _HomeCourse.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

_HomeBanner _$HomeBannerFromJson(Map<String, dynamic> json) => _HomeBanner(
  imageUrl: _readBannerImage(json, 'imageUrl') == null
      ? ''
      : _stringValue(_readBannerImage(json, 'imageUrl')),
  jumpType: _readBannerJumpType(json, 'jumpType') == null
      ? ''
      : _stringValue(_readBannerJumpType(json, 'jumpType')),
  jumpId: _readBannerJumpId(json, 'jumpId') == null
      ? ''
      : _stringValue(_readBannerJumpId(json, 'jumpId')),
  link: json['link'] == null ? '' : _stringValue(json['link']),
);

_HomeCourse _$HomeCourseFromJson(Map<String, dynamic> json) => _HomeCourse(
  id: json['id'] == null ? '' : _stringValue(json['id']),
  type: json['type'] == null ? '' : _stringValue(json['type']),
  picture: _readCoursePicture(json, 'picture') == null
      ? ''
      : _stringValue(_readCoursePicture(json, 'picture')),
  title: json['title'] == null ? '' : _stringValue(json['title']),
  subtitle: json['subtitle'] == null ? '' : _stringValue(json['subtitle']),
  look: _readCourseLook(json, 'look') == null
      ? ''
      : _stringValue(_readCourseLook(json, 'look')),
  money: json['money'] == null ? '' : _stringValue(json['money']),
  oldMoney: json['old_money'] == null ? '' : _stringValue(json['old_money']),
);
