extension MapSafeExt on Map<String, dynamic> {
  /// 通用：按 key 取值并转成 T，失败返回 null
  T? mdAs<T>(String key) => castTo<T>(this[key]);

  /// 通用：按 key 取值并转成 T，失败返回默认值
  T mdAsOr<T>(String key, T defaultValue) =>
      castTo<T>(this[key]) ?? defaultValue;

  // ================= int =================

  /// 取 int，失败返回 null
  int? mdInt(String key) => castTo<int>(this[key]);

  /// 取 int，失败返回默认值（默认 0）
  int mdIntOr(String key, [int defaultValue = 0]) =>
      castTo<int>(this[key]) ?? defaultValue;

  // ================= double =================

  /// 取 double，失败返回 null
  double? mdDouble(String key) => castTo<double>(this[key]);

  /// 取 double，失败返回默认值（默认 0）
  double mdDoubleOr(String key, [double defaultValue = 0]) =>
      castTo<double>(this[key]) ?? defaultValue;

  // ================= String =================

  /// 取 String，失败返回 null
  String? mdString(String key) => castTo<String>(this[key]);

  /// 取 String，失败返回默认值（默认空串）
  String mdStringOr(String key, [String defaultValue = '']) =>
      castTo<String>(this[key]) ?? defaultValue;

  // ================= bool =================

  /// 取 bool，失败返回 null
  bool? mdBool(String key) => castTo<bool>(this[key]);

  /// 取 bool，失败返回默认值（默认 false）
  bool mdBoolOr(String key, [bool defaultValue = false]) =>
      castTo<bool>(this[key]) ?? defaultValue;
}


/// 通用转换：任意值 → T，转换失败返回 null
T? castTo<T>(Object? value) {
  if (value == null) return null;
  // 类型变量 T 下 value is T 不会自动提升类型，需显式强转
  if (value is T) return value as T;

  // 只有目标类型是基础类型时才做兼容转换，其余一律视为失败
  if (T == int) return _castInt(value) as T?;
  if (T == double) return _castDouble(value) as T?;
  if (T == bool) return _castBool(value) as T?;
  if (T == String) {
    // Map/List 直接 toString 没有意义，按失败处理
    if (value is Map || value is Iterable) return null;
    return value.toString() as T;
  }

  return null;
}

int? _castInt(Object? value) {
  if (value is int) return value;
  if (value is bool) return value ? 1 : 0;
  if (value is num) return value.toInt();
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return int.tryParse(text) ?? double.tryParse(text)?.toInt();
  }
  return null;
}

double? _castDouble(Object? value) {
  if (value is double) return value;
  if (value is num) return value.toDouble();
  if (value is String) {
    final text = value.trim();
    if (text.isEmpty) return null;
    return double.tryParse(text);
  }
  return null;
}

bool? _castBool(Object? value) {
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) {
    final text = value.trim().toLowerCase();
    if (text == 'true' || text == '1') return true;
    if (text == 'false' || text == '0') return false;
  }
  return null;
}
