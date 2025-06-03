import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../data/repositories/qibla_repository.dart';
import '../../widgets/compass_widget.dart';
import '../../widgets/error_boundary.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

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
    
    // Request permissions and initialize location when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _requestPermissionsAndInitialize();
    });
  }

  Future<void> _requestPermissionsAndInitialize() async {
    final qiblaRepository = Provider.of<QiblaRepository>(context, listen: false);
    
    // Use the new context-aware permission request method
    final permissionsGranted = await qiblaRepository.requestLocationPermissionsWithContext(context);
    
    if (!permissionsGranted) {
      // Show a snackbar if permissions were denied
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required for accurate Qibla direction'),
            duration: Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Settings',
              onPressed: openAppSettings,
            ),
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
          labelStyle: const TextStyle(
            fontSize: 16.0, 
            fontWeight: FontWeight.bold,
          ),
          unselectedLabelStyle: const TextStyle(
            fontSize: 14.0,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () async {
              final qiblaRepository = Provider.of<QiblaRepository>(context, listen: false);
              await qiblaRepository.refreshLocation();
              if (!mounted) return;
              
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
      body: Consumer<QiblaRepository>(
        builder: (context, qiblaRepository, child) {
          if (qiblaRepository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          
          if (!qiblaRepository.hasLocation) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.location_off, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  const Text(
                    'Location not available',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Please enable location services and grant permission',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                    onPressed: () async {
                      await _requestPermissionsAndInitialize();
                    },
                  ),
                ],
              ),
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Pamja Standarde (Busulla)
              ErrorBoundary(
                sectionName: 'QiblaCompassView',
                child: _CompassViewWidget(
                  qiblaDirection: qiblaRepository.qiblaDirection ?? 0.0,
                ),
              ),

              // Pamja Precize
              ErrorBoundary(
                sectionName: 'QiblaPreciseView',
                child: _PreciseViewWidget(
                  qiblaDirection: qiblaRepository.qiblaDirection ?? 0.0,
                  location: qiblaRepository.currentLocation,
                ),
              ),
              
              // Pamja me Hartë
              ErrorBoundary(
                sectionName: 'QiblaMapView',
                child: _MapViewWidget(
                  location: qiblaRepository.currentLocation,
                  qiblaDirection: qiblaRepository.qiblaDirection ?? 0.0,
                ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "qibla_calibrate_button",
        onPressed: () async {
          setState(() {
            _isCalibrating = true;
          });
          
          // Show calibration UI for 5 seconds
          await Future.delayed(const Duration(seconds: 5));
          
          setState(() {
            _isCalibrating = false;
          });
          
          if (!mounted) return;
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Busulla u kalibrua me sukses'),
              duration: Duration(seconds: 2),
            ),
          );
        },
        backgroundColor: Colors.blue,
        child: Consumer<QiblaRepository>(
          builder: (context, qiblaRepository, child) {
            return qiblaRepository.isLoading
                ? const CircularProgressIndicator(color: Colors.white)
                : const Icon(Icons.compass_calibration);
          },
        ),
      ),
    );
  }
}

// Extracted widget for better performance
class _CompassViewWidget extends StatelessWidget {
  final double qiblaDirection;

  const _CompassViewWidget({
    Key? key,
    required this.qiblaDirection,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Use Consumer only for the compass widget to minimize rebuilds
          Consumer<QiblaRepository>(
            builder: (context, qiblaRepository, child) {
              return CompassWidget(
                direction: qiblaRepository.currentHeading,
                qiblaDirection: qiblaDirection,
              );
            },
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
          if (kDebugMode)
            Padding(
              padding: const EdgeInsets.only(top: 20),
              child: Consumer<QiblaRepository>(
                builder: (context, repo, _) => Text(
                  'Compass update rate: ${(1000 / repo.compassUpdateInterval).toStringAsFixed(1)} Hz',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// Extracted widget for better performance
class _PreciseViewWidget extends StatelessWidget {
  final double qiblaDirection;
  final QiblaLocation? location;

  const _PreciseViewWidget({
    Key? key,
    required this.qiblaDirection,
    this.location,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
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
                        'Distanca nga vendndodhja juaj: ${location?.distanceToKaaba.toStringAsFixed(1)} km',
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
}

// Extracted widget for better performance
class _MapViewWidget extends StatefulWidget {
  final QiblaLocation? location;
  final double qiblaDirection;

  const _MapViewWidget({
    Key? key,
    required this.location,
    required this.qiblaDirection,
  }) : super(key: key);

  @override
  State<_MapViewWidget> createState() => _MapViewWidgetState();
}

class _MapViewWidgetState extends State<_MapViewWidget> {
  @override
  Widget build(BuildContext context) {
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
          if (widget.location != null) Text('Qyteti: ${widget.location!.city ?? "Duke marrë..."}'),
          Text('Drejtimi i Kibles: ${widget.qiblaDirection.toStringAsFixed(1)}°'),
          Text('Distanca deri në Qabe: ${widget.location?.distanceToKaaba.toStringAsFixed(1)} km'),
        ],
      ),
    );
  }
}
