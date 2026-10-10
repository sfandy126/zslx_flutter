enum MDEnv {
  test,
  product;

  static const String appId = '6792423302';
  static const String urlAppstore =
      'https://apps.apple.com/cn/app/%E5%A4%87%E8%80%83%E8%90%A5%E5%9C%B0/id$appId';
  static const String urlForPrivate =
      'http://ht.zhuoshilx.com/news/article/external_detail?id=45&form=app&type=2';
  static const String urlForUser =
      'http://ht.zhuoshilx.com/news/article/external_detail?id=44&form=app&type=1';
  static const String telephone = '18527671224';
  static const String icpLicense = '鄂ICP备2026035920号-2A';

  /// 百家云sdk appId
  static const String bjyAppId = '54200585'; //66514664

  /// api地址
  String get url {
    switch (this) {
      case .test:
      case .product:
      // TODO: 测试api
        return 'http://api_test.edugkw.com';//'http://api.zhuoshilx.com';
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


