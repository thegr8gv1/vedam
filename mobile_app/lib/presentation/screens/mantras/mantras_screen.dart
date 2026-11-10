import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
import 'package:vedam_app/presentation/widgets/empty_state_view.dart';
import 'package:vedam_app/state/audio_state.dart';

class MantrasScreen extends StatefulWidget {
  final MantraRepository repository;
  final AudioState audioState;

  const MantrasScreen({
    super.key,
    required this.repository,
    required this.audioState,
  });

  @override
  State<MantrasScreen> createState() => _MantrasScreenState();
}

class _MantrasScreenState extends State<MantrasScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCollection = 'All';
  String _selectedDeity = 'All';
  bool _bundledOnly = false;
  bool _favoritesOnly = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MantraItem> _getFilteredMantras() {
    List<MantraItem> list = widget.repository.getAllMantras();

    if (_searchQuery.trim().isNotEmpty) {
      final q = _searchQuery.trim().toLowerCase();
      list = list.where((m) =>
          m.title.toLowerCase().contains(q) ||
          m.deity.toLowerCase().contains(q) ||
          m.mantraText.toLowerCase().contains(q) ||
          m.significance.toLowerCase().contains(q) ||
          m.id.toLowerCase().contains(q)).toList();
    }

    if (_selectedCollection != 'All') {
      list = list.where((m) => m.collection.toLowerCase() == _selectedCollection.toLowerCase()).toList();
    }

    if (_selectedDeity != 'All') {
      list = list.where((m) => m.deity.toLowerCase() == _selectedDeity.toLowerCase()).toList();
    }

    if (_bundledOnly) {
      list = list.where((m) => m.isBundled).toList();
    }

    if (_favoritesOnly) {
      list = list.where((m) => widget.audioState.isFavorite(m.id)).toList();
    }

    return list;
  }

  void _showVaultArchiveDialog(BuildContext context, MantraItem mantra, List<MantraItem> currentList) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Row(
          children: [
            Icon(Icons.inventory_2_outlined, color: Colors.orange),
            SizedBox(width: 8),
            Expanded(child: Text('Desktop Vault Archive')),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${mantra.title} (${mantra.deity})',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 6),
            Text(
              'Master File: ${mantra.filename}\nDuration: ${mantra.formattedDuration}',
              style: const TextStyle(fontSize: 12, color: AppColors.saffronPrimary),
            ),
            const SizedBox(height: 10),
            const Text(
              'This authentic recording is preserved in the master desktop vault (C:\\ttv youtube premium\\Mantras\\). To keep the mobile app size compact (<100MB), 31 core recordings are bundled offline, and this recording is not packaged with audio.\n\nYou can chant using the digital Japa Mala counter in Manual Chanting mode.',
              style: TextStyle(fontSize: 12.5, height: 1.4),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.saffronPrimary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.pop(ctx);
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MantraPlayerScreen(
                    mantra: mantra,
                    audioState: widget.audioState,
                    playlist: currentList,
                  ),
                ),
              );
            },
            child: const Text('Open Manual Japa Counter'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCollections = ['All', ...widget.repository.getAllCollections()];
    final allDeities = ['All', ...widget.repository.getAllDeities()];
    final mantras = _getFilteredMantras();
    final hasActiveFilter = _selectedCollection != 'All' ||
        _selectedDeity != 'All' ||
        _bundledOnly ||
        _favoritesOnly ||
        _searchQuery.isNotEmpty;

    return ListenableBuilder(
      listenable: widget.audioState,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Mantra Library & Japa'),
            centerTitle: true,
          ),
          body: Column(
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search 455 mantras, deities, meanings...',
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              setState(() {
                                _searchQuery = '';
                              });
                            },
                          )
                        : null,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  ),
                  onChanged: (val) {
                    setState(() {
                      _searchQuery = val;
                    });
                  },
                ),
              ),

              // Filter Controls Row 1: Offline Ready & Favorites Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                child: Row(
                  children: [
                    FilterChip(
                      avatar: Icon(
                        Icons.offline_pin,
                        size: 16,
                        color: _bundledOnly ? Colors.white : Colors.green,
                      ),
                      label: const Text('Offline Ready', style: TextStyle(fontSize: 11)),
                      selected: _bundledOnly,
                      selectedColor: Colors.green,
                      checkmarkColor: Colors.white,
                      onSelected: (val) {
                        setState(() {
                          _bundledOnly = val;
                        });
                      },
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      avatar: Icon(
                        _favoritesOnly ? Icons.favorite : Icons.favorite_border,
                        size: 16,
                        color: _favoritesOnly ? Colors.white : AppColors.kumkumRed,
                      ),
                      label: Text(
                        'Favorites (${widget.audioState.favoriteMantraIds.length})',
                        style: const TextStyle(fontSize: 11),
                      ),
                      selected: _favoritesOnly,
                      selectedColor: AppColors.kumkumRed,
                      checkmarkColor: Colors.white,
                      onSelected: (val) {
                        setState(() {
                          _favoritesOnly = val;
                        });
                      },
                    ),
                  ],
                ),
              ),

              // Filter Controls Row 2: Deity Selection Chips
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: allDeities.length,
                  itemBuilder: (context, index) {
                    final deity = allDeities[index];
                    final isSel = _selectedDeity == deity;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(deity, style: const TextStyle(fontSize: 11)),
                        selected: isSel,
                        selectedColor: isDark ? AppColors.goldGlow : AppColors.goldDark,
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? (isDark ? Colors.black : Colors.white) : null,
                        ),
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _selectedDeity = deity;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Filter Controls Row 3: Collection Selection Chips
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  itemCount: allCollections.length,
                  itemBuilder: (context, index) {
                    final col = allCollections[index];
                    final isSel = _selectedCollection == col;
                    return Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: ChoiceChip(
                        label: Text(col, style: const TextStyle(fontSize: 10.5)),
                        selected: isSel,
                        selectedColor: AppColors.saffronPrimary.withAlpha(isDark ? 80 : 50),
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSel ? FontWeight.bold : FontWeight.normal,
                          color: isSel ? AppColors.saffronPrimary : null,
                        ),
                        onSelected: (sel) {
                          if (sel) {
                            setState(() {
                              _selectedCollection = col;
                            });
                          }
                        },
                      ),
                    );
                  },
                ),
              ),

              // Mantras Count Header with Now Chanting Indicator & Reset Filters
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Text(
                          '${mantras.length} Sacred Mantras Available',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                          ),
                        ),
                        if (hasActiveFilter) ...[
                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () {
                              _searchController.clear();
                              setState(() {
                                _selectedCollection = 'All';
                                _selectedDeity = 'All';
                                _bundledOnly = false;
                                _favoritesOnly = false;
                                _searchQuery = '';
                              });
                            },
                            child: Text(
                              'Reset Filters',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (widget.audioState.isPlaying && widget.audioState.activeMantra != null)
                      GestureDetector(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => MantraPlayerScreen(
                                mantra: widget.audioState.activeMantra!,
                                audioState: widget.audioState,
                                playlist: mantras,
                              ),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.saffronPrimary,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.volume_up, size: 12, color: Colors.white),
                              const SizedBox(width: 4),
                              Text(
                                'Now Chanting (${widget.audioState.completedRepetitions})',
                                style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              // Mantra List View
              Expanded(
                child: mantras.isEmpty
                    ? EmptyStateView(
                        title: 'No Mantras Found',
                        message:
                            'No sacred chants match the active search query or deity/collection filters.',
                        buttonText: 'Reset Filters',
                        onButtonPressed: () {
                          _searchController.clear();
                          setState(() {
                            _selectedCollection = 'All';
                            _selectedDeity = 'All';
                            _bundledOnly = false;
                            _favoritesOnly = false;
                            _searchQuery = '';
                          });
                        },
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: mantras.length,
                        itemBuilder: (context, index) {
                          final mantra = mantras[index];
                          final isCurrentlyActive =
                              widget.audioState.activeMantra?.id == mantra.id;
                          final isFav = widget.audioState.isFavorite(mantra.id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                              side: BorderSide(
                                color: isCurrentlyActive
                                    ? AppColors.saffronPrimary
                                    : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                                width: isCurrentlyActive ? 1.5 : 1.0,
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: isCurrentlyActive
                                      ? AppColors.saffronPrimary
                                      : (isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground),
                                ),
                                child: Center(
                                  child: Icon(
                                    isCurrentlyActive && widget.audioState.isPlaying
                                        ? Icons.equalizer
                                        : (mantra.isBundled ? Icons.music_note : Icons.touch_app),
                                    color: isCurrentlyActive
                                        ? Colors.white
                                        : (mantra.isBundled
                                            ? (isDark ? AppColors.goldLight : AppColors.goldDark)
                                            : Colors.orange),
                                    size: 22,
                                  ),
                                ),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      mantra.title,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ),
                                  if (mantra.isBundled)
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withAlpha(isDark ? 40 : 25),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.green.withAlpha(100), width: 0.8),
                                      ),
                                      child: const Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Icon(Icons.offline_pin, size: 12, color: Colors.green),
                                          SizedBox(width: 3),
                                          Text(
                                            'Offline Audio',
                                            style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.green),
                                          ),
                                        ],
                                      ),
                                    )
                                  else
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.withAlpha(isDark ? 40 : 20),
                                        borderRadius: BorderRadius.circular(6),
                                        border: Border.all(color: Colors.orange.withAlpha(100), width: 0.8),
                                      ),
                                      child: const Text(
                                        'Manual Japa (Vault)',
                                        style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.bold, color: Colors.orange),
                                      ),
                                    ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Text(
                                    mantra.mantraText,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontStyle: FontStyle.italic,
                                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      Text(
                                        mantra.deity,
                                        style: const TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.saffronPrimary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${mantra.formattedDuration}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        '• ${mantra.repetitionRepresentationLabel}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(
                                      isFav ? Icons.favorite : Icons.favorite_border,
                                      size: 20,
                                      color: isFav ? Colors.red : null,
                                    ),
                                    tooltip: isFav ? 'Remove Favorite' : 'Save Favorite',
                                    onPressed: () => widget.audioState.toggleFavorite(mantra.id),
                                  ),
                                  // Playable button for bundled; Info/Manual button for unbundled
                                  if (mantra.isBundled)
                                    IconButton(
                                      icon: Icon(
                                        isCurrentlyActive && widget.audioState.isPlaying
                                            ? Icons.pause_circle_filled
                                            : Icons.play_circle_fill,
                                        color: AppColors.saffronPrimary,
                                        size: 32,
                                      ),
                                      tooltip: isCurrentlyActive && widget.audioState.isPlaying ? 'Pause' : 'Play Offline',
                                      onPressed: () {
                                        if (isCurrentlyActive && widget.audioState.isPlaying) {
                                          widget.audioState.pause();
                                        } else {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) => MantraPlayerScreen(
                                                mantra: mantra,
                                                audioState: widget.audioState,
                                                playlist: mantras,
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                    )
                                  else
                                    IconButton(
                                      icon: const Icon(
                                        Icons.info_outline,
                                        color: Colors.orange,
                                        size: 26,
                                      ),
                                      tooltip: 'Vault Archive Information',
                                      onPressed: () => _showVaultArchiveDialog(context, mantra, mantras),
                                    ),
                                ],
                              ),
                              onTap: () {
                                if (mantra.isBundled) {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => MantraPlayerScreen(
                                        mantra: mantra,
                                        audioState: widget.audioState,
                                        playlist: mantras,
                                      ),
                                    ),
                                  );
                                } else {
                                  _showVaultArchiveDialog(context, mantra, mantras);
                                }
                              },
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
