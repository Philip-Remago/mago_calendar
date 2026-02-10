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
    final onlineMeetingUrl = json['onlineMeetingUrl']?.toString() ?? '';
    final location = json['location']?['displayName']?.toString() ?? '';
    final organizer =
        json['organizer']?['emailAddress'] as Map<String, dynamic>?;
    return Booking(
      id: 'm:${json['id']?.toString() ?? ''}',
      source: BookingSource.microsoft,
      title: json['subject']?.toString() ?? '',
      start: start ?? DateTime.now(),
      end: end ?? DateTime.now(),
      location: location,
      description: bodyPreview.isNotEmpty ? bodyPreview : bodyContent,
      meetingLink: onlineMeetingUrl,
      organizerName: organizer?['name']?.toString() ?? '',
      organizerEmail: organizer?['address']?.toString() ?? '',
    );
  }

  factory Booking.fromGoogle(Map<String, dynamic> json) {
    final start = parseGoogleDateTime(json['start']);
    final end = parseGoogleDateTime(json['end']);
    final description = json['description']?.toString() ?? '';
    final hangoutLink = json['hangoutLink']?.toString() ?? '';
    final organizer = json['organizer'] as Map<String, dynamic>?;
    return Booking(
      id: 'g:${json['id']?.toString() ?? ''}',
      source: BookingSource.google,
      title: json['summary']?.toString() ?? '',
      start: start ?? DateTime.now(),
      end: end ?? DateTime.now(),
      location: json['location']?.toString() ?? '',
      description: description,
      meetingLink: hangoutLink,
      organizerName: organizer?['displayName']?.toString() ?? '',
      organizerEmail: organizer?['email']?.toString() ?? '',
    );
  }
}
