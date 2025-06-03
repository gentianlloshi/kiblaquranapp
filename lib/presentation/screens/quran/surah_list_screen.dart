import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/models/surah.dart';
import './surah_detail_screen.dart';
import './quran_settings_screen.dart';
import './quran_favorites_screen.dart';
import '../../../utils/translations.dart';

class SurahListScreen extends StatefulWidget {
  final QuranRepository quranRepository;

  const SurahListScreen({super.key, required this.quranRepository});

  @override
  _SurahListScreenState createState() => _SurahListScreenState();
}

class _SurahListScreenState extends State<SurahListScreen> {
  bool _isLoading = true;
  List<Surah> _surahs = [];
  Map<String, dynamic>? _lastRead;
  String? _error;
  int _loadAttempts = 0;

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _loadAttempts++;
    });

    try {
      developer.log('Initializing SurahListScreen data (attempt $_loadAttempts)...', name: 'SurahListScreen');

      // Initialize Quran data if not already loaded
      if (!widget.quranRepository.isDataLoaded) {
        developer.log('Repository not initialized, initializing now...', name: 'SurahListScreen');
        await widget.quranRepository.initialize();
      } else {
        developer.log('Repository already initialized', name: 'SurahListScreen');
      }

      // Get all surahs with better error handling
      List<Surah> surahs = [];
      try {
        surahs = widget.quranRepository.getAllSurahs();
        developer.log('Got ${surahs.length} surahs', name: 'SurahListScreen');

        if (surahs.isEmpty && _loadAttempts < 3) {
          // Try to reinitialize if no surahs were loaded
          developer.log('No surahs loaded, retrying initialization...', name: 'SurahListScreen');
          await Future.delayed(const Duration(milliseconds: 500));
          return _initData(); // Recursive retry
        }
      } catch (e, stack) {
        developer.log('Error getting surahs: $e', name: 'SurahListScreen', error: e, stackTrace: stack);

        if (_loadAttempts < 3) {
          // Retry on error
          await Future.delayed(const Duration(seconds: 1));
          return _initData(); // Recursive retry
        }

        // Create a placeholder surah list for debugging after max retries
        surahs = [
          Surah(number: 1, name: 'Error Loading', englishName: 'Error', ayahs: []),
          Surah(number: 2, name: 'Please Restart App', englishName: 'Restart', ayahs: []),
        ];
      }

      // Get last read position
      Map<String, dynamic>? lastRead;
      try {
        lastRead = await widget.quranRepository.getLastReadPosition();
        developer.log('Last read position loaded', name: 'SurahListScreen');
      } catch (e) {
        developer.log('Error loading last read position: $e', name: 'SurahListScreen', error: e);
        lastRead = null;
      }

      if (mounted) {
        setState(() {
          _surahs = surahs;
          _lastRead = lastRead;
          _isLoading = false;
          _error = surahs.isEmpty ? 'No surahs found. Please restart the app.' : null;
        });
        developer.log('State updated with ${_surahs.length} surahs', name: 'SurahListScreen');
      }
    } catch (e, stack) {
      developer.log('Critical error in _initData: $e', name: 'SurahListScreen', error: e, stackTrace: stack);
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = 'Failed to load Quran data: $e';
          // Create a placeholder surah list for debugging
          _surahs = [
            Surah(number: 1, name: 'Error: $e', englishName: 'Error', ayahs: []),
          ];
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTranslations.browseQuran),
        actions: [
          IconButton(
            icon: const Icon(Icons.favorite),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranFavoritesScreen(
                    quranRepository: widget.quranRepository,
                  ),
                ),
              );
            },
            tooltip: 'Favorites',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => QuranSettingsScreen(
                    quranRepository: widget.quranRepository,
                  ),
                ),
              );
            },
            tooltip: 'Settings',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_lastRead != null)
                  _buildLastReadCard(),
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      _error!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
                Expanded(
                  child: _surahs.isEmpty
                      ? const Center(child: Text(AppTranslations.errorLoadingData))
                      : ListView.builder(
                          itemCount: _surahs.length,
                          itemBuilder: (context, index) {
                            final surah = _surahs[index];
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: Theme.of(context).primaryColor,
                                child: Text(
                                  surah.number.toString(),
                                  style: const TextStyle(color: Colors.white),
                                ),
                              ),
                              title: Text('${AppTranslations.chapter} ${surah.number}'),
                              subtitle: Text('${surah.ayahs.length} ${AppTranslations.verses}'),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => SurahDetailScreen(
                                      quranRepository: widget.quranRepository,
                                      surahNumber: surah.number,
                                    ),
                                  ),
                                ).then((_) => _checkForUpdates());
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildLastReadCard() {
    if (_lastRead == null) return const SizedBox.shrink();

    final surahNumber = _lastRead!['surah'] as int;
    final ayahNumber = _lastRead!['ayah'] as int;
    final timestamp = _lastRead!['timestamp'] as int;
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final dateStr = '${date.day}/${date.month}/${date.year}';

    // Find the surah name
    final surahName = _surahs
        .firstWhere((s) => s.number == surahNumber,
                   orElse: () => Surah(number: surahNumber, name: 'Unknown', englishName: 'Unknown', ayahs: []))
        .englishName;

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahDetailScreen(
                quranRepository: widget.quranRepository,
                surahNumber: surahNumber,
                initialAyahNumber: ayahNumber,
              ),
            ),
          ).then((_) => _checkForUpdates());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.bookmark, color: Theme.of(context).primaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Continue Reading',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Surah $surahName, Verse $ayahNumber',
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last read: $dateStr',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _checkForUpdates() async {
    // Refresh last read position
    final lastRead = await widget.quranRepository.getLastReadPosition();
    if (lastRead != null) {
      setState(() {
        _lastRead = lastRead;
      });
    }
  }
}
