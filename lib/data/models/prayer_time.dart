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
}
