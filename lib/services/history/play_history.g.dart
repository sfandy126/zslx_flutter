// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'play_history.dart';

// **************************************************************************
// IsarCollectionGenerator
// **************************************************************************

// coverage:ignore-file
// ignore_for_file: duplicate_ignore, non_constant_identifier_names, constant_identifier_names, invalid_use_of_protected_member, unnecessary_cast, prefer_const_constructors, lines_longer_than_80_chars, require_trailing_commas, inference_failure_on_function_invocation, unnecessary_parenthesis, unnecessary_raw_strings, unnecessary_null_checks, join_return_with_assignment, prefer_final_locals, avoid_js_rounded_ints, avoid_positional_boolean_parameters, always_specify_types, experimental_member_use

extension GetPlayHistoryCollection on Isar {
  IsarCollection<PlayHistory> get playHistorys => this.collection();
}

const PlayHistorySchema = CollectionSchema(
  name: r'PlayHistory',
  id: 6118132194974220027,
  properties: {
    r'cId': PropertySchema(id: 0, name: r'cId', type: IsarType.string),
    r'cName': PropertySchema(id: 1, name: r'cName', type: IsarType.string),
    r'cPhoto': PropertySchema(id: 2, name: r'cPhoto', type: IsarType.string),
    r'cType': PropertySchema(id: 3, name: r'cType', type: IsarType.string),
    r'createTime': PropertySchema(
      id: 4,
      name: r'createTime',
      type: IsarType.dateTime,
    ),
    r'key': PropertySchema(id: 5, name: r'key', type: IsarType.string),
    r'sCid': PropertySchema(id: 6, name: r'sCid', type: IsarType.string),
    r'sId': PropertySchema(id: 7, name: r'sId', type: IsarType.string),
    r'sName': PropertySchema(id: 8, name: r'sName', type: IsarType.string),
    r'sType': PropertySchema(id: 9, name: r'sType', type: IsarType.string),
    r'source': PropertySchema(id: 10, name: r'source', type: IsarType.long),
    r'time': PropertySchema(id: 11, name: r'time', type: IsarType.long),
    r'total': PropertySchema(id: 12, name: r'total', type: IsarType.long),
    r'updateTime': PropertySchema(
      id: 13,
      name: r'updateTime',
      type: IsarType.dateTime,
    ),
    r'url': PropertySchema(id: 14, name: r'url', type: IsarType.string),
    r'userId': PropertySchema(id: 15, name: r'userId', type: IsarType.string),
  },

  estimateSize: _playHistoryEstimateSize,
  serialize: _playHistorySerialize,
  deserialize: _playHistoryDeserialize,
  deserializeProp: _playHistoryDeserializeProp,
  idName: r'id',
  indexes: {
    r'key': IndexSchema(
      id: -4906094122524121629,
      name: r'key',
      unique: true,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'key',
          type: IndexType.hash,
          caseSensitive: true,
        ),
      ],
    ),
    r'userId_updateTime': IndexSchema(
      id: -5111163695106856734,
      name: r'userId_updateTime',
      unique: false,
      replace: false,
      properties: [
        IndexPropertySchema(
          name: r'userId',
          type: IndexType.hash,
          caseSensitive: true,
        ),
        IndexPropertySchema(
          name: r'updateTime',
          type: IndexType.value,
          caseSensitive: false,
        ),
      ],
    ),
  },
  links: {},
  embeddedSchemas: {},

  getId: _playHistoryGetId,
  getLinks: _playHistoryGetLinks,
  attach: _playHistoryAttach,
  version: '3.4.1',
);

int _playHistoryEstimateSize(
  PlayHistory object,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  var bytesCount = offsets.last;
  bytesCount += 3 + object.cId.length * 3;
  bytesCount += 3 + object.cName.length * 3;
  bytesCount += 3 + object.cPhoto.length * 3;
  bytesCount += 3 + object.cType.length * 3;
  bytesCount += 3 + object.key.length * 3;
  bytesCount += 3 + object.sCid.length * 3;
  bytesCount += 3 + object.sId.length * 3;
  bytesCount += 3 + object.sName.length * 3;
  bytesCount += 3 + object.sType.length * 3;
  bytesCount += 3 + object.url.length * 3;
  bytesCount += 3 + object.userId.length * 3;
  return bytesCount;
}

void _playHistorySerialize(
  PlayHistory object,
  IsarWriter writer,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  writer.writeString(offsets[0], object.cId);
  writer.writeString(offsets[1], object.cName);
  writer.writeString(offsets[2], object.cPhoto);
  writer.writeString(offsets[3], object.cType);
  writer.writeDateTime(offsets[4], object.createTime);
  writer.writeString(offsets[5], object.key);
  writer.writeString(offsets[6], object.sCid);
  writer.writeString(offsets[7], object.sId);
  writer.writeString(offsets[8], object.sName);
  writer.writeString(offsets[9], object.sType);
  writer.writeLong(offsets[10], object.source);
  writer.writeLong(offsets[11], object.time);
  writer.writeLong(offsets[12], object.total);
  writer.writeDateTime(offsets[13], object.updateTime);
  writer.writeString(offsets[14], object.url);
  writer.writeString(offsets[15], object.userId);
}

PlayHistory _playHistoryDeserialize(
  Id id,
  IsarReader reader,
  List<int> offsets,
  Map<Type, List<int>> allOffsets,
) {
  final object = PlayHistory();
  object.cId = reader.readString(offsets[0]);
  object.cName = reader.readString(offsets[1]);
  object.cPhoto = reader.readString(offsets[2]);
  object.cType = reader.readString(offsets[3]);
  object.createTime = reader.readDateTime(offsets[4]);
  object.id = id;
  object.key = reader.readString(offsets[5]);
  object.sCid = reader.readString(offsets[6]);
  object.sId = reader.readString(offsets[7]);
  object.sName = reader.readString(offsets[8]);
  object.sType = reader.readString(offsets[9]);
  object.source = reader.readLong(offsets[10]);
  object.time = reader.readLong(offsets[11]);
  object.total = reader.readLong(offsets[12]);
  object.updateTime = reader.readDateTime(offsets[13]);
  object.url = reader.readString(offsets[14]);
  object.userId = reader.readString(offsets[15]);
  return object;
}

P _playHistoryDeserializeProp<P>(
  IsarReader reader,
  int propertyId,
  int offset,
  Map<Type, List<int>> allOffsets,
) {
  switch (propertyId) {
    case 0:
      return (reader.readString(offset)) as P;
    case 1:
      return (reader.readString(offset)) as P;
    case 2:
      return (reader.readString(offset)) as P;
    case 3:
      return (reader.readString(offset)) as P;
    case 4:
      return (reader.readDateTime(offset)) as P;
    case 5:
      return (reader.readString(offset)) as P;
    case 6:
      return (reader.readString(offset)) as P;
    case 7:
      return (reader.readString(offset)) as P;
    case 8:
      return (reader.readString(offset)) as P;
    case 9:
      return (reader.readString(offset)) as P;
    case 10:
      return (reader.readLong(offset)) as P;
    case 11:
      return (reader.readLong(offset)) as P;
    case 12:
      return (reader.readLong(offset)) as P;
    case 13:
      return (reader.readDateTime(offset)) as P;
    case 14:
      return (reader.readString(offset)) as P;
    case 15:
      return (reader.readString(offset)) as P;
    default:
      throw IsarError('Unknown property with id $propertyId');
  }
}

Id _playHistoryGetId(PlayHistory object) {
  return object.id;
}

List<IsarLinkBase<dynamic>> _playHistoryGetLinks(PlayHistory object) {
  return [];
}

void _playHistoryAttach(
  IsarCollection<dynamic> col,
  Id id,
  PlayHistory object,
) {
  object.id = id;
}

extension PlayHistoryByIndex on IsarCollection<PlayHistory> {
  Future<PlayHistory?> getByKey(String key) {
    return getByIndex(r'key', [key]);
  }

  PlayHistory? getByKeySync(String key) {
    return getByIndexSync(r'key', [key]);
  }

  Future<bool> deleteByKey(String key) {
    return deleteByIndex(r'key', [key]);
  }

  bool deleteByKeySync(String key) {
    return deleteByIndexSync(r'key', [key]);
  }

  Future<List<PlayHistory?>> getAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndex(r'key', values);
  }

  List<PlayHistory?> getAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return getAllByIndexSync(r'key', values);
  }

  Future<int> deleteAllByKey(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndex(r'key', values);
  }

  int deleteAllByKeySync(List<String> keyValues) {
    final values = keyValues.map((e) => [e]).toList();
    return deleteAllByIndexSync(r'key', values);
  }

  Future<Id> putByKey(PlayHistory object) {
    return putByIndex(r'key', object);
  }

  Id putByKeySync(PlayHistory object, {bool saveLinks = true}) {
    return putByIndexSync(r'key', object, saveLinks: saveLinks);
  }

  Future<List<Id>> putAllByKey(List<PlayHistory> objects) {
    return putAllByIndex(r'key', objects);
  }

  List<Id> putAllByKeySync(List<PlayHistory> objects, {bool saveLinks = true}) {
    return putAllByIndexSync(r'key', objects, saveLinks: saveLinks);
  }
}

extension PlayHistoryQueryWhereSort
    on QueryBuilder<PlayHistory, PlayHistory, QWhere> {
  QueryBuilder<PlayHistory, PlayHistory, QAfterWhere> anyId() {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(const IdWhereClause.any());
    });
  }
}

extension PlayHistoryQueryWhere
    on QueryBuilder<PlayHistory, PlayHistory, QWhereClause> {
  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> idEqualTo(Id id) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(IdWhereClause.between(lower: id, upper: id));
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> idNotEqualTo(
    Id id,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            )
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            );
      } else {
        return query
            .addWhereClause(
              IdWhereClause.greaterThan(lower: id, includeLower: false),
            )
            .addWhereClause(
              IdWhereClause.lessThan(upper: id, includeUpper: false),
            );
      }
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> idGreaterThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.greaterThan(lower: id, includeLower: include),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> idLessThan(
    Id id, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.lessThan(upper: id, includeUpper: include),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> idBetween(
    Id lowerId,
    Id upperId, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IdWhereClause.between(
          lower: lowerId,
          includeLower: includeLower,
          upper: upperId,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> keyEqualTo(
    String key,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(indexName: r'key', value: [key]),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause> keyNotEqualTo(
    String key,
  ) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [key],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'key',
                lower: [],
                upper: [key],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdEqualToAnyUpdateTime(String userId) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'userId_updateTime',
          value: [userId],
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdNotEqualToAnyUpdateTime(String userId) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [userId],
                includeLower: false,
                upper: [],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [],
                upper: [userId],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdUpdateTimeEqualTo(String userId, DateTime updateTime) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.equalTo(
          indexName: r'userId_updateTime',
          value: [userId, updateTime],
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdEqualToUpdateTimeNotEqualTo(String userId, DateTime updateTime) {
    return QueryBuilder.apply(this, (query) {
      if (query.whereSort == Sort.asc) {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [userId],
                upper: [userId, updateTime],
                includeUpper: false,
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [userId, updateTime],
                includeLower: false,
                upper: [userId],
              ),
            );
      } else {
        return query
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [userId, updateTime],
                includeLower: false,
                upper: [userId],
              ),
            )
            .addWhereClause(
              IndexWhereClause.between(
                indexName: r'userId_updateTime',
                lower: [userId],
                upper: [userId, updateTime],
                includeUpper: false,
              ),
            );
      }
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdEqualToUpdateTimeGreaterThan(
    String userId,
    DateTime updateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'userId_updateTime',
          lower: [userId, updateTime],
          includeLower: include,
          upper: [userId],
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdEqualToUpdateTimeLessThan(
    String userId,
    DateTime updateTime, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'userId_updateTime',
          lower: [userId],
          upper: [userId, updateTime],
          includeUpper: include,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterWhereClause>
  userIdEqualToUpdateTimeBetween(
    String userId,
    DateTime lowerUpdateTime,
    DateTime upperUpdateTime, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addWhereClause(
        IndexWhereClause.between(
          indexName: r'userId_updateTime',
          lower: [userId, lowerUpdateTime],
          includeLower: includeLower,
          upper: [userId, upperUpdateTime],
          includeUpper: includeUpper,
        ),
      );
    });
  }
}

extension PlayHistoryQueryFilter
    on QueryBuilder<PlayHistory, PlayHistory, QFilterCondition> {
  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cId', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cId', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cName', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cName', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cPhotoEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cPhoto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cPhotoGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cPhoto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cPhotoLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cPhoto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cPhotoBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cPhoto',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cPhotoStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cPhoto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cPhotoEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cPhoto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cPhotoContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cPhoto',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cPhotoMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cPhoto',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cPhotoIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cPhoto', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cPhotoIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cPhoto', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'cType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'cType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'cType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'cType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'cType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'cType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'cType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'cType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> cTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'cType', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  cTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'cType', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  createTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'createTime', value: value),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  createTimeGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'createTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  createTimeLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'createTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  createTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'createTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> idEqualTo(
    Id value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'id', value: value),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> idGreaterThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> idLessThan(
    Id value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'id',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> idBetween(
    Id lower,
    Id upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'id',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'key',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'key',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'key',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> keyIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  keyIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'key', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sCid',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sCid',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sCid',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sCidIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sCid', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sCidIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sCid', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sId', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sId', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sNameGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sName',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sName',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sName',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sNameIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sName', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sNameIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sName', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'sType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sTypeGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'sType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'sType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'sType',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'sType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'sType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'sType',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'sType',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sTypeIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'sType', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sTypeIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'sType', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sourceEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'source', value: value),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  sourceGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sourceLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'source',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> sourceBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'source',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> timeEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'time', value: value),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> timeGreaterThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'time',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> timeLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'time',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> timeBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'time',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> totalEqualTo(
    int value,
  ) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'total', value: value),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  totalGreaterThan(int value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'total',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> totalLessThan(
    int value, {
    bool include = false,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'total',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> totalBetween(
    int lower,
    int upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'total',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  updateTimeEqualTo(DateTime value) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'updateTime', value: value),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  updateTimeGreaterThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'updateTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  updateTimeLessThan(DateTime value, {bool include = false}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'updateTime',
          value: value,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  updateTimeBetween(
    DateTime lower,
    DateTime upper, {
    bool includeLower = true,
    bool includeUpper = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'updateTime',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'url',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlStartsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'url',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'url',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> urlIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  urlIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'url', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> userIdEqualTo(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  userIdGreaterThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> userIdLessThan(
    String value, {
    bool include = false,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.lessThan(
          include: include,
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> userIdBetween(
    String lower,
    String upper, {
    bool includeLower = true,
    bool includeUpper = true,
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.between(
          property: r'userId',
          lower: lower,
          includeLower: includeLower,
          upper: upper,
          includeUpper: includeUpper,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  userIdStartsWith(String value, {bool caseSensitive = true}) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.startsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> userIdEndsWith(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.endsWith(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> userIdContains(
    String value, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.contains(
          property: r'userId',
          value: value,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition> userIdMatches(
    String pattern, {
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.matches(
          property: r'userId',
          wildcard: pattern,
          caseSensitive: caseSensitive,
        ),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  userIdIsEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.equalTo(property: r'userId', value: ''),
      );
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterFilterCondition>
  userIdIsNotEmpty() {
    return QueryBuilder.apply(this, (query) {
      return query.addFilterCondition(
        FilterCondition.greaterThan(property: r'userId', value: ''),
      );
    });
  }
}

extension PlayHistoryQueryObject
    on QueryBuilder<PlayHistory, PlayHistory, QFilterCondition> {}

extension PlayHistoryQueryLinks
    on QueryBuilder<PlayHistory, PlayHistory, QFilterCondition> {}

extension PlayHistoryQuerySortBy
    on QueryBuilder<PlayHistory, PlayHistory, QSortBy> {
  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cId', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cName', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cName', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cPhoto', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cPhoto', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cType', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cType', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCreateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByCreateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySCid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sCid', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySCidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sCid', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sId', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sName', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sName', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sType', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sType', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByUpdateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> sortByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PlayHistoryQuerySortThenBy
    on QueryBuilder<PlayHistory, PlayHistory, QSortThenBy> {
  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cId', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cName', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cName', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCPhoto() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cPhoto', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCPhotoDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cPhoto', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cType', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'cType', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCreateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByCreateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'createTime', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenById() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'id', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByKey() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByKeyDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'key', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySCid() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sCid', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySCidDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sCid', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sId', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySName() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sName', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySNameDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sName', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySType() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sType', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySTypeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'sType', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenBySourceDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'source', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'time', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByTotalDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'total', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByUpdateTimeDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'updateTime', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByUrl() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByUrlDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'url', Sort.desc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByUserId() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.asc);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QAfterSortBy> thenByUserIdDesc() {
    return QueryBuilder.apply(this, (query) {
      return query.addSortBy(r'userId', Sort.desc);
    });
  }
}

extension PlayHistoryQueryWhereDistinct
    on QueryBuilder<PlayHistory, PlayHistory, QDistinct> {
  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByCId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByCName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByCPhoto({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cPhoto', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByCType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'cType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByCreateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'createTime');
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByKey({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'key', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctBySCid({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sCid', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctBySId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sId', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctBySName({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sName', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctBySType({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'sType', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctBySource() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'source');
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'time');
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByTotal() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'total');
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByUpdateTime() {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'updateTime');
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByUrl({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'url', caseSensitive: caseSensitive);
    });
  }

  QueryBuilder<PlayHistory, PlayHistory, QDistinct> distinctByUserId({
    bool caseSensitive = true,
  }) {
    return QueryBuilder.apply(this, (query) {
      return query.addDistinctBy(r'userId', caseSensitive: caseSensitive);
    });
  }
}

extension PlayHistoryQueryProperty
    on QueryBuilder<PlayHistory, PlayHistory, QQueryProperty> {
  QueryBuilder<PlayHistory, int, QQueryOperations> idProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'id');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> cIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cId');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> cNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cName');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> cPhotoProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cPhoto');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> cTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'cType');
    });
  }

  QueryBuilder<PlayHistory, DateTime, QQueryOperations> createTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'createTime');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> keyProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'key');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> sCidProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sCid');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> sIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sId');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> sNameProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sName');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> sTypeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'sType');
    });
  }

  QueryBuilder<PlayHistory, int, QQueryOperations> sourceProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'source');
    });
  }

  QueryBuilder<PlayHistory, int, QQueryOperations> timeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'time');
    });
  }

  QueryBuilder<PlayHistory, int, QQueryOperations> totalProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'total');
    });
  }

  QueryBuilder<PlayHistory, DateTime, QQueryOperations> updateTimeProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'updateTime');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> urlProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'url');
    });
  }

  QueryBuilder<PlayHistory, String, QQueryOperations> userIdProperty() {
    return QueryBuilder.apply(this, (query) {
      return query.addPropertyName(r'userId');
    });
  }
}
