import 'dart:convert';
import 'package:http/http.dart' as http;
import '../constants/api_constants.dart';

class QuranAudioService {
  // Singleton pattern
  static final QuranAudioService _instance = QuranAudioService._internal();
  factory QuranAudioService() => _instance;
  QuranAudioService._internal();

  // Current reciter
  String _currentReciter = 'ar.alafasy';

  // Getter and setter for the reciter
  String get currentReciter => _currentReciter;
  set currentReciter(String reciter) {
    _currentReciter = reciter;
  }

  // Get audio URL for a specific verse
  Future<String> getVerseAudioUrl(int surahNumber, int ayahNumber) async {
    final String primaryReciterId = _currentReciter.startsWith('custom.')
        ? _currentReciter.split('.')[2]
        : _currentReciter;

    // If it's the fallback API
    if (_currentReciter == 'custom.quranapi.$primaryReciterId') {
      return await _getAudioFromFallbackApi(surahNumber, ayahNumber);
    }

    // Otherwise, use the main API
    try {
      final response = await http.get(Uri.parse(
        '${ApiConstants.alQuranCloudBaseUrl}/ayah/$surahNumber:$ayahNumber/$_currentReciter'
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200 && data['data']['audio'] != null) {
          return data['data']['audio'];
        }
        throw Exception('Audio URL not found in AlQuran.cloud');
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      print('Error getting audio from AlQuran.cloud: $e. Trying fallback API...');
      return await _getAudioFromFallbackApi(surahNumber, ayahNumber);
    }
  }

  // Get audio from fallback API
  Future<String> _getAudioFromFallbackApi(int surahNumber, int ayahNumber) async {
    try {
      final response = await http.get(Uri.parse(
        '${ApiConstants.quranApiFallbackBaseUrl}/$surahNumber/$ayahNumber.json'
      ));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['audio'] != null && data['audio']['1'] != null && data['audio']['1']['url'] != null) {
          return data['audio']['1']['url'];
        }
        throw Exception('Audio URL not found in fallback API');
      }
      throw Exception('Request failed with status: ${response.statusCode}');
    } catch (e) {
      throw Exception('Error getting audio from fallback API: $e');
    }
  }

  // List of available reciters
  List<Map<String, String>> getAvailableReciters() {
    return [
      {'id': 'ar.alafasy', 'name': 'Mishary Rashid Al-Alafasy'},
      {'id': 'ar.minshawi', 'name': 'Mohamed Siddiq el-Minshawi'},
      {'id': 'ar.husary', 'name': 'Mahmoud Khalil Al-Husary'},
      {'id': 'ar.abdurrahmaansudais', 'name': 'Abdurrahmaan As-Sudais'},
      {'id': 'ar.shaatree', 'name': 'Abu Bakr Ash-Shaatree'},
      {'id': 'ar.hudhaify', 'name': 'Ali Al-Hudhaify'},
      {'id': 'ar.saoodshuraym', 'name': 'Saood Ash-Shuraym'},
      {'id': 'ar.mahermuaiqly', 'name': 'Maher Al Muaiqly'},
      {'id': 'custom.quranapi.alafasy', 'name': 'Mishary Alafasy (Fallback API)'},
    ];
  }
}
