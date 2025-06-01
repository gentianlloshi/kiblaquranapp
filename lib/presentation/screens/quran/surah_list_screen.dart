import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/models/surah.dart';
import 'surah_detail_screen.dart';
import 'quran_settings_screen.dart';
import 'quran_favorites_screen.dart';

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

  @override
  void initState() {
    super.initState();
    _initData();
  }

  Future<void> _initData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Initialize Quran data if not already loaded
      if (!widget.quranRepository.isDataLoaded) {
        await widget.quranRepository.initialize();
      }

      // Get all surahs
      final surahs = widget.quranRepository.getAllSurahs();

      // Get last read position
      final lastRead = await widget.quranRepository.getLastReadPosition();

      setState(() {
        _surahs = surahs;
        _lastRead = lastRead;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading Quran data: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kurani Fisnik'),
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
                Expanded(
                  child: ListView.builder(
                    itemCount: _surahs.length,
                    itemBuilder: (context, index) {
                      final surah = _surahs[index];
                      return ListTile(
                        leading: CircleAvatar(
                          child: Text(surah.number.toString()),
                        ),
                        title: Text(surah.englishName),
                        subtitle: Text('${surah.ayahs.length} verses'),
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => SurahDetailScreen(
                                surahNumber: surah.number,
                                quranRepository: widget.quranRepository,
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
                surahNumber: surahNumber,
                initialAyahNumber: ayahNumber,
                quranRepository: widget.quranRepository,
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
