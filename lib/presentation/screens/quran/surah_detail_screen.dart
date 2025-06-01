import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/models/surah.dart';
import '../../widgets/quran/ayah_widget.dart';
import '../../widgets/quran/audio_player_widget.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final int? initialAyahNumber;
  final QuranRepository quranRepository;

  const SurahDetailScreen({super.key, 
    required this.surahNumber,
    this.initialAyahNumber,
    required this.quranRepository,
  });

  @override
  _SurahDetailScreenState createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  bool _isLoading = true;
  late Surah _arabicSurah;
  late Surah _translationSurah;
  late Map<String, String> _transliterations;
  final ScrollController _scrollController = ScrollController();

  bool _showArabic = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _loadSurahData();
    _loadDisplayPreferences();
  }

  Future<void> _loadDisplayPreferences() async {
    final prefs = await widget.quranRepository.getDisplayPreferences();
    setState(() {
      _showArabic = prefs['showArabic'];
      _showTransliteration = prefs['showTransliteration'];
      _showTranslation = prefs['showTranslation'];
    });
  }

  Future<void> _loadSurahData() async {
    try {
      final data = await widget.quranRepository.getSurahWithTranslation(widget.surahNumber);

      setState(() {
        _arabicSurah = data['arabic'];
        _translationSurah = data['translation'];

        // Fix: Handle the nested structure of transliteration data correctly
        var transliterationData = data['transliteration'];
        _transliterations = {};

        // Debug what we're receiving
        print('Transliteration data type: ${transliterationData.runtimeType}');
        print('Transliteration data: $transliterationData');

        // If transliterations exist for this surah
        if (transliterationData is Map) {
          transliterationData.forEach((ayahNumber, transliteration) {
            _transliterations[ayahNumber.toString()] = transliteration.toString();
          });
        }

        _isLoading = false;
      });

      // Save last read position
    } catch (e) {
      print('Error loading surah data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Methods to handle ayah actions
  void _playAudio(int surahNumber, int ayahNumber) async {
    try {
      final audioUrl = await widget.quranRepository.getVerseAudioUrl(surahNumber, ayahNumber);

      showModalBottomSheet(
        context: context,
        builder: (context) => Container(
          padding: const EdgeInsets.all(16),
          child: AudioPlayerWidget(
            audioUrl: audioUrl,
            surahNumber: surahNumber,
            ayahNumber: ayahNumber,
          ),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error playing audio: $e')),
      );
    }
  }

  void _toggleFavorite(int surahNumber, int ayahNumber) {
    // Implement favorite functionality in future
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Favorite functionality will be implemented soon')),
    );
  }

  void _shareAyah(int surahNumber, int ayahNumber, String arabicText, String translationText) {
    // Implement share functionality in future
    final textToShare = 'Surah $surahNumber, Ayah $ayahNumber\n\n$arabicText\n\n$translationText';
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Share functionality will be implemented soon')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Surah ${widget.surahNumber}'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              controller: _scrollController,
              itemCount: _arabicSurah.ayahs.length,
              itemBuilder: (context, index) {
                final arabicAyah = _arabicSurah.ayahs[index];
                final translationAyah = _translationSurah.ayahs[index];

                // Properly access the transliteration by the ayah number (not the index)
                final transliteration = _transliterations[arabicAyah.numberInSurah.toString()] ?? '';

                // Debug to check if we have transliteration for this ayah
                if (index < 5) {  // Only print for first few ayahs to avoid flooding console
                  print('Ayah ${arabicAyah.numberInSurah} transliteration: "$transliteration"');
                }

                return AyahWidget(
                  surahNumber: widget.surahNumber,
                  ayahNumber: arabicAyah.numberInSurah,
                  arabicText: arabicAyah.text,
                  translationText: translationAyah.text,
                  transliterationText: transliteration,
                  showArabic: _showArabic,
                  showTransliteration: _showTransliteration,
                  showTranslation: _showTranslation,
                  onPlayAudio: _playAudio,
                  onToggleFavorite: _toggleFavorite,
                  onShare: _shareAyah,
                );
              },
            ),
      // Remove the AudioPlayerWidget from bottomNavigationBar since it requires parameters
      // that aren't appropriate for a persistent bottom navigation bar
      // bottomNavigationBar: AudioPlayerWidget(),
    );
  }
}
