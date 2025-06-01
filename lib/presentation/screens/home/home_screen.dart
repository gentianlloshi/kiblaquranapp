import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hijri/hijri_calendar.dart';

import '../../../data/repositories/prayer_repository.dart';
import '../../../data/repositories/qibla_repository.dart';
import '../../../data/repositories/dua_repository.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late HijriCalendar _hijriDate;
  
  @override
  void initState() {
    super.initState();
    _hijriDate = HijriCalendar.now();
    
    // Initialize data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
      final qiblaRepository = Provider.of<QiblaRepository>(context, listen: false);
      final duaRepository = Provider.of<DuaRepository>(context, listen: false);
      
      prayerRepository.fetchPrayerTimes();
      qiblaRepository.initializeLocation();
      duaRepository.fetchDailyDua();
      duaRepository.fetchDailyVerse();
    });
  }
  
  String _formatHijriDate() {
    return '${_hijriDate.hDay} ${_hijriDate.longMonthName} ${_hijriDate.hYear}';
  }
  
  String _formatGregorianDate() {
    final now = DateTime.now();
    return DateFormat('dd MMMM yyyy', 'sq').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () async {
          final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
          final qiblaRepository = Provider.of<QiblaRepository>(context, listen: false);
          final duaRepository = Provider.of<DuaRepository>(context, listen: false);
          
          await Future.wait([
            prayerRepository.fetchPrayerTimes(),
            qiblaRepository.refreshLocation(),
            duaRepository.fetchDailyDua(),
            duaRepository.fetchDailyVerse(),
          ]);
        },
        child: CustomScrollView(
          slivers: [
            _buildAppBar(),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    _buildDailyVerse(),
                    const SizedBox(height: 16),
                    _buildDailyDua(),
                    const SizedBox(height: 16),
                    _buildPrayerTimes(),
                    const SizedBox(height: 16),
                    _buildQiblaDirection(),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      pinned: true,
      flexibleSpace: FlexibleSpaceBar(
        title: const Text('Kibla App'),
        background: Container(
          color: Theme.of(context).colorScheme.primary,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 60, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatGregorianDate(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                Text(
                  _formatHijriDate(),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.location_on),
          onPressed: () {
            final qiblaRepository = Provider.of<QiblaRepository>(context, listen: false);
            qiblaRepository.refreshLocation();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Vendndodhja u rifreskua'),
                duration: Duration(seconds: 2),
              ),
            );
          },
          tooltip: 'Rifresko vendndodhjen',
        ),
      ],
    );
  }
  
  Widget _buildDailyVerse() {
    return Consumer<DuaRepository>(
      builder: (context, duaRepository, child) {
        final dailyVerse = duaRepository.dailyVerse;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Vargu i ditës',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      dailyVerse?['reference'] ?? '',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  dailyVerse?['arabicText'] ?? 'Duke ngarkuar...',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dailyVerse?['translation'] ?? 'Duke ngarkuar...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        // Implement audio playback
                      },
                      tooltip: 'Dëgjo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // Implement sharing
                      },
                      tooltip: 'Ndaj',
                    ),
                    IconButton(
                      icon: const Icon(Icons.bookmark_border),
                      onPressed: () {
                        // Implement bookmarking
                      },
                      tooltip: 'Ruaj',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildDailyDua() {
    return Consumer<DuaRepository>(
      builder: (context, duaRepository, child) {
        final dailyDua = duaRepository.dailyDua;
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lutja e ditës',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dailyDua?['arabicText'] ?? 'Duke ngarkuar...',
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontFamily: 'Amiri',
                    fontSize: 20,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dailyDua?['transliteration'] ?? '',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  dailyDua?['translation'] ?? 'Duke ngarkuar...',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.volume_up),
                      onPressed: () {
                        // Implement audio playback
                      },
                      tooltip: 'Dëgjo',
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        // Implement sharing
                      },
                      tooltip: 'Ndaj',
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildPrayerTimes() {
    return Consumer<PrayerRepository>(
      builder: (context, prayerRepository, child) {
        final nextPrayer = prayerRepository.nextPrayer;
        final timeUntilNextPrayer = prayerRepository.timeUntilNextPrayer;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kohët e Faljes',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                if (nextPrayer != null)
                  ListTile(
                    leading: const Icon(Icons.access_time),
                    title: Text('Falja e radhës: ${nextPrayer.name}'),
                    subtitle: Text(timeUntilNextPrayer ?? 'Duke ngarkuar...'),
                    trailing: Text(
                      DateFormat('HH:mm').format(nextPrayer.time),
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () {
                    // Navigate to prayer times page
                    DefaultTabController.of(context).animateTo(2);
                  },
                  style: ElevatedButton.styleFrom(
                    minimumSize: const Size(double.infinity, 40),
                  ),
                  child: const Text('Shiko të gjitha kohët e faljes'),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
  
  Widget _buildQiblaDirection() {
    return Consumer<QiblaRepository>(
      builder: (context, qiblaRepository, child) {
        final qiblaDirection = qiblaRepository.qiblaDirection;
        
        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drejtimi i Kibles',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                ListTile(
                  leading: const Icon(Icons.compass_calibration),
                  title: Text(
                    'Drejtimi: ${qiblaDirection?.toStringAsFixed(1) ?? "Duke ngarkuar..."}°',
                  ),
                  trailing: const Icon(Icons.arrow_forward),
                  onTap: () {
                    // Navigate to qibla page
                    DefaultTabController.of(context).animateTo(1);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
