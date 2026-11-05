import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/repositories/scripture_repository.dart';
import '../../../../state/app_state.dart';
import '../../../../state/audio_state.dart';
import '../../../../state/scripture_reader_state.dart';
import '../../library/bookmarks_screen.dart';

/// Saved Devotional Content card on the Devotee Home Dashboard.
///
/// Features:
/// - Provides instant access to the devotee's saved scriptures, bookmarked verses,
///   personal study notes, and favorite mantras.
/// - Strictly local on-device persistence; zero telemetry or cloud accounts.
/// - Consistent 48dp touch targets with clear icons and badge counts.
class SavedDevotionalCard extends StatelessWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final ScriptureReaderState readerState;
  final AudioState? audioState;
  final Function(int tabIndex) onNavigateToTab;
  final VoidCallback? onOpenMantras;

  const SavedDevotionalCard({
    super.key,
    required this.repository,
    required this.appState,
    required this.readerState,
    this.audioState,
    required this.onNavigateToTab,
    this.onOpenMantras,
  });

  void _openBookmarks(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BookmarksScreen(
          repository: repository,
          readerState: readerState,
          audioState: audioState,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final savedScripturesCount = appState.favoriteScriptureIds.length;
    final bookmarksCount = readerState.allBookmarks.length;
    final notesCount = readerState.allNotes.length;
    final favoriteMantrasCount = audioState?.favoriteMantraIds.length ?? 0;

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
              children: [
                const Icon(
                  Icons.favorite,
                  size: 18,
                  color: AppColors.kumkumRed,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'SAVED DEVOTIONAL CONTENT',
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
            const SizedBox(height: 12),

            // 2x2 Grid of Devotional Portals
            Row(
              children: [
                Expanded(
                  child: _SavedItemTile(
                    title: 'Saved Scriptures',
                    subtitle: '$savedScripturesCount scriptures',
                    icon: Icons.bookmark_border,
                    badgeCount: savedScripturesCount,
                    accentColor: AppColors.saffronPrimary,
                    isDark: isDark,
                    onTap: () => onNavigateToTab(3), // Saved / Favorites tab
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SavedItemTile(
                    title: 'Bookmarked Verses',
                    subtitle: '$bookmarksCount verses',
                    icon: Icons.collections_bookmark_outlined,
                    badgeCount: bookmarksCount,
                    accentColor: AppColors.goldPrimary,
                    isDark: isDark,
                    onTap: () => _openBookmarks(context),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _SavedItemTile(
                    title: 'Personal Notes',
                    subtitle: '$notesCount study reflections',
                    icon: Icons.edit_note,
                    badgeCount: notesCount,
                    accentColor: const Color(0xFF0D9488),
                    isDark: isDark,
                    onTap: () => _openBookmarks(context),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _SavedItemTile(
                    title: 'Favorite Mantras',
                    subtitle: '$favoriteMantrasCount sacred chants',
                    icon: Icons.graphic_eq,
                    badgeCount: favoriteMantrasCount,
                    accentColor: AppColors.kumkumRed,
                    isDark: isDark,
                    onTap: onOpenMantras ?? () => onNavigateToTab(1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SavedItemTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final int badgeCount;
  final Color accentColor;
  final bool isDark;
  final VoidCallback onTap;

  const _SavedItemTile({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.badgeCount,
    required this.accentColor,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F2),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            width: 0.8,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentColor.withAlpha(isDark ? 30 : 20),
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 10,
                      color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            if (badgeCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: accentColor.withAlpha(25),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$badgeCount',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
