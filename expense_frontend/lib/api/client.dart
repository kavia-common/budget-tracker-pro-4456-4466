import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A lightweight API client for the Budget Tracker Pro app.
/// - Reads API_BASE_URL from .env
/// - Adds Authorization Bearer token when present
/// - Automatically logs out on 401 by clearing stored token
/// - Provides simple GET/POST helpers with JSON handling
class ApiClient {
  ApiClient._internal();

  static final ApiClient _instance = ApiClient._internal();

  factory ApiClient() => _instance;

  String get baseUrl {
    // Fallbacks for emulator compatibility; prefer .env if present.
    final envBase = dotenv.env['API_BASE_URL']?.trim();
    if (envBase != null && envBase.isNotEmpty) return envBase;
    // Android emulator talks to host via 10.0.2.2
    return kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000';
  }

  Future<Map<String, String>> _headers() async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  Uri _uri(String path, [Map<String, dynamic>? query]) {
    final normalized =
        path.startsWith('/') ? path : '/$path';
    return Uri.parse('$baseUrl$normalized').replace(
      queryParameters: query?.map((k, v) => MapEntry(k, '$v')),
    );
  }

  // PUBLIC_INTERFACE
  Future<dynamic> getJson(String path, {Map<String, dynamic>? query}) async {
    /** Performs a GET request and returns decoded JSON. Throws on non-2xx. */
    final response = await http.get(_uri(path, query), headers: await _headers());
    return _handleResponse(response);
  }

  // PUBLIC_INTERFACE
  Future<dynamic> postJson(String path, Map<String, dynamic> body) async {
    /** Performs a POST request with JSON body and returns decoded JSON. Throws on non-2xx. */
    final response = await http.post(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUBLIC_INTERFACE
  Future<dynamic> putJson(String path, Map<String, dynamic> body) async {
    /** Performs a PUT request with JSON body and returns decoded JSON. Throws on non-2xx. */
    final response = await http.put(
      _uri(path),
      headers: await _headers(),
      body: jsonEncode(body),
    );
    return _handleResponse(response);
  }

  // PUBLIC_INTERFACE
  Future<dynamic> delete(String path) async {
    /** Performs a DELETE request and returns decoded JSON if available. Throws on non-2xx. */
    final response = await http.delete(_uri(path), headers: await _headers());
    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) async {
    if (response.statusCode == 401) {
      // Unauthorized -> clear token to force relogin
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('auth_token');
      throw ApiException('Unauthorized. Please login again.', statusCode: 401);
    }

    dynamic decoded;
    try {
      decoded = response.body.isNotEmpty ? jsonDecode(response.body) : null;
    } catch (_) {
      decoded = response.body;
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    } else {
      final message = (decoded is Map && decoded['message'] is String)
          ? decoded['message']
          : 'Request failed with status ${response.statusCode}';
      throw ApiException(message, statusCode: response.statusCode, data: decoded);
    }
  }
}

class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final dynamic data;
  ApiException(this.message, {this.statusCode, this.data});
  @override
  String toString() => 'ApiException($statusCode): $message';
}
