import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import '../models/prayer_time.dart';
import '../services/location_service.dart';
import '../services/prayer_time_service.dart';

class PrayerRepository extends ChangeNotifier {
  final LocationService _locationService;
  final PrayerTimeService _prayerTimeService;

  List<PrayerTime> _prayerTimes = [];
  String _city = '';
  String _currentCalculationMethod = 'MWL'; // Default to Muslim World League
  bool _isLoading = false;
  int _notificationTime = 15; // minutes before prayer
  bool _hasInitialized = false;

  // Available calculation methods
  final List<String> _availableCalculationMethods = [
    'MWL',
    'ISNA',
    'Egypt',
    'Makkah',
    'Karachi',
    'Tehran',
    'Shia',
  ];

  PrayerRepository({
    required LocationService locationService,
    required PrayerTimeService prayerTimeService,
  })  : _locationService = locationService,
        _prayerTimeService = prayerTimeService {
    // Immediately start loading prayer times when repository is created
    fetchPrayerTimes();
  }

  List<PrayerTime> get prayerTimes => _prayerTimes;
  String get city => _city;
  bool get isLoading => _isLoading;
  String get currentCalculationMethod => _currentCalculationMethod;
  List<String> get availableCalculationMethods => _availableCalculationMethods;
  int get notificationTime => _notificationTime;

  void setCalculationMethod(String method) {
    _currentCalculationMethod = method;
    notifyListeners();
    fetchPrayerTimes();
  }

  void setNotificationTime(int minutes) {
    _notificationTime = minutes;
    notifyListeners();
  }

  void togglePrayerNotification(String prayerType) {
    final index = _prayerTimes.indexWhere((prayer) => prayer.type == prayerType);
    if (index != -1) {
      _prayerTimes[index] = _prayerTimes[index].copyWith(
        notificationEnabled: !_prayerTimes[index].notificationEnabled
      );
      notifyListeners();
    }
  }

  PrayerTime? get nextPrayer {
    if (_prayerTimes.isEmpty) {
      return null;
    }

    final now = DateTime.now();

    // Find the next prayer
    for (final prayer in _prayerTimes) {
      if (prayer.time.isAfter(now)) {
        return prayer;
      }
    }

    // If no prayer is found for today, return the first prayer for tomorrow
    return _prayerTimes.first;
  }

  String? get timeUntilNextPrayer {
    final next = nextPrayer;
    if (next == null) return null;

    final now = DateTime.now();
    final difference = next.time.difference(now);

    // Handle negative differences (should not happen in normal cases)
    if (difference.isNegative) return null;

    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;

    return '$hours orë $minutes minuta';
  }

  Future<void> fetchPrayerTimes() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Try to get location
      double latitude;
      double longitude;
      
      try {
        developer.log('Getting location for prayer times...', name: 'PrayerRepository');
        final position = await _locationService.getCurrentLocation();
        
        if (position == null) {
          throw Exception('Could not get location');
        }
        
        latitude = position.latitude;
        longitude = position.longitude;

        String? cityName = await _locationService.getCityName(position.latitude, position.longitude);
        _city = cityName ?? 'Tiranë';

        developer.log('Got location: $latitude, $longitude, $_city', name: 'PrayerRepository');
      } catch (e, stackTrace) {
        // Fallback to Tirana coordinates
        developer.log('Location error: $e. Using default Tirana location.',
            name: 'PrayerRepository', error: e, stackTrace: stackTrace);
        latitude = 41.3275;
        longitude = 19.8187;
        _city = 'Tiranë';
      }

      // Get prayer times using coordinates (real or fallback)
      developer.log('Calculating prayer times for $_city using method: $_currentCalculationMethod',
          name: 'PrayerRepository');

      _prayerTimes = await _prayerTimeService.getPrayerTimes(
        latitude: latitude,
        longitude: longitude,
        method: _currentCalculationMethod,
      );
      
      _hasInitialized = true;
      developer.log('Prayer times loaded for $_city: ${_prayerTimes.length} prayers',
          name: 'PrayerRepository');
    } catch (e, stackTrace) {
      developer.log('Error fetching prayer times: $e',
          name: 'PrayerRepository', error: e, stackTrace: stackTrace);
      // Create default prayer times as fallback
      final now = DateTime.now();
      _prayerTimes = [
        PrayerTime(type: 'Fajr', name: 'Sabahu', time: DateTime(now.year, now.month, now.day, 4, 0), notificationEnabled: true),
        PrayerTime(type: 'Sunrise', name: 'Lindja e diellit', time: DateTime(now.year, now.month, now.day, 5, 30), notificationEnabled: false),
        PrayerTime(type: 'Dhuhr', name: 'Dreka', time: DateTime(now.year, now.month, now.day, 12, 0), notificationEnabled: true),
        PrayerTime(type: 'Asr', name: 'Ikindia', time: DateTime(now.year, now.month, now.day, 15, 0), notificationEnabled: true),
        PrayerTime(type: 'Maghrib', name: 'Akshami', time: DateTime(now.year, now.month, now.day, 19, 0), notificationEnabled: true),
        PrayerTime(type: 'Isha', name: 'Jacia', time: DateTime(now.year, now.month, now.day, 20, 30), notificationEnabled: true),
      ];
      _city = 'Tiranë (Parazgjedhur)';
      _hasInitialized = true;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshPrayerTimes() async {
    await fetchPrayerTimes();
  }
}
