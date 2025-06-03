import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../utils/translations.dart';
import '../../../data/models/surah.dart';
import 'surah_detail_screen.dart';
import 'quran_favorites_screen.dart';
import 'quran_diagnostic_screen.dart';
import 'quran_settings_screen.dart';

class QuranScreen extends StatefulWidget {
  final QuranRepository quranRepository;

  const QuranScreen({super.key, required this.quranRepository});

  @override
  State<QuranScreen> createState() => _QuranScreenState();
}

class _QuranScreenState extends State<QuranScreen> {
  bool _isLoading = true;
  List<Surah> _surahs = [];
  String? _errorMessage;
  Map<String, dynamic>? _lastReadPosition;
  List<Map<String, dynamic>> _favorites = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });

      // Initialize repository if needed
      if (!widget.quranRepository.isDataLoaded) {
        await widget.quranRepository.initialize();
      }

      // Get all surahs
      final surahs = widget.quranRepository.getAllSurahs();

      // Get last read position
      final lastRead = await widget.quranRepository.getLastReadPosition();
      
      // Get favorite verses
      final favorites = await widget.quranRepository.getFavoriteVerses();

      setState(() {
        _surahs = surahs;
        _lastReadPosition = lastRead;
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to load Quran data: $e';
      });
    }
  }

  void _openSurah(int surahNumber, [int? ayahNumber]) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => SurahDetailScreen(
          surahNumber: surahNumber,
          initialAyahNumber: ayahNumber,
          quranRepository: widget.quranRepository,
        ),
      ),
    ).then((_) => _loadData());  // Refresh data when coming back
  }

  void _openFavorites() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranFavoritesScreen(
          quranRepository: widget.quranRepository,
        ),
      ),
    ).then((_) => _loadData());  // Refresh data when coming back
  }

  void _openSettings() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranSettingsScreen(
          quranRepository: widget.quranRepository,
        ),
      ),
    ).then((_) => _loadData());  // Refresh data when coming back
  }

  void _openDiagnostics() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => QuranDiagnosticScreen(
          quranRepository: widget.quranRepository,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTranslations.quranTitle),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: _openSettings,
            tooltip: AppTranslations.settings,
          ),
          // Show diagnostic button only in debug mode
          if (kDebugMode)
            IconButton(
              icon: const Icon(Icons.bug_report),
              onPressed: _openDiagnostics,
              tooltip: 'Troubleshoot Quran Data',
            ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_errorMessage!, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadData,
              child: const Text(AppTranslations.tryAgain),
            ),
            // Show diagnostic button only in debug mode
            if (kDebugMode) 
              Padding(
                padding: const EdgeInsets.only(top: 16),
                child: ElevatedButton(
                  onPressed: _openDiagnostics,
                  child: const Text('Troubleshoot Quran Data'),
                ),
              ),
          ],
        ),
      );
    }

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppTranslations.welcomeToQuran,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppTranslations.startReadingJourney,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            
            // Continue reading card (if available)
            if (_lastReadPosition != null) _buildContinueReadingCard(),
            
            const SizedBox(height: 20),
            
            Expanded(
              child: ListView(
                children: [
                  _buildOptionTile(
                    context,
                    icon: Icons.menu_book,
                    title: AppTranslations.browseQuran,
                    onTap: () => _buildSurahList(),
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.favorite,
                    title: AppTranslations.favorites,
                    onTap: _openFavorites,
                  ),
                  _buildOptionTile(
                    context,
                    icon: Icons.settings,
                    title: AppTranslations.settings,
                    onTap: _openSettings,
                  ),
                  // Show diagnostic option only in debug mode
                  if (kDebugMode)
                    _buildOptionTile(
                      context,
                      icon: Icons.bug_report,
                      title: 'Troubleshoot Quran Data',
                      onTap: _openDiagnostics,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile(BuildContext context, {required IconData icon, required String title, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon),
      title: Text(title),
      onTap: onTap,
    );
  }

  void _buildSurahList() {
    if (_surahs.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No Data Available'),
          content: const Text('No Quran data is available. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _loadData();
              },
              child: const Text(AppTranslations.refresh),
            ),
            // Show diagnostic button only in debug mode
            if (kDebugMode)
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  _openDiagnostics();
                },
                child: const Text('Troubleshoot'),
              ),
          ],
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(
            title: const Text(AppTranslations.browseQuran),
          ),
          body: ListView.builder(
            itemCount: _surahs.length,
            itemBuilder: (context, index) {
              final surah = _surahs[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Text(surah.number.toString()),
                ),
                title: Text('${surah.number}. ${surah.name}'),
                subtitle: Text('${surah.ayahs.length} ${AppTranslations.verses}'),
                onTap: () => _openSurah(surah.number),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildContinueReadingCard() {
    final surahNumber = _lastReadPosition?['surah'] as int?;
    final ayahNumber = _lastReadPosition?['ayah'] as int?;

    if (surahNumber == null || ayahNumber == null) return Container();

    // Find the surah by number
    final surah = _surahs.firstWhere(
      (s) => s.number == surahNumber,
      orElse: () => Surah(
        number: surahNumber, 
        name: 'Surah $surahNumber', 
        englishName: 'Surah $surahNumber',
        ayahs: []
      ),
    );

    return Card(
      margin: const EdgeInsets.all(8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Vazhdo Leximin', // Albanian for "Continue Reading"
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Surja ${surah.name} (${surah.number}), Ajeti $ayahNumber',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => _openSurah(surahNumber, ayahNumber),
              child: const Text('Vazhdo Leximin'), // Albanian for "Continue Reading"
            ),
          ],
        ),
      ),
    );
  }
}
