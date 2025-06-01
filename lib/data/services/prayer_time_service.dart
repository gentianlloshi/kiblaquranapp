import 'package:flutter/foundation.dart';
import 'package:adhan/adhan.dart';
import '../models/prayer_time.dart';

class PrayerTimeService {
  Future<List<PrayerTime>> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String method,
  }) async {
    try {
      // Set calculation parameters based on selected method
      final params = _getCalculationMethod(method);

      // Set coordinates
      final coordinates = Coordinates(latitude, longitude);

      // Get today's date
      final date = DateTime.now();
      final dateComponents = DateComponents.from(date);

      // Create PrayerTimes object
      final prayerTimes = PrayerTimes(
        coordinates,
        dateComponents,
        params,
      );

      // Convert to our app's prayer time model
      final List<PrayerTime> formattedPrayerTimes = [
        PrayerTime(
          type: 'Fajr',
          name: 'Fajr Prayer',
          time: prayerTimes.fajr,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Sunrise',
          name: 'Sunrise',
          time: prayerTimes.sunrise,
          notificationEnabled: false,
        ),
        PrayerTime(
          type: 'Dhuhr',
          name: 'Dhuhr Prayer',
          time: prayerTimes.dhuhr,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Asr',
          name: 'Asr Prayer',
          time: prayerTimes.asr,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Maghrib',
          name: 'Maghrib Prayer',
          time: prayerTimes.maghrib,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Isha',
          name: 'Isha Prayer',
          time: prayerTimes.isha,
          notificationEnabled: true,
        ),
      ];

      return formattedPrayerTimes;
    } catch (e) {
      debugPrint('Error calculating prayer times: $e');
      throw Exception('Failed to calculate prayer times');
    }
  }

  CalculationParameters _getCalculationMethod(String method) {
    switch(method) {
      case 'Muslim World League':
        return CalculationMethod.muslim_world_league.getParameters();
      case 'Islamic Society of North America':
        return CalculationMethod.north_america.getParameters();
      case 'Egyptian General Authority of Survey':
        return CalculationMethod.egyptian.getParameters();
      case 'Umm Al-Qura University, Makkah':
        return CalculationMethod.umm_al_qura.getParameters();
      case 'University of Islamic Sciences, Karachi':
        return CalculationMethod.karachi.getParameters();
      case 'Institute of Geophysics, University of Tehran':
        return CalculationMethod.tehran.getParameters();
      case 'Shia Ithna-Ashari':
        return CalculationMethod.north_america.getParameters(); // Changed from shia to a supported method
      default:
        return CalculationMethod.muslim_world_league.getParameters();
    }
  }
}
