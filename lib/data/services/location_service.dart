import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../repositories/qibla_repository.dart';

class LocationService {
  Future<Position?> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    try {
      // Test if location services are enabled.
      serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        developer.log('Location services not enabled', name: 'LocationService');
        return null;
      }

      permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        developer.log('Location permission denied', name: 'LocationService');
        return null;
      }

      // When we reach here, permissions are granted and we can continue accessing the position of the device.
      // Using a timeout to prevent hanging if location determination is slow
      developer.log('Getting current position with 5 second timeout...', name: 'LocationService');

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
        timeLimit: const Duration(seconds: 5),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          developer.log('Location request timed out', name: 'LocationService');
          return _getFallbackPosition();
        },
      );
    } catch (e, stack) {
      developer.log('Error getting location: $e',
          name: 'LocationService', error: e, stackTrace: stack);
      
      // Return fallback location in case of error
      if (kDebugMode) {
        // Only use fallback in debug mode
        return _getFallbackPosition();
      }
      
      return null;
    }
  }

  // Fallback position for Albania (Tirana)
  Position _getFallbackPosition() {
    developer.log('Using fallback position for Albania (Tirana)',
        name: 'LocationService');
    return Position(
      latitude: 41.3275,
      longitude: 19.8187,
      timestamp: DateTime.now(),
      accuracy: 0,
      altitude: 0,
      heading: 0,
      speed: 0,
      speedAccuracy: 0,
      altitudeAccuracy: 0,
      headingAccuracy: 0,
    );
  }

  Future<String?> getCityName(double latitude, double longitude) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(latitude, longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        final city = place.locality ?? place.subAdministrativeArea ?? place.administrativeArea;
        developer.log('Retrieved city name: ${city ?? "Unknown"}',
            name: 'LocationService');
        return city;
      }
    } catch (e) {
      developer.log('Error getting city name: $e', name: 'LocationService', error: e);
    }
    return null;
  }

  // Calculate distance between two coordinates in kilometers
  double calculateDistance(
    double startLatitude, 
    double startLongitude,
    double endLatitude, 
    double endLongitude,
  ) {
    try {
      return Geolocator.distanceBetween(
        startLatitude,
        startLongitude,
        endLatitude,
        endLongitude,
      ) / 1000; // Convert meters to kilometers
    } catch (e) {
      developer.log('Error calculating distance: $e', name: 'LocationService', error: e);
      return 0;
    }
  }
}
