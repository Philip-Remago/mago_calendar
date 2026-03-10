enum CalendarSource { microsoft, google }

class CalendarInfo {
  const CalendarInfo({
    required this.id,
    required this.name,
    required this.source,
    this.isPrimary = false,
    this.color,
    this.accessRole,
  });

  final String id;
  final String name;
  final CalendarSource source;
  final bool isPrimary;
  final String? color;
  final String? accessRole;

  factory CalendarInfo.fromMicrosoft(Map<String, dynamic> json) {
    return CalendarInfo(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      source: CalendarSource.microsoft,
      isPrimary: json['isDefaultCalendar'] == true,
      color: json['hexColor']?.toString(),
    );
  }

  factory CalendarInfo.fromGoogle(Map<String, dynamic> json) {
    return CalendarInfo(
      id: json['id']?.toString() ?? '',
      name: json['summary']?.toString() ?? '',
      source: CalendarSource.google,
      isPrimary: json['primary'] == true,
      color: json['backgroundColor']?.toString(),
      accessRole: json['accessRole']?.toString(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CalendarInfo && id == other.id && source == other.source;

  @override
  int get hashCode => id.hashCode ^ source.hashCode;

  @override
  String toString() =>
      'CalendarInfo(id: $id, name: $name, primary: $isPrimary)';
}
