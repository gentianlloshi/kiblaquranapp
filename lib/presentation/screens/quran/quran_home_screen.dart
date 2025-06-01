import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/models/surah.dart';  // Added missing import for Surah
import 'surah_list_screen.dart';
import 'quran_favorites_screen.dart';
import 'quran_settings_screen.dart';

class QuranHomeScreen extends StatefulWidget {
  final QuranRepository quranRepository;

  const QuranHomeScreen({super.key, required this.quranRepository});

  @override
  _QuranHomeScreenState createState() => _QuranHomeScreenState();
}

class _QuranHomeScreenState extends State<QuranHomeScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _lastRead;

  @override
  void initState() {
    super.initState();
    _initializeData();
  }

  Future<void> _initializeData() async {
    try {
      // Initialize repository if needed
      if (!widget.quranRepository.isDataLoaded) {
        await widget.quranRepository.initialize();
      }

      // Get last read position
      final lastRead = await widget.quranRepository.getLastReadPosition();

      setState(() {
        _lastRead = lastRead;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error initializing Quran data: $e')),
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
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildLastReadCard(),
                  const SizedBox(height: 24),

                  _buildMenuCard(
                    title: 'Browse Surahs',
                    icon: Icons.menu_book,
                    color: Colors.teal,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SurahListScreen(
                            quranRepository: widget.quranRepository,
                          ),
                        ),
                      ).then((_) => _initializeData());
                    },
                  ),

                  _buildMenuCard(
                    title: 'Favorites',
                    icon: Icons.favorite,
                    color: Colors.red,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuranFavoritesScreen(
                            quranRepository: widget.quranRepository,
                          ),
                        ),
                      );
                    },
                  ),

                  _buildMenuCard(
                    title: 'Settings',
                    icon: Icons.settings,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => QuranSettingsScreen(
                            quranRepository: widget.quranRepository,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildLastReadCard() {
    if (_lastRead == null) {
      return const Card(
        elevation: 3,
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome to the Quran',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Start your reading journey by browsing through the surahs below.',
                style: TextStyle(fontSize: 16),
              ),
            ],
          ),
        ),
      );
    }

    final surahNumber = _lastRead!['surah'] as int;
    final ayahNumber = _lastRead!['ayah'] as int;

    // Try to find the surah name
    String surahName = 'Surah $surahNumber';
    try {
      final surahs = widget.quranRepository.getAllSurahs();
      final surah = surahs.firstWhere(
        (s) => s.number == surahNumber,
        orElse: () => Surah(
          number: surahNumber,
          name: 'Surah $surahNumber',
          englishName: 'Surah $surahNumber',
          ayahs: []
        )
      );
      surahName = surah.englishName;
    } catch (_) {}

    return Card(
      elevation: 3,
      color: Theme.of(context).colorScheme.surfaceContainerHighest,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => SurahListScreen(
                quranRepository: widget.quranRepository,
              ),
            ),
          ).then((_) => _initializeData());
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.bookmark,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'Continue Reading',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                '$surahName, Verse $ayahNumber',
                style: const TextStyle(
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => SurahListScreen(
                        quranRepository: widget.quranRepository,
                      ),
                    ),
                  ).then((_) => _initializeData());
                },
                child: const Text('Resume Reading'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withOpacity(0.2),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 16),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              const Icon(Icons.arrow_forward_ios, size: 16),
            ],
          ),
        ),
      ),
    );
  }
}
