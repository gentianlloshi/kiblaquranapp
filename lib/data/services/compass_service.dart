import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_compass/flutter_compass.dart';

class CompassService {
  Stream<double>? _compassStream;

  CompassService() {
    _initializeCompass();
  }

  void _initializeCompass() {
    if (FlutterCompass.events == null) {
      debugPrint("Compass sensor not available on this device");
      return;
    }

    _compassStream = FlutterCompass.events!
        .map((event) => event.heading ?? 0)
        .asBroadcastStream();
  }

  Stream<double>? get compassStream => _compassStream;

  Future<bool> isCompassAvailable() async {
    return FlutterCompass.events != null;
  }

  Future<double> getCurrentHeading() async {
    if (await isCompassAvailable()) {
      final CompassEvent event = await FlutterCompass.events!.first;
      return event.heading ?? 0;
    } else {
      return 0; // Default heading if compass is not available
    }
  }
}
