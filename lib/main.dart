import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'presentation/widgets/error_boundary.dart';

// Importimi i ekraneve
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/qibla/qibla_screen.dart';
import 'presentation/screens/prayer/prayer_screen.dart';
import 'presentation/screens/dua/dua_screen.dart';
import 'presentation/screens/mosque/mosque_screen.dart';
import 'presentation/screens/quran/quran_home_screen.dart';  // Shtuar për Kuranin
// Debug screen

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

// Importimi i përkthimeve
import 'utils/translations.dart';

// Global key for showing error snackbars from anywhere in the app
final GlobalKey<ScaffoldMessengerState> rootScaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

// Global debug info to display in debug builds
List<String> debugLogs = [];
void addDebugLog(String message) {
  debugLogs.add("[${DateTime.now().toString().split('.')[0]}] $message");
  if (debugLogs.length > 100) debugLogs.removeAt(0); // Keep only last 100 logs
  developer.log(message, name: 'KiblaApp');
}

void main() async {
  // Catch all errors
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    addDebugLog("Flutter error: ${details.exception}");

    // If in production mode, show a user-friendly error
    if (kReleaseMode) {
      rootScaffoldMessengerKey.currentState?.showSnackBar(
        const SnackBar(content: Text('An error occurred. Please restart the app.'))
      );
    }
  };

  // Handle uncaught async errors
  PlatformDispatcher.instance.onError = (error, stack) {
    addDebugLog("Uncaught platform error: $error");
    return true;
  };

  WidgetsFlutterBinding.ensureInitialized();

  addDebugLog("App starting - release mode: $kReleaseMode");

  // Inicializimi i shërbimeve
  final prefs = await SharedPreferences.getInstance();
  addDebugLog("SharedPreferences initialized");

  final locationService = LocationService();
  addDebugLog("LocationService created");

  final compassService = CompassService();
  addDebugLog("CompassService created");

  final prayerTimeService = PrayerTimeService();
  addDebugLog("PrayerTimeService created");

  final duaService = DuaService();
  addDebugLog("DuaService created");

  final audioService = AudioService();
  addDebugLog("AudioService created");

  final notificationService = NotificationService();
  addDebugLog("NotificationService created");

  // Initialize notification service
  await notificationService.initialize();
  addDebugLog("NotificationService initialized");

  // Inicializimi i repozitorëve
  final qiblaRepository = QiblaRepository(locationService, compassService);
  final prayerRepository = PrayerRepository(
    locationService: locationService, 
    prayerTimeService: prayerTimeService
  );
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
      scaffoldMessengerKey: rootScaffoldMessengerKey, // Added for global error handling
    );
  }
}

class MainScreen extends StatefulWidget {
  final int initialIndex;
  
  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  // Use a method instead of a static const since QuranHomeScreen needs a repository
  List<Widget> _getScreens(BuildContext context) {
    // Get QuranRepository from provider
    final quranRepository = Provider.of<QuranProvider>(context).repository;

    return [
      ErrorBoundary(
        sectionName: AppTranslations.home,
        onRetry: () => setState(() {}),
        child: const HomeScreen(),
      ),
      ErrorBoundary(
        sectionName: AppTranslations.qibla,
        onRetry: () => setState(() {}),
        child: const QiblaScreen(),
      ),
      ErrorBoundary(
        sectionName: AppTranslations.prayer,
        onRetry: () => setState(() {}),
        child: const PrayerScreen(),
      ),
      ErrorBoundary(
        sectionName: AppTranslations.duas,
        onRetry: () => setState(() {}),
        child: const DuaScreen(),
      ),
      ErrorBoundary(
        sectionName: AppTranslations.mosques,
        onRetry: () => setState(() {}),
        child: const MosqueScreen(),
      ),
      ErrorBoundary(
        sectionName: AppTranslations.quran,
        onRetry: () => setState(() {}),
        child: QuranHomeScreen(quranRepository: quranRepository),
      ),
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
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          selectedItemColor: Theme.of(context).primaryColor,
          unselectedItemColor: Colors.grey,
          showSelectedLabels: true,
          showUnselectedLabels: true,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold),
          items: [
            BottomNavigationBarItem(
              icon: const Icon(Icons.home),
              label: AppTranslations.home,
              activeIcon: Icon(Icons.home, color: Theme.of(context).primaryColor),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.explore),
              label: AppTranslations.qibla,
              activeIcon: Icon(Icons.explore, color: Theme.of(context).primaryColor),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.access_time),
              label: AppTranslations.prayer,
              activeIcon: Icon(Icons.access_time, color: Theme.of(context).primaryColor),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.menu_book),
              label: AppTranslations.duas,
              activeIcon: Icon(Icons.menu_book, color: Theme.of(context).primaryColor),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.location_on),
              label: AppTranslations.mosques,
              activeIcon: Icon(Icons.location_on, color: Theme.of(context).primaryColor),
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.book),
              label: AppTranslations.quran,
              activeIcon: Icon(Icons.book, color: Theme.of(context).primaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
