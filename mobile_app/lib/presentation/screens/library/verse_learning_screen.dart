import '../../../state/app_state.dart';
import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/scripture.dart';
import '../../../core/models/verse.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/fixtures/authentic_mantras_data.dart';
import '../../../state/audio_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/script_selector_modal.dart';
import 'verse_reader_screen.dart';
import 'widgets/reading_preferences_modal.dart';
import 'widgets/verse_note_dialog.dart';

/// Focused Verse-by-Verse Learning and Contemplation Mode.
/// Devotees can read one verse at a time with adjustable typography,
/// verified audio integration, local bookmarks, private study notes,
/// and honest Section 8 translation governance disclosures.
class VerseLearningScreen extends StatefulWidget {
  final Scripture scripture;
  final ScriptureReaderState readerState;
  final int? initialVerseNumber;
  final AudioState? audioState;
  final AppState? appState;
  final bool initialShowPreferences;

  const VerseLearningScreen({
    super.key,
    required this.scripture,
    required this.readerState,
    this.initialVerseNumber,
    this.audioState,
    this.appState,
    this.initialShowPreferences = false,
  });

  @override
  State<VerseLearningScreen> createState() => _VerseLearningScreenState();
}

class _VerseLearningScreenState extends State<VerseLearningScreen> {
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    // Resume from passed initial verse, or from saved progress, or start at 0
    final savedProgress = widget.readerState.getProgress(widget.scripture.id);
    if (widget.initialVerseNumber != null) {
      _currentIndex = (widget.initialVerseNumber! - 1)
          .clamp(0, widget.scripture.verses.length - 1);
    } else if (savedProgress != null &&
        savedProgress.lastReadVerseNumber > 0 &&
        savedProgress.lastReadVerseNumber <= widget.scripture.verses.length) {
      _currentIndex = savedProgress.lastReadVerseNumber - 1;
    } else {
      _currentIndex = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _recordProgress();
      }
    });

    if (widget.initialShowPreferences) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ReadingPreferencesModal.show(context, widget.readerState);
        }
      });
    }
  }

  void _recordProgress() {
    if (widget.scripture.verses.isNotEmpty) {
      final vNumber = widget.scripture.verses[_currentIndex].verseNumber;
      widget.readerState.recordReadingProgress(widget.scripture, vNumber);
    }
  }

  void _goToNext() {
    if (_currentIndex < widget.scripture.verses.length - 1) {
      setState(() {
        _currentIndex++;
      });
      _recordProgress();
    }
  }

  void _goToPrevious() {
    if (_currentIndex > 0) {
      setState(() {
        _currentIndex--;
      });
      _recordProgress();
    }
  }

  void _jumpToVerse(int index) {
    if (index >= 0 && index < widget.scripture.verses.length) {
      setState(() {
        _currentIndex = index;
      });
      _recordProgress();
    }
  }

  void _showVerseJumperModal(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Select Verse (${widget.scripture.verseCount} Total)',
              style: AppTextStyles.titleMedium(isDark),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: GridView.builder(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 5,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                ),
                itemCount: widget.scripture.verses.length,
                itemBuilder: (context, idx) {
                  final v = widget.scripture.verses[idx];
                  final isCurrent = idx == _currentIndex;
                  final gId = v.globalId(widget.scripture.contentId);
                  final isBookmarked = widget.readerState.isBookmarked(gId);

                  return InkWell(
                    onTap: () {
                      Navigator.pop(context);
                      _jumpToVerse(idx);
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isCurrent
                            ? AppColors.saffronPrimary
                            : (isDark
                                ? AppColors.nightSurfaceElevated
                                : const Color(0xFFF3ECE1)),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent
                              ? AppColors.saffronPrimary
                              : (isBookmarked
                                  ? AppColors.goldPrimary
                                  : (isDark
                                      ? AppColors.nightBorder
                                      : AppColors.chandanBorder)),
                          width: isBookmarked ? 1.5 : 1,
                        ),
                      ),
                      child: Stack(
                        children: [
                          Center(
                            child: Text(
                              '${v.verseNumber}',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: isCurrent
                                    ? Colors.white
                                    : (isDark
                                        ? AppColors.textLightPrimary
                                        : AppColors.textDarkPrimary),
                              ),
                            ),
                          ),
                          if (isBookmarked)
                            const Positioned(
                              top: 4,
                              right: 4,
                              child: Icon(
                                Icons.bookmark,
                                size: 12,
                                color: AppColors.goldPrimary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (widget.scripture.verses.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: Text(widget.scripture.canonicalTitle)),
        body: const Center(child: Text('No verses available in this scripture.')),
      );
    }

    final verse = widget.scripture.verses[_currentIndex];

    return ListenableBuilder(
      listenable: widget.readerState,
      builder: (context, _) {
        final prefs = widget.readerState.preferences;
        final activeScript = prefs.preferredScript;
        final globalVerseId = verse.globalId(widget.scripture.contentId);
        final isBookmarked = widget.readerState.isBookmarked(globalVerseId);
        final personalNote = widget.readerState.getNote(globalVerseId);
        final totalCount = widget.scripture.verses.length;
        final progressRatio = (verse.verseNumber / totalCount).clamp(0.0, 1.0);

        // Check if verified audio is mapped
        final mappedMantra = verse.audioMantraId != null
            ? AuthenticMantrasData.getMantraById(verse.audioMantraId!)
            : null;

        return Scaffold(
          appBar: SacredAppBar(
            title: widget.scripture.canonicalTitle,
            subtitle: 'Verse ${verse.verseNumber} of $totalCount • ${activeScript.label}',
            showLogo: false,
            actions: [
              // Script Selector
              IconButton(
                icon: const Icon(Icons.translate),
                tooltip: 'Select Script (${activeScript.label})',
                onPressed: () {
                  ScriptSelectorModal.show(
                    context,
                    currentScript: activeScript,
                    onScriptSelected: (s) {
                      widget.readerState.updatePreferences(
                        prefs.copyWith(preferredScript: s),
                      );
                    },
                  );
                },
              ),
              // Reading Preferences Modal
              IconButton(
                icon: const Icon(Icons.format_size),
                tooltip: 'Typography & Layout Preferences',
                onPressed: () => ReadingPreferencesModal.show(
                  context,
                  widget.readerState,
                ),
              ),
              // Switch to Continuous Scroll Reader
              IconButton(
                icon: const Icon(Icons.view_agenda_outlined),
                tooltip: 'Continuous Scroll View',
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => VerseReaderScreen(
                        scripture: widget.scripture,
                        appState: widget.appState,
                        readerState: widget.readerState,
                        audioState: widget.audioState,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Reading Progress Bar
              LinearProgressIndicator(
                value: progressRatio,
                backgroundColor: isDark
                    ? AppColors.nightSurfaceElevated
                    : const Color(0xFFEADBCE),
                valueColor:
                    const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
                minHeight: 4,
              ),

              // 2. Verse Navigation Sub-Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                color: isDark ? AppColors.nightSurface : const Color(0xFFF7F2EA),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: InkWell(
                      onTap: () => _showVerseJumperModal(context),
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.saffronPrimary
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: AppColors.saffronPrimary
                                      .withValues(alpha: 0.4),
                                ),
                              ),
                              child: Text(
                                'VERSE ${verse.verseNumber} / $totalCount',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? AppColors.goldGlow
                                      : AppColors.saffronDark,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_drop_down,
                              size: 18,
                              color: isDark
                                  ? AppColors.goldGlow
                                  : AppColors.saffronDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                    ),
                    Row(
                      children: [
                        // Bookmark Toggle
                        IconButton(
                          icon: Icon(
                            isBookmarked ? Icons.bookmark : Icons.bookmark_border,
                            color: isBookmarked
                                ? AppColors.goldPrimary
                                : (isDark
                                    ? AppColors.textLightSecondary
                                    : AppColors.textDarkSecondary),
                          ),
                          tooltip: isBookmarked
                              ? 'Remove Bookmark'
                              : 'Bookmark this verse',
                          onPressed: () {
                            widget.readerState.toggleBookmark(
                              verse,
                              widget.scripture,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  isBookmarked
                                      ? 'Bookmark removed.'
                                      : 'Verse ${verse.verseNumber} bookmarked.',
                                ),
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          },
                        ),
                        // Note Button
                        IconButton(
                          icon: Icon(
                            personalNote != null
                                ? Icons.edit_note
                                : Icons.note_add_outlined,
                            color: personalNote != null
                                ? AppColors.saffronPrimary
                                : (isDark
                                    ? AppColors.textLightSecondary
                                    : AppColors.textDarkSecondary),
                          ),
                          tooltip: personalNote != null
                              ? 'Edit Study Note'
                              : 'Add Study Note',
                          onPressed: () => VerseNoteDialog.show(
                            context: context,
                            verse: verse,
                            scripture: widget.scripture,
                            readerState: widget.readerState,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // 3. Main Verse Card & Contemplation Body
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      // Section Header / Traditional Usage Tag
                      if (verse.sectionTitle != null ||
                          widget.scripture.traditionalUsage.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Text(
                            verse.sectionTitle ??
                                widget.scripture.traditionalUsage,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              fontStyle: FontStyle.italic,
                              color: isDark
                                  ? AppColors.goldGlow
                                  : AppColors.saffronDark,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),

                      // Sacred Indic Text in chosen script
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.nightSurface
                              : AppColors.ivorySurface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isDark
                                ? AppColors.nightBorder
                                : AppColors.chandanBorder,
                            width: 1.2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: isDark ? 0.25 : 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            SelectableText(
                              verse.getTextInScript(activeScript),
                              style: TextStyle(
                                fontSize: prefs.sanskritFontSize,
                                height: prefs.lineSpacing,
                                fontWeight: FontWeight.w600,
                                fontFamilyFallback: AppTextStyles.indicFontFamilyFallback,
                                color: isDark
                                    ? AppColors.textLightPrimary
                                    : AppColors.textDarkPrimary,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (verse.meter.isNotEmpty) ...[
                              const SizedBox(height: 12),
                              Text(
                                'Meter: ${verse.meter}',
                                style: AppTextStyles.caption(isDark),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Expandable / Configurable Transliteration
                      if (prefs.showTransliteration &&
                          activeScript != ScriptOption.iast &&
                          verse.iastText.isNotEmpty) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.nightSurfaceElevated
                                : const Color(0xFFF9F6F0),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? AppColors.nightBorder
                                  : AppColors.chandanBorder,
                              width: 0.8,
                            ),
                          ),
                          child: Column(
                            children: [
                              Text(
                                'IAST TRANSLITERATION',
                                style: AppTextStyles.caption(isDark).copyWith(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 10.5,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                verse.iastText,
                                style: TextStyle(
                                  fontSize: prefs.transliterationFontSize,
                                  height: prefs.lineSpacing,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? const Color(0xFFE2E8F0)
                                      : const Color(0xFF334155),
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Optional Verified Audio Player Bar
                      if (verse.hasVerifiedAudio && mappedMantra != null) ...[
                        const SizedBox(height: 16),
                        _VerseAudioPlayerCard(
                          mantra: mappedMantra,
                          audioState: widget.audioState,
                          isDark: isDark,
                        ),
                      ] else ...[
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.volume_off_outlined,
                              size: 14,
                              color: isDark
                                  ? AppColors.textLightMuted
                                  : AppColors.textDarkMuted,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'Audio recording not yet mapped for this verse',
                                style: AppTextStyles.caption(isDark).copyWith(
                                  fontSize: 11,
                                  fontStyle: FontStyle.italic,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],

                      // Translation & Bhavartha Section (Strict Section 8 Draft Safeguard)
                      if (prefs.showTranslation) ...[
                        const SizedBox(height: 18),
                        if (verse.hasDraftTranslation) ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? const Color(0xFF26190C)
                                  : AppColors.draftWarningLight,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF8C5311)
                                    : AppColors.draftWarningBorder,
                                width: 1.2,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Icon(
                                      Icons.rate_review_outlined,
                                      size: 15,
                                      color: isDark
                                          ? const Color(0xFFFCD34D)
                                          : AppColors.draftWarning,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'BHAVARTHA (STUDY TRANSLATION)',
                                        style: TextStyle(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.bold,
                                          letterSpacing: 0.6,
                                          color: isDark
                                              ? const Color(0xFFFCD34D)
                                              : const Color(0xFF92400E),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                SelectableText(
                                  verse.draftTranslation!,
                                  style: TextStyle(
                                    fontSize: prefs.translationFontSize,
                                    height: prefs.lineSpacing,
                                    color: isDark
                                        ? const Color(0xFFFEF3C7)
                                        : const Color(0xFF451A03),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    'Status: Section 8 Draft • Under scholarly peer review • For devotional study only',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontStyle: FontStyle.italic,
                                      color: isDark
                                          ? const Color(0xFFD97706)
                                          : const Color(0xFFB45309),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else ...[
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark
                                  ? AppColors.nightSurfaceElevated
                                  : const Color(0xFFF3EFE8),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: isDark
                                    ? AppColors.nightBorder
                                    : AppColors.chandanBorder,
                                width: 0.8,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.hourglass_top_outlined,
                                  size: 18,
                                  color: isDark
                                      ? AppColors.goldGlow
                                      : AppColors.saffronDark,
                                ),
                                const SizedBox(width: 10),
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

                      // Word-by-Word Meaning (Padartha)
                      if (verse.hasWordByWord) ...[
                        const SizedBox(height: 14),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF7F3EE),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'WORD-BY-WORD MEANING (PADARTHA)',
                                style: AppTextStyles.metadataTag(isDark).copyWith(fontSize: 10.5, fontWeight: FontWeight.bold),
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 8,
                                runSpacing: 6,
                                children: verse.wordByWord!.entries.map((e) {
                                  return Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: isDark ? AppColors.nightSurface : Colors.white,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: AppColors.goldPrimary.withAlpha(80), width: 0.6),
                                    ),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          TextSpan(
                                            text: '${e.key} ',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                                            ),
                                          ),
                                          TextSpan(
                                            text: '= ${e.value}',
                                            style: TextStyle(
                                              color: isDark ? AppColors.textLightSecondary : AppColors.textDarkSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // Traditional Commentary & Tatparya
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.menu_book, size: 14, color: AppColors.goldPrimary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    'TRADITIONAL COMMENTARY & TATPARYA',
                                    style: AppTextStyles.metadataTag(isDark).copyWith(fontSize: 10.5, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            if (verse.hasCommentary) ...[
                              SelectableText(
                                verse.commentary!,
                                style: TextStyle(
                                  fontSize: prefs.translationFontSize - 1,
                                  height: 1.4,
                                  fontStyle: FontStyle.italic,
                                  color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                                ),
                              ),
                              if (verse.sourceReference != null) ...[
                                const SizedBox(height: 6),
                                Text(
                                  'Source: ${verse.sourceReference!}',
                                  style: AppTextStyles.caption(isDark).copyWith(fontSize: 10.5),
                                ),
                              ],
                            ] else ...[
                              Text(
                                'Traditional Commentary: Awaiting authorized scholarly compilation from verified Bhashya sources.',
                                style: AppTextStyles.caption(isDark).copyWith(fontStyle: FontStyle.italic, fontSize: 11),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Canonical Reference & Provenance Banner
                      const SizedBox(height: 14),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurface : const Color(0xFFF5F0E8),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCRIPTURE & PROVENANCE',
                              style: AppTextStyles.metadataTag(isDark).copyWith(fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${widget.scripture.canonicalTitle} (${widget.scripture.devanagariTitle}) • ${widget.scripture.sourceScripture}',
                              style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
                            ),
                            Text(
                              'Composer: ${widget.scripture.composer} • Rishi: ${widget.scripture.rishi}',
                              style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ),

                      // Personal Study Note Preview
                      if (personalNote != null &&
                          personalNote.noteText.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.nightSurfaceElevated
                                : const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? Colors.blue.shade900
                                  : Colors.blue.shade200,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Row(
                                      children: [
                                        Icon(
                                          Icons.note,
                                          size: 14,
                                          color: isDark
                                              ? Colors.blue.shade300
                                              : Colors.blue.shade700,
                                        ),
                                        const SizedBox(width: 6),
                                        Flexible(
                                          child: Text(
                                            'PERSONAL DEVOTEE REFLECTION',
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.bold,
                                              color: isDark
                                                  ? Colors.blue.shade300
                                                  : Colors.blue.shade800,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  InkWell(
                                    onTap: () => VerseNoteDialog.show(
                                      context: context,
                                      verse: verse,
                                      scripture: widget.scripture,
                                      readerState: widget.readerState,
                                    ),
                                    child: Text(
                                      'Edit',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isDark
                                            ? Colors.blue.shade300
                                            : Colors.blue.shade700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              SelectableText(
                                personalNote.noteText,
                                style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? AppColors.textLightPrimary
                                      : AppColors.textDarkPrimary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // 4. Bottom Accessible Verse Navigation Targets
              Container(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                decoration: BoxDecoration(
                  color: isDark
                      ? AppColors.nightSurface
                      : AppColors.ivorySurface,
                  border: Border(
                    top: BorderSide(
                      color: isDark
                          ? AppColors.nightBorder
                          : AppColors.chandanBorder,
                      width: 1,
                    ),
                  ),
                ),
                child: Row(
                  children: [
                    // PREVIOUS VERSE BUTTON
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: const Icon(Icons.arrow_back),
                        label: const Text('PREVIOUS'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: _currentIndex > 0
                                ? AppColors.saffronPrimary
                                : (isDark
                                    ? AppColors.nightBorder
                                    : AppColors.chandanBorder),
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _currentIndex > 0 ? _goToPrevious : null,
                      ),
                    ),
                    const SizedBox(width: 14),
                    // NEXT VERSE BUTTON
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.arrow_forward),
                        label: Text(
                          _currentIndex < totalCount - 1
                              ? 'NEXT VERSE'
                              : 'COMPLETED',
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        onPressed: _currentIndex < totalCount - 1
                            ? _goToNext
                            : () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Completed reading ${widget.scripture.canonicalTitle}!',
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _VerseAudioPlayerCard extends StatelessWidget {
  final dynamic mantra;
  final AudioState? audioState;
  final bool isDark;

  const _VerseAudioPlayerCard({
    required this.mantra,
    required this.audioState,
    required this.isDark,
  });

  void _playOrShowVaultFallback(BuildContext context) async {
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
    if (audioState == null) return const SizedBox.shrink();

    return ListenableBuilder(
      listenable: audioState!,
      builder: (context, _) {
        final isPlayingCurrent = audioState!.isPlaying &&
            audioState!.activeMantra?.id == mantra.id;

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.nightSurfaceElevated
                : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? AppColors.goldDark
                  : AppColors.saffronPrimary.withValues(alpha: 0.5),
            ),
          ),
          child: Row(
            children: [
              IconButton(
                icon: Icon(
                  isPlayingCurrent
                      ? Icons.pause_circle_filled
                      : Icons.play_circle_fill,
                  size: 32,
                  color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                ),
                tooltip: isPlayingCurrent ? 'Pause Audio' : 'Play Verified Audio',
                onPressed: () => _playOrShowVaultFallback(context),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Verified Audio Recording',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.goldGlow
                            : AppColors.saffronDark,
                      ),
                    ),
                    Text(
                      '${mantra.title} • 48 kHz Master',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
