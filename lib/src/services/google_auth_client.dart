import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:google_sign_in_all_platforms/google_sign_in_all_platforms.dart';
import 'package:http/http.dart' as http;

import '../config/auth_config.dart';
import '../models/booking.dart';
import '../models/sync_result.dart';

class GoogleAuthClient {
  GoogleAuthClient() {
    _googleSignIn = GoogleSignIn(
      params: GoogleSignInParams(
        clientId: AuthConfig.googleClientIdForPlatform(),
        clientSecret: AuthConfig.googleClientSecretForPlatform(),
        scopes: const ['https://www.googleapis.com/auth/calendar.readonly'],
      ),
    );
    _googleSignIn.authenticationState.listen((credentials) {
      _credentials = credentials;
    });
  }

  late final GoogleSignIn _googleSignIn;
  GoogleSignInCredentials? _credentials;
  String? _nextSyncToken;

  bool get isSignedIn => _credentials != null;
  Stream<GoogleSignInCredentials?> get authenticationState =>
      _googleSignIn.authenticationState;

  Future<void> silentSignIn() async {
    try {
      _credentials = await _googleSignIn.silentSignIn();
    } catch (_) {}
  }

  Future<void> signIn() async {
    _credentials = await _googleSignIn.signIn();
  }

  Future<void> signOut() async {
    await _googleSignIn.signOut();
    _credentials = null;
    _nextSyncToken = null;
  }

  Widget? signInButton({required VoidCallback onSignedIn}) {
    return _googleSignIn.signInButton(
      config: GSIAPButtonConfig(onSignIn: (_) => onSignedIn()),
    );
  }

  Future<List<Booking>> fetchBookings({
    required DateTime start,
    required DateTime end,
  }) async {
    if (_credentials == null) {
      throw StateError('Google not signed in.');
    }

    final result = await fetchChanges(start: start, end: end, forceFull: true);
    return result.upserts;
  }

  void resetSync() {
    _nextSyncToken = null;
  }

  Future<SyncResult<Booking>> fetchChanges({
    required DateTime start,
    required DateTime end,
    bool forceFull = false,
  }) async {
    if (_credentials == null) {
      throw StateError('Google not signed in.');
    }

    final params = <String, String>{
      'timeMin': start.toUtc().toIso8601String(),
      'timeMax': end.toUtc().toIso8601String(),
      'singleEvents': 'true',
      'orderBy': 'startTime',
      'conferenceDataVersion': '1',
      'showDeleted': 'true',
    };

    if (!forceFull && _nextSyncToken != null) {
      params['syncToken'] = _nextSyncToken!;
    }

    final uri = Uri.https(
      'www.googleapis.com',
      '/calendar/v3/calendars/primary/events',
      params,
    );

    final response = await http.get(
      uri,
      headers: {'Authorization': 'Bearer ${_credentials!.accessToken}'},
    );

    if (response.statusCode == 410) {
      _nextSyncToken = null;
      return fetchChanges(start: start, end: end, forceFull: true);
    }

    if (response.statusCode != 200) {
      throw StateError('Google API error: ${response.statusCode}');
    }

    final data = jsonDecode(response.body) as Map<String, dynamic>;
    final items = (data['items'] as List<dynamic>? ?? [])
        .whereType<Map<String, dynamic>>()
        .toList();
    final upserts = <Booking>[];
    final removed = <String>[];
    for (final item in items) {
      final status = item['status']?.toString();
      if (status == 'cancelled') {
        final id = item['id']?.toString();
        if (id != null) {
          removed.add('g:$id');
        }
      } else {
        upserts.add(Booking.fromGoogle(item));
      }
    }

    _nextSyncToken = data['nextSyncToken']?.toString() ?? _nextSyncToken;
    return SyncResult<Booking>(
      upserts: upserts,
      removedIds: removed,
      nextToken: _nextSyncToken,
    );
  }
}
