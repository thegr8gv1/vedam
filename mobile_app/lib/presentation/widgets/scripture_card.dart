import 'package:flutter/material.dart';
import '../../core/models/scripture.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/text_styles.dart';

class ScriptureCard extends StatelessWidget {
  final Scripture scripture;
  final bool isFavorite;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onTap;

  const ScriptureCard({
    super.key,
    required this.scripture,
    required this.isFavorite,
    required this.onFavoriteToggle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          scripture.canonicalTitle,
                          style: AppTextStyles.titleMedium(isDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          scripture.devanagariTitle,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      isFavorite ? Icons.favorite : Icons.favorite_border,
                      color: isFavorite ? AppColors.kumkumRed : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                    ),
                    onPressed: onFavoriteToggle,
                    tooltip: isFavorite ? 'Remove from favorites' : 'Add to favorites',
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: [
                  _Badge(
                    label: scripture.category,
                    color: AppColors.saffronPrimary,
                    isDark: isDark,
                  ),
                  _Badge(
                    label: scripture.deity,
                    color: AppColors.goldDark,
                    isDark: isDark,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    scripture.composer.isNotEmpty ? 'By ${scripture.composer}' : scripture.sourceScripture,
                    style: AppTextStyles.caption(isDark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book_outlined,
                        size: 14,
                        color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${scripture.verseCount} verses',
                        style: AppTextStyles.caption(isDark).copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;
  final bool isDark;

  const _Badge({
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color.withValues(alpha: 0.4),
          width: 0.8,
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFFDE68A) : color,
        ),
      ),
    );
  }
}
