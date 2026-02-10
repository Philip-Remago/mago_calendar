import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../config/auth_config.dart';
import '../models/booking.dart';
import '../models/oauth_token.dart';
import '../models/sync_result.dart';

class MicrosoftAuthClient {
  static const _tenant = 'common';
  static const _authorizeEndpoint =
      'https://login.microsoftonline.com/$_tenant/oauth2/v2.0/authorize';
  static const _tokenEndpoint =
      'https://login.microsoftonline.com/$_tenant/oauth2/v2.0/token';
  static const _tokenStorageKey = 'mago_calendar.microsoft_token';

  OAuthToken? _token;
  String? _deltaLink;

  bool get isSignedIn => _token != null;

  Future<void> restoreSession() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tokenStorageKey);
    if (raw == null || raw.isEmpty) {
      return;
    }
    try {
      final payload = jsonDecode(raw) as Map<String, dynamic>;
      _token = OAuthToken.fromJson(payload);
    } catch (_) {
      await prefs.remove(_tokenStorageKey);
    }
  }

  Future<void> signIn() async {
    if (AuthConfig.microsoftClientId.isEmpty) {
      throw StateError('Missing Microsoft client ID.');
    }

    final codeVerifier = _createCodeVerifier();
    final codeChallenge = _codeChallenge(codeVerifier);
    final state = _randomString(16);

    final uri = Uri.parse(_authorizeEndpoint).replace(
      queryParameters: {
        'client_id': AuthConfig.microsoftClientId,
        'response_type': 'code',
        'redirect_uri': AuthConfig.microsoftRedirectUri(),
        'response_mode': 'query',
        'scope': 'Calendars.Read offline_access',
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
      },
    );

    final callbackUrl = await FlutterWebAuth2.authenticate(
      url: uri.toString(),
      callbackUrlScheme: AuthConfig.microsoftCallbackScheme(),
      options: FlutterWebAuth2Options(
        windowName: 'flutter-web-auth-2',
        debugOrigin: Uri.base.origin,
      ),
    );

    final returned = Uri.parse(callbackUrl);
    final returnedState = returned.queryParameters['state'];
    if (returnedState != state) {
      throw StateError('Microsoft auth state mismatch.');
    }

    final code = returned.queryParameters['code'];
    if (code == null) {
      throw StateError('Missing authorization code.');
    }

    await _exchangeCode(code: code, codeVerifier: codeVerifier);
  }

  void signOut() {
    _token = null;
    _deltaLink = null;
    _clearStoredToken();
  }

  Future<List<Booking>> fetchBookings({
    required DateTime start,
    required DateTime end,
  }) async {
    final result = await fetchChanges(start: start, end: end, forceFull: true);
    return result.upserts;
  }

  void resetSync() {
    _deltaLink = null;
  }

  Future<SyncResult<Booking>> fetchChanges({
    required DateTime start,
    required DateTime end,
    bool forceFull = false,
  }) async {
    final accessToken = await _getAccessToken();
    if (accessToken == null) {
      throw StateError('Microsoft not signed in.');
    }

    String? requestUrl;
    if (!forceFull && _deltaLink != null) {
      requestUrl = _deltaLink;
    } else {
      requestUrl =
          Uri.parse('https://graph.microsoft.com/v1.0/me/calendarView/delta')
              .replace(
                queryParameters: {
                  'startDateTime': start.toUtc().toIso8601String(),
                  'endDateTime': end.toUtc().toIso8601String(),
                  r'$select':
                      'subject,bodyPreview,body,start,end,location,onlineMeetingUrl,organizer',
                },
              )
              .toString();
    }

    final upserts = <Booking>[];
    final removed = <String>[];
    String? nextLink;
    String? deltaLink;

    do {
      final response = await http.get(
        Uri.parse(requestUrl!),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode != 200) {
        throw StateError('Microsoft Graph error: ${response.statusCode}');
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final items = (data['value'] as List<dynamic>? ?? [])
          .whereType<Map<String, dynamic>>()
          .toList();

      for (final item in items) {
        if (item.containsKey('@removed')) {
          final id = item['id']?.toString();
          if (id != null) {
            removed.add('m:$id');
          }
          continue;
        }
        upserts.add(Booking.fromMicrosoft(item));
      }

      nextLink = data['@odata.nextLink']?.toString();
      deltaLink = data['@odata.deltaLink']?.toString() ?? deltaLink;
      requestUrl = nextLink;
    } while (nextLink != null);

    if (deltaLink != null) {
      _deltaLink = deltaLink;
    }

    return SyncResult<Booking>(
      upserts: upserts,
      removedIds: removed,
      nextToken: _deltaLink,
    );
  }

  Future<void> _exchangeCode({
    required String code,
    required String codeVerifier,
  }) async {
    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': AuthConfig.microsoftClientId,
        if (AuthConfig.microsoftClientSecret.isNotEmpty)
          'client_secret': AuthConfig.microsoftClientSecret,
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': AuthConfig.microsoftRedirectUri(),
        'code_verifier': codeVerifier,
        'scope': 'Calendars.Read offline_access',
      },
    );

    if (response.statusCode != 200) {
      throw StateError(
        'Token exchange failed: ${response.statusCode} ${response.body}',
      );
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    _token = OAuthToken.fromJson(payload);
    await _persistToken();
  }

  Future<void> _refreshToken() async {
    final refreshToken = _token?.refreshToken;
    if (refreshToken == null) {
      _token = null;
      return;
    }

    final response = await http.post(
      Uri.parse(_tokenEndpoint),
      headers: const {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {
        'client_id': AuthConfig.microsoftClientId,
        if (AuthConfig.microsoftClientSecret.isNotEmpty)
          'client_secret': AuthConfig.microsoftClientSecret,
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'redirect_uri': AuthConfig.microsoftRedirectUri(),
        'scope': 'Calendars.Read offline_access',
      },
    );

    if (response.statusCode != 200) {
      _token = null;
      return;
    }

    final payload = jsonDecode(response.body) as Map<String, dynamic>;
    _token = OAuthToken.fromJson(payload);
    await _persistToken();
  }

  Future<String?> _getAccessToken() async {
    if (_token == null) {
      return null;
    }
    if (_token!.isExpired) {
      await _refreshToken();
    }
    return _token?.accessToken;
  }

  Future<void> _persistToken() async {
    final prefs = await SharedPreferences.getInstance();
    if (_token == null) {
      await prefs.remove(_tokenStorageKey);
      return;
    }
    await prefs.setString(_tokenStorageKey, jsonEncode(_token!.toJson()));
  }

  Future<void> _clearStoredToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenStorageKey);
  }
}

String _createCodeVerifier() => _randomString(64);

String _codeChallenge(String verifier) {
  final bytes = sha256.convert(utf8.encode(verifier)).bytes;
  return base64UrlEncode(bytes).replaceAll('=', '');
}

String _randomString(int length) {
  final random = Random.secure();
  final values = List<int>.generate(length, (_) => random.nextInt(256));
  return base64UrlEncode(values).replaceAll('=', '');
}
