// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_server.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppUpdateInfo _$AppUpdateInfoFromJson(Map<String, dynamic> json) =>
    AppUpdateInfo(
      title: json['title'] as String,
      content: json['content'] as String,
      isCoerce: _isCoerceFromJson(json['is_coerce']),
      downloadUrl: json['download_url'] as String?,
    );
