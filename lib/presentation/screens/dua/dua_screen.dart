import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:flutter/services.dart';

import '../../../data/models/dua.dart';
import '../../../data/repositories/dua_repository.dart';

class DuaScreen extends StatefulWidget {
  const DuaScreen({Key? key}) : super(key: key);

  @override
  State<DuaScreen> createState() => _DuaScreenState();
}

class _DuaScreenState extends State<DuaScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);

    // Initialize data on first load
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final duaRepository = Provider.of<DuaRepository>(context, listen: false);
      duaRepository.loadDuas();
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
        title: const Text('Duatë dhe Lutjet'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              _showSearchDialog(context);
            },
            tooltip: 'Kërko',
          ),
          IconButton(
            icon: const Icon(Icons.star),
            onPressed: () {
              _showFavoritesDialog(context);
            },
            tooltip: 'Të preferuarat',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Ditore'),
            Tab(text: 'Mëngjes/Mbrëmje'),
            Tab(text: 'Namazi'),
            Tab(text: 'Kuranore'),
            Tab(text: '99 Emrat e Allahut'),
          ],
        ),
      ),
      body: Consumer<DuaRepository>(
        builder: (context, duaRepository, child) {
          if (duaRepository.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Once data is loaded, show the TabBarView
          return TabBarView(
            controller: _tabController,
            children: [
              // Duatë ditore
              _buildDuaList(duaRepository.getDailyDuas()),

              // Duatë e mëngjesit dhe mbrëmjes
              _buildMorningEveningTab(duaRepository),

              // Duatë e lidhura me namazin
              _buildDuaList(duaRepository.getPrayerRelatedDuas()),

              // Duatë kuranore
              _buildDuaList(duaRepository.getQuranicDuas()),

              // 99 emrat e Allahut
              _buildAllahNamesGrid(duaRepository.getAllahNames()),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMorningEveningTab(DuaRepository duaRepository) {
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          const TabBar(
            labelColor: Colors.black,
            tabs: [
              Tab(
                icon: Icon(Icons.wb_sunny),
                text: 'Mëngjes',
              ),
              Tab(
                icon: Icon(Icons.nights_stay),
                text: 'Mbrëmje',
              ),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _buildDuaList(duaRepository.getMorningDuas()),
                _buildDuaList(duaRepository.getEveningDuas()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDuaList(List<Dua> duas) {
    if (duas.isEmpty) {
      return const Center(
        child: Text('Nuk u gjetën dua në këtë kategori'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: duas.length,
      itemBuilder: (context, index) {
        final dua = duas[index];
        return _buildDuaCard(dua);
      },
    );
  }

  Widget _buildDuaCard(Dua dua) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      child: ExpansionTile(
        title: Text(
          dua.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text('Ref: ${dua.reference}'),
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Arabic Text with larger font
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    dua.arabicText,
                    style: const TextStyle(
                      fontFamily: 'Amiri',
                      fontSize: 24,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.right,
                    textDirection: TextDirection.rtl,
                  ),
                ),
                const SizedBox(height: 16),

                // Transliteration
                const Text(
                  'Transliterim:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  dua.transliteration,
                  style: const TextStyle(fontStyle: FontStyle.italic),
                ),
                const SizedBox(height: 16),

                // Translation
                const Text(
                  'Përkthim:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(dua.translation),
                const SizedBox(height: 16),

                // Reference
                const Text(
                  'Referenca:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(dua.reference),
                const SizedBox(height: 16),

                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Consumer<DuaRepository>(
                      builder: (context, repository, _) {
                        final isPlaying = repository.isPlaying(dua.id);

                        return IconButton(
                          icon: Icon(
                            isPlaying ? Icons.pause : Icons.volume_up,
                            color: dua.audioUrl != null
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey,
                          ),
                          onPressed: dua.audioUrl != null
                            ? () {
                                if (isPlaying) {
                                  repository.pauseDuaAudio();
                                } else {
                                  repository.playDuaAudio(dua.id);
                                }
                              }
                            : null,
                          tooltip: isPlaying ? 'Ndalo audio' : 'Dëgjo',
                        );
                      }
                    ),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        _copyDuaToClipboard(dua);
                      },
                      tooltip: 'Kopjo',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    Consumer<DuaRepository>(
                      builder: (context, repository, child) {
                        final isFavorite = repository.isFavorite(dua.id);
                        return IconButton(
                          icon: Icon(
                            isFavorite ? Icons.star : Icons.star_border,
                          ),
                          onPressed: () {
                            repository.toggleFavorite(dua.id);
                          },
                          tooltip: isFavorite ? 'Hiq nga të preferuarat' : 'Shto te të preferuarat',
                          color: isFavorite ? Colors.amber : Theme.of(context).colorScheme.primary,
                        );
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.share),
                      onPressed: () {
                        _shareDua(dua);
                      },
                      tooltip: 'Ndaj',
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAllahNamesGrid(List<Dua> names) {
    if (names.isEmpty) {
      return const Center(
        child: Text('Emrat e Allahut nuk u gjetën'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.5,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: names.length,
      itemBuilder: (context, index) {
        final name = names[index];
        return _buildNameCard(name);
      },
    );
  }

  Widget _buildNameCard(Dua name) {
    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          _showNameDetails(context, name);
        },
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                name.arabicText,
                style: const TextStyle(
                  fontFamily: 'Amiri',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                name.title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                name.translation,
                style: const TextStyle(fontSize: 14),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showNameDetails(BuildContext context, Dua name) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              name.arabicText,
              style: const TextStyle(
                fontFamily: 'Amiri',
                fontSize: 32,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              name.title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              name.translation,
              style: const TextStyle(fontSize: 18),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Kuptimi dhe Virtytet:',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 8),
            Text(
              name.transliteration,  // Using this field for explanation in this context
              textAlign: TextAlign.justify,
            ),
            const SizedBox(height: 36),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Consumer<DuaRepository>(
                  builder: (context, repository, _) {
                    final isPlaying = repository.isPlaying(name.id);

                    return IconButton(
                      icon: Icon(
                        isPlaying ? Icons.pause : Icons.volume_up,
                        color: name.audioUrl != null
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                      ),
                      onPressed: name.audioUrl != null
                        ? () {
                            if (isPlaying) {
                              repository.pauseDuaAudio();
                            } else {
                              repository.playDuaAudio(name.id);
                            }
                          }
                        : null,
                      tooltip: isPlaying ? 'Ndalo audio' : 'Dëgjo',
                    );
                  }
                ),
                Consumer<DuaRepository>(
                  builder: (context, repository, child) {
                    final isFavorite = repository.isFavorite(name.id);
                    return IconButton(
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                      ),
                      onPressed: () {
                        repository.toggleFavorite(name.id);
                      },
                      tooltip: isFavorite ? 'Hiq nga të preferuarat' : 'Shto te të preferuarat',
                      color: isFavorite ? Colors.amber : Theme.of(context).colorScheme.primary,
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.share),
                  onPressed: () {
                    _shareDua(name);
                  },
                  tooltip: 'Ndaj',
                  color: Theme.of(context).colorScheme.primary,
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
              child: const Text('Mbyll'),
            ),
          ],
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kërko dua'),
        content: TextField(
          controller: _searchController,
          decoration: const InputDecoration(
            hintText: 'Shkruaj për të kërkuar...',
            prefixIcon: Icon(Icons.search),
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
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
              if (_searchQuery.isNotEmpty) {
                _showSearchResults(context);
              }
              Navigator.pop(context);
            },
            child: const Text('Kërko'),
          ),
        ],
      ),
    );
  }

  void _showSearchResults(BuildContext context) {
    final duaRepository = Provider.of<DuaRepository>(context, listen: false);
    final results = duaRepository.searchDuas(_searchQuery);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Rezultatet e kërkimit për "$_searchQuery"',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ),
            results.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text('Nuk u gjetën rezultate për këtë kërkim'),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: results.length,
                    itemBuilder: (context, index) {
                      return _buildDuaCard(results[index]);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _showFavoritesDialog(BuildContext context) {
    final duaRepository = Provider.of<DuaRepository>(context, listen: false);
    final favorites = duaRepository.getFavoriteDuas();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber),
                  const SizedBox(width: 8),
                  const Text(
                    'Duatë e preferuara',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                  ),
                ],
              ),
            ),
            favorites.isEmpty
              ? const Expanded(
                  child: Center(
                    child: Text('Nuk keni dua të preferuara'),
                  ),
                )
              : Expanded(
                  child: ListView.builder(
                    controller: scrollController,
                    padding: const EdgeInsets.all(8),
                    itemCount: favorites.length,
                    itemBuilder: (context, index) {
                      return _buildDuaCard(favorites[index]);
                    },
                  ),
                ),
          ],
        ),
      ),
    );
  }

  void _copyDuaToClipboard(Dua dua) {
    final text = '${dua.title}\n\n${dua.arabicText}\n\n${dua.transliteration}\n\n${dua.translation}\n\n${dua.reference}';

    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Dua u kopjua në clipboard'),
        duration: Duration(seconds: 1),
      ),
    );
  }

  void _shareDua(Dua dua) {
    final text = '${dua.title}\n\n${dua.arabicText}\n\n${dua.transliteration}\n\n${dua.translation}\n\n${dua.reference}';

    Share.share(text);
  }
}
