class MosquePrayerTime {
  final String name;
  final String time;

  MosquePrayerTime({
    required this.name,
    required this.time,
  });
}

class Mosque {
  final String id;
  final String name;
  final String address;
  final double latitude;
  final double longitude;
  final double distance;
  final List<MosquePrayerTime> prayerTimes;
  final List<String> facilities;
  final String? imageUrl;

  Mosque({
    required this.id,
    required this.name,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.distance,
    required this.prayerTimes,
    required this.facilities,
    this.imageUrl,
  });
}
