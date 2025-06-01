import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';
import 'surah_detail_screen.dart';

class QuranFavoritesScreen extends StatefulWidget {
  final QuranRepository quranRepository;

  const QuranFavoritesScreen({super.key, required this.quranRepository});

  @override
  _QuranFavoritesScreenState createState() => _QuranFavoritesScreenState();
}

class _QuranFavoritesScreenState extends State<QuranFavoritesScreen> {
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    try {
      final favorites = await widget.quranRepository.getFavoriteVerses();
      setState(() {
        _favorites = favorites;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading favorites: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Favorite Verses'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _favorites.isEmpty
              ? const Center(child: Text('No favorites yet'))
              : ListView.builder(
                  itemCount: _favorites.length,
                  itemBuilder: (context, index) {
                    final favorite = _favorites[index];
                    final surahNumber = favorite['surah'] as int;
                    final ayahNumber = favorite['ayah'] as int;

                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(surahNumber.toString()),
                      ),
                      title: Text('Surah $surahNumber, Verse $ayahNumber'),
                      subtitle: Text('Added on: ${_formatTimestamp(favorite['timestamp'])}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _removeFavorite(surahNumber, ayahNumber),
                      ),
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
                        ).then((_) => _loadFavorites());
                      },
                    );
                  },
                ),
    );
  }

  String _formatTimestamp(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    return '${date.day}/${date.month}/${date.year}';
  }

  Future<void> _removeFavorite(int surahNumber, int ayahNumber) async {
    try {
      await widget.quranRepository.toggleFavoriteVerse(surahNumber, ayahNumber);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Removed from favorites')),
      );
      _loadFavorites();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing favorite: $e')),
      );
    }
  }
}
