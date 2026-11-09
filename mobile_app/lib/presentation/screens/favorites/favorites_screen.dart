import 'package:flutter/material.dart';
import '../../../core/models/mantra_item.dart';
import '../../../core/models/scripture.dart';
import '../../../core/models/scripture_user_data.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../l10n/app_localizations.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/scripture_card.dart';
import '../library/scripture_detail_screen.dart';
import '../library/verse_learning_screen.dart';
import '../mantras/mantra_player_screen.dart';

/// Unified Devotional Shelf Screen (Tab 3: Saved).
///
/// Integrates:
/// 1. Saved Scriptures (Favorites)
/// 2. Bookmarked Verses across all scriptures
/// 3. Personal Study Reflections & Notes
/// 4. Favorite Sacred Mantras
/// 5. Reading History (Recents)
///
/// Features:
/// - Real-time synchronization with AppState, ScriptureReaderState, and AudioState.
/// - Unfavoriting or unbookmarking immediately updates the list without reload.
/// - One-tap direct navigation to the exact verse in VerseLearningScreen.
/// - One-tap direct audio playback in MantraPlayerScreen.
/// - Minimum 48dp touch targets and screen-reader Semantics throughout.
class FavoritesScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final Function(int tabIndex) onNavigateToTab;
  final ScriptureReaderState? readerState;
  final AudioState? audioState;
  final MantraRepository? mantraRepository;
  final int initialTabIndex;

  const FavoritesScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.onNavigateToTab,
    this.readerState,
    this.audioState,
    this.mantraRepository,
    this.initialTabIndex = 0,
  });

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late final ScriptureReaderState _readerState;
  late final AudioState _audioState;

  @override
  void initState() {
    super.initState();
    _readerState = widget.readerState ?? ScriptureReaderState();
    _audioState = widget.audioState ?? AudioState(audioService: AudioPlaybackServiceImpl());
    _tabController = TabController(
      length: 5,
      vsync: this,
      initialIndex: widget.initialTabIndex.clamp(0, 4),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToVerse(int scriptureId, int verseNumber) async {
    final scripture = await widget.repository.getScriptureById(scriptureId);
    if (scripture != null && mounted) {
      widget.appState.recordRecentlyRead(scripture.id);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerseLearningScreen(
            scripture: scripture,
            readerState: _readerState,
            initialVerseNumber: verseNumber,
            audioState: _audioState,
          ),
        ),
      );
    }
  }

  void _openMantraPlayer(MantraItem mantra) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MantraPlayerScreen(
          mantra: mantra,
          audioState: _audioState,
          playlist: widget.mantraRepository?.getAllMantras(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return ListenableBuilder(
      listenable: Listenable.merge([widget.appState, _readerState, _audioState]),
      builder: (context, _) {
        final favoriteIds = widget.appState.favoriteScriptureIds;
        final recentIds = widget.appState.recentlyReadScriptureIds;
        final bookmarks = _readerState.allBookmarks;
        final notes = _readerState.allNotes;
        final favoriteMantraIds = _audioState.favoriteMantraIds;

        return Scaffold(
          appBar: SacredAppBar(
            title: l10n?.navSaved ?? 'Devotional Shelf',
            subtitle: 'मम ग्रन्थसङ्ग्रहः • Sacred Collections',
            showLogo: false,
            actions: const [],
          ),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                isScrollable: true,
                indicatorColor: AppColors.saffronPrimary,
                labelColor: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                unselectedLabelColor:
                    isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.favorite, size: 18),
                    text: 'Scriptures (${favoriteIds.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.bookmark, size: 18),
                    text: 'Bookmarks (${bookmarks.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.note_alt_outlined, size: 18),
                    text: 'Notes (${notes.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.graphic_eq, size: 18),
                    text: 'Mantras (${favoriteMantraIds.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.history, size: 18),
                    text: 'Recents (${recentIds.length})',
                  ),
                ],
              ),
              Expanded(
                child: FutureBuilder<List<Scripture>>(
                  future: widget.repository.getAllScriptures(),
                  builder: (context, snapshot) {
                    final allScriptures = snapshot.data ?? [];
                    final scriptureMap = {for (var s in allScriptures) s.id: s};

                    final favoriteScriptures = favoriteIds
                        .map((id) => scriptureMap[id])
                        .whereType<Scripture>()
                        .toList();

                    final recentScriptures = recentIds
                        .map((id) => scriptureMap[id])
                        .whereType<Scripture>()
                        .toList();

                    return TabBarView(
                      controller: _tabController,
                      children: [
                        // Tab 0: Saved Scriptures (Favorites)
                        _buildFavoritesTab(context, isDark, favoriteScriptures),

                        // Tab 1: Bookmarked Verses
                        _buildBookmarksTab(context, isDark, bookmarks, scriptureMap),

                        // Tab 2: Personal Study Notes
                        _buildNotesTab(context, isDark, notes, scriptureMap),

                        // Tab 3: Favorite Sacred Mantras
                        _buildMantrasTab(context, isDark, favoriteMantraIds),

                        // Tab 4: Reading History
                        _buildRecentsTab(context, isDark, recentScriptures),
                      ],
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

  // --- Tab 0: Saved Scriptures ---
  Widget _buildFavoritesTab(
    BuildContext context,
    bool isDark,
    List<Scripture> favoriteScriptures,
  ) {
    if (favoriteScriptures.isEmpty) {
      return EmptyStateView(
        title: 'No Favorites Yet',
        message:
            'Tap the heart icon on any scripture in the library to save it to your personal devotional shelf.',
        icon: Icons.favorite_border,
        buttonText: 'Browse Scripture Library',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: favoriteScriptures.length,
      itemBuilder: (context, index) {
        final s = favoriteScriptures[index];
        final progress = _readerState.getProgress(s.id);
        final bookmarkedCount = _readerState.getBookmarksForScripture(s.id).length;

        return ScriptureCard(
          scripture: s,
          isFavorite: true,
          progress: progress,
          bookmarkedCount: bookmarkedCount,
          onFavoriteToggle: () => widget.appState.toggleFavorite(s.id),
          onTap: () {
            widget.appState.recordRecentlyRead(s.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScriptureDetailScreen(
                  scripture: s,
                  appState: widget.appState,
                  readerState: _readerState,
                  audioState: _audioState,
                ),
              ),
            );
          },
        );
      },
    );
  }

  // --- Tab 1: Bookmarked Verses ---
  Widget _buildBookmarksTab(
    BuildContext context,
    bool isDark,
    List<VerseBookmark> bookmarks,
    Map<int, Scripture> scriptureMap,
  ) {
    if (bookmarks.isEmpty) {
      return EmptyStateView(
        title: 'No Bookmarked Verses',
        message:
            'Save meaningful verses while reading or chanting by tapping the bookmark icon.',
        icon: Icons.collections_bookmark_outlined,
        buttonText: 'Explore Scriptures',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: bookmarks.length,
      itemBuilder: (context, index) {
        final b = bookmarks[index];
        final scripture = scriptureMap[b.scriptureId];
        final title = scripture?.canonicalTitle ?? b.scriptureTitle;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            ),
          ),
          child: InkWell(
            onTap: () => _navigateToVerse(b.scriptureId, b.verseNumber),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppColors.goldPrimary.withAlpha(isDark ? 35 : 20),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.bookmark, size: 18, color: AppColors.goldPrimary),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$title • Verse ${b.verseNumber}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          ),
                        ),
                        if (b.verseSnippet.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Text(
                            b.verseSnippet,
                            style: AppTextStyles.verseDevanagari(isDark, scale: 0.85),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.bookmark_remove, size: 20, color: AppColors.kumkumRed),
                    tooltip: 'Remove Bookmark',
                    onPressed: () {
                      _readerState.removeBookmark(b.verseId);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Tab 2: Personal Study Notes ---
  Widget _buildNotesTab(
    BuildContext context,
    bool isDark,
    List<VerseNote> notes,
    Map<int, Scripture> scriptureMap,
  ) {
    if (notes.isEmpty) {
      return EmptyStateView(
        title: 'No Study Notes Yet',
        message:
            'Record personal contemplative insights, guru commentary, and reflections as you study sacred verses.',
        icon: Icons.edit_note,
        buttonText: 'Read Scriptures',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: notes.length,
      itemBuilder: (context, index) {
        final note = notes[index];
        final scripture = scriptureMap[note.scriptureId];
        final title = scripture?.canonicalTitle ?? note.scriptureTitle;

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            ),
          ),
          child: InkWell(
            onTap: () => _navigateToVerse(note.scriptureId, note.verseNumber),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.note_alt, size: 16, color: Color(0xFF0D9488)),
                          const SizedBox(width: 6),
                          Text(
                            '$title • Verse ${note.verseNumber}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF0D9488),
                            ),
                          ),
                        ],
                      ),
                      const Icon(Icons.arrow_forward_ios, size: 12, color: AppColors.saffronPrimary),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    note.noteText,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // --- Tab 3: Favorite Sacred Mantras ---
  Widget _buildMantrasTab(
    BuildContext context,
    bool isDark,
    Set<String> favoriteMantraIds,
  ) {
    final allMantras = widget.mantraRepository?.getAllMantras() ?? [];
    final favMantras =
        allMantras.where((m) => favoriteMantraIds.contains(m.id)).toList();

    if (favMantras.isEmpty) {
      return EmptyStateView(
        title: 'No Favorite Mantras',
        message:
            'Star sacred chants in the Mantra Library to practice dedicated Japa repetition.',
        icon: Icons.graphic_eq,
        buttonText: 'Browse Sacred Mantras',
        onButtonPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MantraPlayerScreen(
                mantra: allMantras.isNotEmpty
                    ? allMantras.first
                    : const MantraItem(
                        id: 'om_namah_shivaya',
                        collection: 'Panchakshara',
                        deity: 'Lord Shiva',
                        title: 'Om Namah Shivaya',
                        filename: 'om_namah_shivaya.mp3',
                        mantraText: 'ॐ नमः शिवाय',
                        significance: 'Sacred Panchakshara Shiva Mantra',
                        form: '',
                        durationSeconds: 4.5,
                        sampleRate: 48000,
                        bitDepth: 16,
                        channels: 2,
                        fileSizeBytes: 877484,
                        sha256: 'dummy',
                        sourceTxt: '',
                        isBundled: true,
                        bundledAssetPath: 'assets/audio/bundled/om_namah_shivaya.mp3',
                      ),
                audioState: _audioState,
                playlist: allMantras,
              ),
            ),
          );
        },
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: favMantras.length,
      itemBuilder: (context, index) {
        final m = favMantras[index];

        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            ),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.saffronPrimary.withAlpha(isDark ? 30 : 20),
              ),
              child: const Icon(Icons.play_arrow, color: AppColors.saffronPrimary),
            ),
            title: Text(
              m.title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            subtitle: Row(
              children: [
                Expanded(
                  child: Text(
                    '${m.deity} • ${m.formattedDuration}',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (m.isBundled)
                  Container(
                    margin: const EdgeInsets.only(left: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: Colors.green.withAlpha(isDark ? 35 : 20),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      'OFFLINE',
                      style: TextStyle(
                        fontSize: 8.5,
                        fontWeight: FontWeight.w700,
                        color: Colors.green,
                      ),
                    ),
                  ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.favorite, color: AppColors.kumkumRed),
              tooltip: 'Remove Favorite',
              onPressed: () => _audioState.toggleFavoriteMantra(m.id),
            ),
            onTap: () => _openMantraPlayer(m),
          ),
        );
      },
    );
  }

  // --- Tab 4: Reading History ---
  Widget _buildRecentsTab(
    BuildContext context,
    bool isDark,
    List<Scripture> recentScriptures,
  ) {
    if (recentScriptures.isEmpty) {
      return EmptyStateView(
        title: 'No Reading History',
        message:
            'Scriptures you open and recite will appear here for fast resumption of daily sadhana.',
        icon: Icons.history,
        buttonText: 'Explore Scriptures',
        onButtonPressed: () => widget.onNavigateToTab(1),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 12),
      itemCount: recentScriptures.length,
      itemBuilder: (context, index) {
        final s = recentScriptures[index];
        final isFav = widget.appState.isFavorite(s.id);
        final progress = _readerState.getProgress(s.id);
        final bookmarkedCount = _readerState.getBookmarksForScripture(s.id).length;

        return ScriptureCard(
          scripture: s,
          isFavorite: isFav,
          progress: progress,
          bookmarkedCount: bookmarkedCount,
          onFavoriteToggle: () => widget.appState.toggleFavorite(s.id),
          onTap: () {
            widget.appState.recordRecentlyRead(s.id);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ScriptureDetailScreen(
                  scripture: s,
                  appState: widget.appState,
                  readerState: _readerState,
                  audioState: _audioState,
                ),
              ),
            );
          },
        );
      },
    );
  }
}
