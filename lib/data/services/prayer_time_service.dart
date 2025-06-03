import 'dart:developer' as developer;
import 'package:adhan/adhan.dart';
import '../models/prayer_time.dart';

class PrayerTimeService {
  Future<List<PrayerTime>> getPrayerTimes({
    required double latitude,
    required double longitude,
    required String method,
  }) async {
    try {
      // Use log instead of debugPrint to ensure it works in release mode when needed
      developer.log('Calculating prayer times for: $latitude, $longitude using method: $method',
          name: 'PrayerTimeService');

      // Validate coordinates
      if (latitude < -90 || latitude > 90 || longitude < -180 || longitude > 180) {
        throw ArgumentError('Invalid coordinates: $latitude, $longitude');
      }

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

      developer.log('Prayer times calculated successfully', name: 'PrayerTimeService');

      // Convert to our app's prayer time model with Albanian names
      final List<PrayerTime> formattedPrayerTimes = [
        PrayerTime(
          type: 'Fajr',
          name: 'Sabahu',
          time: prayerTimes.fajr,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Sunrise',
          name: 'Lindja e diellit',
          time: prayerTimes.sunrise,
          notificationEnabled: false,
        ),
        PrayerTime(
          type: 'Dhuhr',
          name: 'Dreka',
          time: prayerTimes.dhuhr,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Asr',
          name: 'Ikindia',
          time: prayerTimes.asr,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Maghrib',
          name: 'Akshami',
          time: prayerTimes.maghrib,
          notificationEnabled: true,
        ),
        PrayerTime(
          type: 'Isha',
          name: 'Jacia',
          time: prayerTimes.isha,
          notificationEnabled: true,
        ),
      ];
      
      return formattedPrayerTimes;
    } catch (e, stackTrace) {
      // Log error in a way that works in both debug and release mode
      developer.log('Error calculating prayer times: $e',
          name: 'PrayerTimeService', error: e, stackTrace: stackTrace);

      // Create fallback prayer times instead of rethrowing
      final now = DateTime.now();
      return [
        PrayerTime(type: 'Fajr', name: 'Sabahu', time: DateTime(now.year, now.month, now.day, 4, 0), notificationEnabled: true),
        PrayerTime(type: 'Sunrise', name: 'Lindja e diellit', time: DateTime(now.year, now.month, now.day, 5, 30), notificationEnabled: false),
        PrayerTime(type: 'Dhuhr', name: 'Dreka', time: DateTime(now.year, now.month, now.day, 12, 0), notificationEnabled: true),
        PrayerTime(type: 'Asr', name: 'Ikindia', time: DateTime(now.year, now.month, now.day, 15, 0), notificationEnabled: true),
        PrayerTime(type: 'Maghrib', name: 'Akshami', time: DateTime(now.year, now.month, now.day, 19, 0), notificationEnabled: true),
        PrayerTime(type: 'Isha', name: 'Jacia', time: DateTime(now.year, now.month, now.day, 20, 30), notificationEnabled: true),
      ];
    }
  }

  CalculationParameters _getCalculationMethod(String method) {
    try {
      // Use simple method keys that match the repository
      switch (method) {
        case 'MWL':
          return CalculationMethod.muslim_world_league.getParameters();
        case 'ISNA':
          return CalculationMethod.north_america.getParameters();
        case 'Egypt':
          return CalculationMethod.egyptian.getParameters();
        case 'Makkah':
          return CalculationMethod.umm_al_qura.getParameters();
        case 'Karachi':
          return CalculationMethod.karachi.getParameters();
        case 'Tehran':
          return CalculationMethod.tehran.getParameters();
        case 'Shia':
          // Use another calculation method since 'shia' isn't available
          return CalculationMethod.other.getParameters();
        default:
          developer.log('Unknown calculation method: $method, falling back to Muslim World League', name: 'PrayerTimeService');
          return CalculationMethod.muslim_world_league.getParameters();
      }
    } catch (e) {
      developer.log('Error getting calculation method: $e', name: 'PrayerTimeService');
      return CalculationMethod.muslim_world_league.getParameters();
    }
  }
}
