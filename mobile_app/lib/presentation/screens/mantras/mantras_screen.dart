import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/mantra_item.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/data/repositories/mantra_repository.dart';
import 'package:vedam_app/presentation/screens/mantras/mantra_player_screen.dart';
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
  bool _bundledOnly = false;
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<MantraItem> _getFilteredMantras() {
    List<MantraItem> list;
    if (_searchQuery.isNotEmpty) {
      list = widget.repository.searchMantras(_searchQuery);
    } else if (_selectedCollection != 'All') {
      list = widget.repository.getMantrasByCollection(_selectedCollection);
    } else {
      list = widget.repository.getAllMantras();
    }

    if (_bundledOnly) {
      list = list.where((m) => m.isBundled).toList();
    }

    return list;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final allCollections = ['All', ...widget.repository.getAllCollections()];
    final mantras = _getFilteredMantras();

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

              // Filter Controls: Collections and Offline Toggle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
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
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: allCollections.map((col) {
                            final isSel = _selectedCollection == col;
                            return Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: ChoiceChip(
                                label: Text(col, style: const TextStyle(fontSize: 11)),
                                selected: isSel,
                                selectedColor: AppColors.saffronPrimary.withAlpha(60),
                                onSelected: (sel) {
                                  if (sel) {
                                    setState(() {
                                      _selectedCollection = col;
                                    });
                                  }
                                },
                              ),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Mantras Count Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${mantras.length} Sacred Mantras Available',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                      ),
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
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.search_off, size: 48, color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                            const SizedBox(height: 8),
                            const Text('No mantras found matching your search.'),
                          ],
                        ),
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
                                        : Icons.music_note,
                                    color: isCurrentlyActive
                                        ? Colors.white
                                        : (isDark ? AppColors.goldLight : AppColors.goldDark),
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
                                    const Padding(
                                      padding: EdgeInsets.only(left: 4),
                                      child: Icon(Icons.offline_pin, size: 14, color: Colors.green),
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
                                    onPressed: () => widget.audioState.toggleFavorite(mantra.id),
                                  ),
                                  IconButton(
                                    icon: Icon(
                                      isCurrentlyActive && widget.audioState.isPlaying
                                          ? Icons.pause_circle_filled
                                          : Icons.play_circle_fill,
                                      color: AppColors.saffronPrimary,
                                      size: 32,
                                    ),
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
                                            ),
                                          ),
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => MantraPlayerScreen(
                                      mantra: mantra,
                                      audioState: widget.audioState,
                                    ),
                                  ),
                                );
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
