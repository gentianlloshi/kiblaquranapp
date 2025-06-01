import 'dart:async';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:geolocator/geolocator.dart';

import '../services/location_service.dart';
import '../services/compass_service.dart';

class Location {
  final double latitude;
  final double longitude;
  final String? city;

  Location({
    required this.latitude,
    required this.longitude,
    this.city,
  });
}

class QiblaRepository extends ChangeNotifier {
  final LocationService _locationService;
  final CompassService _compassService;

  Location? _currentLocation;
  double? _qiblaDirection;
  double _distanceToKaaba = 0;
  bool _isLoading = false;
  StreamSubscription<double>? _compassSubscription;
  double _currentHeading = 0;

  // Kaaba coordinates
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  QiblaRepository(this._locationService, this._compassService) {
    _listenToCompass();
  }

  Location? get currentLocation => _currentLocation;
  double? get qiblaDirection => _qiblaDirection;
  double get distanceToKaaba => _distanceToKaaba;
  bool get isLoading => _isLoading;
  double get currentHeading => _currentHeading;

  void _listenToCompass() {
    final compassStream = _compassService.compassStream;
    if (compassStream != null) {
      _compassSubscription = compassStream.listen((heading) {
        _currentHeading = heading;
        notifyListeners();
      });
    }
  }

  Future<void> initializeLocation() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Special handling for web platforms
      if (kIsWeb) {
        // On web, use default values since geolocation permissions can be complex
        debugPrint('Running on web platform: using mock location data for Qibla');
        _currentLocation = Location(
          latitude: 41.3275, // Default location (Tirana, Albania)
          longitude: 19.8187,
          city: 'Tiranë',
        );

        _calculateQiblaDirection();
        _calculateDistanceToKaaba();

        _isLoading = false;
        notifyListeners();
        return;
      }

      // Normal flow for mobile platforms
      final position = await _locationService.getCurrentLocation();
      _currentLocation = Location(
        latitude: position.latitude,
        longitude: position.longitude,
        city: await _locationService.getCityName(position),
      );

      _calculateQiblaDirection();
      _calculateDistanceToKaaba();
    } catch (e) {
      debugPrint('Error initializing location: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshLocation() async {
    await initializeLocation();
  }

  void _calculateQiblaDirection() {
    if (_currentLocation == null) return;

    final lat1 = _currentLocation!.latitude * (math.pi / 180);
    final lon1 = _currentLocation!.longitude * (math.pi / 180);
    const lat2 = kaabaLat * (math.pi / 180);
    const lon2 = kaabaLng * (math.pi / 180);

    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);

    var qibla = math.atan2(y, x);
    qibla = qibla * (180 / math.pi);
    _qiblaDirection = (qibla + 360) % 360; // Normalize to 0-360°
  }

  void _calculateDistanceToKaaba() {
    if (_currentLocation == null) return;

    // Calculate distance using Haversine formula
    _distanceToKaaba = Geolocator.distanceBetween(
      _currentLocation!.latitude,
      _currentLocation!.longitude,
      kaabaLat,
      kaabaLng,
    ) / 1000; // Convert meters to kilometers
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}
