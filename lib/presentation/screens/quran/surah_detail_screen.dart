import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/repositories/quran_repository.dart';
import '../../../data/models/surah.dart';
import '../../widgets/quran/ayah_widget.dart';
import '../../widgets/quran/audio_player_widget.dart';
import '../../../utils/translations.dart';
import '../../../data/controllers/surah_playback_controller.dart';

class SurahDetailScreen extends StatefulWidget {
  final int surahNumber;
  final int? initialAyahNumber;
  final QuranRepository quranRepository;

  const SurahDetailScreen({
    super.key,
    required this.surahNumber,
    this.initialAyahNumber,
    required this.quranRepository,
  });

  @override
  State<SurahDetailScreen> createState() => _SurahDetailScreenState();
}

class _SurahDetailScreenState extends State<SurahDetailScreen> {
  bool _isLoading = true;
  String? _error;

  // Changed from late variables to nullable variables with defaults
  Surah? _arabicSurah;
  Surah? _translationSurah;
  Map<String, String> _transliterations = {};
  final ScrollController _scrollController = ScrollController();
  
  // Surah playback controller
  SurahPlaybackController? _playbackController;
  bool _isPlayingSurah = false;
  int _currentPlayingAyah = 0;

  bool _showArabic = true;
  bool _showTransliteration = true;
  bool _showTranslation = true;

  @override
  void initState() {
    super.initState();
    _loadDisplayPreferences();
    _loadSurahData();
  }

  Future<void> _loadDisplayPreferences() async {
    try {
      final prefs = await widget.quranRepository.getDisplayPreferences();
      if (mounted) {
        setState(() {
          _showArabic = prefs['showArabic'];
          _showTransliteration = prefs['showTransliteration'];
          _showTranslation = prefs['showTranslation'];
        });
      }
    } catch (e) {
      developer.log('Error loading display preferences: $e', name: 'SurahDetailScreen', error: e);
      // Use defaults if preferences can't be loaded
      if (mounted) {
        setState(() {
          _showArabic = true;
          _showTransliteration = true;
          _showTranslation = true;
        });
      }
    }
  }

  Future<void> _saveDisplayPreferences() async {
    await widget.quranRepository.updateDisplayPreferences(
      showArabic: _showArabic,
      showTransliteration: _showTransliteration,
      showTranslation: _showTranslation,
    );
  }

  Future<void> _loadSurahData() async {
    try {
      setState(() {
        _isLoading = true;
        _error = null;
      });

      // Get surah with translation using the correct repository method
      final result = await widget.quranRepository.getSurahWithTranslation(widget.surahNumber);
      
      if (mounted) {
        setState(() {
          _arabicSurah = result['arabic'];
          _translationSurah = result['translation'];
          
          // Handle transliteration based on the format (could be Map or List)
          final transliterationData = result['transliteration'];
          if (transliterationData is Map<String, String>) {
            _transliterations = transliterationData;
          } else if (transliterationData is List<String> && _arabicSurah != null) {
            // Convert list to map if needed
            final Map<String, String> transliterationMap = {};
            for (int i = 0; i < transliterationData.length; i++) {
              if (i < _arabicSurah!.ayahs.length) {
                final ayahNumber = _arabicSurah!.ayahs[i].numberInSurah.toString();
                transliterationMap[ayahNumber] = transliterationData[i];
              }
            }
            _transliterations = transliterationMap;
          } else {
            _transliterations = {};
          }
          
          _isLoading = false;
          
          // Initialize playback controller after data is loaded
          if (_arabicSurah != null) {
            _playbackController = SurahPlaybackController(
              surahNumber: widget.surahNumber,
              totalAyahs: _arabicSurah!.ayahs.length,
              onAyahChange: (ayahNumber) {
                setState(() {
                  _currentPlayingAyah = ayahNumber;
                });
                _scrollToAyah(ayahNumber);
              },
            );
          }
        });

        // Scroll to initial ayah if specified
        if (widget.initialAyahNumber != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scrollToAyah(widget.initialAyahNumber!);
          });
        }
      }
    } catch (e) {
      developer.log('Error loading surah data: $e', name: 'SurahDetailScreen', error: e);
      if (mounted) {
        setState(() {
          _error = 'Could not load surah data: ${e.toString()}';
          _isLoading = false;
        });
      }
    }
  }

  void _scrollToAyah(int ayahNumber) {
    if (_scrollController.hasClients) {
      // Find the index of the ayah in the list
      final ayahIndex = _arabicSurah?.ayahs.indexWhere(
            (a) => a.numberInSurah == ayahNumber,
          ) ??
          -1;

      if (ayahIndex >= 0) {
        // Calculate approximate position (this is an estimate)
        final estimatedItemHeight = 200.0; // Adjust based on your actual item height
        final offset = ayahIndex * estimatedItemHeight;
        
        _scrollController.animateTo(
          offset,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    }
  }

  void _toggleSurahPlayback() {
    if (_playbackController == null || _arabicSurah == null) return;
    
    setState(() {
      if (_isPlayingSurah) {
        _playbackController!.pausePlayback();
      } else {
        if (_currentPlayingAyah > 0) {
          _playbackController!.resumePlayback();
        } else {
          _playbackController!.startPlayback();
        }
      }
      _isPlayingSurah = !_isPlayingSurah;
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _playbackController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_arabicSurah?.name ?? 'Surah ${widget.surahNumber}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _showDisplayOptionsDialog,
            tooltip: AppTranslations.displayOptions,
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: _shareSurah,
            tooltip: AppTranslations.share,
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

    if (_error != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            Text(_error!, style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadSurahData,
              child: Text(AppTranslations.tryAgain),
            ),
          ],
        ),
      );
    }

    if (_arabicSurah == null || _arabicSurah!.ayahs.isEmpty) {
      return Center(
        child: Text(AppTranslations.noDataAvailable),
      );
    }

    return Column(
      children: [
        // Play Surah button
        if (_playbackController != null)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isPlayingSurah 
                          ? '${AppTranslations.playingAyah} ${_currentPlayingAyah}/${_arabicSurah!.ayahs.length}'
                          : AppTranslations.playSurah,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: Icon(_isPlayingSurah ? Icons.pause : Icons.play_arrow),
                      onPressed: _toggleSurahPlayback,
                      tooltip: _isPlayingSurah ? AppTranslations.pauseSurah : AppTranslations.playSurah,
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        // Ayahs list
        Expanded(
          child: ListView.builder(
            controller: _scrollController,
            itemCount: _arabicSurah!.ayahs.length,
            itemBuilder: (context, index) {
              final ayah = _arabicSurah!.ayahs[index];
              final ayahNumber = ayah.numberInSurah;
              final translationAyah = _translationSurah?.ayahs.firstWhere(
                (a) => a.numberInSurah == ayahNumber,
                orElse: () => ayah,
              );
              
              // Get transliteration for this ayah
              final transliterationText = _transliterations[ayahNumber.toString()] ?? '';
              
              // Determine if this is the currently playing ayah
              final isCurrentlyPlaying = _isPlayingSurah && _currentPlayingAyah == ayahNumber;
              
              // Apply special styling for the currently playing ayah
              return Container(
                decoration: isCurrentlyPlaying
                    ? BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                        borderRadius: BorderRadius.circular(8),
                        color: Theme.of(context).primaryColor.withOpacity(0.1),
                      )
                    : null,
                child: AyahWidget(
                  surahNumber: widget.surahNumber,
                  ayahNumber: ayahNumber,
                  arabicText: ayah.text,
                  translationText: translationAyah?.text ?? '',
                  transliterationText: transliterationText,
                  showArabic: _showArabic,
                  showTransliteration: _showTransliteration,
                  showTranslation: _showTranslation,
                  onPlayAudio: (surahNumber, ayahNumber) {
                    // Individual ayah play button clicked
                    if (_isPlayingSurah) {
                      // Stop surah playback if it's active
                      _playbackController?.stopPlayback();
                      setState(() {
                        _isPlayingSurah = false;
                      });
                    }
                  },
                  onToggleFavorite: _toggleFavorite,
                  onShare: _shareAyah,
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _showDisplayOptionsDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(AppTranslations.displayOptions),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Show Arabic text option
            SwitchListTile(
              title: Text(AppTranslations.showArabic),
              value: _showArabic,
              onChanged: (value) {
                setState(() {
                  _showArabic = value;
                });
                _saveDisplayPreferences();
                Navigator.pop(context);
              },
            ),
            
            // Show transliteration option
            SwitchListTile(
              title: Text(AppTranslations.showTransliteration),
              value: _showTransliteration,
              onChanged: (value) {
                setState(() {
                  _showTransliteration = value;
                });
                _saveDisplayPreferences();
                Navigator.pop(context);
              },
            ),
            
            // Show translation option
            SwitchListTile(
              title: Text(AppTranslations.showTranslation),
              value: _showTranslation,
              onChanged: (value) {
                setState(() {
                  _showTranslation = value;
                });
                _saveDisplayPreferences();
                Navigator.pop(context);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(AppTranslations.close),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleFavorite(int surahNumber, int ayahNumber) async {
    await widget.quranRepository.toggleFavoriteVerse(surahNumber, ayahNumber);
    // Show a snackbar or some other feedback
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppTranslations.favoriteToggled)),
      );
    }
  }

  Future<void> _shareAyah(int surahNumber, int ayahNumber, String arabicText, String translationText) async {
    final text = 'Surah $surahNumber, Ayah $ayahNumber\n\n$arabicText\n\n$translationText';
    await Share.share(text);
  }

  Future<void> _shareSurah() async {
    if (_arabicSurah == null) return;
    
    final surahName = _arabicSurah!.name;
    final surahNumber = _arabicSurah!.number;
    final totalAyahs = _arabicSurah!.ayahs.length;
    
    final text = 'Surah $surahName ($surahNumber)\nTotal Ayahs: $totalAyahs\n\nShared from Kibla App';
    await Share.share(text);
  }
}
