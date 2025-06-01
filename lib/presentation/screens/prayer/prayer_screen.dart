import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../../../data/repositories/prayer_repository.dart';
import '../../../data/repositories/qibla_repository.dart';
import '../../../data/models/prayer_time.dart';
import '../../../data/services/notification_service.dart';

class PrayerScreen extends StatefulWidget {
  const PrayerScreen({Key? key}) : super(key: key);

  @override
  State<PrayerScreen> createState() => _PrayerScreenState();
}

class _PrayerScreenState extends State<PrayerScreen> {
  Timer? _countdownTimer;
  Duration? _timeUntilNextPrayer;
  late final NotificationService _notificationService;

  @override
  void initState() {
    super.initState();
    _notificationService = NotificationService();

    // Initialize data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _notificationService.initialize();
      final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
      await prayerRepository.fetchPrayerTimes();
      _startCountdownTimer();
      _scheduleNotifications(prayerRepository);
    });
  }

  void _startCountdownTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
      final nextPrayer = prayerRepository.nextPrayer;

      if (nextPrayer != null) {
        final now = DateTime.now();
        final timeUntil = nextPrayer.time.difference(now);

        setState(() {
          _timeUntilNextPrayer = timeUntil;
        });
      }
    });
  }

  void _scheduleNotifications(PrayerRepository repository) {
    // Cancel any existing notifications first
    _notificationService.cancelAllNotifications();

    // Schedule notifications for today's prayers
    for (final prayer in repository.prayerTimes) {
      if (prayer.notificationEnabled && prayer.time.isAfter(DateTime.now())) {
        final notificationTime = prayer.time.subtract(Duration(minutes: repository.notificationTime));

        if (notificationTime.isAfter(DateTime.now())) {
          _notificationService.schedulePrayerNotification(
            id: prayer.hashCode,
            title: 'Koha e faljes ${prayer.type}',
            body: 'Falja ${prayer.type} do të jetë pas ${repository.notificationTime} minutash',
            scheduledTime: notificationTime,
          );
        }
      }
    }
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return 'Duke llogaritur...';

    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kohët e Faljes'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
              prayerRepository.fetchPrayerTimes();
              _scheduleNotifications(prayerRepository);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Kohët e faljes u rifreskuan'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            tooltip: 'Rifresko',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _showSettingsDialog(context);
            },
            tooltip: 'Cilësimet',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return Consumer2<PrayerRepository, QiblaRepository>(
      builder: (context, prayerRepository, qiblaRepository, child) {
        if (prayerRepository.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        final prayerTimes = prayerRepository.prayerTimes;
        final nextPrayer = prayerRepository.nextPrayer;
        final location = qiblaRepository.currentLocation;
        
        if (prayerTimes.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text('Nuk u gjetën kohë faljeje'),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    prayerRepository.fetchPrayerTimes();
                  },
                  child: const Text('Provo përsëri'),
                ),
              ],
            ),
          );
        }
        
        return RefreshIndicator(
          onRefresh: () => prayerRepository.fetchPrayerTimes(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLocationHeader(location),
                const SizedBox(height: 24),
                _buildNextPrayerCard(nextPrayer),
                const SizedBox(height: 24),
                _buildPrayerTimesList(prayerTimes, nextPrayer),
                const SizedBox(height: 24),
                _buildCalculationMethodInfo(prayerRepository.currentCalculationMethod),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildLocationHeader(location) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.location_on, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    location?.city ?? 'Duke marrë vendndodhjen...',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  if (location != null)
                    Text(
                      '${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  Text(
                    DateFormat('dd MMMM yyyy', 'sq').format(DateTime.now()),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNextPrayerCard(PrayerTime? nextPrayer) {
    if (nextPrayer == null) {
      return const SizedBox.shrink();
    }
    
    final countdownText = _formatDuration(_timeUntilNextPrayer);

    return Card(
      elevation: 4,
      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Text(
              'Falja e ardhshme',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPrayerIcon(nextPrayer.type, 32),
                const SizedBox(width: 16),
                Text(
                  nextPrayer.type,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 32,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              DateFormat('HH:mm').format(nextPrayer.time),
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 48,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Mbetur: $countdownText',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimesList(List<PrayerTime> prayerTimes, PrayerTime? nextPrayer) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Kohët e Faljes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ...prayerTimes.map((prayer) => _buildPrayerTimeItem(prayer, prayer.type == nextPrayer?.type)),
          ],
        ),
      ),
    );
  }

  Widget _buildPrayerTimeItem(PrayerTime prayer, bool isNext) {
    return Consumer<PrayerRepository>(
      builder: (context, repository, _) {
        return Container(
          decoration: BoxDecoration(
            color: isNext ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : null,
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          margin: const EdgeInsets.only(bottom: 8),
          child: Row(
            children: [
              _buildPrayerIcon(prayer.type, 24),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  prayer.type,
                  style: TextStyle(
                    fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                DateFormat('HH:mm').format(prayer.time),
                style: TextStyle(
                  fontWeight: isNext ? FontWeight.bold : FontWeight.normal,
                  fontSize: 16,
                ),
              ),
              const SizedBox(width: 16),
              Switch(
                value: prayer.notificationEnabled,
                onChanged: (value) {
                  repository.togglePrayerNotification(prayer.type);
                  // Reschedule notifications after toggling
                  _scheduleNotifications(repository);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPrayerIcon(String prayerType, double size) {
    IconData iconData;

    switch (prayerType) {
      case 'Fajr':
        iconData = Icons.wb_twilight;
        break;
      case 'Sunrise':
        iconData = Icons.wb_sunny;
        break;
      case 'Dhuhr':
        iconData = Icons.sunny;
        break;
      case 'Asr':
        iconData = Icons.sunny_snowing;
        break;
      case 'Maghrib':
        iconData = Icons.nights_stay;
        break;
      case 'Isha':
        iconData = Icons.dark_mode;
        break;
      default:
        iconData = Icons.access_time;
    }
    
    return Icon(iconData, size: size);
  }

  Widget _buildCalculationMethodInfo(String method) {
    return Card(
      elevation: 1,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            const Icon(Icons.calculate, size: 24),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metoda e llogaritjes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(method),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () {
                _showSettingsDialog(context);
              },
              tooltip: 'Ndrysho',
            ),
          ],
        ),
      ),
    );
  }

  void _showSettingsDialog(BuildContext context) {
    final prayerRepository = Provider.of<PrayerRepository>(context, listen: false);
    String selectedMethod = prayerRepository.currentCalculationMethod;
    int notificationTime = prayerRepository.notificationTime;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Cilësimet'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Metoda e llogaritjes së kohëve të faljes',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  DropdownButton<String>(
                    value: selectedMethod,
                    isExpanded: true,
                    items: prayerRepository.availableCalculationMethods
                        .map((method) => DropdownMenuItem<String>(
                              value: method,
                              child: Text(method),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() {
                          selectedMethod = value;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Lajmërimet',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Text('Koha e lajmërimit para faljes: '),
                      DropdownButton<int>(
                        value: notificationTime,
                        items: [5, 10, 15, 20, 30, 45, 60]
                            .map((minutes) => DropdownMenuItem<int>(
                                  value: minutes,
                                  child: Text('$minutes minuta'),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              notificationTime = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text('Anulo'),
              ),
              TextButton(
                onPressed: () {
                  prayerRepository.setCalculationMethod(selectedMethod);
                  prayerRepository.setNotificationTime(notificationTime);
                  // Reschedule notifications after settings change
                  _scheduleNotifications(prayerRepository);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cilësimet u ruajtën'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                child: const Text('Ruaj'),
              ),
            ],
          );
        },
      ),
    );
  }
}
