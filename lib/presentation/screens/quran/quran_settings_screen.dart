import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';

class QuranSettingsScreen extends StatefulWidget {
  final QuranRepository quranRepository;

  const QuranSettingsScreen({super.key, required this.quranRepository});

  @override
  _QuranSettingsScreenState createState() => _QuranSettingsScreenState();
}

class _QuranSettingsScreenState extends State<QuranSettingsScreen> {
  bool _isLoading = true;
  String _currentTranslator = 'sq.ahmeti';
  String _currentReciter = 'ar.alafasy';

  // Display options
  bool _showArabic = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;
  String _arabicFontFamily = 'ScheherazadeNew';
  double _arabicFontSize = 2.0;
  double _translationFontSize = 1.0;
  double _transliterationFontSize = 0.95;

  final Map<String, String> _translators = {
    'sq.ahmeti': 'Sherif Ahmeti',
    'sq.mehdiu': 'Feti Mehdiu',
    'sq.nahi': 'Hasan Nahi',
  };

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      // Get display preferences
      final displayPrefs = await widget.quranRepository.getDisplayPreferences();

      // Get current translator and reciter
      final currentTranslator = await widget.quranRepository.getDisplayPreferences().then((prefs) =>
          prefs['currentTranslator'] ?? 'sq.ahmeti');
      final currentReciter = await widget.quranRepository.getDisplayPreferences().then((prefs) =>
          prefs['currentReciter'] ?? 'ar.alafasy');

      setState(() {
        // Set display options
        _showArabic = displayPrefs['showArabic'] ?? true;
        _showTransliteration = displayPrefs['showTransliteration'] ?? true;
        _showTranslation = displayPrefs['showTranslation'] ?? true;
        _arabicFontFamily = displayPrefs['arabicFontFamily'] ?? 'ScheherazadeNew';
        _arabicFontSize = displayPrefs['arabicFontSize'] ?? 2.0;
        _translationFontSize = displayPrefs['translationFontSize'] ?? 1.0;
        _transliterationFontSize = displayPrefs['transliterationFontSize'] ?? 0.95;

        // Set current translator and reciter
        _currentTranslator = currentTranslator;
        _currentReciter = currentReciter;

        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading settings: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quran Settings'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('Translation'),
                  _buildTranslatorSelector(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Audio'),
                  _buildReciterSelector(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Display Options'),
                  _buildDisplayOptions(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Font Sizes'),
                  _buildFontSizeSliders(),
                  const SizedBox(height: 24),

                  _buildSectionTitle('Arabic Font'),
                  _buildArabicFontSelector(),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildTranslatorSelector() {
    return Card(
      child: Column(
        children: _translators.entries.map((entry) {
          final translatorId = entry.key;
          final translatorName = entry.value;

          return RadioListTile<String>(
            title: Text(translatorName),
            value: translatorId,
            groupValue: _currentTranslator,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _currentTranslator = value;
                });
                await widget.quranRepository.setCurrentTranslator(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Translator changed to $translatorName')),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildReciterSelector() {
    final reciters = widget.quranRepository.getAvailableReciters();

    return Card(
      child: Column(
        children: reciters.map((reciter) {
          return RadioListTile<String>(
            title: Text(reciter['name']!),
            value: reciter['id']!,
            groupValue: _currentReciter,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _currentReciter = value;
                });
                await widget.quranRepository.setCurrentReciter(value);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Reciter changed to ${reciter['name']}')),
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildDisplayOptions() {
    return Card(
      child: Column(
        children: [
          SwitchListTile(
            title: const Text('Show Arabic Text'),
            value: _showArabic,
            onChanged: (value) async {
              setState(() {
                _showArabic = value;
              });
              await widget.quranRepository.updateDisplayPreferences(
                showArabic: value,
              );
            },
          ),
          SwitchListTile(
            title: const Text('Show Transliteration'),
            value: _showTransliteration,
            onChanged: (value) async {
              setState(() {
                _showTransliteration = value;
              });
              await widget.quranRepository.updateDisplayPreferences(
                showTransliteration: value,
              );
            },
          ),
          SwitchListTile(
            title: const Text('Show Translation'),
            value: _showTranslation,
            onChanged: (value) async {
              setState(() {
                _showTranslation = value;
              });
              await widget.quranRepository.updateDisplayPreferences(
                showTranslation: value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFontSizeSliders() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Arabic Text Size'),
            Slider(
              value: _arabicFontSize,
              min: 1.0,
              max: 3.0,
              divisions: 10,
              label: _arabicFontSize.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _arabicFontSize = value;
                });
              },
              onChangeEnd: (value) async {
                await widget.quranRepository.updateDisplayPreferences(
                  arabicFontSize: value,
                );
              },
            ),
            const SizedBox(height: 16),

            const Text('Translation Text Size'),
            Slider(
              value: _translationFontSize,
              min: 0.8,
              max: 2.0,
              divisions: 6,
              label: _translationFontSize.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _translationFontSize = value;
                });
              },
              onChangeEnd: (value) async {
                await widget.quranRepository.updateDisplayPreferences(
                  translationFontSize: value,
                );
              },
            ),
            const SizedBox(height: 16),

            const Text('Transliteration Text Size'),
            Slider(
              value: _transliterationFontSize,
              min: 0.8,
              max: 2.0,
              divisions: 6,
              label: _transliterationFontSize.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  _transliterationFontSize = value;
                });
              },
              onChangeEnd: (value) async {
                await widget.quranRepository.updateDisplayPreferences(
                  transliterationFontSize: value,
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArabicFontSelector() {
    final arabicFonts = {
      'ScheherazadeNew': 'Scheherazade New',
      'Amiri': 'Amiri',
      'NotoNaskhArabic': 'Noto Naskh Arabic',
    };

    return Card(
      child: Column(
        children: arabicFonts.entries.map((entry) {
          final fontFamily = entry.key;
          final fontName = entry.value;

          return RadioListTile<String>(
            title: Text(
              'بِسْمِ اللَّهِ الرَّحْمَنِ الرَّحِيمِ',
              style: TextStyle(fontFamily: fontFamily),
            ),
            subtitle: Text(fontName),
            value: fontFamily,
            groupValue: _arabicFontFamily,
            onChanged: (value) async {
              if (value != null) {
                setState(() {
                  _arabicFontFamily = value;
                });
                await widget.quranRepository.updateDisplayPreferences(
                  arabicFontFamily: value,
                );
              }
            },
          );
        }).toList(),
      ),
    );
  }
}
