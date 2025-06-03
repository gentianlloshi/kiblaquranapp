import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:share_plus/share_plus.dart';

import '../../../data/repositories/mosque_repository.dart';
import '../../../data/repositories/qibla_repository.dart';
import '../../../data/models/mosque.dart';

class MosqueScreen extends StatefulWidget {
  const MosqueScreen({Key? key}) : super(key: key);

  @override
  State<MosqueScreen> createState() => _MosqueScreenState();
}

class _MosqueScreenState extends State<MosqueScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  double _filterDistance = 5.0; // Default 5km radius
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    
    // Initialize data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final mosqueRepository = Provider.of<MosqueRepository>(context, listen: false);
      mosqueRepository.fetchNearbyMosques();
    });
  }
  
  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xhamitë e Afërta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              final mosqueRepository = Provider.of<MosqueRepository>(context, listen: false);
              mosqueRepository.fetchNearbyMosques();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Xhamitë u rifreskuan'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              _showFilterDialog(context);
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Harta'),
            Tab(text: 'Lista'),
          ],
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Kërko xhami...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _searchQuery = '';
                    });
                    
                    // Reset search
                    final mosqueRepository = Provider.of<MosqueRepository>(context, listen: false);
                    mosqueRepository.searchMosques('');
                  },
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
                
                // Search as you type
                final mosqueRepository = Provider.of<MosqueRepository>(context, listen: false);
                mosqueRepository.searchMosques(value);
              },
            ),
          ),
          Expanded(
            child: Consumer<MosqueRepository>(
              builder: (context, mosqueRepository, child) {
                if (mosqueRepository.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                final mosques = _searchQuery.isEmpty
                    ? mosqueRepository.nearbyMosques
                    : mosqueRepository.searchResults;
                
                if (mosques.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.mosque,
                          size: 80,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _searchQuery.isEmpty
                              ? 'Nuk u gjetën xhami në afërsi'
                              : 'Nuk u gjetën xhami që përputhen me "$_searchQuery"',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            mosqueRepository.fetchNearbyMosques();
                          },
                          child: const Text('Rifresko'),
                        ),
                      ],
                    ),
                  );
                }
                
                return TabBarView(
                  controller: _tabController,
                  children: [
                    // Pamja e Hartës
                    _buildMapView(mosques),
                    
                    // Pamja e Listës
                    _buildListView(mosques),
                  ],
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        heroTag: "mosque_add_button",
        onPressed: () {
          _showAddMosqueDialog(context);
        },
        tooltip: 'Shto xhami të re',
        child: const Icon(Icons.add),
      ),
    );
  }
  
  Widget _buildMapView(List<Mosque> mosques) {
    return Consumer<MosqueRepository>(
      builder: (context, mosqueRepo, child) {
        if (mosqueRepo.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }
        
        return FutureBuilder<Position>(
          future: Geolocator.getCurrentPosition(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.location_off,
                      size: 80,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Nuk mund të merret vendndodhja',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {});  // Refresh the widget
                      },
                      child: const Text('Provo përsëri'),
                    ),
                  ],
                ),
              );
            }
            
            final position = snapshot.data!;
            final initialCameraPosition = CameraPosition(
              target: LatLng(position.latitude, position.longitude),
              zoom: 14,
            );
            
            final markers = <Marker>{};
            
            // Add marker for current location
            markers.add(
              Marker(
                markerId: const MarkerId('current_location'),
                position: LatLng(position.latitude, position.longitude),
                infoWindow: const InfoWindow(
                  title: 'Vendndodhja juaj',
                ),
                icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
              ),
            );
            
            // Add markers for mosques
            for (final mosque in mosques) {
              markers.add(
                Marker(
                  markerId: MarkerId(mosque.id),
                  position: LatLng(mosque.latitude, mosque.longitude),
                  infoWindow: InfoWindow(
                    title: mosque.name,
                    snippet: '${mosque.distance.toStringAsFixed(1)} km • ${mosque.address}',
                    onTap: () {
                      _showMosqueDetails(context, mosque);
                    },
                  ),
                  onTap: () {
                    // This is needed to ensure the info window shows up
                  },
                ),
              );
            }
            
            return GoogleMap(
              initialCameraPosition: initialCameraPosition,
              markers: markers,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              mapToolbarEnabled: true,
              zoomControlsEnabled: true,
              onMapCreated: (GoogleMapController controller) {
                // You could store the controller if needed for later use
              },
            );
          },
        );
      },
    );
  }
  
  Widget _buildListView(List mosques) {
    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: mosques.length,
      itemBuilder: (context, index) {
        final mosque = mosques[index];
        return _buildMosqueCard(mosque);
      },
    );
  }
  
  Widget _buildMosqueCard(mosque) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showMosqueDetails(context, mosque);
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Mosque image or placeholder
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(4),
                  topRight: Radius.circular(4),
                ),
              ),
              child: mosque.imageUrl != null
                  ? Image.network(
                      mosque.imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Center(
                          child: Icon(
                            Icons.mosque,
                            size: 64,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        );
                      },
                    )
                  : Center(
                      child: Icon(
                        Icons.mosque,
                        size: 64,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
            ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    mosque.name,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          mosque.address,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.directions_walk, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text(
                        '${mosque.distance.toStringAsFixed(1)} km larg',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      OutlinedButton.icon(
                        icon: const Icon(Icons.directions),
                        label: const Text('Udhëzimet'),
                        onPressed: () {
                          // Implement directions functionality
                        },
                      ),
                      OutlinedButton.icon(
                        icon: const Icon(Icons.access_time),
                        label: const Text('Kohët e Faljes'),
                        onPressed: () {
                          _showMosquePrayerTimes(context, mosque);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Filtro Xhamitë'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Distanca maksimale: ${_filterDistance.toStringAsFixed(1)} km'),
              Slider(
                value: _filterDistance,
                min: 1.0,
                max: 20.0,
                divisions: 19,
                onChanged: (value) {
                  setState(() {
                    _filterDistance = value;
                  });
                },
              ),
            ],
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
                final mosqueRepository = Provider.of<MosqueRepository>(context, listen: false);
                mosqueRepository.filterByDistance(_filterDistance);
                Navigator.pop(context);
              },
              child: const Text('Apliko'),
            ),
          ],
        ),
      ),
    );
  }
  
  void _showMosqueDetails(BuildContext context, Mosque mosque) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(16),
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.7,
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                if (mosque.imageUrl != null)
                  Container(
                    height: 200,
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      image: DecorationImage(
                        image: NetworkImage(mosque.imageUrl!),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                Text(
                  mosque.name,
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.location_on, size: 16),
                    const SizedBox(width: 4),
                    Expanded(child: Text(mosque.address)),
                    Text('${mosque.distance.toStringAsFixed(1)} km'),
                  ],
                ),
                const SizedBox(height: 16),
                if (mosque.prayerTimes.isNotEmpty) ...[
                  Text(
                    'Kohët e Faljes',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Card(
                    child: Column(
                      children: [
                        ListTile(
                          title: const Text('Fajr'),
                          trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Fajr')),
                        ),
                        ListTile(
                          title: const Text('Dhuhr'),
                          trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Dhuhr')),
                        ),
                        ListTile(
                          title: const Text('Asr'),
                          trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Asr')),
                        ),
                        ListTile(
                          title: const Text('Maghrib'),
                          trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Maghrib')),
                        ),
                        ListTile(
                          title: const Text('Isha'),
                          trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Isha')),
                        ),
                        ListTile(
                          title: const Text('Jumah'),
                          trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Jumah')),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                if (mosque.facilities.isNotEmpty) ...[
                  Text(
                    'Shërbimet',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: mosque.facilities.map((facility) {
                      return Chip(
                        label: Text(facility),
                        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 16),
                ],
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton.icon(
                      icon: const Icon(Icons.directions),
                      label: const Text('Udhëzime'),
                      onPressed: () {
                        _launchMapsUrl(mosque.latitude, mosque.longitude, mosque.name);
                      },
                    ),
                    ElevatedButton.icon(
                      icon: const Icon(Icons.share),
                      label: const Text('Ndaje'),
                      onPressed: () {
                        _shareMosqueLocation(mosque);
                      },
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
  
  void _launchMapsUrl(double latitude, double longitude, String label) async {
    final url = 'https://www.google.com/maps/search/?api=1&query=$latitude,$longitude';
    
    // Using url_launcher would be better but we'll use a simple share for now
    Share.share('$label - $url', subject: 'Vendndodhja e xhamisë');
  }
  
  void _shareMosqueLocation(Mosque mosque) {
    final prayerTimesText = mosque.prayerTimes.isNotEmpty
        ? '\nKohët e faljes:\n${mosque.prayerTimes.map((p) => '${p.name}: ${p.time}').join('\n')}'
        : '';
        
    final shareText = '''
Xhamia: ${mosque.name}
Adresa: ${mosque.address}
Distanca: ${mosque.distance.toStringAsFixed(1)} km$prayerTimesText

Shërbimet: ${mosque.facilities.join(', ')}

Vendndodhja në Google Maps:
https://www.google.com/maps/search/?api=1&query=${mosque.latitude},${mosque.longitude}

Ndare nga Kibla App
''';

    Share.share(shareText, subject: 'Xhamia ${mosque.name}');
  }
  
  void _showMosquePrayerTimes(BuildContext context, Mosque mosque) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Kohët e Faljes - ${mosque.name}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('Fajr'),
              trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Fajr')),
            ),
            ListTile(
              title: const Text('Dhuhr'),
              trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Dhuhr')),
            ),
            ListTile(
              title: const Text('Asr'),
              trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Asr')),
            ),
            ListTile(
              title: const Text('Maghrib'),
              trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Maghrib')),
            ),
            ListTile(
              title: const Text('Isha'),
              trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Isha')),
            ),
            ListTile(
              title: const Text('Jumah'),
              trailing: Text(_getPrayerTime(mosque.prayerTimes, 'Jumah')),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
            },
            child: const Text('Mbyll'),
          ),
        ],
      ),
    );
  }
  
  String _getPrayerTime(List<MosquePrayerTime> prayerTimes, String prayerName) {
    final prayer = prayerTimes.firstWhere(
      (prayer) => prayer.name.toLowerCase() == prayerName.toLowerCase(),
      orElse: () => MosquePrayerTime(name: prayerName, time: 'N/A'),
    );
    return prayer.time;
  }
  
  void _showAddMosqueDialog(BuildContext context) {
    final nameController = TextEditingController();
    final addressController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Shto xhami të re'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: 'Emri i xhamisë',
                  hintText: 'Shkruaj emrin e xhamisë',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: addressController,
                decoration: const InputDecoration(
                  labelText: 'Adresa',
                  hintText: 'Shkruaj adresën e saktë',
                ),
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
              // Validate input
              if (nameController.text.isEmpty || addressController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Ju lutemi plotësoni të gjitha fushat'),
                    duration: Duration(seconds: 2),
                  ),
                );
                return;
              }
              
              // Add mosque
              final mosqueRepository = Provider.of<MosqueRepository>(context, listen: false);
              final location = Provider.of<QiblaRepository>(context, listen: false).currentLocation;
              
              // Create a Mosque object with the form data
              final newMosque = Mosque(
                id: '0', // Temporary ID, the repository will assign a proper one
                name: nameController.text,
                address: addressController.text,
                latitude: location?.latitude ?? 0.0,
                longitude: location?.longitude ?? 0.0,
                distance: 0.0, // Will be calculated by the repository
                prayerTimes: [], // Empty initially
                facilities: [], // Empty initially
              );
              
              mosqueRepository.addMosque(newMosque);
              
              Navigator.pop(context);
              
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Xhamia u shtua me sukses'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Shto'),
          ),
        ],
      ),
    );
  }
}
