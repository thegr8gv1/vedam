import 'package:flutter/material.dart';
import '../../../../core/models/scripture.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/repositories/scripture_repository.dart';
import '../../../../state/app_state.dart';
import '../../../../state/audio_state.dart';
import '../../../../state/scripture_reader_state.dart';
import '../../library/verse_learning_screen.dart';

/// Scripture Learning Progress card on the Devotee Home Dashboard.
///
/// Features:
/// - Reuses ScriptureReaderState, AppState, and ScriptureRepository.
/// - Shows the most recently read scripture and current verse progress.
/// - Displays total bookmarked verses count.
/// - Continue Reading action opening VerseReaderScreen at the exact saved verse ID.
/// - Section 8 Editorial Governance disclosure assuring that translations are working drafts.
/// - Direct link to the full Scripture Library.
class ScriptureProgressCard extends StatelessWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final ScriptureReaderState readerState;
  final AudioState? audioState;
  final VoidCallback onOpenLibrary;

  const ScriptureProgressCard({
    super.key,
    required this.repository,
    required this.appState,
    required this.readerState,
    this.audioState,
    required this.onOpenLibrary,
  });

  Future<Scripture?> _resolveRecentScripture() async {
    // 1. Check AppState recently read
    if (appState.recentlyReadScriptureIds.isNotEmpty) {
      final recentId = appState.recentlyReadScriptureIds.first;
      final scripture = await repository.getScriptureById(recentId);
      if (scripture != null) return scripture;
    }

    // 2. Check ReaderState progress entries
    final progressEntries = readerState.allProgress.values.toList();
    if (progressEntries.isNotEmpty) {
      progressEntries.sort((a, b) => b.lastReadAt.compareTo(a.lastReadAt));
      final recentId = progressEntries.first.scriptureId;
      final scripture = await repository.getScriptureById(recentId);
      if (scripture != null) return scripture;
    }

    // 3. Fallback to foundational scripture (Mahamrityunjaya or Gayatri)
    return await repository.getScriptureById(5) ??
        await repository.getScriptureById(1);
  }

  void _openScripture(BuildContext context, Scripture scripture, int verseNum) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VerseLearningScreen(
          scripture: scripture,
          readerState: readerState,
          audioState: audioState,
          initialVerseNumber: verseNum,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bookmarkCount = readerState.allBookmarks.length;

    return FutureBuilder<Scripture?>(
      future: _resolveRecentScripture(),
      builder: (context, snapshot) {
        final scripture = snapshot.data;
        final progressData = scripture != null ? readerState.getProgress(scripture.id) : null;
        final hasHistory = progressData != null;
        final lastVerse = progressData?.lastReadVerseNumber ?? 1;
        final totalVerses = scripture?.verseCount ?? 1;
        final progressPct = hasHistory ? (lastVerse / (totalVerses > 0 ? totalVerses : 1)).clamp(0.0, 1.0) : 0.0;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          const Icon(
                            Icons.menu_book,
                            size: 18,
                            color: AppColors.saffronPrimary,
                          ),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              'SCRIPTURE LEARNING PROGRESS',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: onOpenLibrary,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'All Scriptures',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                              ),
                            ),
                            const SizedBox(width: 3),
                            const Icon(Icons.arrow_forward_ios, size: 11, color: AppColors.saffronPrimary),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                if (scripture != null) ...[
                  // Scripture Progress Container
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF8F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                        width: 0.8,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    scripture.canonicalTitle,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    scripture.devanagariTitle,
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.saffronPrimary.withAlpha(20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                hasHistory
                                    ? 'Verse $lastVerse of $totalVerses'
                                    : '$totalVerses Verses',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.saffronPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),

                        // Progress Bar
                        ClipRRect(
                          borderRadius: BorderRadius.circular(6),
                          child: LinearProgressIndicator(
                            value: progressPct,
                            minHeight: 6,
                            backgroundColor: isDark ? AppColors.nightBorder : const Color(0xFFE5DDD0),
                            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
                          ),
                        ),
                        const SizedBox(height: 6),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              hasHistory
                                  ? '${(progressPct * 100).toInt()}% completed'
                                  : 'Not yet started',
                              style: TextStyle(
                                fontSize: 10.5,
                                color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                              ),
                            ),
                            if (bookmarkCount > 0)
                              Text(
                                '$bookmarkCount bookmarked verses',
                                style: TextStyle(
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.goldLight : AppColors.goldDark,
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Continue Reading Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 42,
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.auto_stories, size: 16),
                      label: Text(
                        hasHistory ? 'Continue Reading (Verse $lastVerse)' : 'Start Reading',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.saffronPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: () => _openScripture(context, scripture, lastVerse),
                    ),
                  ),
                ] else ...[
                  // Loading Placeholder
                  const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                ],

                const SizedBox(height: 8),

                // Section 8 Translation Disclosure Notice
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF7F3EA),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                      width: 0.6,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.gavel_outlined, size: 12, color: AppColors.saffronPrimary),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Section 8 Notice: All English scripture translations are scholarly DRAFT translations.',
                          style: TextStyle(
                            fontSize: 9.5,
                            fontStyle: FontStyle.italic,
                            color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                          ),
                        ),
                      ),
                    ],
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
