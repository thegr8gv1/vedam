import 'package:flutter/material.dart';
import '../../../core/models/scripture.dart';
import '../../../core/models/verse.dart';
import '../../../core/models/scripture_user_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/script_selector_modal.dart';
import 'verse_learning_screen.dart';
import 'verse_reader_screen.dart';

class ScriptureDetailScreen extends StatelessWidget {
  final Scripture scripture;
  final AppState appState;
  final ScriptureReaderState? readerState;
  final AudioState? audioState;

  const ScriptureDetailScreen({
    super.key,
    required this.scripture,
    required this.appState,
    this.readerState,
    this.audioState,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final rState = readerState ?? ScriptureReaderState();

    return ListenableBuilder(
      listenable: Listenable.merge([rState, appState]),
      builder: (context, _) {
        final isFav = appState.isFavorite(scripture.id);
        final readingProgress = rState.getProgress(scripture.id);
        final bookmarkedCount = rState.getBookmarksForScripture(scripture.id).length;
        final hasProgress = readingProgress != null && readingProgress.lastReadVerseNumber > 0;

        return Scaffold(
          appBar: SacredAppBar(
            title: scripture.canonicalTitle,
            subtitle: scripture.category,
            showLogo: false,
            actions: [
              IconButton(
                icon: const Icon(Icons.translate),
                tooltip: 'Select Script (${appState.activeScript.label})',
                onPressed: () {
                  ScriptSelectorModal.show(
                    context,
                    currentScript: appState.activeScript,
                    onScriptSelected: (s) {
                      appState.setActiveScript(s);
                      rState.updatePreferences(
                        rState.preferences.copyWith(preferredScript: s),
                      );
                    },
                  );
                },
              ),
              IconButton(
                icon: Icon(
                  isFav ? Icons.favorite : Icons.favorite_border,
                  color: isFav ? AppColors.kumkumRed : null,
                ),
                tooltip: isFav ? 'Remove from favorites' : 'Add to favorites',
                onPressed: () => appState.toggleFavorite(scripture.id),
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Header Hero Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        scripture.devanagariTitle,
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        scripture.canonicalTitle,
                        style: AppTextStyles.titleMedium(isDark),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 8,
                        runSpacing: 6,
                        children: [
                          _DetailPill(label: scripture.category, color: AppColors.saffronPrimary, isDark: isDark),
                          _DetailPill(label: scripture.deity, color: AppColors.goldDark, isDark: isDark),
                          _DetailPill(label: '${scripture.verseCount} Sacred Verses', color: const Color(0xFF0D9488), isDark: isDark),
                          _DetailPill(
                            label: scripture.verses.any((v) => v.audioMantraId != null)
                                ? 'Chanting Audio Available'
                                : 'Text Study',
                            color: scripture.verses.any((v) => v.audioMantraId != null)
                                ? const Color(0xFF10B981)
                                : const Color(0xFF6B7280),
                            isDark: isDark,
                          ),
                          _DetailPill(label: 'Script: ${appState.activeScript.label}', color: const Color(0xFF6366F1), isDark: isDark),
                          if (bookmarkedCount > 0)
                            _DetailPill(
                              label: '$bookmarkedCount Bookmarked',
                              color: AppColors.goldPrimary,
                              isDark: isDark,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // 2. Reading Progress & Quick Resume (if devotee started reading)
                if (hasProgress) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.goldDark : AppColors.saffronPrimary.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.history_edu, size: 16, color: AppColors.saffronPrimary),
                                const SizedBox(width: 6),
                                Text(
                                  'Reading Progress',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                                  ),
                                ),
                              ],
                            ),
                            Text(
                              'Verse ${readingProgress.lastReadVerseNumber} of ${scripture.verseCount} (${(readingProgress.percentCompleted * 100).toInt()}%)',
                              style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: readingProgress.percentCompleted,
                            backgroundColor: isDark ? AppColors.nightBorder : const Color(0xFFE2D6C5),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
                            minHeight: 6,
                          ),
                        ),
                        const SizedBox(height: 10),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton.icon(
                            icon: const Icon(Icons.play_arrow, size: 18),
                            label: Text('RESUME FROM VERSE ${readingProgress.lastReadVerseNumber}'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.saffronPrimary,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                            onPressed: () {
                              appState.recordRecentlyRead(scripture.id);
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => VerseLearningScreen(
                                    scripture: scripture,
                                    readerState: rState,
                                    initialVerseNumber: readingProgress.lastReadVerseNumber,
                                    audioState: audioState,
                                    appState: appState,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 3. Primary Learning & Reading CTA Buttons
                Row(
                  children: [
                    // Start Verse-by-Verse Learning Mode
                    Expanded(
                      flex: 6,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.school),
                        label: Text(
                          'READ SCRIPTURE (1 - ${scripture.verseCount})',
                          style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.6),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 2,
                        ),
                        onPressed: () {
                          appState.recordRecentlyRead(scripture.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerseLearningScreen(
                                scripture: scripture,
                                readerState: rState,
                                initialVerseNumber: 1,
                                audioState: audioState,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Continuous Scroll View
                    Expanded(
                      flex: 5,
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.auto_stories),
                        label: const Text(
                          'ALL VERSES',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 15),
                          side: BorderSide(
                            color: isDark ? AppColors.goldDark : AppColors.saffronPrimary,
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () {
                          appState.recordRecentlyRead(scripture.id);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerseReaderScreen(
                                scripture: scripture,
                                appState: appState,
                                readerState: rState,
                                audioState: audioState,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Study Utilities: Bookmarks & Notes
                Builder(
                  builder: (context) {
                    final bookmarks = rState.getBookmarksForScripture(scripture.id);
                    final notes = rState.getNotesForScripture(scripture.id);
                    if (bookmarks.isEmpty && notes.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: Row(
                        children: [
                          if (bookmarks.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.bookmark_added, size: 16, color: AppColors.saffronPrimary),
                                label: Text(
                                  'BOOKMARKS (${bookmarks.length})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showBookmarksSheet(context, scripture, bookmarks, rState, audioState, appState, isDark),
                              ),
                            ),
                          if (bookmarks.isNotEmpty && notes.isNotEmpty)
                            const SizedBox(width: 10),
                          if (notes.isNotEmpty)
                            Expanded(
                              child: OutlinedButton.icon(
                                icon: const Icon(Icons.edit_note, size: 18, color: AppColors.goldPrimary),
                                label: Text(
                                  'NOTES (${notes.length})',
                                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                                ),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 10),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                ),
                                onPressed: () => _showNotesSheet(context, scripture, notes, rState, audioState, appState, isDark),
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                // 4. Content Integrity & Coverage Disclosure
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.verified_outlined, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CONTENT COVERAGE & SCHOLARLY INTEGRITY',
                                style: AppTextStyles.metadataTag(isDark).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _AttrRow(label: 'Coverage Status', value: scripture.displayCoverageStatus, isDark: isDark),
                        _AttrRow(label: 'Canonical ID', value: scripture.contentId, isDark: isDark),
                        _AttrRow(label: 'Translations', value: 'Section 8 Draft (0 Approved, Under Peer Review)', isDark: isDark),
                        _AttrRow(label: 'Indic Scripts', value: 'Devanagari, IAST, Telugu, Tamil, Kannada, Malayalam', isDark: isDark),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Content Completeness & Availability
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.fact_check_outlined, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'CONTENT AVAILABILITY & COMPLETENESS',
                                style: AppTextStyles.metadataTag(isDark).copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 16),
                        _CompletenessRow(
                          label: 'Original Indic Text',
                          status: scripture.hasOriginalSanskrit ? 'Available (${scripture.verseCount} Verses in Devanagari)' : 'Unavailable',
                          isAvailable: scripture.hasOriginalSanskrit,
                          isDark: isDark,
                        ),
                        _CompletenessRow(
                          label: 'Roman Transliteration',
                          status: scripture.hasTransliteration ? 'Available (IAST & 4 Regional Scripts)' : 'Unavailable',
                          isAvailable: scripture.hasTransliteration,
                          isDark: isDark,
                        ),
                        _CompletenessRow(
                          label: 'English Translation',
                          status: scripture.hasTranslation
                              ? 'Available (${scripture.versesWithTranslationCount}/${scripture.verseCount} verses • Section 8 DRAFT)'
                              : 'Under Translation Compilation',
                          isAvailable: scripture.hasTranslation,
                          isDark: isDark,
                        ),
                        _CompletenessRow(
                          label: 'Scholarly Commentary',
                          status: scripture.hasCommentary
                              ? 'Available on Selected Verses'
                              : 'Under Scholarly Review & Compilation',
                          isAvailable: scripture.hasCommentary,
                          isDark: isDark,
                        ),
                        _CompletenessRow(
                          label: 'Chanting Audio',
                          status: scripture.hasAudio
                              ? 'Available (${scripture.versesWithAudioCount}/${scripture.verseCount} verses)'
                              : 'Text-Only Study (No Audio Mapped)',
                          isAvailable: scripture.hasAudio,
                          isDark: isDark,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 5. Liturgical Attribution & Provenance
                Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.account_balance, size: 18, color: AppColors.goldPrimary),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'TRADITIONAL ATTRIBUTION & PROVENANCE',
                                style: AppTextStyles.metadataTag(isDark).copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),
                        _AttrRow(label: 'Composer / Originator', value: scripture.composer, isDark: isDark),
                        _AttrRow(label: 'Vedic Rishi (Sage)', value: scripture.rishi, isDark: isDark),
                        _AttrRow(label: 'Poetic Meter (Chandas)', value: scripture.chandas, isDark: isDark),
                        _AttrRow(label: 'Presiding Devata', value: scripture.devata, isDark: isDark),
                        _AttrRow(label: 'Source Scripture', value: scripture.sourceScripture, isDark: isDark),
                        _AttrRow(label: 'Liturgical Practice', value: scripture.traditionalUsage, isDark: isDark),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // 6. Opening Shloka Preview
                if (scripture.verses.isNotEmpty) ...[
                  Card(
                    margin: EdgeInsets.zero,
                    child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  'OPENING SHLOKA (VERSE 1)',
                                  style: AppTextStyles.metadataTag(isDark),
                                ),
                              ),
                              Text(
                                appState.activeScript.label,
                                style: AppTextStyles.caption(isDark).copyWith(
                                  color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF9F5EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              scripture.verses.first.getTextInScript(appState.activeScript),
                              style: AppTextStyles.verseDevanagari(isDark, scale: 0.95),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          if (appState.activeScript != ScriptOption.iast && scripture.verses.first.iastText.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text(
                              scripture.verses.first.iastText,
                              style: AppTextStyles.verseTransliteration(isDark, scale: 0.9),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],

                // 7. Section 8 Governance Banner
                const Section8GovernanceBanner(),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showBookmarksSheet(
    BuildContext context,
    Scripture scripture,
    List<VerseBookmark> bookmarks,
    ScriptureReaderState rState,
    AudioState? audioState,
    AppState appState,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Bookmarked Verses (${bookmarks.length})',
                      style: AppTextStyles.titleMedium(isDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: bookmarks.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final b = bookmarks[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.saffronPrimary.withValues(alpha: 0.15),
                          child: Text(
                            '',
                            style: const TextStyle(
                              color: AppColors.saffronPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Verse ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          b.verseSnippet,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(isDark),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerseLearningScreen(
                                scripture: scripture,
                                readerState: rState,
                                initialVerseNumber: b.verseNumber,
                                audioState: audioState,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showNotesSheet(
    BuildContext context,
    Scripture scripture,
    List<VerseNote> notes,
    ScriptureReaderState rState,
    AudioState? audioState,
    AppState appState,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? AppColors.nightSurface : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Personal Study Notes (${notes.length})',
                      style: AppTextStyles.titleMedium(isDark),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(ctx),
                    ),
                  ],
                ),
                const Divider(),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: notes.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (_, index) {
                      final n = notes[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.2),
                          child: Text(
                            '',
                            style: const TextStyle(
                              color: AppColors.goldDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        title: Text('Verse ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          n.noteText,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.caption(isDark),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(ctx);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => VerseLearningScreen(
                                scripture: scripture,
                                readerState: rState,
                                initialVerseNumber: n.verseNumber,
                                audioState: audioState,
                                appState: appState,
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}


class _DetailPill extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _DetailPill({required this.label, required this.color, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFFDE68A) : color,
        ),
      ),
    );
  }
}

class _AttrRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;

  const _AttrRow({required this.label, required this.value, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value.trim().isNotEmpty ? value : 'Unspecified in canonical record',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _CompletenessRow extends StatelessWidget {
  final String label;
  final String status;
  final bool isAvailable;
  final bool isDark;

  const _CompletenessRow({
    required this.label,
    required this.status,
    required this.isAvailable,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = isAvailable
        ? (isDark ? AppColors.goldDark : AppColors.verifiedGreen)
        : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary);
    final iconData = isAvailable ? Icons.check_circle_outline : Icons.pending_outlined;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(iconData, size: 16, color: statusColor),
          const SizedBox(width: 8),
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.caption(isDark).copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              status,
              style: TextStyle(
                fontSize: 12,
                color: statusColor,
                fontWeight: isAvailable ? FontWeight.w500 : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
