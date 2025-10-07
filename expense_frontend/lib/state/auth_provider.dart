import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../api/client.dart';

/// AuthProvider manages authentication state, token persistence, and user info.
class AuthProvider extends ChangeNotifier {
  String? _token;
  Map<String, dynamic>? _user;
  bool _initialized = false;

  bool get isInitialized => _initialized;
  bool get isAuthenticated => _token != null && _token!.isNotEmpty;
  String? get token => _token;
  Map<String, dynamic>? get user => _user;

  // PUBLIC_INTERFACE
  Future<void> initialize() async {
    /** Loads token from shared preferences and optionally fetches profile. */
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token');
    if (_token != null) {
      try {
        final me = await ApiClient().getJson('/auth/me');
        if (me is Map<String, dynamic>) {
          _user = me;
        }
      } catch (_) {
        // if profile fails, keep token but clear user
        _user = null;
      }
    }
    _initialized = true;
    notifyListeners();
  }

  // PUBLIC_INTERFACE
  Future<bool> login(String email, String password) async {
    /** Authenticates the user and persists JWT token. Returns true on success. */
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
    /** Registers a user, then logs them in. Returns true on success. */
    await ApiClient().postJson('/auth/register', {
      'name': name,
      'email': email,
      'password': password,
    });
    // Auto-login after registration
    return login(email, password);
  }

  // PUBLIC_INTERFACE
  Future<void> logout() async {
    /** Clears stored auth token and user info. */
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    _token = null;
    _user = null;
    notifyListeners();
  }
}
