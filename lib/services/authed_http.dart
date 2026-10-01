/// Drop-in replacement for `package:http/http.dart` that attaches the
/// signed-in user's bearer token to every backend request.
///
/// Import as `import 'authed_http.dart' as http;` - get/post/put/delete/
/// patch/head are overridden; every other symbol (Response, MultipartRequest,
/// ...) is re-exported unchanged.
///
/// Tokens are issued by the backend on login/sign-up
/// (`POST /users/{name}/verify-password`, `POST /users/`), kept per user so
/// the device's quick-login list keeps working, and are never sent to hosts
/// other than the API (the token is only attached to [ApiConfig.baseUrl]).
library;

import 'dart:convert';

import 'package:http/http.dart' as h;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/api_config.dart';

export 'package:http/http.dart' hide get, post, put, delete, patch, head;

class AuthSession {
  static const _prefsKey = 'auth_tokens';
  static final Map<String, String> _tokens = {};
  static String? _active;
  static bool _loaded = false;

  /// Called when the backend rejects the token (expired/invalid).
  static void Function()? onUnauthorized;

  static String _k(String name) => name.trim().toUpperCase();

  static Future<void> load() async {
    if (_loaded) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefsKey);
      if (raw != null) {
        (jsonDecode(raw) as Map<String, dynamic>).forEach(
          (k, v) => _tokens[k] = v as String,
        );
      }
      // Older builds kept plaintext passwords here - never store them.
      await prefs.remove('saved_passwords');
      _active ??= prefs.getString('auth_active');
    } catch (_) {}
    _loaded = true;
  }

  /// Select whose token is attached to outgoing requests.
  static void use(String name) => _active = _k(name);

  static bool hasToken(String name) => _tokens.containsKey(_k(name));

  static Future<void> save(String name, String token) async {
    _tokens[_k(name)] = token;
    _active = _k(name);
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_tokens));
      await prefs.setString('auth_active', _active!);
    } catch (_) {}
  }

  static Future<void> clear(String name) async {
    _tokens.remove(_k(name));
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefsKey, jsonEncode(_tokens));
    } catch (_) {}
  }

  static Map<String, String> headersFor(
    Uri url,
    Map<String, String>? headers,
  ) {
    final out = <String, String>{...?headers};
    final token = _active == null ? null : _tokens[_active!];
    if (token != null && url.toString().startsWith(ApiConfig.baseUrl)) {
      out['Authorization'] = 'Bearer $token';
    }
    return out;
  }

  static h.Response _check(h.Response r, Uri url) {
    if (r.statusCode == 401 && url.toString().startsWith(ApiConfig.baseUrl)) {
      onUnauthorized?.call();
    }
    return r;
  }
}

Future<h.Response> get(Uri url, {Map<String, String>? headers}) async =>
    AuthSession._check(
      await h.get(url, headers: AuthSession.headersFor(url, headers)),
      url,
    );

Future<h.Response> head(Uri url, {Map<String, String>? headers}) =>
    h.head(url, headers: AuthSession.headersFor(url, headers));

Future<h.Response> post(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async => AuthSession._check(
  await h.post(
    url,
    headers: AuthSession.headersFor(url, headers),
    body: body,
    encoding: encoding,
  ),
  url,
);

Future<h.Response> put(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async => AuthSession._check(
  await h.put(
    url,
    headers: AuthSession.headersFor(url, headers),
    body: body,
    encoding: encoding,
  ),
  url,
);

Future<h.Response> patch(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async => AuthSession._check(
  await h.patch(
    url,
    headers: AuthSession.headersFor(url, headers),
    body: body,
    encoding: encoding,
  ),
  url,
);

Future<h.Response> delete(
  Uri url, {
  Map<String, String>? headers,
  Object? body,
  Encoding? encoding,
}) async => AuthSession._check(
  await h.delete(
    url,
    headers: AuthSession.headersFor(url, headers),
    body: body,
    encoding: encoding,
  ),
  url,
);

