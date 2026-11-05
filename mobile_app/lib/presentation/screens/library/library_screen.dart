import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../state/app_state.dart';
import '../../../state/scripture_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/scripture_card.dart';
import 'scripture_detail_screen.dart';

class LibraryScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final AppState appState;

  const LibraryScreen({
    super.key,
    required this.repository,
    required this.appState,
  });

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> {
  late final ScriptureState _scriptureState;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _scriptureState = ScriptureState(widget.repository);
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
      ),
      body: ListenableBuilder(
        listenable: _scriptureState,
        builder: (context, _) {
          return Column(
            children: [
              // 1. Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by title, deity, sage, or composer...',
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

              // 2. Deity Filter Chips (Horizontal Scroll)
              SizedBox(
                height: 42,
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
                          fontSize: 12,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          color: isSelected
                              ? Colors.white
                              : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                        ),
                        selectedColor: AppColors.saffronPrimary,
                        backgroundColor: isDark ? AppColors.nightSurface : const Color(0xFFF0EAE1),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.saffronPrimary
                              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                        ),
                        onSelected: (_) => _scriptureState.setDeity(deity),
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 6),

              // 3. Category Filter Chips (Horizontal Scroll)
              SizedBox(
                height: 38,
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
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected
                              ? (isDark ? Colors.black : Colors.white)
                              : (isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary),
                        ),
                        selectedColor: isDark ? AppColors.goldGlow : AppColors.goldDark,
                        backgroundColor: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF9F5EE),
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

              const SizedBox(height: 8),

              // 4. Results Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${_scriptureState.filteredScriptures.length} Sacred Texts Available',
                      style: AppTextStyles.caption(isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (_scriptureState.selectedCategory != 'All Categories' ||
                        _scriptureState.selectedDeity != 'All Deities' ||
                        _scriptureState.searchQuery.isNotEmpty)
                      InkWell(
                        onTap: () {
                          _searchController.clear();
                          _scriptureState.resetFilters();
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

              const Divider(height: 8),

              // 5. Scripture List
              Expanded(
                child: _scriptureState.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : _scriptureState.filteredScriptures.isEmpty
                        ? EmptyStateView(
                            title: 'No Scriptures Found',
                            message: 'Try clearing your search query or choosing another deity or category.',
                            buttonText: 'Reset Filters',
                            onButtonPressed: () {
                              _searchController.clear();
                              _scriptureState.resetFilters();
                            },
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: _scriptureState.filteredScriptures.length,
                            itemBuilder: (context, index) {
                              final scripture = _scriptureState.filteredScriptures[index];
                              final isFav = widget.appState.isFavorite(scripture.id);
                              return ScriptureCard(
                                scripture: scripture,
                                isFavorite: isFav,
                                onFavoriteToggle: () => widget.appState.toggleFavorite(scripture.id),
                                onTap: () {
                                  widget.appState.recordRecentlyRead(scripture.id);
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ScriptureDetailScreen(
                                        scripture: scripture,
                                        appState: widget.appState,
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
