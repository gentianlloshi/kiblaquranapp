class PrayerTime {
  final String type;
  final String name;
  final DateTime time;
  bool notificationEnabled;

  PrayerTime({
    required this.type,
    required this.name,
    required this.time,
    this.notificationEnabled = true,
  });

  // Add copyWith method for creating a new instance with modified properties
  PrayerTime copyWith({
    String? type,
    String? name,
    DateTime? time,
    bool? notificationEnabled,
  }) {
    return PrayerTime(
      type: type ?? this.type,
      name: name ?? this.name,
      time: time ?? this.time,
      notificationEnabled: notificationEnabled ?? this.notificationEnabled,
    );
  }
}
