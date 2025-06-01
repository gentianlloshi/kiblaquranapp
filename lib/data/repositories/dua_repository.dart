import 'package:flutter/material.dart';
import '../models/dua.dart';
import '../services/dua_service.dart';
import '../services/audio_service.dart';

class DuaRepository extends ChangeNotifier {
  final DuaService _duaService;
  final AudioService _audioService;

  List<Dua> _duas = [];
  List<Dua> _allahNames = [];
  final Set<String> _favoriteDuaIds = {};
  bool _isLoading = false;
  String? _currentlyPlayingDuaId;
  Map<String, String>? _dailyDua;
  Map<String, String>? _dailyVerse;

  DuaRepository(this._duaService, this._audioService);

  List<Dua> get duas => _duas;
  List<Dua> get allahNames => _allahNames;
  bool get isLoading => _isLoading;
  String? get currentlyPlayingDuaId => _currentlyPlayingDuaId;
  Map<String, String>? get dailyDua => _dailyDua;
  Map<String, String>? get dailyVerse => _dailyVerse;

  Future<void> loadDuas() async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Load actual duas from the service that reads JSON files
      _duas = await _duaService.loadDuas();

      // Load Allah names from separate JSON file
      _allahNames = await _duaService.loadAllahNames();
      
      // Set a daily dua
      await fetchDailyDua();
      
      // Set a daily verse
      await fetchDailyVerse();
    } catch (e) {
      debugPrint('Error loading duas: $e');
      // Fallback to empty list if loading fails
      _duas = [];
      _allahNames = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Fetch a daily dua (randomly selects one from the list)
  Future<void> fetchDailyDua() async {
    try {
      if (_duas.isEmpty) await loadDuas();
      
      // Get a random dua for the day based on current date
      final now = DateTime.now();
      final randomIndex = (now.day + now.month) % _duas.length;
      final dailyDua = _duas.length > randomIndex ? _duas[randomIndex] : null;
      
      if (dailyDua != null) {
        _dailyDua = {
          'title': dailyDua.title,
          'arabicText': dailyDua.arabicText,
          'translation': dailyDua.translation,
          'transliteration': dailyDua.transliteration,
        };
      } else {
        _dailyDua = null;
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching daily dua: $e');
    }
  }

  // Fetch a daily Quranic verse
  Future<void> fetchDailyVerse() async {
    try {
      // This would normally fetch from an API or local database
      // For now, we'll use a placeholder
      await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay
      
      _dailyVerse = {
        'text': 'Vërtet, në krijimin e qiejve dhe të tokës, dhe në ndërrimin e natës dhe të ditës, ka argumente për të zotët e mendjes.',
        'arabicText': 'إِنَّ فِي خَلْقِ السَّمَاوَاتِ وَالْأَرْضِ وَاخْتِلَافِ اللَّيْلِ وَالنَّهَارِ لَآيَاتٍ لِّأُولِي الْأَلْبَابِ',
        'reference': 'Al-Imran 3:190',
        'translation': 'Indeed, in the creation of the heavens and the earth and the alternation of the night and the day are signs for those of understanding.'
      };
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching daily verse: $e');
    }
  }

  List<Dua> getDailyDuas() {
    return _duas.where((dua) => dua.category == 'daily').toList();
  }

  Dua? getDailyDua() {
    final dailyDuas = getDailyDuas();
    return dailyDuas.isNotEmpty ? dailyDuas[0] : null;
  }

  List<Dua> getFavoriteDuas() {
    return _duas.where((dua) => _favoriteDuaIds.contains(dua.id)).toList();
  }

  List<Dua> getDuasByCategory(String category) {
    return _duas.where((dua) => dua.category == category).toList();
  }

  List<Dua> getMorningDuas() {
    return _duas.where((dua) => dua.category == 'morning_evening' && dua.subcategory == 'morning').toList();
  }

  List<Dua> getEveningDuas() {
    return _duas.where((dua) => dua.category == 'morning_evening' && dua.subcategory == 'evening').toList();
  }

  List<Dua> getPrayerRelatedDuas() {
    return _duas.where((dua) => dua.category == 'prayer_related').toList();
  }

  List<Dua> getQuranicDuas() {
    return _duas.where((dua) => dua.category == 'quranic').toList();
  }

  List<Dua> getAllahNames() {
    return _allahNames;
  }

  void toggleFavorite(String duaId) {
    if (_favoriteDuaIds.contains(duaId)) {
      _favoriteDuaIds.remove(duaId);
    } else {
      _favoriteDuaIds.add(duaId);
    }
    notifyListeners();
  }

  bool isFavorite(String duaId) {
    return _favoriteDuaIds.contains(duaId);
  }

  List<Dua> searchDuas(String query) {
    if (query.isEmpty) {
      return _duas;
    }

    final normalizedQuery = query.toLowerCase();
    return _duas.where((dua) {
      return dua.title.toLowerCase().contains(normalizedQuery) ||
             dua.translation.toLowerCase().contains(normalizedQuery) ||
             dua.transliteration.toLowerCase().contains(normalizedQuery);
    }).toList();
  }

  Future<void> playDuaAudio(String duaId) async {
    final dua = _findDuaById(duaId);

    if (dua != null && dua.audioUrl != null) {
      await _audioService.playAudio(dua.audioUrl!);
      _currentlyPlayingDuaId = duaId;
      notifyListeners();
    }
  }

  Dua? _findDuaById(String duaId) {
    try {
      return _duas.firstWhere((d) => d.id == duaId);
    } catch (_) {
      try {
        return _allahNames.firstWhere((d) => d.id == duaId);
      } catch (_) {
        return null;
      }
    }
  }

  Future<void> pauseDuaAudio() async {
    await _audioService.pauseAudio();
    notifyListeners();
  }

  Future<void> stopDuaAudio() async {
    await _audioService.stopAudio();
    _currentlyPlayingDuaId = null;
    notifyListeners();
  }

  bool isPlaying(String duaId) {
    return _currentlyPlayingDuaId == duaId && _audioService.isPlaying;
  }
}
