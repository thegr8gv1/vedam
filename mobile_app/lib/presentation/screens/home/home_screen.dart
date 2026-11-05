import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/daily_darshan.dart';
import '../../../core/models/scripture.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../state/app_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/scripture_card.dart';
import '../../widgets/section_header.dart';
import '../library/scripture_detail_screen.dart';
import 'widgets/daily_verse_card.dart';
import 'widgets/panchangam_preview_card.dart';

class HomeScreen extends StatelessWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final Function(int tabIndex) onNavigateToTab;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darshan = DailyDarshan.today();

    return Scaffold(
      appBar: SacredAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => onNavigateToTab(1), // Go to library
            tooltip: 'Search Scriptures',
          ),
          IconButton(
            icon: Icon(
              appState.themePreference.mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              final next = appState.themePreference.mode == ThemeMode.dark
                  ? ThemePreference.light
                  : ThemePreference.dark;
              appState.setThemePreference(next);
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: FutureBuilder<List<Scripture>>(
        future: repository.getAllScriptures(),
        builder: (context, snapshot) {
          final scriptures = snapshot.data ?? [];

          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 1. Invocation Header Banner
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1F1712) : const Color(0xFFF7F1E6),
                    border: Border(
                      bottom: BorderSide(
                        color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                        width: 0.8,
                      ),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        AppConstants.invocationShloka,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        AppConstants.invocationTranslation,
                        style: AppTextStyles.caption(isDark),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // 2. Daily Devotional Verse (Darshan)
                DailyVerseCard(
                  darshan: darshan,
                  onReadFull: () async {
                    final mrityunjaya = await repository.getScriptureById(5);
                    if (mrityunjaya != null && context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ScriptureDetailScreen(
                            scripture: mrityunjaya,
                            appState: appState,
                          ),
                        ),
                      );
                    }
                  },
                ),

                // 3. Today's Panchangam Preview
                PanchangamPreviewCard(darshan: darshan),

                // 4. Quick Portals Grid
                SectionHeader(
                  title: 'Sacred Portals',
                  subtitle: 'Direct pathways to scripture, japa, and daily worship',
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PortalCard(
                          title: 'Scripture Library',
                          subtitle: 'Vedas, Suktams, Stotras',
                          icon: Icons.menu_book,
                          accentColor: AppColors.saffronPrimary,
                          onTap: () => onNavigateToTab(1), // Library
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PortalCard(
                          title: 'Daily Sadhana',
                          subtitle: 'Puja, Japa & Sankalpam',
                          icon: Icons.self_improvement,
                          accentColor: AppColors.goldPrimary,
                          onTap: () => onNavigateToTab(2), // Sadhana
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: _PortalCard(
                          title: 'Mantras & Chanting',
                          subtitle: 'Gayatri, Vedic hymns',
                          icon: Icons.graphic_eq,
                          accentColor: const Color(0xFF0D9488),
                          onTap: () => onNavigateToTab(1),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _PortalCard(
                          title: 'My Devotional Shelf',
                          subtitle: '${appState.favoriteScriptureIds.length} Saved Scriptures',
                          icon: Icons.favorite_border,
                          accentColor: AppColors.kumkumRed,
                          onTap: () => onNavigateToTab(3), // Favorites
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // 5. Popular Sacred Compositions
                SectionHeader(
                  title: 'Popular Sacred Compositions',
                  subtitle: 'Canonical hymns for daily recitation',
                  actionText: 'View All (20)',
                  onAction: () => onNavigateToTab(1),
                ),

                if (scriptures.isEmpty)
                  const Center(child: CircularProgressIndicator())
                else
                  ...scriptures.take(4).map((scripture) {
                    final isFav = appState.isFavorite(scripture.id);
                    return ScriptureCard(
                      scripture: scripture,
                      isFavorite: isFav,
                      onFavoriteToggle: () => appState.toggleFavorite(scripture.id),
                      onTap: () {
                        appState.recordRecentlyRead(scripture.id);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScriptureDetailScreen(
                              scripture: scripture,
                              appState: appState,
                            ),
                          ),
                        );
                      },
                    );
                  }),

                const SizedBox(height: 16),

                // 6. Section 8 Governance Assurance Banner
                const Section8GovernanceBanner(),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _PortalCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final VoidCallback onTap;

  const _PortalCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: accentColor),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption(isDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
