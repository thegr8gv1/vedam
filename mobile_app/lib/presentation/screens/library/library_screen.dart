import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../../state/scripture_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/scripture_card.dart';
import 'bookmarks_screen.dart';
import 'scripture_detail_screen.dart';
import 'widgets/reading_preferences_modal.dart';

enum ReadingStatusFilter {
  all('All'),
  inProgress('In Progress'),
  bookmarked('Bookmarked'),
  completed('Completed'),
  unread('Unread');

  final String label;
  const ReadingStatusFilter(this.label);
}

enum AudioAvailabilityFilter {
  all('All Formats'),
  audioOnly('Chanting Audio'),
  textOnly('Text Study');

  final String label;
  const AudioAvailabilityFilter(this.label);
}

class LibraryScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final ScriptureReaderState? readerState;
  final AudioState? audioState;

  const LibraryScreen({
    super.key,
    required this.repository,
    required this.appState,
    this.readerState,
    this.audioState,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ScriptureState _scriptureState;
  late final ScriptureReaderState _readerState;
  final TextEditingController _searchController = TextEditingController();
  ReadingStatusFilter _readingStatusFilter = ReadingStatusFilter.all;
  AudioAvailabilityFilter _audioFilter = AudioAvailabilityFilter.all;

  @override
  void initState() {
    super.initState();
    _scriptureState = ScriptureState(widget.repository);
    _readerState = widget.readerState ?? ScriptureReaderState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scriptureState.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SacredAppBar(
        title: 'Scripture Library',
        subtitle: 'विशाल धर्मग्रन्थालयः',
        showLogo: false,
        actions: [
          // Bookmarks & Notes Screen
          IconButton(
            icon: const Icon(Icons.bookmark_outline),
            tooltip: 'View Bookmarks & Notes',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BookmarksScreen(
                    repository: widget.repository,
                    readerState: _readerState,
                    audioState: widget.audioState,
                  ),
                ),
              );
            },
          ),
          // Reading Preferences Modal
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Reading Preferences',
            onPressed: () => ReadingPreferencesModal.show(context, _readerState),
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([_scriptureState, _readerState]),
        builder: (context, _) {
          // Apply reading status and audio availability filters on top of filtered scriptures
          final displayed = _scriptureState.filteredScriptures.where((s) {
            final progress = _readerState.getProgress(s.id);
            final bookmarks = _readerState.getBookmarksForScripture(s.id);

            bool matchesStatus;
            switch (_readingStatusFilter) {
              case ReadingStatusFilter.all:
                matchesStatus = true;
              case ReadingStatusFilter.inProgress:
                matchesStatus = progress != null &&
                    progress.completedVerseNumbers.isNotEmpty &&
                    !progress.isCompleted;
              case ReadingStatusFilter.bookmarked:
                matchesStatus = bookmarks.isNotEmpty;
              case ReadingStatusFilter.completed:
                matchesStatus = progress != null && progress.isCompleted;
              case ReadingStatusFilter.unread:
                matchesStatus = progress == null || progress.completedVerseNumbers.isEmpty;
            }
            if (!matchesStatus) return false;

            final hasAudio = s.verses.any((v) => v.audioMantraId != null);
            switch (_audioFilter) {
              case AudioAvailabilityFilter.all:
                return true;
              case AudioAvailabilityFilter.audioOnly:
                return hasAudio;
              case AudioAvailabilityFilter.textOnly:
                return !hasAudio;
            }
          }).toList();

          return Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search title, deity, verse text, or identifier...',
                    prefixIcon: const Icon(Icons.search, color: AppColors.saffronPrimary),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _scriptureState.setSearchQuery('');
                            },
                          )
                        : null,
                  ),
                  onChanged: (val) => _scriptureState.setSearchQuery(val),
                ),
              ),

              // 2. Reading Status Quick Filters
              SizedBox(
                height: 38,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: ReadingStatusFilter.values.length,
                  itemBuilder: (context, index) {
                    final filter = ReadingStatusFilter.values[index];
                    final isSelected = filter == _readingStatusFilter;

                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(filter.label),
                        labelStyle: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                        ),
                        selectedColor: AppColors.saffronPrimary,
                        backgroundColor:
                            isDark ? AppColors.nightSurface : const Color(0xFFF3ECE1),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.saffronPrimary
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _readingStatusFilter = filter;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              // 3. Deity Filter Chips (Horizontal Scroll)
              SizedBox(
                height: 36,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.repository.getDeities().length,
                  itemBuilder: (context, index) {
                    final deity = widget.repository.getDeities()[index];
                    final isSelected = deity == _scriptureState.selectedDeity;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        selected: isSelected,
                        label: Text(deity),
                        labelStyle: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                        ),
                        selectedColor: isDark ? AppColors.goldGlow : AppColors.goldDark,
                        backgroundColor:
                            isDark ? AppColors.nightSurface : const Color(0xFFF0EAE1),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                        ),
                        onSelected: (_) => _scriptureState.setDeity(deity),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              // 4. Category Filter Chips (Horizontal Scroll)
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: widget.repository.getCategories().length,
                  itemBuilder: (context, index) {
                    final cat = widget.repository.getCategories()[index];
                    final isSelected = cat == _scriptureState.selectedCategory;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: ChoiceChip(
                        selected: isSelected,
                        label: Text(cat),
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
                        ),
                        selectedColor: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        backgroundColor:
                            isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF9F5EE),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.goldPrimary
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                          width: 0.8,
                        ),
                        onSelected: (_) => _scriptureState.setCategory(cat),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 4),

              // 4b. Audio Availability Filter Chips (Horizontal Scroll)
              SizedBox(
                height: 34,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: AudioAvailabilityFilter.values.length,
                  itemBuilder: (context, index) {
                    final af = AudioAvailabilityFilter.values[index];
                    final isSelected = af == _audioFilter;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: FilterChip(
                        avatar: Icon(
                          af == AudioAvailabilityFilter.audioOnly
                              ? Icons.volume_up
                              : (af == AudioAvailabilityFilter.textOnly
                                  ? Icons.menu_book
                                  : Icons.layers),
                          size: 14,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.goldLight : AppColors.saffronPrimary),
                        ),
                        selected: isSelected,
                        label: Text(af.label),
                        labelStyle: TextStyle(
                          fontSize: 10.5,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                        ),
                        selectedColor: const Color(0xFF10B981),
                        backgroundColor:
                            isDark ? AppColors.nightSurface : const Color(0xFFF3ECE1),
                        side: BorderSide(
                          color: isSelected
                              ? const Color(0xFF10B981)
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                        ),
                        onSelected: (_) {
                          setState(() {
                            _audioFilter = af;
                          });
                        },
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // 5. Results Count & Reset
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${displayed.length} Sacred Texts Available',
                      style: AppTextStyles.caption(isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_scriptureState.selectedCategory != 'All Categories' ||
                        _scriptureState.selectedDeity != 'All Deities' ||
                        _readingStatusFilter != ReadingStatusFilter.all ||
                        _audioFilter != AudioAvailabilityFilter.all ||
                        _scriptureState.searchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          _scriptureState.resetFilters();
                          setState(() {
                            _readingStatusFilter = ReadingStatusFilter.all;
                            _audioFilter = AudioAvailabilityFilter.all;
                          });
                        },
                        child: Text(
                          'Reset Filters',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                          ),
                        ),
                      ),
                  ],
                ),
              ),

              const Divider(height: 6),

              // 6. Scripture List
              Expanded(
                child: _scriptureState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : displayed.isEmpty
                        ? EmptyStateView(
                            title: 'No Scriptures Match Criteria',
                            message: 'Try clearing your search query or adjusting your filters.',
                            buttonText: 'Reset Filters',
                            onButtonPressed: () {
                              _searchController.clear();
                              _scriptureState.resetFilters();
                              setState(() {
                                _readingStatusFilter = ReadingStatusFilter.all;
                                _audioFilter = AudioAvailabilityFilter.all;
                              });
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: displayed.length,
                            itemBuilder: (context, index) {
                              final scripture = displayed[index];
                              final isFav = widget.appState.isFavorite(scripture.id);
                              final progress = _readerState.getProgress(scripture.id);
                              final bookmarks = _readerState.getBookmarksForScripture(scripture.id);

                              return ScriptureCard(
                                scripture: scripture,
                                isFavorite: isFav,
                                progress: progress,
                                bookmarkedCount: bookmarks.length,
                                onFavoriteToggle: () => widget.appState.toggleFavorite(scripture.id),
                                onTap: () {
                                  widget.appState.recordRecentlyRead(scripture.id);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScriptureDetailScreen(
                                        scripture: scripture,
                                        appState: widget.appState,
                                        readerState: _readerState,
                                        audioState: widget.audioState,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
              ),
            ],
          );
        },
      ),
    );
  }
}
