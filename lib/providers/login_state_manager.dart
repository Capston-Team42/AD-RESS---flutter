import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LoginStateManager with ChangeNotifier {
  static const _tokenKey = 'accessToken';
  static const _userIdKey = 'userId';
  static const _passwordKey = 'password';
  static const _rememberKey = 'rememberLogin';
  static const _usernameKey = 'username';

  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _accessToken;
  String? _userId;
  String? _username;
  String? _password;
  bool _rememberLogin = false;

  /// 현재 토큰 반환
  String? get accessToken => _accessToken;
  String? get userId => _userId;
  String? get username => _username;
  String? get password => _password;
  bool get rememberLogin => _rememberLogin;

  /// 로그인 상태 여부
  bool get isLoggedIn => _accessToken != null && _accessToken!.isNotEmpty;

  /// 앱 시작 시 호출: 저장된 로그인 정보(ID, PW) 불러오기
  Future<void> loadLoginInfo() async {
    _userId = await _storage.read(key: _userIdKey);
    _username = await _storage.read(key: _usernameKey);
    _password = await _storage.read(key: _passwordKey);
    _accessToken = await _storage.read(key: _tokenKey);
    final rememberStr = await _storage.read(key: _rememberKey);
    _rememberLogin = rememberStr == 'true';
    notifyListeners();
  }

  /// 자동 로그인 시도
  Future<bool> tryAutoLogin(
    Future<Map<String, dynamic>?> Function(String id, String pw) loginRequest,
  ) async {
    await loadLoginInfo();

    if (_userId != null && _password != null) {
      final response = await loginRequest(_userId!, _password!);
      if (response != null && response.containsKey('token')) {
        _accessToken = response['token'];
        await _storage.write(key: _tokenKey, value: _accessToken);
        await _storage.write(key: _usernameKey, value: username);
        notifyListeners();
        return true;
      }
    }
    return false; // 자동 로그인 실패
  }

  /// 로그인 성공 시 저장
  Future<void> saveLoginData({
    required String token,
    required String userId,
    required String username,
    required String password,
    required bool rememberLogin,
  }) async {
    _accessToken = token;
    _userId = userId;
    _password = password;
    _rememberLogin = rememberLogin;
    _username = username;
    await _storage.write(key: _tokenKey, value: token);
    await _storage.write(key: _rememberKey, value: rememberLogin.toString());

    if (rememberLogin) {
      await _storage.write(key: _userIdKey, value: userId);
      await _storage.write(key: _usernameKey, value: username);
      await _storage.write(key: _passwordKey, value: password);
    } else {
      await _storage.delete(key: _userIdKey);
      await _storage.delete(key: _usernameKey);
      await _storage.delete(key: _passwordKey);
    }

    notifyListeners();
  }

  /// 사용자명 변경
  void setToken(String token) {
    _accessToken = token;
    notifyListeners();
  }

  void setUsername(String name) {
    _username = name;
    notifyListeners();
  }

  /// 로그아웃 시: 토큰 삭제
  Future<void> clearToken() async {
    _accessToken = null;
    await _storage.delete(key: _tokenKey);
    notifyListeners();
  }
}
