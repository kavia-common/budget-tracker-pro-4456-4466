import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

/// AuthProvider manages authentication state, token persistence, and user info.
/// In mock mode, it does not require a real JWT and returns a pseudo user.
class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  bool get _useMock => (dotenv.env['USE_MOCK_DATA'] ?? 'true').toLowerCase() != 'false';

  // PUBLIC_INTERFACE
  Future<void> initialize() async {
    /** Initialize auth. In mock mode sets a pseudo token and user. */
    final prefs = await SharedPreferences.getInstance();
    if (_useMock) {
      _token = 'mock-token';
      try {
        final me = await ApiClient().getJson('/auth/me');
        if (me is Map<String, dynamic>) _user = me;
      } catch (_) {
        _user = {'name': 'Guest', 'email': 'guest@example.com'};
      }
      _initialized = true;
      notifyListeners();
      return;
    }

    _token = prefs.getString('auth_token');
    if (_token != null) {
      try {
        final me = await ApiClient().getJson('/auth/me');
        if (me is Map<String, dynamic>) {
          _user = me;
        }
      } catch (_) {
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  Future<bool> login(String email, String password) async {
    /** Authenticates the user and persists JWT token. */
    if (_useMock) {
      _token = 'mock-token';
      _user = {'name': email.split('@').first, 'email': email};
      notifyListeners();
      return true;
    }
    final res = await ApiClient().postJson('/auth/login', {
      'email': email,
      'password': password,
    });
    if (res is Map<String, dynamic> && res['token'] != null) {
      _token = res['token'] as String;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', _token!);
      try {
        final me = await ApiClient().getJson('/auth/me');
        if (me is Map<String, dynamic>) _user = me;
      } catch (_) {}
      notifyListeners();
      return true;
    }
    return false;
  }

  // PUBLIC_INTERFACE
  Future<bool> register(String name, String email, String password) async {
    /** Registers a user, then logs them in. */
    if (_useMock) {
      _user = {'name': name, 'email': email};
      _token = 'mock-token';
      notifyListeners();
      return true;
    }
    await ApiClient().postJson('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    return login(email, password);
  }

  // PUBLIC_INTERFACE
  Future<void> logout() async {
    /** Clears stored auth token and user info. In mock mode becomes guest. */
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    if (_useMock) {
      _token = 'mock-token';
      _user = {'name': 'Guest', 'email': 'guest@example.com'};
    } else {
      _token = null;
      _user = null;
    }
    notifyListeners();
  }
}
