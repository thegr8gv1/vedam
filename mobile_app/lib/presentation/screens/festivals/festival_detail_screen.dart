import 'package:flutter/material.dart';
import '../../../core/models/festival_event.dart';
import '../../../core/models/vrat_observance.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/vrat_state.dart';
import '../mantras/mantra_player_screen.dart';
import '../sadhana/guided_puja_screen.dart';
import '../vrat/vrat_detail_screen.dart';

/// Comprehensive, source-grounded event detail screen for Hindu festivals and observances.
///
/// Features:
/// - Prominently displays festival name, Sanskrit title, deity, and category.
/// - Location-aware calculation context and prevailing Tithi/Nakshatra.
/// - Specific sacred muhurta / ruling time window (e.g., Nishita, Madhyahna, Pradosha).
/// - Source-backed spiritual significance and primary scriptural references.
/// - Clear notes on regional and sampradaya variations without imposing universal dogma.
/// - Direct one-click integration to start genuine related guided puja or audio japa.
/// - Seamless addition to personal Vrat tracking with strict duplicate prevention.
class FestivalDetailScreen extends StatefulWidget {
  final FestivalEvent event;
  final VratState vratState;
  final PanchangamState? panchangamState;
  final SadhanaState? sadhanaState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;

  const FestivalDetailScreen({
    super.key,
    required this.event,
    required this.vratState,
    this.panchangamState,
    this.sadhanaState,
    this.mantraRepository,
    this.audioState,
  });

  @override
  State<FestivalDetailScreen> createState() => _FestivalDetailScreenState();
}

class _FestivalDetailScreenState extends State<FestivalDetailScreen> {
  @override
  void initState() {
    super.initState();
    widget.vratState.addListener(_onVratStateChanged);
  }

  @override
  void dispose() {
    widget.vratState.removeListener(_onVratStateChanged);
    super.dispose();
  }

  void _onVratStateChanged() {
    if (mounted) setState(() {});
  }

  VratObservance? _findExistingVrat() {
    final targetId = 'vrat_${widget.event.id}';
    for (final obs in widget.vratState.observances) {
      if (obs.id == targetId ||
          (obs.title == widget.event.name && obs.targetDate == widget.event.targetDate)) {
        return obs;
      }
    }
    return null;
  }

  Future<void> _addToPersonalVrat() async {
    final existing = _findExistingVrat();
    if (existing != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${widget.event.name} is already in your personal Vrat practice.'),
          duration: const Duration(seconds: 2),
        ),
      );
      return;
    }

    final locationName = widget.panchangamState?.selectedLocation.name ??
        'Varanasi, India (25.3176°N, 82.9739°E)';

    final newObservance = VratObservance(
      id: 'vrat_${widget.event.id}',
      type: widget.event.suggestedVratType ?? VratType.custom,
      title: widget.event.name,
      sanskritTitle: widget.event.sanskritName,
      targetDate: widget.event.targetDate,
      location: locationName,
      tradition: widget.event.regionalVariations.isNotEmpty
          ? 'Traditional Hindu'
          : 'Universal',
      status: ObservanceStatus.planned,
      personalIntention:
          'Dedicated personal observance of ${widget.event.name} for spiritual clarity, purification, and divine contemplation.',
      associatedPujaGuideId: widget.event.associatedPujaGuideId,
      associatedMantraId: widget.event.associatedMantraId,
      checklist: widget.event.suggestedChecklist,
      panchangamSnapshot: VratPanchangamSnapshot(
        tithiName: widget.event.tithi,
        paksha: widget.event.paksha,
        nakshatraName: widget.event.nakshatra,
        calendarConvention: widget.event.calculationConvention,
        calculationSource: widget.event.sourceName,
      ),
      createdAt: DateTime.now().toIso8601String(),
    );

    await widget.vratState.addObservance(newObservance);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Added "${widget.event.name}" to your Personal Vrat calendar!'),
          backgroundColor: AppColors.saffronPrimary,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  void _openExistingVrat(VratObservance existing) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => VratDetailScreen(
          observanceId: existing.id,
          vratState: widget.vratState,
          sadhanaState: widget.sadhanaState,
          mantraRepository: widget.mantraRepository,
          audioState: widget.audioState,
          panchangamState: widget.panchangamState,
        ),
      ),
    );
  }

  void _openPujaGuide(String guideId) {
    final guide = AuthenticPujaGuidesData.getGuideById(guideId);
    if (guide == null || widget.sadhanaState == null) return;

    widget.sadhanaState!.startGuide(guide);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GuidedPujaScreen(
          guide: guide,
          sadhanaState: widget.sadhanaState!,
          mantraRepository: widget.mantraRepository,
          audioState: widget.audioState,
        ),
      ),
    );
  }

  void _openMantraPlayer(String mantraId) {
    if (widget.mantraRepository == null || widget.audioState == null) return;
    final mantra = widget.mantraRepository!.getMantraById(mantraId);
    if (mantra == null) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => MantraPlayerScreen(
          mantra: mantra,
          audioState: widget.audioState!,
          playlist: widget.mantraRepository!.getAllMantras(),
        ),
      ),
    );
  }

  Color _getCategoryColor(FestivalCategory cat) {
    switch (cat) {
      case FestivalCategory.majorFestival:
        return AppColors.saffronPrimary;
      case FestivalCategory.ekadashi:
        return Colors.indigo;
      case FestivalCategory.pradosham:
        return Colors.deepPurple;
      case FestivalCategory.purnima:
        return Colors.amber.shade700;
      case FestivalCategory.amavasya:
        return Colors.blueGrey;
      case FestivalCategory.sankashtiChaturthi:
        return Colors.deepOrange;
      case FestivalCategory.regionalObservance:
        return Colors.teal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final catColor = _getCategoryColor(widget.event.category);
    final existingVrat = _findExistingVrat();
    final locationName = widget.panchangamState?.selectedLocation.name ??
        'Varanasi (Kashi), India';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.event.name),
        actions: [
          IconButton(
            icon: Icon(
              existingVrat != null ? Icons.bookmark : Icons.bookmark_border,
              color: existingVrat != null ? AppColors.goldGlow : null,
            ),
            tooltip: existingVrat != null ? 'In My Vrat' : 'Add to My Vrat',
            onPressed: existingVrat != null
                ? () => _openExistingVrat(existingVrat)
                : _addToPersonalVrat,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Header Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurface : const Color(0xFFFBF8F2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category & Deity Badges
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: catColor.withAlpha(30),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: catColor.withAlpha(120), width: 0.8),
                          ),
                          child: Text(
                            widget.event.category.displayName.toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: catColor,
                              letterSpacing: 0.6,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: (isDark ? Colors.white : Colors.black).withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.temple_hindu, size: 12, color: AppColors.saffronPrimary),
                              const SizedBox(width: 4),
                              Text(
                                widget.event.deity,
                                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Sanskrit Title
                    if (widget.event.sanskritName.isNotEmpty)
                      Text(
                        widget.event.sanskritName,
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        ),
                      ),
                    const SizedBox(height: 4),

                    // Main Name
                    Text(
                      widget.event.name,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 10),

                    // Target Date & Location Context
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 14, color: AppColors.saffronPrimary),
                        const SizedBox(width: 6),
                        Text(
                          widget.event.targetDate,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 14),
                        const Icon(Icons.location_on_outlined, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            locationName,
                            style: const TextStyle(fontSize: 12, color: Colors.grey),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Sacred Timing & Coordinates Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.access_time_outlined, size: 16, color: AppColors.saffronPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'PANCHANGAM COORDINATES & TIMING',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Hindu Lunar Month', widget.event.masa),
                      _buildInfoRow('Paksha & Tithi', '${widget.event.paksha} • ${widget.event.tithi}'),
                      if (widget.event.nakshatra != null)
                        _buildInfoRow('Ruling Nakshatra', widget.event.nakshatra!),
                      _buildInfoRow('Observance Rule', widget.event.timingRule),
                      _buildInfoRow('Muhurta Window', widget.event.timingWindow),
                      _buildInfoRow('Ephemeris Basis', widget.event.calculationConvention),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Spiritual Significance Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.menu_book_outlined, size: 16, color: AppColors.saffronPrimary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'SPIRITUAL SIGNIFICANCE & CONTEMPLATION',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.event.significance,
                        style: const TextStyle(fontSize: 14, height: 1.5),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 4. Source Provenance & Regional Variations Card
              Card(
                elevation: 1,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 16, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'AUTHENTIC SOURCING & REGIONAL VARIATIONS',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      _buildInfoRow('Primary Sastra', widget.event.sourceName),
                      _buildInfoRow('Specific Reference', widget.event.sourceReference),
                      const SizedBox(height: 8),
                      Text(
                        'Regional & Sampradaya Notes:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        widget.event.regionalVariations,
                        style: AppTextStyles.caption(isDark).copyWith(height: 1.4),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.nightSurface : const Color(0xFFF9F5EF),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          'Devotee Guidance: Astronomical algorithms compute civil occurrences based on ephemeris models. Specific temple sampradayas (Smartha, Sri Vaishnava, Gaudiya, Shaiva Siddhanta) may observe variations based on ancient parampara rules.',
                          style: TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 5. Genuine Related Practices Card (Puja & Mantra)
              if (widget.event.associatedPujaGuideId != null ||
                  widget.event.associatedMantraId != null) ...[
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.self_improvement, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'AUTHENTIC DEVOTIONAL PRACTICES',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ],
                        ),
                        const Divider(height: 20),

                        // Related Puja Guide
                        if (widget.event.associatedPujaGuideId != null) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: AppColors.saffronPrimary.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.local_fire_department, color: AppColors.saffronPrimary),
                            ),
                            title: const Text(
                              'Recommended Guided Puja',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Authentic domestic Pancha Upachara paddhati for ${widget.event.deity}',
                              style: AppTextStyles.caption(isDark),
                            ),
                            trailing: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.saffronPrimary,
                                foregroundColor: Colors.white,
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _openPujaGuide(widget.event.associatedPujaGuideId!),
                              child: const Text('Start Puja', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Related Mantra
                        if (widget.event.associatedMantraId != null) ...[
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.indigo.withAlpha(25),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: const Icon(Icons.music_note, color: Colors.indigo),
                            ),
                            title: const Text(
                              'Devotional Audio & Japa',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            subtitle: Text(
                              'Sacred repetition chanting consecrated to ${widget.event.deity}',
                              style: AppTextStyles.caption(isDark),
                            ),
                            trailing: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                              ),
                              onPressed: () => _openMantraPlayer(widget.event.associatedMantraId!),
                              child: const Text('Listen', style: TextStyle(fontSize: 12)),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // 6. Personal Vrat Integration Action Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: existingVrat != null
                      ? Colors.green.withAlpha(isDark ? 30 : 15)
                      : (isDark ? AppColors.nightSurface : const Color(0xFFFBF8F2)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: existingVrat != null
                        ? Colors.green.withAlpha(120)
                        : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                    width: existingVrat != null ? 1.4 : 1.0,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          existingVrat != null ? Icons.check_circle : Icons.bookmark_add_outlined,
                          size: 18,
                          color: existingVrat != null ? Colors.green : AppColors.saffronPrimary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          existingVrat != null
                              ? 'INCLUDED IN PERSONAL VRAT PRACTICE'
                              : 'PERSONAL VRAT TRACKING',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: existingVrat != null ? Colors.green : AppColors.saffronPrimary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      existingVrat != null
                          ? 'This holy day is part of your active personal spiritual calendar. Status: ${existingVrat.status.name.toUpperCase()}'
                          : 'Plan this festival as a personal devotional Vrat with structured preparation checklists and contemplative reminders.',
                      style: AppTextStyles.caption(isDark),
                    ),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: existingVrat != null
                          ? OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                side: const BorderSide(color: Colors.green),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.arrow_forward, color: Colors.green),
                              label: const Text('Open Personal Vrat Details', style: TextStyle(color: Colors.green)),
                              onPressed: () => _openExistingVrat(existingVrat),
                            )
                          : ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                                backgroundColor: AppColors.saffronPrimary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                              ),
                              icon: const Icon(Icons.add_task),
                              label: const Text(
                                'Plan Personal Vrat Practice',
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                              onPressed: _addToPersonalVrat,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              label,
              style: AppTextStyles.caption(isDark).copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
