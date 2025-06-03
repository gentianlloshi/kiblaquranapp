import 'package:flutter/material.dart';
import '../../../data/repositories/quran_repository.dart';
import './surah_list_screen.dart';
import '../../../utils/translations.dart';
import './quran_favorites_screen.dart';
import './quran_settings_screen.dart';

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
      // Show loading indicator immediately
      setState(() {
        _isLoading = true;
      });

      print('🔍 QuranHomeScreen: Starting initialization');
      
      // Use compute to move initialization to a background isolate
      await Future.delayed(Duration.zero); // Ensure UI updates before heavy work
      
      // Initialize repository if needed
      if (!widget.quranRepository.isDataLoaded) {
        print('🔍 QuranHomeScreen: Repository not initialized, initializing now');
        await widget.quranRepository.initialize();
        print('🔍 QuranHomeScreen: Repository initialization complete');
      } else {
        print('🔍 QuranHomeScreen: Repository already initialized');
      }

      // Get last read position
      final lastRead = await widget.quranRepository.getLastReadPosition();
      print('🔍 QuranHomeScreen: Got last read position');

      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          _lastRead = lastRead;
          _isLoading = false;
        });
        print('🔍 QuranHomeScreen: UI updated with last read position');
      }
    } catch (e) {
      print('❌ QuranHomeScreen ERROR: $e');
      
      // Only update state if widget is still mounted
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Error loading Quran data. Please restart the app.'),
            duration: const Duration(seconds: 5),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () => _initializeData(),
            ),
          ),
        );
      }
      print('Error initializing Quran data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppTranslations.quranTitle),
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
      body: SafeArea(
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
              Expanded(
                child: ListView(
                  children: [
                    _buildOptionTile(
                      context,
                      icon: Icons.menu_book,
                      title: AppTranslations.browseQuran,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SurahListScreen(
                              quranRepository: widget.quranRepository,
                            ),
                          ),
                        );
                      },
                    ),
                    _buildOptionTile(
                      context,
                      icon: Icons.favorite,
                      title: AppTranslations.favorites,
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
                    _buildOptionTile(
                      context,
                      icon: Icons.settings,
                      title: AppTranslations.settings,
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
            ],
          ),
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
}
