/// 说明：扩展方法只在静态类型上解析，接收者若为 dynamic（如 `Map<String, dynamic>` 取值结果）
/// 会走动态调用并抛 NoSuchMethodError，此时请用 map_safe.dart 的 MapExt 取值。
extension ObjectNull on Object? {
  bool get isNull => this == null;
  bool get isNotNull => this != null;

  /// 转 int，失败返回 null（支持 num、数字字符串）
  int? get mdIntOrNull => _parseInt(this);

  /// 转 int，失败返回 0
  int mdToInt() => _parseInt(this) ?? 0;

  /// 转 String，null 返回空串；整数型 double 去掉多余的 .0
  String mdToString() {
    final value = this;
    if (value == null) return '';
    if (value is double && value.isFinite && value == value.toInt()) {
      return value.toInt().toString();
    }
    return value.toString();
  }
}

/// 任意值 → int：num 直接截断小数，字符串先按 int、再按 double 解析
int? _parseInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  final text = value.toString().trim();
  if (text.isEmpty) return null;
  return int.tryParse(text) ?? double.tryParse(text)?.toInt();
}
