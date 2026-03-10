import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:mago_calendar/mago_calendar.dart';

void main() {
  group('Booking', () {
    test('creates from Google JSON', () {
      final json = {
        'id': 'test-id',
        'summary': 'Test Meeting',
        'start': {'dateTime': '2026-02-10T10:00:00Z'},
        'end': {'dateTime': '2026-02-10T11:00:00Z'},
        'location': 'Room 101',
        'description': 'Test description',
        'hangoutLink': 'https://meet.google.com/test',
        'organizer': {
          'displayName': 'Test Organizer',
          'email': 'organizer@example.com',
        },
      };

      final booking = Booking.fromGoogle(json);

      expect(booking.id, 'g:test-id');
      expect(booking.source, BookingSource.google);
      expect(booking.title, 'Test Meeting');
      expect(booking.location, 'Room 101');
      expect(booking.description, 'Test description');
      expect(booking.meetingLink, 'https://meet.google.com/test');
      expect(booking.organizerName, 'Test Organizer');
      expect(booking.organizerEmail, 'organizer@example.com');
    });

    test('creates from Google JSON with date only (all-day event)', () {
      final json = {
        'id': 'all-day-id',
        'summary': 'All Day Event',
        'start': {'date': '2026-02-10'},
        'end': {'date': '2026-02-11'},
        'location': '',
        'description': '',
      };

      final booking = Booking.fromGoogle(json);

      expect(booking.id, 'g:all-day-id');
      expect(booking.title, 'All Day Event');
      expect(booking.start.year, 2026);
      expect(booking.start.month, 2);
      expect(booking.start.day, 10);
    });

    test('creates from Google JSON with missing optional fields', () {
      final json = {
        'id': 'minimal-id',
        'start': {'dateTime': '2026-02-10T10:00:00Z'},
        'end': {'dateTime': '2026-02-10T11:00:00Z'},
      };

      final booking = Booking.fromGoogle(json);

      expect(booking.id, 'g:minimal-id');
      expect(booking.title, '');
      expect(booking.location, '');
      expect(booking.description, '');
      expect(booking.meetingLink, '');
      expect(booking.organizerName, '');
      expect(booking.organizerEmail, '');
    });

    test('creates from Microsoft JSON', () {
      final json = {
        'id': 'test-id',
        'subject': 'Test Meeting',
        'start': {'dateTime': '2026-02-10T10:00:00'},
        'end': {'dateTime': '2026-02-10T11:00:00'},
        'location': {'displayName': 'Room 101'},
        'bodyPreview': 'Test description',
        'onlineMeetingUrl': 'https://teams.microsoft.com/test',
        'organizer': {
          'emailAddress': {
            'name': 'Test Organizer',
            'address': 'organizer@example.com',
          },
        },
      };

      final booking = Booking.fromMicrosoft(json);

      expect(booking.id, 'm:test-id');
      expect(booking.source, BookingSource.microsoft);
      expect(booking.title, 'Test Meeting');
      expect(booking.location, 'Room 101');
      expect(booking.description, 'Test description');
      expect(booking.meetingLink, 'https://teams.microsoft.com/test');
      expect(booking.organizerName, 'Test Organizer');
      expect(booking.organizerEmail, 'organizer@example.com');
    });

    test('creates from Microsoft JSON with body content fallback', () {
      final json = {
        'id': 'test-id',
        'subject': 'Meeting',
        'start': {'dateTime': '2026-02-10T10:00:00'},
        'end': {'dateTime': '2026-02-10T11:00:00'},
        'bodyPreview': '',
        'body': {'content': 'Full body content here'},
      };

      final booking = Booking.fromMicrosoft(json);

      expect(booking.description, 'Full body content here');
    });

    test('creates from Microsoft JSON with missing optional fields', () {
      final json = {
        'id': 'minimal-id',
        'start': {'dateTime': '2026-02-10T10:00:00'},
        'end': {'dateTime': '2026-02-10T11:00:00'},
      };

      final booking = Booking.fromMicrosoft(json);

      expect(booking.id, 'm:minimal-id');
      expect(booking.title, '');
      expect(booking.location, '');
      expect(booking.description, '');
      expect(booking.meetingLink, '');
      expect(booking.organizerName, '');
      expect(booking.organizerEmail, '');
    });
  });

  group('OAuthToken', () {
    test('fromJson with expires_at', () {
      final json = {
        'access_token': 'test-token',
        'refresh_token': 'refresh-token',
        'expires_at': '2026-02-10T12:00:00.000Z',
      };

      final token = OAuthToken.fromJson(json);

      expect(token.accessToken, 'test-token');
      expect(token.refreshToken, 'refresh-token');
      expect(token.expiresAt.year, 2026);
    });

    test('fromJson with expires_in', () {
      final json = {'access_token': 'test-token', 'expires_in': '3600'};

      final token = OAuthToken.fromJson(json);

      expect(token.accessToken, 'test-token');
      expect(token.isExpired, false);
    });

    test('fromJson with default expires_in when missing', () {
      final json = {'access_token': 'test-token'};

      final token = OAuthToken.fromJson(json);

      expect(token.accessToken, 'test-token');
      expect(token.isExpired, false);
    });

    test('isExpired returns true for expired token', () {
      final token = OAuthToken(
        accessToken: 'test',
        expiresAt: DateTime.now().subtract(const Duration(hours: 1)),
      );

      expect(token.isExpired, true);
    });

    test('isExpired returns true within 1 minute buffer', () {
      final token = OAuthToken(
        accessToken: 'test',
        expiresAt: DateTime.now().add(const Duration(seconds: 30)),
      );

      expect(token.isExpired, true);
    });

    test('isExpired returns false for valid token', () {
      final token = OAuthToken(
        accessToken: 'test',
        expiresAt: DateTime.now().add(const Duration(hours: 1)),
      );

      expect(token.isExpired, false);
    });

    test('toJson round-trip', () {
      final token = OAuthToken(
        accessToken: 'test',
        refreshToken: 'refresh',
        expiresAt: DateTime(2026, 2, 10, 12, 0),
      );

      final json = token.toJson();

      expect(json['access_token'], 'test');
      expect(json['refresh_token'], 'refresh');
      expect(json['expires_at'], isNotNull);

      // Verify round-trip
      final restored = OAuthToken.fromJson(json);
      expect(restored.accessToken, token.accessToken);
      expect(restored.refreshToken, token.refreshToken);
    });

    test('toJson with null refresh token', () {
      final token = OAuthToken(
        accessToken: 'test',
        expiresAt: DateTime(2026, 2, 10, 12, 0),
      );

      final json = token.toJson();

      expect(json['access_token'], 'test');
      expect(json['refresh_token'], null);
    });
  });

  group('SyncResult', () {
    test('stores upserts and removedIds', () {
      final result = SyncResult<String>(
        upserts: ['a', 'b'],
        removedIds: ['c'],
        nextToken: 'token123',
      );

      expect(result.upserts, ['a', 'b']);
      expect(result.removedIds, ['c']);
      expect(result.nextToken, 'token123');
    });

    test('allows null nextToken', () {
      final result = SyncResult<int>(upserts: [1, 2, 3], removedIds: []);

      expect(result.upserts, [1, 2, 3]);
      expect(result.removedIds, isEmpty);
      expect(result.nextToken, null);
    });

    test('works with Booking type', () {
      final booking = Booking(
        id: 'test',
        source: BookingSource.google,
        title: 'Test',
        start: DateTime.now(),
        end: DateTime.now(),
        location: '',
        description: '',
        meetingLink: '',
        organizerName: '',
        organizerEmail: '',
      );

      final result = SyncResult<Booking>(
        upserts: [booking],
        removedIds: ['old-id'],
        nextToken: 'sync-token',
      );

      expect(result.upserts.length, 1);
      expect(result.upserts.first.id, 'test');
      expect(result.removedIds, ['old-id']);
    });
  });

  group('Date Parsers', () {
    group('parseMicrosoftDateTime', () {
      test('parses dateTime with timezone', () {
        final json = {'dateTime': '2026-02-10T10:00:00Z'};
        final result = parseMicrosoftDateTime(json);

        expect(result, isNotNull);
        expect(result!.year, 2026);
        expect(result.month, 2);
        expect(result.day, 10);
        expect(result.hour, 10);
      });

      test('parses dateTime without timezone as UTC', () {
        final json = {'dateTime': '2026-02-10T14:30:00'};
        final result = parseMicrosoftDateTime(json);

        expect(result, isNotNull);
        expect(result!.isUtc, true);
        expect(result.hour, 14);
        expect(result.minute, 30);
      });

      test('parses dateTime with positive offset', () {
        final json = {'dateTime': '2026-02-10T10:00:00+05:00'};
        final result = parseMicrosoftDateTime(json);

        expect(result, isNotNull);
        expect(result!.year, 2026);
      });

      test('returns null for invalid json', () {
        expect(parseMicrosoftDateTime(null), null);
        expect(parseMicrosoftDateTime('string'), null);
        expect(parseMicrosoftDateTime({}), null);
        expect(parseMicrosoftDateTime({'dateTime': null}), null);
      });
    });

    group('parseGoogleDateTime', () {
      test('parses dateTime format', () {
        final json = {'dateTime': '2026-02-10T15:00:00-08:00'};
        final result = parseGoogleDateTime(json);

        expect(result, isNotNull);
        expect(result!.year, 2026);
        expect(result.month, 2);
        expect(result.day, 10);
      });

      test('parses date only format (all-day events)', () {
        final json = {'date': '2026-02-10'};
        final result = parseGoogleDateTime(json);

        expect(result, isNotNull);
        expect(result!.year, 2026);
        expect(result.month, 2);
        expect(result.day, 10);
      });

      test('prefers dateTime over date', () {
        final json = {'dateTime': '2026-02-10T15:00:00Z', 'date': '2026-02-11'};
        final result = parseGoogleDateTime(json);

        expect(result, isNotNull);
        expect(result!.day, 10);
      });

      test('returns null for invalid json', () {
        expect(parseGoogleDateTime(null), null);
        expect(parseGoogleDateTime('string'), null);
        expect(parseGoogleDateTime({}), null);
        expect(parseGoogleDateTime({'dateTime': null, 'date': null}), null);
      });
    });
  });

  group('Formatting', () {
    test('formatTime formats morning time correctly', () {
      final time = DateTime(2026, 2, 10, 9, 30);
      final result = formatTime(time);

      expect(result, '9:30 AM');
    });

    test('formatTime formats afternoon time correctly', () {
      final time = DateTime(2026, 2, 10, 14, 45);
      final result = formatTime(time);

      expect(result, '2:45 PM');
    });

    test('formatTime formats noon correctly', () {
      final time = DateTime(2026, 2, 10, 12, 0);
      final result = formatTime(time);

      expect(result, '12:00 PM');
    });

    test('formatTime formats midnight correctly', () {
      final time = DateTime(2026, 2, 10, 0, 0);
      final result = formatTime(time);

      expect(result, '12:00 AM');
    });

    test('formatTime pads minutes with zero', () {
      final time = DateTime(2026, 2, 10, 10, 5);
      final result = formatTime(time);

      expect(result, '10:05 AM');
    });

    test('formatDateTime formats correctly', () {
      final dateTime = DateTime(2026, 2, 10, 14, 30);
      final result = formatDateTime(dateTime);

      expect(result, contains('2026'));
      expect(result, contains('02'));
      expect(result, contains('10'));
      expect(result, contains('14'));
      expect(result, contains('30'));
    });
  });
}
