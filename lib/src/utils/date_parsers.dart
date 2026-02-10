DateTime? parseMicrosoftDateTime(dynamic json) {
  if (json is Map<String, dynamic>) {
    final value = json['dateTime']?.toString();
    if (value != null) {
      var parsed = DateTime.tryParse(value);
      if (parsed != null &&
          !value.contains('Z') &&
          !value.contains('+') &&
          !value.contains('-', 10)) {
        parsed = DateTime.utc(
          parsed.year,
          parsed.month,
          parsed.day,
          parsed.hour,
          parsed.minute,
          parsed.second,
          parsed.millisecond,
          parsed.microsecond,
        );
      }
      return parsed;
    }
  }
  return null;
}

DateTime? parseGoogleDateTime(dynamic json) {
  if (json is Map<String, dynamic>) {
    final dateTime = json['dateTime']?.toString();
    if (dateTime != null) {
      return DateTime.tryParse(dateTime);
    }
    final date = json['date']?.toString();
    if (date != null) {
      return DateTime.tryParse(date);
    }
  }
  return null;
}
