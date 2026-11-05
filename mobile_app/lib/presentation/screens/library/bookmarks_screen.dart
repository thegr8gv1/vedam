import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../widgets/sacred_app_bar.dart';
import 'verse_learning_screen.dart';

/// Screen displaying all bookmarked verses and personal study notes across scriptures.
class BookmarksScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final ScriptureReaderState readerState;
  final AudioState? audioState;

  const BookmarksScreen({
    super.key,
    required this.repository,
    required this.readerState,
    this.audioState,
  });

  @override
  State<BookmarksScreen> createState() => _BookmarksScreenState();
}

class _BookmarksScreenState extends State<BookmarksScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _navigateToVerse(int scriptureId, int verseNumber) async {
    final scripture = await widget.repository.getScriptureById(scriptureId);
    if (scripture != null && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => VerseLearningScreen(
            scripture: scripture,
            readerState: widget.readerState,
            initialVerseNumber: verseNumber,
            audioState: widget.audioState,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.readerState,
      builder: (context, _) {
        final bookmarks = widget.readerState.allBookmarks;
        final notes = widget.readerState.allNotes;

        return Scaffold(
          appBar: SacredAppBar(
            title: 'Bookmarks & Notes',
            subtitle: 'स्वाध्याय स्मरणम्',
            showLogo: false,
          ),
          body: Column(
            children: [
              TabBar(
                controller: _tabController,
                indicatorColor: AppColors.saffronPrimary,
                labelColor: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                unselectedLabelColor: isDark
                    ? AppColors.textLightSecondary
                    : AppColors.textDarkSecondary,
                tabs: [
                  Tab(
                    icon: const Icon(Icons.bookmark),
                    text: 'Bookmarks (${bookmarks.length})',
                  ),
                  Tab(
                    icon: const Icon(Icons.note_alt_outlined),
                    text: 'Study Notes (${notes.length})',
                  ),
                ],
              ),
              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    // Tab 1: Bookmarks List
                    bookmarks.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.bookmark_border,
                                    size: 56,
                                    color: isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Bookmarks Yet',
                                    style: AppTextStyles.titleMedium(isDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Tap the bookmark icon in any scripture to save verses for quick daily reflection.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption(isDark),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: bookmarks.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final b = bookmarks[index];
                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.saffronPrimary
                                        .withValues(alpha: 0.15),
                                    child: Text(
                                      '${b.verseNumber}',
                                      style: TextStyle(
                                        color: isDark
                                            ? AppColors.goldGlow
                                            : AppColors.saffronDark,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                  title: Text(
                                    b.scriptureTitle,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        b.verseSnippet,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textLightSecondary
                                              : AppColors.textDarkSecondary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Verse ${b.verseNumber} • ID: ${b.verseId}',
                                        style: AppTextStyles.caption(isDark),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.bookmark_remove_outlined),
                                    color: Colors.redAccent,
                                    tooltip: 'Remove Bookmark',
                                    onPressed: () =>
                                        widget.readerState.removeBookmark(b.verseId),
                                  ),
                                  onTap: () => _navigateToVerse(
                                    b.scriptureId,
                                    b.verseNumber,
                                  ),
                                ),
                              );
                            },
                          ),

                    // Tab 2: Notes List
                    notes.isEmpty
                        ? Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.edit_note_outlined,
                                    size: 56,
                                    color: isDark
                                        ? AppColors.textLightMuted
                                        : AppColors.textDarkMuted,
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'No Study Notes Yet',
                                    style: AppTextStyles.titleMedium(isDark),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Record personal insights, reflections, or devotional notes on any verse.',
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.caption(isDark),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.all(16),
                            itemCount: notes.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final n = notes[index];
                              return Card(
                                child: ListTile(
                                  contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 8,
                                  ),
                                  leading: CircleAvatar(
                                    backgroundColor: AppColors.goldDark
                                        .withValues(alpha: 0.15),
                                    child: Icon(
                                      Icons.note,
                                      color: isDark
                                          ? AppColors.goldGlow
                                          : AppColors.goldDark,
                                    ),
                                  ),
                                  title: Text(
                                    '${n.scriptureTitle} • Verse ${n.verseNumber}',
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 6),
                                      Text(
                                        n.noteText,
                                        maxLines: 3,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: isDark
                                              ? AppColors.textLightPrimary
                                              : AppColors.textDarkPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        'Saved locally on device',
                                        style: AppTextStyles.caption(isDark).copyWith(
                                          fontStyle: FontStyle.italic,
                                        ),
                                      ),
                                    ],
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline),
                                    color: Colors.redAccent,
                                    tooltip: 'Delete Note',
                                    onPressed: () =>
                                        widget.readerState.deleteNote(n.verseId),
                                  ),
                                  onTap: () => _navigateToVerse(
                                    n.scriptureId,
                                    n.verseNumber,
                                  ),
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
