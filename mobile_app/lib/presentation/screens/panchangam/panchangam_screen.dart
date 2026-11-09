import 'package:flutter/material.dart';
import '../../../core/models/panchangam_data.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/panchangam_repository.dart';
import '../../../state/panchangam_state.dart';
import 'widgets/location_selector_modal.dart';
import '../../../core/models/festival_event.dart';
import '../../../core/models/vrat_observance.dart';
import '../../../data/fixtures/authentic_festival_catalog_data.dart';
import '../../../data/repositories/mantra_repository.dart';
import '../../../state/audio_state.dart';
import '../../../state/sadhana_state.dart';
import '../../../state/vrat_state.dart';
import '../festivals/festival_detail_screen.dart';

class PanchangamScreen extends StatefulWidget {
  final PanchangamState state;
  final PanchangamRepository repository;
  final VratState? vratState;
  final SadhanaState? sadhanaState;
  final MantraRepository? mantraRepository;
  final AudioState? audioState;

  const PanchangamScreen({
    super.key,
    required this.state,
    required this.repository,
    this.vratState,
    this.sadhanaState,
    this.mantraRepository,
    this.audioState,
  });

  @override
  State<PanchangamScreen> createState() => _PanchangamScreenState();
}

class _PanchangamScreenState extends State<PanchangamScreen> {
  @override
  void initState() {
    super.initState();
    widget.state.addListener(_onStateChange);
    if (widget.state.data == null && !widget.state.isLoading) {
      widget.state.loadPanchangam();
    }
  }

  @override
  void dispose() {
    widget.state.removeListener(_onStateChange);
    super.dispose();
  }

  void _onStateChange() {
    if (mounted) setState(() {});
  }

  void _openObservanceDetails(BuildContext context, Observance obs) {
    final query = obs.name.toLowerCase();
    final match = AuthenticFestivalCatalogData.allEvents.cast<FestivalEvent?>().firstWhere(
      (e) {
        if (e == null) return false;
        final name = e.name.toLowerCase();
        final skt = e.sanskritName.toLowerCase();
        return name.contains(query) ||
            query.contains(name) ||
            skt.contains(obs.sanskritName.toLowerCase());
      },
      orElse: () => null,
    );

    final eventToOpen = match ??
        FestivalEvent(
          id: 'panchangam_${obs.name.replaceAll(' ', '_').toLowerCase()}',
          name: obs.name,
          sanskritName: obs.sanskritName,
          category: FestivalCategory.regionalObservance,
          targetDate: widget.state.selectedDate.toIso8601String().split('T').first,
          deity: 'Presiding Deity of the Day',
          masa: 'Kartika (Purnimanta) / Ashvina (Amanta)',
          paksha: widget.state.data?.paksha ?? 'Shukla Paksha',
          tithi: widget.state.data?.tithi.name ?? 'Dashami',
          nakshatra: widget.state.data?.nakshatra.name ?? 'Ashwini',
          timingRule: 'Observed during prevailing astrological tithi',
          timingWindow: 'Full day devotional observance',
          significance: obs.description,
          calculationConvention: 'Drik Ganita / Lahiri Ayanamsa',
          sourceName: 'Panchangam Liturgical Tradition',
          sourceReference: obs.disclaimer ?? 'Traditional Hindu Almanac Ephemeris',
          regionalVariations: 'Observed according to local Panchangam ephemeris calculations and sampradaya customs.',
          suggestedVratType: VratType.custom,
        );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FestivalDetailScreen(
          event: eventToOpen,
          vratState: widget.vratState ?? VratState(),
          panchangamState: widget.state,
          sadhanaState: widget.sadhanaState,
          mantraRepository: widget.mantraRepository,
          audioState: widget.audioState,
        ),
      ),
    );
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.state.selectedDate,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      builder: (context, child) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: isDark
                ? const ColorScheme.dark(
                    primary: AppColors.goldPrimary,
                    onPrimary: Colors.black,
                    surface: AppColors.nightSurface,
                  )
                : const ColorScheme.light(
                    primary: AppColors.saffronDark,
                    onPrimary: Colors.white,
                    surface: AppColors.ivorySurface,
                  ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      widget.state.goToDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final state = widget.state;
    final data = state.data;

    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            Text(
              'Panchangam (पञ्चाङ्गम्)',
              style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 18),
            ),
            Text(
              'ASTRONOMICAL VEDIC CALENDAR',
              style: AppTextStyles.metadataTag(isDark).copyWith(
                fontSize: 10,
                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
              ),
            ),
          ],
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh Astronomical Ephemeris',
            onPressed: state.isLoading ? null : state.refresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // 1. Date Navigation Bar
          _buildDateNavigationBar(isDark),

          // 2. Location & Timezone Bar
          _buildLocationBar(isDark),

          // 3. Main Content
          Expanded(
            child: state.isLoading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(color: AppColors.goldPrimary),
                        SizedBox(height: 16),
                        Text(
                          'Calculating Astronomical Ephemerides...',
                          style: TextStyle(fontSize: 14, fontStyle: FontStyle.italic),
                        ),
                      ],
                    ),
                  )
                : state.isUnavailable || data == null
                    ? _buildUnavailableView(isDark)
                    : _buildPanchangamContentView(isDark, data),
          ),
        ],
      ),
    );
  }

  Widget _buildDateNavigationBar(bool isDark) {
    final date = widget.state.selectedDate;
    final formattedDate = '${_weekdayName(date.weekday)}, ${date.day} ${_monthName(date.month)} ${date.year}';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: isDark ? AppColors.nightSurface : const Color(0xFFF9F6F0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 24),
            tooltip: 'Previous Day',
            onPressed: widget.state.goToPreviousDay,
          ),
          InkWell(
            onTap: _pickDate,
            borderRadius: BorderRadius.circular(8),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, size: 18, color: AppColors.goldPrimary),
                  const SizedBox(width: 8),
                  Text(
                    formattedDate,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 24),
            tooltip: 'Next Day',
            onPressed: widget.state.goToNextDay,
          ),
        ],
      ),
    );
  }

  Widget _buildLocationBar(bool isDark) {
    final loc = widget.state.selectedLocation;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFEFE8DD),
        border: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
            width: 0.8,
          ),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.location_on,
            size: 16,
            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${loc.name} (${loc.timezone})',
              style: AppTextStyles.caption(isDark).copyWith(
                fontWeight: FontWeight.w600,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          OutlinedButton(
            onPressed: () {
              LocationSelectorModal.show(
                context: context,
                currentLocation: widget.state.selectedLocation,
                repository: widget.repository,
                onLocationSelected: widget.state.setLocation,
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              minimumSize: const Size(0, 28),
              side: BorderSide(
                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                width: 0.8,
              ),
            ),
            child: Text(
              'CHANGE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailableView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.satellite_alt_outlined,
              size: 56,
              color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
            ),
            const SizedBox(height: 16),
            Text(
              'Astronomical Engine Offline',
              style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 18),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF9F5),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                ),
              ),
              child: Text(
                'In strict adherence to Vedam\'s Section 8 authenticity standards, '
                'planetary positions and Pancha Anga transitions are calculated '
                'from genuine astronomical ephemerides rather than fabricated or conjectured tables.\n\n'
                'Please ensure the backend calculation service is running or check your network connection.',
                style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 13, height: 1.4),
                textAlign: TextAlign.center,
              ),
            ),
            if (widget.state.errorMessage != null) ...[
              const SizedBox(height: 12),
              Text(
                widget.state.errorMessage!,
                style: const TextStyle(fontSize: 11, color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            ],
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: widget.state.refresh,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry Astronomical Calculation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.goldPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchangamContentView(bool isDark, DailyPanchangamData data) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // 1. Observances Banner (if present)
        if (data.observances.isNotEmpty) _buildObservancesBanner(isDark, data.observances),

        // 2. Celestial Sun & Moon Card
        _buildSunMoonCard(isDark, data.sunMoon),
        const SizedBox(height: 14),

        // 3. Five Primary Elements (Pancha Anga)
        _buildPanchaAngaCard(isDark, data),
        const SizedBox(height: 14),

        // 4. Auspicious & Inauspicious Muhurtas
        _buildMuhurtasCard(isDark, data),
        const SizedBox(height: 14),

        // 5. Calculation Conventions & Transparency
        _buildConventionsCard(isDark, data.conventions),
      ],
    );
  }

  Widget _buildObservancesBanner(bool isDark, List<Observance> observances) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2D1F10) : const Color(0xFFFFF7EB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.goldPrimary, width: 1.2),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.temple_hindu, color: AppColors.goldPrimary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'LITURGICAL OBSERVANCES',
                  style: AppTextStyles.metadataTag(isDark).copyWith(
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF3E2C1A) : const Color(0xFFEBDBC6),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'INFORMATIONAL',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...observances.map(
              (obs) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${obs.name} • ${obs.sanskritName}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      obs.description,
                      style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 12),
                    ),
                    if (obs.disclaimer != null) ...[
                      const SizedBox(height: 4),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 13,
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                          ),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              obs.disclaimer!,
                              style: TextStyle(
                                fontSize: 11,
                                fontStyle: FontStyle.italic,
                                height: 1.3,
                                color: isDark ? const Color(0xFFB8A48B) : const Color(0xFF6B5C4A),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: () => _openObservanceDetails(context, obs),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withAlpha(isDark ? 30 : 20),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            width: 0.8,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.menu_book,
                              size: 14,
                              color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            ),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'View Observance Details & Guided Practices',
                                overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                              ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 10,
                              color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSunMoonCard(bool isDark, SunMoonEvents sm) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.wb_sunny_outlined, size: 18, color: AppColors.goldPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'CELESTIAL TIMINGS (SURYODAYA & CHANDRODAYA)',
                    style: AppTextStyles.metadataTag(isDark).copyWith(
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Sunrise (सूर्योदय)',
                    value: sm.sunriseFormatted,
                    icon: Icons.wb_twilight,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Sunset (सूर्यास्त)',
                    value: sm.sunsetFormatted,
                    icon: Icons.nights_stay_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Day Length (दिनमान)',
                    value: sm.dayLengthFormatted,
                    icon: Icons.hourglass_bottom,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: _MetricTile(
                    label: 'Moonrise (चन्द्रोदय)',
                    value: sm.moonriseFormatted ?? 'Not today',
                    icon: Icons.brightness_3,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Moonset (चन्द्रास्त)',
                    value: sm.moonsetFormatted ?? 'Not today',
                    icon: Icons.bedtime_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MetricTile(
                    label: 'Illumination',
                    value: '${sm.moonIlluminationPercent.toStringAsFixed(0)}%',
                    icon: Icons.pie_chart_outline,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPanchaAngaCard(bool isDark, DailyPanchangamData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Row(
                    children: [
                      const Icon(Icons.auto_stories_outlined, size: 18, color: AppColors.goldPrimary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'THE FIVE LIMBS (पञ्चाङ्गानि)',
                          style: AppTextStyles.metadataTag(isDark).copyWith(
                            color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF0EAE1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    data.paksha,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // 1. Vara
            _PanchangamElementTile(
              label: 'Vara (वार - Weekday)',
              title: '${data.vara.name} • ${data.vara.sanskritName}',
              subtitle: 'Lord: ${data.vara.presidingDeity}',
              endTime: data.vara.endTimeFormatted,
              meaning: data.vara.meaning,
              isDark: isDark,
            ),
            const Divider(height: 20),

            // 2. Tithi
            _PanchangamElementTile(
              label: 'Tithi (तिथि - Lunar Day)',
              title: '${data.tithi.name} • ${data.tithi.sanskritName}',
              subtitle: 'Presiding Lord: ${data.tithi.presidingDeity}',
              endTime: data.tithi.endTimeFormatted,
              meaning: data.tithi.meaning,
              isDark: isDark,
            ),
            const Divider(height: 20),

            // 3. Nakshatra
            _PanchangamElementTile(
              label: 'Nakshatra (नक्षत्र - Lunar Mansion)',
              title: '${data.nakshatra.name} • ${data.nakshatra.sanskritName}',
              subtitle: 'Presiding Lord: ${data.nakshatra.presidingDeity}',
              endTime: data.nakshatra.endTimeFormatted,
              meaning: data.nakshatra.meaning,
              isDark: isDark,
            ),
            const Divider(height: 20),

            // 4. Yoga
            _PanchangamElementTile(
              label: 'Yoga (योग - Solar-Lunar Sum)',
              title: '${data.yoga.name} • ${data.yoga.sanskritName}',
              subtitle: null,
              endTime: data.yoga.endTimeFormatted,
              meaning: data.yoga.meaning,
              isDark: isDark,
            ),
            const Divider(height: 20),

            // 5. Karana
            _PanchangamElementTile(
              label: 'Karana (करण - Half-Tithi)',
              title: '${data.karana.name} • ${data.karana.sanskritName}',
              subtitle: null,
              endTime: data.karana.endTimeFormatted,
              meaning: data.karana.meaning,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMuhurtasCard(bool isDark, DailyPanchangamData data) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.access_time_outlined, size: 18, color: AppColors.goldPrimary),
                const SizedBox(width: 8),
                Text(
                  'AUSPICIOUS & INAUSPICIOUS TIMINGS',
                  style: AppTextStyles.metadataTag(isDark).copyWith(
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Auspicious
            Text(
              'Auspicious Periods (शुभ मुहूर्त)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.verifiedGreen : const Color(0xFF15803D),
              ),
            ),
            const SizedBox(height: 8),
            if (data.abhijitMuhurat != null)
              _MuhurtaRow(
                name: 'Abhijit Muhurat (अभिजित्)',
                timing: data.abhijitMuhurat!.formatted,
                isAuspicious: data.abhijitMuhurat!.isAuspicious,
                description: data.abhijitMuhurat!.description,
                isDark: isDark,
              ),
            if (data.brahmaMuhurta != null) ...[
              const SizedBox(height: 6),
              _MuhurtaRow(
                name: 'Brahma Muhurta (ब्रह्म मुहूर्त)',
                timing: data.brahmaMuhurta!.formatted,
                isAuspicious: true,
                description: data.brahmaMuhurta!.description,
                isDark: isDark,
              ),
            ],
            const SizedBox(height: 6),
            _MuhurtaRow(
              name: 'Gulika Kalam (गुलिक काल)',
              timing: data.gulikaKalam.formatted,
              isAuspicious: true,
              description: data.gulikaKalam.description,
              isDark: isDark,
            ),

            const Divider(height: 24),

            // Inauspicious (Varjyam)
            Text(
              'Inauspicious Periods (वर्ज्य काल)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: isDark ? const Color(0xFFFCA5A5) : AppColors.kumkumRed,
              ),
            ),
            const SizedBox(height: 8),
            _MuhurtaRow(
              name: 'Rahu Kalam (राहुकाल)',
              timing: data.rahuKalam.formatted,
              isAuspicious: false,
              description: data.rahuKalam.description,
              isDark: isDark,
            ),
            const SizedBox(height: 6),
            _MuhurtaRow(
              name: 'Yamagandam (यमगण्ड)',
              timing: data.yamagandam.formatted,
              isAuspicious: false,
              description: data.yamagandam.description,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConventionsCard(bool isDark, CalculationConventions conv) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.verified_outlined, size: 16, color: AppColors.goldPrimary),
                const SizedBox(width: 8),
                Text(
                  'ASTRONOMICAL CALCULATION STANDARDS',
                  style: AppTextStyles.metadataTag(isDark).copyWith(
                    color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              '• Ayanamsa: ${conv.ayanamsaUsed} (${conv.ayanamsaValueFormatted})\n'
              '• Ephemeris: ${conv.ephemerisEngine}\n'
              '• Coordinate System: ${conv.coordinateSystem}\n'
              '• Solar Horizon: ${conv.sunriseConvention}\n'
              '• Day Governance: ${conv.udayaTithiRule}',
              style: AppTextStyles.caption(isDark).copyWith(
                fontSize: 12,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _weekdayName(int day) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return names[(day - 1) % 7];
  }

  static String _monthName(int month) {
    const names = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return names[(month - 1) % 12];
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isDark;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 12, color: AppColors.goldPrimary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.caption(isDark).copyWith(fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _PanchangamElementTile extends StatelessWidget {
  final String label;
  final String title;
  final String? subtitle;
  final String? endTime;
  final String meaning;
  final bool isDark;

  const _PanchangamElementTile({
    required this.label,
    required this.title,
    this.subtitle,
    this.endTime,
    required this.meaning,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.caption(isDark).copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (endTime != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF3EFE9),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  endTime!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle!,
            style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
          ),
        ],
        const SizedBox(height: 4),
        Text(
          meaning,
          style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 12),
        ),
      ],
    );
  }
}

class _MuhurtaRow extends StatelessWidget {
  final String name;
  final String timing;
  final bool isAuspicious;
  final String description;
  final bool isDark;

  const _MuhurtaRow({
    required this.name,
    required this.timing,
    required this.isAuspicious,
    required this.description,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final color = isAuspicious
        ? (isDark ? AppColors.verifiedGreen : const Color(0xFF15803D))
        : (isDark ? const Color(0xFFFCA5A5) : AppColors.kumkumRed);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFAF7F2),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 0.8,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                timing,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            description,
            style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
