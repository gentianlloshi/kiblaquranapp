import 'package:flutter/material.dart';
import '../models/mosque.dart';
import '../services/location_service.dart';

class MosqueRepository extends ChangeNotifier {
  final LocationService _locationService;

  List<Mosque> _nearbyMosques = [];
  List<Mosque> _searchResults = [];
  bool _isLoading = false;
  double _maxDistance = 10.0; // km
  String _sortBy = 'distance'; // 'distance' or 'name'

  MosqueRepository(this._locationService);

  List<Mosque> get nearbyMosques => _nearbyMosques;
  List<Mosque> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  double get maxDistance => _maxDistance;
  String get sortBy => _sortBy;

  Future<void> loadNearbyMosques() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      final position = await _locationService.getCurrentLocation();

      // In a real app, this would fetch data from an API
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      _loadDummyMosques(position.latitude, position.longitude);

      _filterAndSortMosques();
    } catch (e) {
      debugPrint('Error loading mosques: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Method to search for mosques by name
  void searchMosques(String query) {
    if (query.isEmpty) {
      _searchResults = [];
    } else {
      _searchResults = _nearbyMosques
          .where((mosque) => mosque.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    notifyListeners();
  }

  // Alias for loadNearbyMosques for better semantics
  Future<void> fetchNearbyMosques() async {
    await loadNearbyMosques();
  }

  Future<void> refreshNearbyMosques() async {
    await loadNearbyMosques();
  }

  void setMaxDistance(double distance) {
    _maxDistance = distance;
    _filterAndSortMosques();
    notifyListeners();
  }

  void setSortBy(String sortBy) {
    _sortBy = sortBy;
    _filterAndSortMosques();
    notifyListeners();
  }

  // Filter mosques by distance
  void filterByDistance(double maxDistance) {
    _maxDistance = maxDistance;
    _filterAndSortMosques();
    notifyListeners();
  }

  void _filterAndSortMosques() {
    // Filter by distance
    _nearbyMosques = _nearbyMosques
        .where((mosque) => mosque.distance <= _maxDistance)
        .toList();

    // Sort by selected criteria
    if (_sortBy == 'distance') {
      _nearbyMosques.sort((a, b) => a.distance.compareTo(b.distance));
    } else if (_sortBy == 'name') {
      _nearbyMosques.sort((a, b) => a.name.compareTo(b.name));
    }
  }

  // Add a new mosque to the list
  Future<void> addMosque(Mosque mosque) async {
    _isLoading = true;
    notifyListeners();
    
    try {
      // In a real app, this would send data to an API
      await Future.delayed(const Duration(milliseconds: 800)); // Simulate network delay
      
      // Add mosque to list with a new ID
      final newId = (_nearbyMosques.length + 1).toString();
      final newMosque = Mosque(
        id: newId,
        name: mosque.name,
        address: mosque.address,
        latitude: mosque.latitude,
        longitude: mosque.longitude,
        distance: mosque.distance,
        prayerTimes: mosque.prayerTimes,
        facilities: mosque.facilities,
        imageUrl: mosque.imageUrl,
      );
      
      _nearbyMosques.add(newMosque);
      _filterAndSortMosques();
    } catch (e) {
      debugPrint('Error adding mosque: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Temporary method to load dummy data for demonstration
  void _loadDummyMosques(double latitude, double longitude) {
    _nearbyMosques = [
      Mosque(
        id: '1',
        name: 'Xhamia e Namazgjasë',
        address: 'Bul. Zogu I, Tiranë, Shqipëri',
        latitude: latitude + 0.002,
        longitude: longitude + 0.003,
        distance: 0.8,
        prayerTimes: [
          MosquePrayerTime(name: 'Fajr', time: '04:30'),
          MosquePrayerTime(name: 'Alba', time: '06:15'),
          MosquePrayerTime(name: 'Dhuhr', time: '12:00'),
          MosquePrayerTime(name: 'Asr', time: '15:45'),
          MosquePrayerTime(name: 'Maghrib', time: '19:30'),
          MosquePrayerTime(name: 'Isha', time: '21:00'),
        ],
        facilities: ['Parking', 'Abdest', 'Seksion për gra'],
      ),
      Mosque(
        id: '2',
        name: 'Xhamia Et\'hem Beu',
        address: 'Sheshi Skënderbej, Tiranë, Shqipëri',
        latitude: latitude - 0.001,
        longitude: longitude + 0.001,
        distance: 1.2,
        prayerTimes: [
          MosquePrayerTime(name: 'Fajr', time: '04:35'),
          MosquePrayerTime(name: 'Alba', time: '06:18'),
          MosquePrayerTime(name: 'Dhuhr', time: '12:05'),
          MosquePrayerTime(name: 'Asr', time: '15:50'),
          MosquePrayerTime(name: 'Maghrib', time: '19:35'),
          MosquePrayerTime(name: 'Isha', time: '21:05'),
        ],
        facilities: ['Historike', 'Turistike', 'Abdest', 'Seksion për gra'],
        imageUrl: 'https://example.com/ethem-bey.jpg',
      ),
      Mosque(
        id: '3',
        name: 'Xhamia e Dine Hoxhës',
        address: 'Rruga Kavajës, Tiranë, Shqipëri',
        latitude: latitude + 0.005,
        longitude: longitude - 0.002,
        distance: 2.1,
        prayerTimes: [
          MosquePrayerTime(name: 'Fajr', time: '04:32'),
          MosquePrayerTime(name: 'Alba', time: '06:16'),
          MosquePrayerTime(name: 'Dhuhr', time: '12:02'),
          MosquePrayerTime(name: 'Asr', time: '15:47'),
          MosquePrayerTime(name: 'Maghrib', time: '19:32'),
          MosquePrayerTime(name: 'Isha', time: '21:02'),
        ],
        facilities: ['Parking', 'Abdest', 'Bibliotekë', 'Seksion për gra'],
      ),
      Mosque(
        id: '4',
        name: 'Xhamia e Kokonozit',
        address: 'Rr. Myslym Shyri, Tiranë, Shqipëri',
        latitude: latitude - 0.004,
        longitude: longitude - 0.003,
        distance: 3.5,
        prayerTimes: [
          MosquePrayerTime(name: 'Fajr', time: '04:33'),
          MosquePrayerTime(name: 'Alba', time: '06:17'),
          MosquePrayerTime(name: 'Dhuhr', time: '12:03'),
          MosquePrayerTime(name: 'Asr', time: '15:48'),
          MosquePrayerTime(name: 'Maghrib', time: '19:33'),
          MosquePrayerTime(name: 'Isha', time: '21:03'),
        ],
        facilities: ['Parking', 'Abdest'],
      ),
      Mosque(
        id: '5',
        name: 'Xhamia e Tabakëve',
        address: 'Rruga e Dibrës, Tiranë, Shqipëri',
        latitude: latitude + 0.007,
        longitude: longitude + 0.005,
        distance: 4.2,
        prayerTimes: [
          MosquePrayerTime(name: 'Fajr', time: '04:31'),
          MosquePrayerTime(name: 'Alba', time: '06:16'),
          MosquePrayerTime(name: 'Dhuhr', time: '12:01'),
          MosquePrayerTime(name: 'Asr', time: '15:46'),
          MosquePrayerTime(name: 'Maghrib', time: '19:31'),
          MosquePrayerTime(name: 'Isha', time: '21:01'),
        ],
        facilities: ['Historike', 'Abdest', 'Seksion për gra'],
      ),
      Mosque(
        id: '6',
        name: 'Xhamia e Xhamlliqut',
        address: 'Rruga Pjeter Budi, Tiranë, Shqipëri',
        latitude: latitude - 0.008,
        longitude: longitude - 0.006,
        distance: 8.7,
        prayerTimes: [
          MosquePrayerTime(name: 'Fajr', time: '04:34'),
          MosquePrayerTime(name: 'Alba', time: '06:19'),
          MosquePrayerTime(name: 'Dhuhr', time: '12:04'),
          MosquePrayerTime(name: 'Asr', time: '15:49'),
          MosquePrayerTime(name: 'Maghrib', time: '19:34'),
          MosquePrayerTime(name: 'Isha', time: '21:04'),
        ],
        facilities: ['Parking', 'Abdest', 'Seksion për gra'],
      ),
    ];
  }
}
