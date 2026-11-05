import 'package:flutter/material.dart';
import '../../../core/models/scripture.dart';
import '../../../core/models/verse.dart';
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
                            Text(
                              'CONTENT COVERAGE & SCHOLARLY INTEGRITY',
                              style: AppTextStyles.metadataTag(isDark).copyWith(fontWeight: FontWeight.bold),
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
                            Text(
                              'TRADITIONAL ATTRIBUTION & PROVENANCE',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
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
                              Text(
                                'OPENING SHLOKA (VERSE 1)',
                                style: AppTextStyles.metadataTag(isDark),
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
              value.isNotEmpty ? value : 'Traditional Canonical',
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
