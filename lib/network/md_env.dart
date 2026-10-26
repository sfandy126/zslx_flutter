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

  /// 当前使用的域名
  static bool get isZslx =>
      Uri.tryParse(MDEnv.current.url)?.host.contains('zhuoshilx') ?? true;

  /// 百家云sdk appId
  static String get bjyAppId {
    if (isZslx) return '66514664';
    return '54200585';
  }

  /// 当前使用的环境
  static const MDEnv current = .product;

  /// api地址
  String get url {
    switch (this) {
      case .test:
        return 'http://api_test.edugkw.com';
      case .product:
        return 'http://api.zhuoshilx.com';
    }
  }

  /// 内购api地址
  String get iapUrl {
    switch (this) {
      case .test:
        return "http://api.eduxingchen.com/apiv1/";
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
