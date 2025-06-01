import 'package:flutter/material.dart';

import '../models/prayer_time.dart';
import '../services/location_service.dart';
import '../services/prayer_time_service.dart';

class PrayerRepository extends ChangeNotifier {
  final LocationService _locationService;
  final PrayerTimeService _prayerTimeService;

  List<PrayerTime> _prayerTimes = [];
  bool _isLoading = false;
  String? _city;
  String _currentCalculationMethod = 'Muslim World League';
  int _notificationTime = 15; // minutes before prayer

  final List<String> _availableCalculationMethods = [
    'Muslim World League',
    'Islamic Society of North America',
    'Egyptian General Authority of Survey',
    'Umm Al-Qura University, Makkah',
    'University of Islamic Sciences, Karachi',
    'Institute of Geophysics, University of Tehran',
    'Shia Ithna-Ashari',
  ];

  PrayerRepository(this._locationService, this._prayerTimeService);

  List<PrayerTime> get prayerTimes => _prayerTimes;
  bool get isLoading => _isLoading;
  String? get city => _city;
  String get currentCalculationMethod => _currentCalculationMethod;
  List<String> get availableCalculationMethods => _availableCalculationMethods;
  int get notificationTime => _notificationTime;

  Future<void> fetchPrayerTimes() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();
      _city = await _locationService.getCityName(position);

      _prayerTimes = await _prayerTimeService.getPrayerTimes(
        latitude: position.latitude,
        longitude: position.longitude,
        method: _currentCalculationMethod,
      );
    } catch (e) {
      debugPrint('Error loading prayer times: $e');
      // Use dummy data for demonstration purposes
      _loadDummyPrayerTimes();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Helper function to load dummy data when real data can't be fetched
  void _loadDummyPrayerTimes() {
    final now = DateTime.now();
    _city = "Tiranë";

    _prayerTimes = [
      PrayerTime(type: 'Fajr', name: 'Fajr Prayer', time: DateTime(now.year, now.month, now.day, 4, 15), notificationEnabled: true),
      PrayerTime(type: 'Sunrise', name: 'Sunrise', time: DateTime(now.year, now.month, now.day, 5, 45), notificationEnabled: false),
      PrayerTime(type: 'Dhuhr', name: 'Dhuhr Prayer', time: DateTime(now.year, now.month, now.day, 12, 30), notificationEnabled: true),
      PrayerTime(type: 'Asr', name: 'Asr Prayer', time: DateTime(now.year, now.month, now.day, 16, 0), notificationEnabled: true),
      PrayerTime(type: 'Maghrib', name: 'Maghrib Prayer', time: DateTime(now.year, now.month, now.day, 19, 45), notificationEnabled: true),
      PrayerTime(type: 'Isha', name: 'Isha Prayer', time: DateTime(now.year, now.month, now.day, 21, 15), notificationEnabled: true),
    ];
  }

  Future<void> refreshPrayerTimes() async {
    await fetchPrayerTimes();
  }

  void setCalculationMethod(String method) {
    if (_availableCalculationMethods.contains(method) && method != _currentCalculationMethod) {
      _currentCalculationMethod = method;
      fetchPrayerTimes();
    }
  }

  void setNotificationTime(int minutes) {
    _notificationTime = minutes;
    notifyListeners();
  }

  void togglePrayerNotification(String prayerType) {
    final index = _prayerTimes.indexWhere((prayer) => prayer.type == prayerType);
    if (index != -1) {
      _prayerTimes[index].notificationEnabled = !_prayerTimes[index].notificationEnabled;
      notifyListeners();
    }
  }

  PrayerTime? get nextPrayer {
    final now = DateTime.now();

    // Find the next prayer
    for (final prayer in _prayerTimes) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    // If no prayer is found for today, return the first prayer for tomorrow
    return _prayerTimes.isEmpty ? null : _prayerTimes.first;
  }

  String? get timeUntilNextPrayer {
    final next = nextPrayer;
    if (next == null) return null;

    final now = DateTime.now();
    final difference = next.time.difference(now);

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return '$hours orë $minutes minuta';
  }
}
