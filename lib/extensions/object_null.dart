extension ObjectNull on Object? {
  bool get isNull => this == null;
  bool get isNotNull => this != null;

  int? get mdIntOrNull {
    final value = this;
    if (value is int) return value;
    final text = this?.toString().trim();
    if (text == null || text.isEmpty) return null;
    return int.tryParse(text);
  }

  int mdToInt() {
    final value = this;
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  String mdToString() {
    final value = this;
    return value == null ? '' : value.toString();
  }
}