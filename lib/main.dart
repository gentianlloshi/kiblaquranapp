import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Importimi i ekraneve
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/qibla/qibla_screen.dart';
import 'presentation/screens/prayer/prayer_screen.dart';
import 'presentation/screens/dua/dua_screen.dart';
import 'presentation/screens/mosque/mosque_screen.dart';
import 'presentation/screens/quran/quran_home_screen.dart';  // Shtuar për Kuranin

// Importimi i shërbimeve
import 'data/services/location_service.dart';
import 'data/services/compass_service.dart';
import 'data/services/prayer_time_service.dart';
import 'data/services/dua_service.dart';
import 'data/services/audio_service.dart';
import 'data/services/notification_service.dart';

// Importimi i ofruesve
import 'presentation/providers/quran_provider.dart';  // Shtuar për Kuranin

// Importimi i repozitorëve
import 'data/repositories/qibla_repository.dart';
import 'data/repositories/prayer_repository.dart';
import 'data/repositories/dua_repository.dart';
import 'data/repositories/mosque_repository.dart';

// Importimi i temës
import 'config/theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inicializimi i shërbimeve
  final prefs = await SharedPreferences.getInstance();
  final locationService = LocationService();
  final compassService = CompassService();
  final prayerTimeService = PrayerTimeService();
  final duaService = DuaService();
  final audioService = AudioService();
  final notificationService = NotificationService();

  // Initialize notification service
  await notificationService.initialize();

  // Inicializimi i repozitorëve
  final qiblaRepository = QiblaRepository(locationService, compassService);
  final prayerRepository = PrayerRepository(locationService, prayerTimeService);
  final duaRepository = DuaRepository(duaService, audioService);
  final mosqueRepository = MosqueRepository(locationService);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => qiblaRepository),
        ChangeNotifierProvider(create: (_) => prayerRepository),
        ChangeNotifierProvider(create: (_) => duaRepository),
        ChangeNotifierProvider(create: (_) => mosqueRepository),
        ChangeNotifierProvider(create: (_) => QuranProvider()), // Shtuar për Kuranin
      ],
      child: const KiblaApp(),
    ),
  );
}

class KiblaApp extends StatelessWidget {
  const KiblaApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kibla App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('sq', ''), // Shqip
        Locale('en', ''), // Anglisht (rezervë)
      ],
      locale: const Locale('sq', ''),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;

  // Use a method instead of a static const since QuranHomeScreen needs a repository
  List<Widget> _getScreens(BuildContext context) {
    // Get QuranRepository from provider
    final quranRepository = Provider.of<QuranProvider>(context).repository;

    return [
      const HomeScreen(),
      const QiblaScreen(),
      const PrayerScreen(),
      const DuaScreen(),
      const MosqueScreen(),
      QuranHomeScreen(quranRepository: quranRepository), // Shtuar për Kuranin
    ];
  }

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Get screens including QuranHomeScreen with repository
    final screens = _getScreens(context);

    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Kryefaqja',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.compass_calibration),
            label: 'Kibla',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.access_time),
            label: 'Namazi',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.auto_stories),
            label: 'Lutjet',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.mosque),
            label: 'Xhamitë',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book),
            label: 'Kurani',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}
