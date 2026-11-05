import 'package:flutter/material.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/daily_darshan.dart';
import '../../../core/services/audio_service.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../data/repositories/scripture_repository.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/scripture_reader_state.dart';
import '../../../state/vrat_state.dart';
import '../../widgets/empty_state_view.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/section_header.dart';
import '../festivals/festival_calendar_screen.dart';
import '../library/scripture_detail_screen.dart';
import 'widgets/daily_routine_card.dart';
import 'widgets/daily_verse_card.dart';
import 'widgets/dashboard_japa_card.dart';
import 'widgets/devotional_welcome_header.dart';
import 'widgets/panchangam_preview_card.dart';
import 'widgets/saved_devotional_card.dart';
import 'widgets/scripture_progress_card.dart';
import 'widgets/upcoming_vrat_card.dart';

/// Unified Devotee Home Dashboard for the Vedam application.
///
/// Brings together:
/// 1. Devotional greeting and today's local date.
/// 2. Daily Devotional Verse (Darshan).
/// 3. Today's Panchangam (Pancha Angas, Sun events, Rahu Kalam, location).
/// 4. Daily Spiritual Routine (Sadhana checklist, progress, guided puja shortcut).
/// 5. Daily Japa Practice (Mantra, target, progress, tap-to-count bead, player link).
/// 6. Upcoming Vrat & Observances (Next fasting day, checklist, calendar link).
/// 7. Scripture Learning Progress (Recently read scripture, continue reading, bookmarks).
/// 8. Saved Devotional Content (Saved scriptures, bookmarks, study notes, favorite mantras).
/// 9. Section 8 Editorial Governance Assurance.
class HomeScreen extends StatefulWidget {
  final ScriptureRepository repository;
  final AppState appState;
  final Function(int tabIndex) onNavigateToTab;
  final VoidCallback? onOpenMantras;
  final VoidCallback? onOpenPanchangam;
  final PanchangamState? panchangamState;
  final SadhanaState? sadhanaState;
  final AudioState? audioState;
  final VratState? vratState;
  final ScriptureReaderState? readerState;
  final MantraRepository? mantraRepository;

  const HomeScreen({
    super.key,
    required this.repository,
    required this.appState,
    required this.onNavigateToTab,
    this.onOpenMantras,
    this.onOpenPanchangam,
    this.panchangamState,
    this.sadhanaState,
    this.audioState,
    this.vratState,
    this.readerState,
    this.mantraRepository,
  });

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with WidgetsBindingObserver {
  late DateTime _currentDate;
  late final SadhanaState _localSadhana;
  late final AudioState _localAudio;
  late final VratState _localVrat;
  late final ScriptureReaderState _localReader;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _currentDate = DateTime.now();

    // Safe fallbacks if not supplied (e.g. in targeted tests)
    _localSadhana = widget.sadhanaState ?? SadhanaState();
    _localAudio = widget.audioState ?? AudioState(audioService: AudioPlaybackServiceImpl());
    _localVrat = widget.vratState ?? VratState();
    _localReader = widget.readerState ?? ScriptureReaderState();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshDateSensitiveData();
    }
  }

  void _refreshDateSensitiveData() {
    final now = DateTime.now();
    if (now.day != _currentDate.day ||
        now.month != _currentDate.month ||
        now.year != _currentDate.year) {
      setState(() {
        _currentDate = now;
      });
      widget.panchangamState?.loadPanchangam();
    }
  }

  void _openFestivalCalendar(
    BuildContext context,
    VratState vrat,
    SadhanaState sadhana,
    AudioState audio,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FestivalCalendarScreen(
          vratState: vrat,
          panchangamState: widget.panchangamState,
          sadhanaState: sadhana,
          mantraRepository: widget.mantraRepository,
          audioState: audio,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final darshan = DailyDarshan.today();

    final sadhana = widget.sadhanaState ?? _localSadhana;
    final audio = widget.audioState ?? _localAudio;
    final vrat = widget.vratState ?? _localVrat;
    final reader = widget.readerState ?? _localReader;

    final listenables = <Listenable>[
      widget.appState,
      sadhana,
      audio,
      vrat,
      reader,
      if (widget.panchangamState != null) widget.panchangamState!,
    ];

    return Scaffold(
      appBar: SacredAppBar(
        actions: [
          IconButton(
            icon: const Icon(Icons.event_available_outlined),
            onPressed: () => _openFestivalCalendar(context, vrat, sadhana, audio),
            tooltip: 'Festival Calendar',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => widget.onNavigateToTab(1), // Go to library
            tooltip: 'Search Scriptures',
          ),
          IconButton(
            icon: Icon(
              widget.appState.themePreference.mode == ThemeMode.dark
                  ? Icons.light_mode_outlined
                  : Icons.dark_mode_outlined,
            ),
            onPressed: () {
              final next = widget.appState.themePreference.mode == ThemeMode.dark
                  ? ThemePreference.light
                  : ThemePreference.dark;
              widget.appState.setThemePreference(next);
            },
            tooltip: 'Toggle Theme',
          ),
        ],
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge(listenables),
        builder: (context, _) {
          return LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;

              return SingleChildScrollView(
                padding: const EdgeInsets.only(left: 16, right: 16, top: 12, bottom: 40),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1100),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // 1. Welcome & Date Header
                        DevotionalWelcomeHeader(
                          currentDate: _currentDate,
                          panchangamState: widget.panchangamState,
                        ),
                        const SizedBox(height: 14),

                        // 2. Responsive Dashboard Body
                        if (!isWide)
                          _buildSingleColumnLayout(context, isDark, darshan, sadhana, audio, vrat, reader)
                        else
                          _buildDualColumnLayout(context, isDark, darshan, sadhana, audio, vrat, reader),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // --- Mobile Single-Column Layout ---
  Widget _buildSingleColumnLayout(
    BuildContext context,
    bool isDark,
    DailyDarshan darshan,
    SadhanaState sadhana,
    AudioState audio,
    VratState vrat,
    ScriptureReaderState reader,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Daily Devotional Verse (Darshan)
        DailyVerseCard(
          darshan: darshan,
          onReadFull: () async {
            final mrityunjaya = await widget.repository.getScriptureById(5);
            if (mrityunjaya != null && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ScriptureDetailScreen(
                    scripture: mrityunjaya,
                    appState: widget.appState,
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 12),

        // Today's Panchangam Summary Card
        PanchangamPreviewCard(
          darshan: darshan,
          panchangamState: widget.panchangamState,
          onTap: widget.onOpenPanchangam,
        ),
        const SizedBox(height: 12),

        // Daily Spiritual Routine Card
        DailyRoutineCard(
          sadhanaState: sadhana,
          appState: widget.appState,
          onOpenSadhana: () => widget.onNavigateToTab(2),
        ),
        const SizedBox(height: 12),

        // Daily Japa & Mantra Practice Card
        DashboardJapaCard(
          audioState: audio,
          mantraRepository: widget.mantraRepository,
          onOpenMantras: widget.onOpenMantras,
        ),
        const SizedBox(height: 12),

        // Upcoming Vrat & Observances Card
        UpcomingVratCard(
          vratState: vrat,
          panchangamState: widget.panchangamState,
          sadhanaState: sadhana,
          mantraRepository: widget.mantraRepository,
          audioState: audio,
        ),
        const SizedBox(height: 12),

        // Scripture Learning Progress Card
        ScriptureProgressCard(
          repository: widget.repository,
          appState: widget.appState,
          readerState: reader,
          audioState: audio,
          onOpenLibrary: () => widget.onNavigateToTab(1),
        ),
        const SizedBox(height: 12),

        // Saved Devotional Content Card
        SavedDevotionalCard(
          repository: widget.repository,
          appState: widget.appState,
          readerState: reader,
          audioState: audio,
          onNavigateToTab: widget.onNavigateToTab,
          onOpenMantras: widget.onOpenMantras,
        ),
        const SizedBox(height: 16),

        // Sacred Portals Quick Access
        _buildPortalsGrid(context, isDark),
        const SizedBox(height: 16),

        // Section 8 Editorial Governance Assurance Banner
        const Section8GovernanceBanner(),
      ],
    );
  }

  // --- Wide / Web Dual-Column Layout ---
  Widget _buildDualColumnLayout(
    BuildContext context,
    bool isDark,
    DailyDarshan darshan,
    SadhanaState sadhana,
    AudioState audio,
    VratState vrat,
    ScriptureReaderState reader,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Left Column: Panchangam, Routine, Saved Content
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DailyVerseCard(
                    darshan: darshan,
                    onReadFull: () async {
                      final mrityunjaya = await widget.repository.getScriptureById(5);
                      if (mrityunjaya != null && context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ScriptureDetailScreen(
                              scripture: mrityunjaya,
                              appState: widget.appState,
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  PanchangamPreviewCard(
                    darshan: darshan,
                    panchangamState: widget.panchangamState,
                    onTap: widget.onOpenPanchangam,
                  ),
                  const SizedBox(height: 14),
                  DailyRoutineCard(
                    sadhanaState: sadhana,
                    appState: widget.appState,
                    onOpenSadhana: () => widget.onNavigateToTab(2),
                  ),
                  const SizedBox(height: 14),
                  SavedDevotionalCard(
                    repository: widget.repository,
                    appState: widget.appState,
                    readerState: reader,
                    audioState: audio,
                    onNavigateToTab: widget.onNavigateToTab,
                    onOpenMantras: widget.onOpenMantras,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),

            // Right Column: Japa Practice, Vrat, Scripture Progress
            Expanded(
              flex: 5,
              child: Column(
                children: [
                  DashboardJapaCard(
                    audioState: audio,
                    mantraRepository: widget.mantraRepository,
                    onOpenMantras: widget.onOpenMantras,
                  ),
                  const SizedBox(height: 14),
                  UpcomingVratCard(
                    vratState: vrat,
                    panchangamState: widget.panchangamState,
                    sadhanaState: sadhana,
                    mantraRepository: widget.mantraRepository,
                    audioState: audio,
                  ),
                  const SizedBox(height: 14),
                  ScriptureProgressCard(
                    repository: widget.repository,
                    appState: widget.appState,
                    readerState: reader,
                    audioState: audio,
                    onOpenLibrary: () => widget.onNavigateToTab(1),
                  ),
                  const SizedBox(height: 14),
                  _buildPortalsGrid(context, isDark),
                  const SizedBox(height: 14),
                  const Section8GovernanceBanner(),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPortalsGrid(BuildContext context, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          title: 'Sacred Portals',
          subtitle: 'Direct pathways to scripture, japa, and daily worship',
        ),
        Row(
          children: [
            Expanded(
              child: _PortalCard(
                title: 'Scripture Library',
                subtitle: 'Vedas, Suktams, Stotras',
                icon: Icons.menu_book,
                accentColor: AppColors.saffronPrimary,
                onTap: () => widget.onNavigateToTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PortalCard(
                title: 'Daily Sadhana',
                subtitle: 'Puja, Japa & Sankalpam',
                icon: Icons.self_improvement,
                accentColor: AppColors.goldPrimary,
                onTap: () => widget.onNavigateToTab(2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _PortalCard(
                title: 'Mantras & Chanting',
                subtitle: '455 Master Recordings',
                icon: Icons.graphic_eq,
                accentColor: const Color(0xFF0D9488),
                onTap: widget.onOpenMantras ?? () => widget.onNavigateToTab(1),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PortalCard(
                title: 'My Devotional Shelf',
                subtitle: '${widget.appState.favoriteScriptureIds.length} Saved Scriptures',
                icon: Icons.favorite_border,
                accentColor: AppColors.kumkumRed,
                onTap: () => widget.onNavigateToTab(3),
              ),
            ),
          ],
        ),
      ],
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
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(isDark ? 30 : 10),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: accentColor.withAlpha(25),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: accentColor),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: AppTextStyles.caption(isDark).copyWith(fontSize: 10),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
