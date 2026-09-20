import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

///
/// 注意：在 Flutter 中构造函数不能为异步，因此需要在应用启动时调用
/// `await MDUser.defualt.init()` 来加载本地保存的数据。
class MDUser extends ChangeNotifier {
  MDUser._internal();
  // 单例模式
  static final MDUser defualt = MDUser._internal();

  // 本地字段 私有属性_开头
  String? _priToken;
  String? _priUid;
  String? _priGuest;
  String? _priNick;
  String? _priAvatar;
  String? _priPhone;

  // 不存本地
  String? wxOpenid;
  String? wxName;

  // 兼容原来的通知常量（如果你使用事件总线或其他方式，也可以不用）
  static const String notificationForLogin = 'MDUSER_LOGIN_NOTIFICATION';
  static const String notificationForLogout = 'MDUSER_LOGOUT_NOTIFICATION';
  static const String notificationForInfoUpdate = 'MDUSER_INFO_UPDATE_NOTIFICATION';

  // 简单的广播事件（可选）
  final StreamController<String> _eventController = StreamController<String>.broadcast();
  Stream<String> get events => _eventController.stream;

  /// 在应用启动时调用以从 SharedPreferences 读取本地数据
  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _priToken = prefs.getString(_k(SaveKey.token));
    _priUid = prefs.getString(_k(SaveKey.uid));
    _priGuest = prefs.getString(_k(SaveKey.guest));
    _priNick = prefs.getString(_k(SaveKey.nick));
    _priAvatar = prefs.getString(_k(SaveKey.avatar));
    _priPhone = prefs.getString(_k(SaveKey.phone));
  }

  /// 保存 last account 
  static Future<void> saveLast(String? phone, String? passwd) async {
    if (phone == null || phone.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('MDUSER_LAST_ACCOUNT', phone);
    if (passwd != null && passwd.isNotEmpty) {
      await prefs.setString('MDUSER_LAST_PASSWD', passwd);
    }
  }

  /// 读取 last account 
  static Future<Map<String, String?>?> readLast() async {
    final prefs = await SharedPreferences.getInstance();
    final phone = prefs.getString('MDUSER_LAST_ACCOUNT');
    if (phone == null || phone.isEmpty) return null;
    final passwd = prefs.getString('MDUSER_LAST_PASSWD');
    return {'phone': phone, 'passwd': passwd};
  }

  /// 更新 last passwd（修改密码后更新）
  static Future<void> updateLastPasswd(String? passwd) async {
    if (passwd == null || passwd.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('MDUSER_LAST_PASSWD', passwd);
  }

  // MARK: - 私有键管理
  Future<void> _save(SaveKey key, String? value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_k(key), value ?? '');
  }

  // 已用不到的读取函数已移除（使用 init/_save/_updateFromMap 处理读取需求）
  Future<void> _removeAllKey() async {
    final prefs = await SharedPreferences.getInstance();
    for (final key in SaveKey.values) {
      await prefs.remove(_k(key));
    }
  }

  String _k(SaveKey key) => 'MDUSER_${key.name.toUpperCase()}';

  /// 登录成功信息
  Future<void> login(Map<String, dynamic>? res) async {
    _priToken = _mapStr(res, 'token');
    _priUid = _mapStr(res, 'user_id');
    _priGuest = _mapStr(res, 'is_yk');
    await _save(SaveKey.token, _priToken);
    await _save(SaveKey.uid, _priUid);
    await _save(SaveKey.guest, _priGuest);
    await _updateFromMap(res);
    _eventController.add(notificationForLogin);
    notifyListeners();
  }

  /// 注销登录
  Future<void> logout() async {
    _priToken = null;
    _priUid = null;
    _priGuest = null;
    _priNick = null;
    _priPhone = null;
    _priAvatar = null;
    wxOpenid = null;
    wxName = null;
    await _removeAllKey();
    _eventController.add(notificationForLogout);
    _eventController.add(notificationForInfoUpdate);
    notifyListeners();
  }

  /// 更新用户信息
  Future<void> update(Map<String, dynamic>? res) async {
    await _updateFromMap(res);
    _eventController.add(notificationForInfoUpdate);
    notifyListeners();
  }

  /// 更新用户头像
  Future<void> updateAvatar(String? avatar) async {
    if (avatar == null || avatar.isEmpty) return;
    _priAvatar = avatar;
    await _save(SaveKey.avatar, _priAvatar);
    _eventController.add(notificationForInfoUpdate);
    notifyListeners();
  }

  /// 更新用户昵称
  Future<void> updateNick(String? nick) async {
    if (nick == null || nick.isEmpty) return;
    _priNick = nick;
    await _save(SaveKey.nick, _priNick);
    _eventController.add(notificationForInfoUpdate);
    notifyListeners();
  }

  /// 更新用户 token（第三方登录时调用）
  Future<void> updateToken(String? token) async {
    if (token == null || token.isEmpty) return;
    _priToken = token;
    await _save(SaveKey.token, _priToken);
  }

  /// 更新微信信息（微信绑定）
  Future<void> updateWx(Map<String, dynamic>? res) async {
    final openid = res?['wx_openid'] as String?;
    if (openid == null || openid.isEmpty) return;
    wxOpenid = openid;
    wxName = res?['wx_name'] as String?;
    _eventController.add(notificationForInfoUpdate);
    notifyListeners();
  }

  /// 更新用户手机号
  Future<void> updatePhone(String? phone) async {
    if (phone == null || phone.isEmpty) return;
    _priPhone = phone;
    await _save(SaveKey.phone, _priPhone);
    _eventController.add(notificationForInfoUpdate);
    notifyListeners();
  }

  /// 更新用户信息（占位：此处应调用网络接口获取最新用户信息）
  Future<void> updateData({bool animate = false, VoidCallback? completed}) async {
    // TODO: 调用你的接口获取用户信息并调用 update(info)
    // 示例： final res = await Api.getMemberInfo(); if (res.success) update(res.data);
    completed?.call();
  }

  // MARK: - 游客 UUID 保存/读取（使用 SharedPreferences）
  static Future<void> saveForGuest(String? uuid) async {
    if (uuid == null || uuid.isEmpty) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('MDUSER_GUEST_UUID', uuid);
  }

  static Future<String?> readForGuest() async {
    final prefs = await SharedPreferences.getInstance();
    var id = prefs.getString('MDUSER_GUEST_UUID');
    if (id != null && id.isNotEmpty) return id;
    id = DateTime.now().millisecondsSinceEpoch.toString();
    await prefs.setString('MDUSER_GUEST_UUID', id);
    return id;
  }

  // 私有帮助
  Future<void> _updateFromMap(Map<String, dynamic>? res) async {
    _priNick = _mapStr(res, 'nickname');
    _priPhone = _mapStr(res, 'phone');
    if (res != null && res['profile'] is String && (res['profile'] as String).isNotEmpty) {
      _priAvatar = res['profile'] as String;
    } else {
      _priAvatar = _mapStr(res, 'avatar');
    }
    wxOpenid = _mapStr(res, 'wx_openid');
    wxName = _mapStr(res, 'wx_name');
    await _save(SaveKey.nick, _priNick);
    await _save(SaveKey.phone, _priPhone);
    await _save(SaveKey.avatar, _priAvatar);
  }

  static String? _mapStr(Map<String, dynamic>? m, String key) {
    final v = m == null ? null : m[key];
    if (v == null) return null;
    if (v is String) return v;
    return v.toString();
  }

  @override
  void dispose() {
    _eventController.close();
    super.dispose();
  }
}

enum SaveKey { token, uid, guest, nick, avatar, phone }

extension MdUserExtension on MDUser {
  // MARK: - getter
  static bool get islogined {
    final uid = MDUser.defualt._priUid;
    return uid != null && uid.isNotEmpty && uid != '0';
  }

  String? get token => _priToken;

  String? get uid {
    if (_priUid != null && _priUid!.isNotEmpty && _priUid != '0') {
      return _priUid;
    }
    return null;
  }

  String? get nick => _priNick;
  String? get avatar => _priAvatar;
  String? get phone => _priPhone;
  bool get guest => (_priGuest ?? '') == '1';
}