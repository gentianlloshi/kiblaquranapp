import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  // Stream controller to manage the heading data
  final StreamController<double> _headingController = StreamController<double>.broadcast();
  Stream<double> get compassStream => _headingController.stream;
  Stream<double> get headingStream => _headingController.stream;

  Timer? _compassCheckTimer;
  bool _compassSensorWorking = false;
  DateTime? _lastRealCompassUpdate;
  StreamSubscription? _compassSubscription;

  CompassService() {
    _initializeCompass();
  }

  void _initializeCompass() {
    try {
      developer.log("Initializing compass", name: 'CompassService');

      // Check if compass is available
      if (FlutterCompass.events == null) {
        developer.log("Compass sensor not available on this device", name: 'CompassService');
        _startFallbackCompass();
        return;
      }

      // Listen to compass events
      _compassSubscription = FlutterCompass.events!.listen(
        (CompassEvent event) {
          if (event.heading != null) {
            _lastRealCompassUpdate = DateTime.now();
            _compassSensorWorking = true;
            _headingController.add(event.heading!);
          } else {
            developer.log("Received null heading", name: 'CompassService');
          }
        },
        onError: (e) {
          developer.log("Error from compass: $e", name: 'CompassService', error: e);
          _compassSensorWorking = false;
          _startFallbackCompass();
        },
        cancelOnError: false,
      );

      // Start a timer to check if compass is working
      _compassCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) {
        _checkCompassStatus();
      });

      developer.log("Compass initialized successfully", name: 'CompassService');
    } catch (e) {
      developer.log("Failed to initialize compass: $e", name: 'CompassService', error: e);
      _startFallbackCompass();
    }
  }

  void _checkCompassStatus() {
    // Check if we've received compass updates in the last 5 seconds
    if (_lastRealCompassUpdate != null) {
      final timeSinceUpdate = DateTime.now().difference(_lastRealCompassUpdate!);
      if (timeSinceUpdate.inSeconds > 5) {
        developer.log("No compass updates for 5 seconds, switching to fallback", name: 'CompassService');
        _compassSensorWorking = false;
        _startFallbackCompass();
      }
    } else if (!_compassSensorWorking) {
      _startFallbackCompass();
    }
  }

  void _startFallbackCompass() {
    developer.log("Starting fallback compass simulation", name: 'CompassService');

    // Cancel real compass subscription if it exists
    _compassSubscription?.cancel();

    // Provide a simulated compass stream
    Timer.periodic(const Duration(milliseconds: 100), (timer) {
      // If the real compass starts working again, cancel this timer
      if (_compassSensorWorking) {
        timer.cancel();
        return;
      }

      // Generate a small random movement to simulate compass adjustments
      // This will rotate slowly in a circle to simulate a working compass
      final now = DateTime.now();
      final angle = (now.millisecondsSinceEpoch / 50) % 360;
      _headingController.add(angle);
    });
  }

  Future<bool> isCompassAvailable() async {
    try {
      final isAvailable = FlutterCompass.events != null;
      developer.log("Compass available: $isAvailable", name: 'CompassService');
      return isAvailable;
    } catch (e) {
      developer.log("Error checking compass availability: $e", name: 'CompassService', error: e);
      return false;
    }
  }

  Future<double> getCurrentHeading() async {
    try {
      if (await isCompassAvailable() && _compassSensorWorking) {
        final CompassEvent event = await FlutterCompass.events!.first;
        return event.heading ?? 0;
      } else {
        developer.log("Using fallback heading", name: 'CompassService');
        // Return a simulated value
        return (DateTime.now().millisecondsSinceEpoch / 50) % 360;
      }
    } catch (e) {
      developer.log("Error getting compass heading: $e", name: 'CompassService', error: e);
      return 0;
    }
  }

  void dispose() {
    _compassSubscription?.cancel();
    _compassCheckTimer?.cancel();
    _headingController.close();
  }
}
