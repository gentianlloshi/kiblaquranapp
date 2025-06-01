import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../data/repositories/qibla_repository.dart';
import '../../widgets/compass_widget.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({Key? key}) : super(key: key);

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isCalibrating = false;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    
    // Initialize location on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final qiblaRepository = Provider.of<QiblaRepository>(context, listen: false);
      qiblaRepository.initializeLocation();
    });
  }
  
  Future<void> _calibrateCompass() async {
    setState(() {
      _isCalibrating = true;
    });
    
    // Show calibration UI for 5 seconds
    await Future.delayed(const Duration(seconds: 5));
    
    setState(() {
      _isCalibrating = false;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Busulla u kalibrua me sukses'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QiblaRepository>(
      builder: (context, qiblaRepository, child) {
        final qiblaDirection = qiblaRepository.qiblaDirection ?? 0.0;
        final location = qiblaRepository.currentLocation;
        final distance = qiblaRepository.distanceToKaaba;
        final compassHeading = qiblaRepository.currentHeading;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Drejtimi i Kibles'),
            bottom: TabBar(
              controller: _tabController,
              tabs: const [
                Tab(text: 'Busulla'),
                Tab(text: 'Precize'),
                Tab(text: 'Harta'),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () async {
                  await qiblaRepository.refreshLocation();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Vendndodhja u rifreskua'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
            ],
          ),
          body: qiblaRepository.isLoading
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Pamja Standarde (Busulla)
                    _buildCompassView(compassHeading, qiblaDirection),

                    // Pamja Precize
                    _buildPreciseView(qiblaDirection, location, distance),
                    
                    // Pamja me Hartë
                    _buildMapView(location, qiblaDirection),
                  ],
                ),
          floatingActionButton: FloatingActionButton(
            onPressed: _calibrateCompass,
            tooltip: 'Kalibro Busullën',
            child: _isCalibrating
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.compass_calibration),
          ),
        );
      },
    );
  }
  
  Widget _buildCompassView(double direction, double qiblaDirection) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CompassWidget(
            direction: direction,
            qiblaDirection: qiblaDirection,
          ),
          const SizedBox(height: 20),
          Text(
            'Drejtimi i Kibles: ${qiblaDirection.toStringAsFixed(1)}°',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 20),
          const Text(
            'Mbajeni telefonin paralel me tokën\nQëndroni larg objekteve metalike',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
  
  Widget _buildPreciseView(double qiblaDirection, Location? location, double distance) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Vendndodhja Aktuale',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  Text('Qyteti: ${location?.city ?? "Duke marrë..."}'),
                  const SizedBox(height: 4),
                  Text('Gjerësia: ${location?.latitude.toStringAsFixed(6) ?? "N/A"}'),
                  const SizedBox(height: 4),
                  Text('Gjatësia: ${location?.longitude.toStringAsFixed(6) ?? "N/A"}'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Qabja (Ka\'bah)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 8),
                  const Text('Qyteti: Meka, Arabia Saudite'),
                  const SizedBox(height: 4),
                  const Text('Gjerësia: 21.4225°'),
                  const SizedBox(height: 4),
                  const Text('Gjatësia: 39.8262°'),
                  const SizedBox(height: 8),
                  const Divider(),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.place, color: Colors.red),
                      const SizedBox(width: 8),
                      Text(
                        'Distanca nga vendndodhja juaj: ${distance.toStringAsFixed(1)} km',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.navigation, color: Colors.blue),
                      const SizedBox(width: 8),
                      Text(
                        'Drejtimi i saktë: ${qiblaDirection.toStringAsFixed(2)}°',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Card(
            elevation: 2,
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Si duhet ta përdorni',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  SizedBox(height: 8),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Mbajeni telefonin paralel me tokën'),
                    dense: true,
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Qëndroni larg objekteve metalike'),
                    dense: true,
                  ),
                  ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('Për kalibrim të saktë, lëvizni telefonin në formë 8-she'),
                    dense: true,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMapView(Location? location, double qiblaDirection) {
    // In a real app, this would be a Google Map or other map implementation
    // For now, just show a placeholder
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.map, size: 100, color: Colors.grey),
          const SizedBox(height: 20),
          const Text('Harta do të implementohet së shpejti'),
          const SizedBox(height: 20),
          if (location != null) Text('Qyteti: ${location.city}'),
          Text('Drejtimi i Kibles: ${qiblaDirection.toStringAsFixed(1)}°'),
          Text('Distanca deri në Qabe: ${location != null ? "${Provider.of<QiblaRepository>(context, listen: false).distanceToKaaba.toStringAsFixed(1)} km" : "Duke llogaritur..."}'),
        ],
      ),
    );
  }
}
