import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

/// Cultural and respectful Offline status banner.
/// Informs devotees that local scriptures, Japa, Sadhana, and Panchangam
/// remain fully accessible offline without internet connection.
class OfflineStatusBanner extends StatefulWidget {
  final bool isOffline;
  final VoidCallback? onDismiss;

  const OfflineStatusBanner({
    super.key,
    this.isOffline = true,
    this.onDismiss,
  });

  @override
  State<OfflineStatusBanner> createState() => _OfflineStatusBannerState();
}

class _OfflineStatusBannerState extends State<OfflineStatusBanner> {
  bool _dismissed = false;

  @override
  Widget build(BuildContext context) {
    if (!widget.isOffline || _dismissed) {
      return const SizedBox.shrink();
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l10n = AppLocalizations.of(context);

    return Semantics(
      label: 'Offline indicator banner',
      value: l10n?.offlineModeBanner ??
          'Offline Mode — Local scriptures & practices available',
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF231B12) : const Color(0xFFFFF8EC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isDark ? AppColors.goldPrimary.withAlpha(80) : AppColors.saffronPrimary.withAlpha(60),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(12),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            const Icon(
              Icons.cloud_off_outlined,
              size: 18,
              color: AppColors.saffronPrimary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                l10n?.offlineModeBanner ??
                    'Offline Mode — Local scriptures & practices available',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                  height: 1.3,
                ),
              ),
            ),
            InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                setState(() => _dismissed = true);
                widget.onDismiss?.call();
              },
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Icon(
                  Icons.close,
                  size: 16,
                  color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
