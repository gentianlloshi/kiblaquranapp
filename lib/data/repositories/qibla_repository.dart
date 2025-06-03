import 'dart:async';
import 'dart:math' as math;
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../services/location_service.dart';
import '../services/compass_service.dart';
import '../../utils/permission_utils.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaRepository extends ChangeNotifier {
  final LocationService _locationService;
  final CompassService _compassService;

  QiblaLocation? _currentLocation;
  double? _qiblaDirection;
  double _distanceToKaaba = 0;
  bool _isLoading = false;
  bool _isInitializing = false;
  StreamSubscription<double>? _compassSubscription;
  double _currentHeading = 0;
  
  // Performance monitoring
  DateTime? _lastCompassUpdate;
  double _compassUpdateInterval = 0;

  // Kaaba coordinates
  static const double kaabaLat = 21.4225;
  static const double kaabaLng = 39.8262;

  QiblaRepository(this._locationService, this._compassService) {
    _listenToCompass();
    initializeLocation();
  }

  void _listenToCompass() {
    final compassStream = _compassService.compassStream;
    _compassSubscription?.cancel();
    _compassSubscription = compassStream.listen(
      (heading) {
        // Calculate update interval for performance monitoring
        final now = DateTime.now();
        if (_lastCompassUpdate != null) {
          _compassUpdateInterval = now.difference(_lastCompassUpdate!).inMilliseconds.toDouble();
        }
        _lastCompassUpdate = now;
        
        _currentHeading = heading;
        notifyListeners();
      },
      onError: (e) {
        if (kDebugMode) {
          print('❌ Error in compass stream: $e');
        }
      }
    );
  }

  Future<bool> initializeLocation() async {
    if (_isInitializing) return false;
    
    _isInitializing = true;
    _isLoading = true;
    notifyListeners();
    
    try {
      // Request permissions using PermissionUtils
      final permissionsGranted = await _requestLocationPermissions();
      
      if (!permissionsGranted) {
        _isLoading = false;
        _isInitializing = false;
        notifyListeners();
        return false;
      }

      // Get current location
      await _updateLocation();
      
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
      return true;
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing location: $e');
      }
      _isLoading = false;
      _isInitializing = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> _updateLocation() async {
    try {
      final position = await _locationService.getCurrentLocation();
      
      if (position != null) {
        // Get city name if possible
        String? cityName;
        try {
          cityName = await _locationService.getCityName(position.latitude, position.longitude);
        } catch (e) {
          developer.log('Error getting city name: $e', name: 'QiblaRepository');
        }
        
        _currentLocation = QiblaLocation(
          latitude: position.latitude,
          longitude: position.longitude,
          altitude: position.altitude,
          accuracy: position.accuracy,
          city: cityName,
          distanceToKaaba: _calculateDistanceToKaaba(position.latitude, position.longitude),
        );
        _calculateQiblaDirection();
      }
    } catch (e) {
      developer.log('Error updating location: $e', name: 'QiblaRepository');
    }
  }

  Future<bool> _requestLocationPermissions() async {
    // Check if we can request permissions (requires a BuildContext)
    final locationStatus = await Permission.locationWhenInUse.status;
    
    // If already granted, return true
    if (locationStatus.isGranted) {
      return true;
    }
    
    // Otherwise, request directly (without UI context)
    final result = await Permission.locationWhenInUse.request();
    return result.isGranted;
  }

  /// Request location permissions with proper UI context
  Future<bool> requestLocationPermissionsWithContext(BuildContext context) async {
    final permissions = [Permission.locationWhenInUse];
    final rationales = {
      Permission.locationWhenInUse: 'Qibla direction requires location access to calculate the direction to Mecca based on your current position.',
    };
    
    final results = await PermissionUtils.requestPermissionsSequentially(
      context: context,
      permissions: permissions,
      rationales: rationales,
    );
    
    // Check if all permissions were granted
    return results.values.every((granted) => granted);
  }

  void _calculateQiblaDirection() {
    if (_currentLocation == null) return;
    
    final lat1 = _currentLocation!.latitude * (math.pi / 180);
    final lon1 = _currentLocation!.longitude * (math.pi / 180);
    final lat2 = kaabaLat * (math.pi / 180);
    final lon2 = kaabaLng * (math.pi / 180);
    
    final y = math.sin(lon2 - lon1) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) - math.sin(lat1) * math.cos(lat2) * math.cos(lon2 - lon1);
    final bearing = math.atan2(y, x);
    
    _qiblaDirection = (bearing * (180 / math.pi) + 360) % 360;
    notifyListeners();
  }

  double _calculateDistanceToKaaba(double lat1, double lon1) {
    return _locationService.calculateDistance(
      lat1,
      lon1,
      kaabaLat,
      kaabaLng,
    );
  }

  // Getters
  QiblaLocation? get currentLocation => _currentLocation;
  double? get qiblaDirection => _qiblaDirection;
  double get distanceToKaaba => _currentLocation?.distanceToKaaba ?? 0;
  bool get isLoading => _isLoading;
  bool get isInitializing => _isInitializing;
  double get currentHeading => _currentHeading;
  double get compassUpdateInterval => _compassUpdateInterval;
  bool get hasLocation => _currentLocation != null;
  
  // Method to refresh location data
  Future<void> refreshLocation() async {
    if (_isLoading) return;
    
    _isLoading = true;
    notifyListeners();
    
    try {
      await _updateLocation();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    super.dispose();
  }
}

class QiblaLocation {
  final double latitude;
  final double longitude;
  final double? altitude;
  final double? accuracy;
  final String? city;
  double distanceToKaaba;
  
  QiblaLocation({
    required this.latitude,
    required this.longitude,
    this.altitude,
    this.accuracy,
    this.city,
    this.distanceToKaaba = 0,
  });
  
  @override
  String toString() => 'QiblaLocation(lat: $latitude, lng: $longitude)';
}
