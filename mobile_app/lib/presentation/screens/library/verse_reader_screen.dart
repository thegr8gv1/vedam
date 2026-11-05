import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/scripture.dart';
import '../../../core/models/verse.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../state/app_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/script_selector_modal.dart';

class VerseReaderScreen extends StatefulWidget {
  final Scripture scripture;
  final AppState appState;

  const VerseReaderScreen({
    super.key,
    required this.scripture,
    required this.appState,
  });

  @override
  State<VerseReaderScreen> createState() => _VerseReaderScreenState();
}

class _VerseReaderScreenState extends State<VerseReaderScreen> {
  bool _showTranslation = true;
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _cycleFontScale() {
    final current = widget.appState.textScalePreference;
    switch (current) {
      case TextScalePreference.normal:
        widget.appState.setTextScalePreference(TextScalePreference.large);
        break;
      case TextScalePreference.large:
        widget.appState.setTextScalePreference(TextScalePreference.extraLarge);
        break;
      case TextScalePreference.extraLarge:
        widget.appState.setTextScalePreference(TextScalePreference.normal);
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: widget.appState,
      builder: (context, _) {
        final fontScale = widget.appState.fontScale;
        final activeScript = widget.appState.activeScript;

        return Scaffold(
          appBar: SacredAppBar(
            title: widget.scripture.canonicalTitle,
            subtitle: '${widget.scripture.verseCount} Verses • ${activeScript.label}',
            showLogo: false,
            actions: [
              // Script Switcher Button
              IconButton(
                icon: const Icon(Icons.translate),
                tooltip: 'Switch Script (${activeScript.label})',
                onPressed: () {
                  ScriptSelectorModal.show(
                    context,
                    currentScript: activeScript,
                    onScriptSelected: (s) => widget.appState.setActiveScript(s),
                  );
                },
              ),
              // Font Scaler Button
              IconButton(
                icon: const Icon(Icons.format_size),
                tooltip: 'Text Size (${widget.appState.textScalePreference.label})',
                onPressed: _cycleFontScale,
              ),
              // Show/Hide Translation
              IconButton(
                icon: Icon(_showTranslation ? Icons.menu_book : Icons.menu_book_outlined),
                tooltip: _showTranslation ? 'Hide Translation' : 'Show Translation',
                onPressed: () {
                  setState(() {
                    _showTranslation = !_showTranslation;
                  });
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Sticky Reader Setting Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                color: isDark ? AppColors.nightSurface : const Color(0xFFF7F2EA),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    InkWell(
                      onTap: () {
                        ScriptSelectorModal.show(
                          context,
                          currentScript: activeScript,
                          onScriptSelected: (s) => widget.appState.setActiveScript(s),
                        );
                      },
                      child: Row(
                        children: [
                          Icon(Icons.language, size: 16, color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary),
                          const SizedBox(width: 6),
                          Text(
                            'Script: ${activeScript.label}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                            ),
                          ),
                          const Icon(Icons.arrow_drop_down, size: 16),
                        ],
                      ),
                    ),
                    Text(
                      'Size: ${(fontScale * 100).toInt()}%',
                      style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),

              // 2. Verse List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
                  itemCount: widget.scripture.verses.length,
                  itemBuilder: (context, index) {
                    final verse = widget.scripture.verses[index];
                    return _VerseReaderCard(
                      verse: verse,
                      scripture: widget.scripture,
                      activeScript: activeScript,
                      fontScale: fontScale,
                      showTranslation: _showTranslation,
                      isDark: isDark,
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerseReaderCard extends StatelessWidget {
  final Verse verse;
  final Scripture scripture;
  final ScriptOption activeScript;
  final double fontScale;
  final bool showTranslation;
  final bool isDark;

  const _VerseReaderCard({
    required this.verse,
    required this.scripture,
    required this.activeScript,
    required this.fontScale,
    required this.showTranslation,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final scriptText = verse.getTextInScript(activeScript);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Verse Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.saffronPrimary.withValues(alpha: isDark ? 0.25 : 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.saffronPrimary.withValues(alpha: 0.4),
                      width: 0.8,
                    ),
                  ),
                  child: Text(
                    'VERSE ${verse.verseNumber}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isDark ? const Color(0xFFFFDBC8) : AppColors.saffronDark,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                if (verse.meter.isNotEmpty)
                  Text(
                    'Meter: ${verse.meter}',
                    style: AppTextStyles.caption(isDark),
                  ),
              ],
            ),

            const SizedBox(height: 14),

            // Sacred Verse in Chosen Script
            SelectableText(
              scriptText,
              style: AppTextStyles.verseDevanagari(isDark, scale: fontScale),
              textAlign: TextAlign.center,
            ),

            // Transliteration (Shown if active script is not IAST)
            if (activeScript != ScriptOption.iast && verse.iastText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF9F6F0),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: SelectableText(
                  verse.iastText,
                  style: AppTextStyles.verseTransliteration(isDark, scale: fontScale * 0.9),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Translation Section
            if (showTranslation) ...[
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),

              if (verse.hasDraftTranslation) ...[
                // Draft Translation Card with Section 8 Warning
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF26190C) : AppColors.draftWarningLight,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? const Color(0xFF8C5311) : AppColors.draftWarningBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.rate_review_outlined,
                            size: 14,
                            color: isDark ? const Color(0xFFFCD34D) : AppColors.draftWarning,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'BHAVARTHA (STUDY TRANSLATION)',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                              color: isDark ? const Color(0xFFFCD34D) : const Color(0xFF92400E),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      SelectableText(
                        verse.draftTranslation!,
                        style: TextStyle(
                          fontSize: 14 * fontScale,
                          height: 1.55,
                          color: isDark ? const Color(0xFFFEF3C7) : const Color(0xFF451A03),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Status: Section 8 Draft • Under scholarly peer review • For study only',
                        style: TextStyle(
                          fontSize: 10,
                          fontStyle: FontStyle.italic,
                          color: isDark ? const Color(0xFFD97706) : const Color(0xFFB45309),
                        ),
                      ),
                    ],
                  ),
                ),
              ] else ...[
                // Translation Unavailable / In Progress Graceful State
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF3EFE8),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                      width: 0.8,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.hourglass_top_outlined,
                        size: 16,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppConstants.translationInProgressBanner,
                          style: AppTextStyles.caption(isDark).copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
