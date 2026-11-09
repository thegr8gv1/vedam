import '../../../core/models/mantra_item.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/scripture.dart';
import '../../../core/models/scripture_user_data.dart';
import '../../../core/models/verse.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/fixtures/authentic_mantras_data.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/script_selector_modal.dart';
import 'verse_learning_screen.dart';
import 'widgets/reading_preferences_modal.dart';
import 'widgets/verse_note_dialog.dart';

class VerseReaderScreen extends StatefulWidget {
  final Scripture scripture;
  final AppState? appState;
  final ScriptureReaderState? readerState;
  final AudioState? audioState;

  const VerseReaderScreen({
    super.key,
    required this.scripture,
    this.appState,
    this.readerState,
    this.audioState,
  });

  @override
  State<VerseReaderScreen> createState() => _VerseReaderScreenState();
}

class _VerseReaderScreenState extends State<VerseReaderScreen> {
  final ScrollController _scrollController = ScrollController();
  late final ScriptureReaderState _readerState;
  late final AppState _appState;

  @override
  void initState() {
    super.initState();
    _readerState = widget.readerState ?? ScriptureReaderState();
    _appState = widget.appState ?? AppState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: Listenable.merge([_readerState, _appState]),
      builder: (context, _) {
        final prefs = _readerState.preferences;
        final activeScript = _appState.activeScript;

        return Scaffold(
          appBar: SacredAppBar(
            title: widget.scripture.canonicalTitle,
            subtitle: '${widget.scripture.verseCount} Verses • ${activeScript.label}',
            showLogo: false,
            actions: [
              // 1. Switch to Verse-by-Verse Learning Mode
              IconButton(
                icon: const Icon(Icons.school_outlined),
                tooltip: 'Verse-by-Verse Learning Mode',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerseLearningScreen(
                        scripture: widget.scripture,
                        readerState: _readerState,
                        audioState: widget.audioState,
                        appState: _appState,
                      ),
                    ),
                  );
                },
              ),
              // 2. Script Switcher Button
              IconButton(
                icon: const Icon(Icons.translate),
                tooltip: 'Switch Script (${activeScript.label})',
                onPressed: () {
                  ScriptSelectorModal.show(
                    context,
                    currentScript: activeScript,
                    onScriptSelected: (s) {
                      _readerState.updatePreferences(
                        prefs.copyWith(preferredScript: s),
                      );
                      _appState.setActiveScript(s);
                    },
                  );
                },
              ),
              // 3. Typography & Reading Preferences
              IconButton(
                icon: const Icon(Icons.format_size),
                tooltip: 'Reading Preferences',
                onPressed: () => ReadingPreferencesModal.show(context, _readerState),
              ),
              // 4. Show/Hide Translation
              IconButton(
                icon: Icon(prefs.showTranslation ? Icons.menu_book : Icons.menu_book_outlined),
                tooltip: prefs.showTranslation ? 'Hide Translation' : 'Show Translation',
                onPressed: () {
                  _readerState.updatePreferences(
                    prefs.copyWith(showTranslation: !prefs.showTranslation),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Sticky Reader Settings & Status Bar
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
                          onScriptSelected: (s) {
                            _readerState.updatePreferences(
                              prefs.copyWith(preferredScript: s),
                            );
                            _appState.setActiveScript(s);
                          },
                        );
                      },
                      child: Row(
                        children: [
                          Icon(
                            Icons.language,
                            size: 16,
                            color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                          ),
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
                    InkWell(
                      onTap: () => ReadingPreferencesModal.show(context, _readerState),
                      child: Text(
                        'Font: ${prefs.sanskritFontSize.toInt()}pt • Spacing: ${prefs.lineSpacing}',
                        style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Continuous Verse List
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
                      readerState: _readerState,
                      audioState: widget.audioState,
                      appState: _appState,
                      activeScript: activeScript,
                      prefs: prefs,
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
  final ScriptureReaderState readerState;
  final AudioState? audioState;
  final AppState? appState;
  final ScriptOption activeScript;
  final ReadingPreferences prefs;
  final bool isDark;

  const _VerseReaderCard({
    required this.verse,
    required this.scripture,
    required this.readerState,
    this.audioState,
    this.appState,
    required this.activeScript,
    required this.prefs,
    required this.isDark,
  });

  void _playOrShowVaultFallback(BuildContext context, MantraItem mantra) async {
    if (audioState == null) return;
    if (audioState!.isPlaying && audioState!.activeMantra?.id == mantra.id) {
      await audioState!.pause();
      return;
    }
    await audioState!.playMantra(mantra);
    if (audioState!.errorMessage != null && context.mounted) {
      showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: Colors.orange),
              SizedBox(width: 8),
              Expanded(child: Text('Vault Archive Recording')),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recording: ${mantra.filename}\nDuration: ${mantra.formattedDuration}',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              ),
              const SizedBox(height: 10),
              const Text(
                'This master recording is preserved in the desktop vault (C:\\ttv youtube premium\\Mantras\\). '
                'To keep the mobile app size compact (<100MB), it is not bundled for offline audio playback in this release.\n\n'
                'You can practice chanting along with the script display and transliteration.',
                style: TextStyle(fontSize: 13, height: 1.4),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronPrimary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Understood'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final scriptText = verse.getTextInScript(activeScript);
    final globalVerseId = verse.globalId(scripture.contentId);
    final isBookmarked = readerState.isBookmarked(globalVerseId);
    final personalNote = readerState.getNote(globalVerseId);

    // Mapped audio if available
    final mappedMantra = verse.audioMantraId != null
        ? AuthenticMantrasData.getMantraById(verse.audioMantraId!)
        : null;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isBookmarked
              ? AppColors.goldPrimary
              : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
          width: isBookmarked ? 1.5 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Verse Header & Controls
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
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
                    if (verse.meter.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Text(
                        'Meter: ${verse.meter}',
                        style: AppTextStyles.caption(isDark),
                      ),
                    ],
                  ],
                ),
                Row(
                  children: [
                    // Study Mode Jump Button
                    IconButton(
                      icon: const Icon(Icons.school, size: 20),
                      tooltip: 'Learn this verse',
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => VerseLearningScreen(
                              scripture: scripture,
                              readerState: readerState,
                              initialVerseNumber: verse.verseNumber,
                              audioState: audioState,
                              appState: appState,
                            ),
                          ),
                        );
                      },
                    ),
                    // Bookmark Button
                    IconButton(
                      icon: Icon(
                        isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                        color: isBookmarked ? AppColors.goldPrimary : null,
                        size: 20,
                      ),
                      tooltip: isBookmarked ? 'Remove Bookmark' : 'Bookmark Verse',
                      onPressed: () => readerState.toggleBookmark(verse, scripture),
                    ),
                    // Note Button
                    IconButton(
                      icon: Icon(
                        personalNote != null ? Icons.edit_note : Icons.note_add_outlined,
                        color: personalNote != null ? AppColors.saffronPrimary : null,
                        size: 20,
                      ),
                      tooltip: personalNote != null ? 'Edit Study Note' : 'Add Study Note',
                      onPressed: () => VerseNoteDialog.show(
                        context: context,
                        verse: verse,
                        scripture: scripture,
                        readerState: readerState,
                      ),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 14),

            // Sacred Verse in Chosen Script
            SelectableText(
              scriptText,
              style: TextStyle(
                fontSize: prefs.sanskritFontSize,
                height: prefs.lineSpacing,
                fontWeight: FontWeight.w600,
                fontFamilyFallback: AppTextStyles.indicFontFamilyFallback,
                color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
              ),
              textAlign: TextAlign.center,
            ),

            // Transliteration (Shown if active script is not IAST and preference enabled)
            if (prefs.showTransliteration &&
                activeScript != ScriptOption.iast &&
                verse.iastText.isNotEmpty) ...[
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
                  style: TextStyle(
                    fontSize: prefs.transliterationFontSize,
                    height: prefs.lineSpacing,
                    fontStyle: FontStyle.italic,
                    color: isDark ? const Color(0xFFE2E8F0) : const Color(0xFF334155),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],

            // Verified Audio Control (Only if mapped)
            if (verse.hasVerifiedAudio && mappedMantra != null && audioState != null) ...[
              const SizedBox(height: 12),
              ListenableBuilder(
                listenable: audioState!,
                builder: (context, _) {
                  final isPlaying = audioState!.isPlaying &&
                      audioState!.activeMantra?.id == mappedMantra.id;
                  return OutlinedButton.icon(
                    icon: Icon(
                      isPlaying ? Icons.pause_circle_filled : Icons.play_circle_fill,
                      color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                    ),
                    label: Text(
                      isPlaying ? 'Pause Audio' : 'Chant Verse (Audio)',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                      ),
                    ),
                    onPressed: () => _playOrShowVaultFallback(context, mappedMantra),
                  );
                },
              ),
            ],

            // Translation Section
            if (prefs.showTranslation) ...[
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
                          fontSize: prefs.translationFontSize,
                          height: prefs.lineSpacing,
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

            // Personal Study Note Snippet
            if (personalNote != null && personalNote.noteText.isNotEmpty) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark ? Colors.blue.shade900 : Colors.blue.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.note,
                      size: 14,
                      color: isDark ? Colors.blue.shade300 : Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        personalNote.noteText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
