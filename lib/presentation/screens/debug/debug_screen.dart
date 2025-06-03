import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../data/services/compass_service.dart';
import '../../../data/services/location_service.dart';
import '../../../data/services/prayer_time_service.dart';
import '../../../data/services/quran_service.dart';

class DebugScreen extends StatefulWidget {
  const DebugScreen({Key? key}) : super(key: key);

  @override
  State<DebugScreen> createState() => _DebugScreenState();
}

class _DebugScreenState extends State<DebugScreen> {
  final List<String> _logs = [];
  bool _isLoadingAssets = false;
  bool _compassWorking = false;
  bool _locationWorking = false;
  bool _prayerTimesWorking = false;
  bool _quranWorking = false;
  StreamSubscription? _compassSubscription;
  Timer? _locationTimer;
  String _locationStatus = "Unknown";
  String _quranStatus = "Unknown";
  String _prayerStatus = "Unknown";

  @override
  void initState() {
    super.initState();
    _addLog("Debug screen initialized");
    _testCompass();
    _testLocation();
    _testPrayerTimes();
    _testQuranLoading();
    _listAssetFiles();
  }

  @override
  void dispose() {
    _compassSubscription?.cancel();
    _locationTimer?.cancel();
    super.dispose();
  }

  void _addLog(String message) {
    setState(() {
      _logs.add("[${DateTime.now().toString().split('.')[0]}] $message");
      if (_logs.length > 100) _logs.removeAt(0);
    });
  }

  Future<void> _testCompass() async {
    _addLog("Testing compass...");
    try {
      final compassService = CompassService();
      final isAvailable = await compassService.isCompassAvailable();
      _addLog("Compass available: $isAvailable");

      _compassSubscription = compassService.headingStream.listen(
        (heading) {
          if (!_compassWorking) {
            setState(() {
              _compassWorking = true;
            });
            _addLog("Compass is working! First heading: $heading");
          }
        },
        onError: (e) {
          _addLog("Compass error: $e");
        }
      );

      // Add a timeout
      Future.delayed(const Duration(seconds: 5), () {
        if (!_compassWorking) {
          _addLog("Compass timed out after 5 seconds");
        }
      });
    } catch (e) {
      _addLog("Error testing compass: $e");
    }
  }

  Future<void> _testLocation() async {
    _addLog("Testing location service...");
    try {
      final locationService = LocationService();

      _locationTimer = Timer.periodic(const Duration(seconds: 2), (timer) async {
        try {
          final position = await locationService.getCurrentLocation();
          setState(() {
            _locationWorking = true;
            if (position != null) {
              _locationStatus = "Lat: ${position.latitude}, Lng: ${position.longitude}";
            } else {
              _locationStatus = "Location unavailable";
            }
          });
          _addLog("Location obtained: $_locationStatus");
          timer.cancel();
        } catch (e) {
          _addLog("Location error: $e");
          setState(() {
            _locationStatus = "Error: $e";
          });
        }
      });
    } catch (e) {
      _addLog("Error initializing location service: $e");
    }
  }

  Future<void> _testPrayerTimes() async {
    _addLog("Testing prayer times...");
    try {
      final prayerService = PrayerTimeService();
      final prayerTimes = await prayerService.getPrayerTimes(
        latitude: 41.3275,
        longitude: 19.8187,
        method: 'MWL',
      );

      setState(() {
        _prayerTimesWorking = prayerTimes.isNotEmpty;
        _prayerStatus = "Prayer times count: ${prayerTimes.length}";
      });

      if (prayerTimes.isNotEmpty) {
        _addLog("Prayer times loaded successfully: ${prayerTimes.length} prayers");
        _addLog("First prayer time: ${prayerTimes.first.name} at ${prayerTimes.first.time}");
      } else {
        _addLog("Prayer times empty!");
      }
    } catch (e) {
      _addLog("Error testing prayer times: $e");
      setState(() {
        _prayerStatus = "Error: $e";
      });
    }
  }

  Future<void> _testQuranLoading() async {
    _addLog("Testing Quran loading...");
    try {
      final quranService = QuranService();
      await quranService.loadQuranData();

      setState(() {
        _quranWorking = quranService.arabicQuran.isNotEmpty;
        _quranStatus = "Quran surahs: ${quranService.arabicQuran.length}";
      });

      if (quranService.arabicQuran.isNotEmpty) {
        _addLog("Quran loaded successfully: ${quranService.arabicQuran.length} surahs");
      } else {
        _addLog("Quran data empty!");
      }
    } catch (e) {
      _addLog("Error testing Quran loading: $e");
      setState(() {
        _quranStatus = "Error: $e";
      });
    }
  }

  Future<void> _listAssetFiles() async {
    setState(() {
      _isLoadingAssets = true;
    });

    _addLog("Checking asset files...");
    try {
      // Check if required asset files exist
      final assetFiles = [
        'assets/data/arabic_quran.json',
        'assets/data/sq_ahmeti.json',
        'assets/data/sq_mehdiu.json',
        'assets/data/sq_nahi.json',
      ];

      for (final assetPath in assetFiles) {
        try {
          final data = await rootBundle.load(assetPath);
          final size = data.lengthInBytes / 1024;
          _addLog("✅ Asset found: $assetPath (${size.toStringAsFixed(2)} KB)");

          if (assetPath.endsWith('.json')) {
            // Try to parse the JSON to validate it
            final jsonStr = utf8.decode(data.buffer.asUint8List());
            final json = jsonDecode(jsonStr);
            _addLog("  ✓ JSON valid, keys: ${json.keys.join(', ')}");
          }
        } catch (e) {
          _addLog("❌ Asset missing or invalid: $assetPath - $e");
        }
      }
    } catch (e) {
      _addLog("Error checking assets: $e");
    } finally {
      setState(() {
        _isLoadingAssets = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Debug Information')),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.black,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Feature Status',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    _statusIndicator(_compassWorking, 'Qibla'),
                    _statusIndicator(_locationWorking, 'Location'),
                    _statusIndicator(_prayerTimesWorking, 'Prayer Times'),
                    _statusIndicator(_quranWorking, 'Quran'),
                  ],
                ),
                const SizedBox(height: 8),
                Text('Location: $_locationStatus',
                  style: const TextStyle(color: Colors.grey)),
                Text('Prayer: $_prayerStatus',
                  style: const TextStyle(color: Colors.grey)),
                Text('Quran: $_quranStatus',
                  style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
          Expanded(
            child: _logs.isEmpty
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: _logs.length,
                  itemBuilder: (context, index) {
                    final log = _logs[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8.0, vertical: 2.0),
                      child: Text(log, style: TextStyle(
                        fontSize: 12,
                        color: log.contains('error') || log.contains('Error') || log.contains('❌')
                          ? Colors.red
                          : log.contains('success') || log.contains('✅')
                            ? Colors.green
                            : null,
                      )),
                    );
                  },
                ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: _listAssetFiles,
                  child: const Text('Check Assets'),
                ),
                ElevatedButton(
                  onPressed: _testQuranLoading,
                  child: const Text('Test Quran'),
                ),
                ElevatedButton(
                  onPressed: () {
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Debug Logs'),
                        content: SingleChildScrollView(
                          child: Text(_logs.join('\n')),
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Close'),
                          ),
                          TextButton(
                            onPressed: () {
                              Clipboard.setData(ClipboardData(text: _logs.join('\n')));
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Logs copied to clipboard')),
                              );
                              Navigator.pop(context);
                            },
                            child: const Text('Copy'),
                          ),
                        ],
                      ),
                    );
                  },
                  child: const Text('Share Logs'),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _statusIndicator(bool isWorking, String label) {
    return Expanded(
      child: Row(
        children: [
          Container(
            width: 12,
            height: 12,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isWorking ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }
}
