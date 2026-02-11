import '../utils/date_parsers.dart';

enum BookingSource { microsoft, google }

class Booking {
  const Booking({
    required this.id,
    required this.source,
    required this.title,
    required this.start,
    required this.end,
    required this.location,
    required this.description,
    required this.meetingLink,
    required this.organizerName,
    required this.organizerEmail,
  });

  final String id;
  final BookingSource source;
  final String title;
  final DateTime start;
  final DateTime end;
  final String location;
  final String description;
  final String meetingLink;
  final String organizerName;
  final String organizerEmail;

  factory Booking.fromMicrosoft(Map<String, dynamic> json) {
    final start = parseMicrosoftDateTime(json['start']);
    final end = parseMicrosoftDateTime(json['end']);
    final bodyPreview = json['bodyPreview']?.toString() ?? '';
    final bodyContent = json['body']?['content']?.toString() ?? '';
    final location = json['location']?['displayName']?.toString() ?? '';
    final organizer =
        json['organizer']?['emailAddress'] as Map<String, dynamic>?;

    String meetingLink = '';

    final onlineMeeting = json['onlineMeeting'] as Map<String, dynamic>?;
    if (onlineMeeting != null) {
      meetingLink = onlineMeeting['joinUrl']?.toString() ?? '';
    }

    if (meetingLink.isEmpty) {
      meetingLink = json['onlineMeetingUrl']?.toString() ?? '';
    }

    if (meetingLink.isEmpty) {
      meetingLink = _extractMeetingLinkFromHtml(bodyContent);
    }

    if (meetingLink.isEmpty && location.startsWith('https://')) {
      meetingLink = location;
    }

    return Booking(
      id: 'm:${json['id']?.toString() ?? ''}',
      source: BookingSource.microsoft,
      title: json['subject']?.toString() ?? '',
      start: start ?? DateTime.now(),
      end: end ?? DateTime.now(),
      location: location,
      description: bodyPreview.isNotEmpty ? bodyPreview : bodyContent,
      meetingLink: meetingLink,
      organizerName: organizer?['name']?.toString() ?? '',
      organizerEmail: organizer?['address']?.toString() ?? '',
    );
  }

  factory Booking.fromGoogle(Map<String, dynamic> json) {
    final start = parseGoogleDateTime(json['start']);
    final end = parseGoogleDateTime(json['end']);
    final description = json['description']?.toString() ?? '';
    final locationField = json['location']?.toString() ?? '';
    final organizer = json['organizer'] as Map<String, dynamic>?;

    String meetingLink = '';

    final conferenceData = json['conferenceData'] as Map<String, dynamic>?;
    if (conferenceData != null) {
      final entryPoints = conferenceData['entryPoints'] as List<dynamic>?;
      if (entryPoints != null && entryPoints.isNotEmpty) {
        for (final ep in entryPoints) {
          if (ep is Map<String, dynamic>) {
            final entryPointType = ep['entryPointType']?.toString() ?? '';
            final uri = ep['uri']?.toString() ?? '';
            if (entryPointType == 'video' && uri.isNotEmpty) {
              meetingLink = uri;
              break;
            }
          }
        }
        if (meetingLink.isEmpty) {
          for (final ep in entryPoints) {
            if (ep is Map<String, dynamic>) {
              final uri = ep['uri']?.toString() ?? '';
              if (uri.startsWith('https://')) {
                meetingLink = uri;
                break;
              }
            }
          }
        }
      }
    }

    if (meetingLink.isEmpty) {
      meetingLink = json['hangoutLink']?.toString() ?? '';
    }

    if (meetingLink.isEmpty && locationField.startsWith('https://')) {
      meetingLink = locationField;
    }

    if (meetingLink.isEmpty) {
      meetingLink = _extractMeetingLinkFromHtml(description);
    }

    return Booking(
      id: 'g:${json['id']?.toString() ?? ''}',
      source: BookingSource.google,
      title: json['summary']?.toString() ?? '',
      start: start ?? DateTime.now(),
      end: end ?? DateTime.now(),
      location: locationField,
      description: description,
      meetingLink: meetingLink,
      organizerName: organizer?['displayName']?.toString() ?? '',
      organizerEmail: organizer?['email']?.toString() ?? '',
    );
  }

  static String _extractMeetingLinkFromHtml(String html) {
    if (html.isEmpty) return '';

    String decoded = html
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"');

    final patterns = <RegExp>[
      RegExp(r'https://teams\.microsoft\.com/l/meetup-join/[^\s<>"]+'),
      RegExp(r'https://teams\.live\.com/meet/[^\s<>"]+'),
      RegExp(r'href="(https://teams\.microsoft\.com/l/meetup-join/[^"]+)"'),

      RegExp(r'https://[a-z0-9]+\.zoom\.us/j/[^\s<>"]+'),
      RegExp(r'https://zoom\.us/j/[^\s<>"]+'),

      RegExp(r'https://meet\.google\.com/[a-z]{3}-[a-z]{4}-[a-z]{3}'),

      RegExp(r'https://[a-z0-9]+\.webex\.com/[^\s<>"]+'),
    ];

    for (final pattern in patterns) {
      final match = pattern.firstMatch(decoded);
      if (match != null) {
        final link = match.groupCount > 0 ? match.group(1) : match.group(0);
        if (link != null && link.isNotEmpty) {
          return link;
        }
      }
    }

    return '';
  }
}
