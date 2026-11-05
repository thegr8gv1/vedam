import 'package:flutter/material.dart';
import '../../../core/models/scripture.dart';
import '../../../core/theme/app_colors.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../state/app_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/scripture_card.dart';
import '../library/scripture_detail_screen.dart';

class FavoritesScreen extends StatelessWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final Function(int tabIndex) onNavigateToTab;

  const FavoritesScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.onNavigateToTab,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: SacredAppBar(
          title: 'Devotional Shelf',
          subtitle: 'मम ग्रन्थसङ्ग्रहः',
          showLogo: false,
          actions: const [],
        ),
        body: Column(
          children: [
            TabBar(
              indicatorColor: AppColors.saffronPrimary,
              labelColor: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
              unselectedLabelColor: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
              tabs: [
                Tab(
                  icon: const Icon(Icons.favorite, size: 18),
                  text: 'Favorites (${appState.favoriteScriptureIds.length})',
                ),
                Tab(
                  icon: const Icon(Icons.history, size: 18),
                  text: 'Recently Read (${appState.recentlyReadScriptureIds.length})',
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<List<Scripture>>(
                future: repository.getAllScriptures(),
                builder: (context, snapshot) {
                  final allScriptures = snapshot.data ?? [];
                  final scriptureMap = {for (var s in allScriptures) s.id: s};

                  final favoriteScriptures = appState.favoriteScriptureIds
                      .map((id) => scriptureMap[id])
                      .whereType<Scripture>()
                      .toList();

                  final recentScriptures = appState.recentlyReadScriptureIds
                      .map((id) => scriptureMap[id])
                      .whereType<Scripture>()
                      .toList();

                  return TabBarView(
                    children: [
                      // Tab 1: Favorites
                      favoriteScriptures.isEmpty
                          ? EmptyStateView(
                              title: 'No Favorites Yet',
                              message: 'Tap the heart icon on any scripture in the library to save it to your personal devotional shelf.',
                              icon: Icons.favorite_border,
                              buttonText: 'Browse Scripture Library',
                              onButtonPressed: () => onNavigateToTab(1),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: favoriteScriptures.length,
                              itemBuilder: (context, index) {
                                final s = favoriteScriptures[index];
                                return ScriptureCard(
                                  scripture: s,
                                  isFavorite: true,
                                  onFavoriteToggle: () => appState.toggleFavorite(s.id),
                                  onTap: () {
                                    appState.recordRecentlyRead(s.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScriptureDetailScreen(
                                          scripture: s,
                                          appState: appState,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),

                      // Tab 2: Recently Read
                      recentScriptures.isEmpty
                          ? EmptyStateView(
                              title: 'No Reading History',
                              message: 'Scriptures you open and recite will appear here for fast resumption of daily sadhana.',
                              icon: Icons.history,
                              buttonText: 'Explore Scriptures',
                              onButtonPressed: () => onNavigateToTab(1),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              itemCount: recentScriptures.length,
                              itemBuilder: (context, index) {
                                final s = recentScriptures[index];
                                final isFav = appState.isFavorite(s.id);
                                return ScriptureCard(
                                  scripture: s,
                                  isFavorite: isFav,
                                  onFavoriteToggle: () => appState.toggleFavorite(s.id),
                                  onTap: () {
                                    appState.recordRecentlyRead(s.id);
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (_) => ScriptureDetailScreen(
                                          scripture: s,
                                          appState: appState,
                                        ),
                                      ),
                                    );
                                  },
                                );
                              },
                            ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
