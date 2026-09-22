enum MDEnv {
  test,
  product;

  static const String appId = '6792423302';
  static const String urlForPrivate =
      'http://ht.zhuoshilx.com/news/article/external_detail?id=45&form=app&type=2';
  static const String urlForUser =
      'http://ht.zhuoshilx.com/news/article/external_detail?id=44&form=app&type=1';
  static const String telephone = '18527671224';
  static const String icpLicense = '鄂ICP备2026035920号-2A';

  /// api地址
  String get url {
    switch (this) {
      case .test:
      case .product:
        return 'http://api.zhuoshilx.com';
    }
  }

  /// 内购api地址
  String get iapUrl {
    switch (this) {
      case .test:
      case .product:
        return 'https://apiios.zhuoshilx.com/apiv1';
    }
  }

  /// 切换下一个环境
  MDEnv next() {
    final allCases = MDEnv.values;
    final currentIndex = allCases.indexOf(this);
    if (currentIndex < 0) {
      return this;
    }

    final nextIndex = (currentIndex + 1) % allCases.length;
    return allCases[nextIndex];
  }
}


