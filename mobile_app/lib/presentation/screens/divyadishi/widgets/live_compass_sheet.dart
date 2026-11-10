import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/models/bearing_result.dart';
import '../../../../core/models/corrected_heading_reading.dart';
import '../../../../core/models/declination_model.dart';
import '../../../../core/models/heading_model.dart';
import '../../../../core/models/temple.dart';
import '../../../../core/services/compass_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../state/divyadishi_state.dart';

/// Modal bottom sheet presenting the opt-in, foreground-only live device compass
/// with offline World Magnetic Model (WMM) declination correction and approximate sacred alignment.
///
/// Governance & Correctness Guarantees:
/// - Explicit Start/Stop controls; zero background execution.
/// - Unregistered immediately on pause or disposal.
/// - Strictly prevents equating Magnetic North with True North.
/// - Declination sourced 100% offline via official NOAA WMM models.
/// - Withholds precise turn angles for pending temples by default; requires explicit opt-in.
/// - Retains all PENDING coordinate and approximate origin transparency disclaimers.
class LiveCompassSheet extends StatefulWidget {
  final DivyaDishiState state;
  final Temple? selectedTemple;
  final CompassService? compassService;

  const LiveCompassSheet({
    super.key,
    required this.state,
    this.selectedTemple,
    this.compassService,
  });

  static Future<void> show(
    BuildContext context, {
    required DivyaDishiState state,
    Temple? selectedTemple,
    CompassService? compassService,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LiveCompassSheet(
        state: state,
        selectedTemple: selectedTemple,
        compassService: compassService,
      ),
    );
  }

  @override
  State<LiveCompassSheet> createState() => _LiveCompassSheetState();
}

class _LiveCompassSheetState extends State<LiveCompassSheet> with WidgetsBindingObserver {
  late final CompassService _compassService;
  bool _showApproximateAlignment = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _compassService = widget.compassService ?? widget.state.compassService;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState appState) {
    if (appState == AppLifecycleState.paused || appState == AppLifecycleState.inactive) {
      _compassService.pauseCompass();
    } else if (appState == AppLifecycleState.resumed) {
      _compassService.resumeCompass();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _compassService.stopCompass();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bearing = widget.selectedTemple != null
        ? widget.state.calculateBearing(widget.selectedTemple!)
        : null;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.ivorySurface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 12,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: ListenableBuilder(
        listenable: _compassService,
        builder: (context, _) {
          final reading = _compassService.reading;
          final isActive = _compassService.isActive;
          final declination = widget.state.currentDeclination;
          final corrected = widget.state.getCorrectedHeading(reading);

          RelativeSacredAlignment? alignment;
          if (widget.selectedTemple != null && bearing != null && bearing.isAvailable) {
            alignment = widget.state.calculateRelativeAlignment(
              widget.selectedTemple!,
              reading,
              userOptedIn: _showApproximateAlignment,
            );
          }

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                // 1. Drag handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: AppColors.chandanBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // 2. Header
                Row(
                  children: [
                    const Icon(Icons.explore, color: AppColors.saffronPrimary, size: 24),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Live Sacred Compass',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDarkPrimary,
                            ),
                          ),
                          const Text(
                            'Foreground orientation aid • Zero GPS tracking',
                            style: TextStyle(
                              fontSize: 11,
                              color: AppColors.textDarkSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textDarkMuted),
                      tooltip: 'Close Compass',
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // 3. Devotional Orientation Disclaimer Banner
                _buildDisclaimerBanner(),
                const SizedBox(height: 12),

                // 4. Target Temple Card (if selected)
                if (widget.selectedTemple != null && bearing != null) ...[
                  _buildTempleTargetCard(widget.selectedTemple!, bearing),
                  const SizedBox(height: 12),
                ],

                // 5. Central Compass Dial
                _buildCompassVisualizer(reading, corrected),
                const SizedBox(height: 16),

                // 6. Heading Readout & Quality Badges
                _buildHeadingReadout(reading, corrected, declination),
                const SizedBox(height: 12),

                // 7. Reference & Alignment Transparency Notice
                _buildAlignmentNotice(reading, corrected, declination, bearing, alignment),
                const SizedBox(height: 12),

                // 8. Interference & Calibration Guidance
                _buildInterferenceGuidance(reading),
                const SizedBox(height: 16),

                // 9. Start / Stop Action Buttons
                _buildActionButtons(isActive, reading),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildDisclaimerBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.chandanBorder),
      ),
      child: const Text(
        'DEVOTIONAL AID ONLY: Great-circle orientation is a meditative aid without ritual mandate. Traditional household puja canonically faces East or North.',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontSize: 10.5,
          color: AppColors.textDarkSecondary,
          height: 1.3,
        ),
      ),
    );
  }

  Widget _buildTempleTargetCard(Temple temple, BearingResult bearing) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ivorySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.saffronPrimary.withAlpha(60)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.temple_hindu, size: 16, color: AppColors.saffronPrimary),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  temple.name,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: AppColors.draftWarningLight,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: AppColors.draftWarningBorder),
                ),
                child: const Text(
                  'PENDING',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.bold,
                    color: AppColors.draftWarning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Target: ${temple.city}, ${temple.country} • ${temple.pointType.label}',
            style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
          ),
          if (bearing.isAvailable) ...[
            const SizedBox(height: 6),
            Text(
              'True Geodetic Bearing: ${bearing.degrees!.toStringAsFixed(1)}° ${bearing.cardinalDirection} (${bearing.sanskritDirection ?? ""}) • ${bearing.distanceKm!.toStringAsFixed(0)} km',
              style: const TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w600,
                color: AppColors.saffronDark,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompassVisualizer(HeadingReading reading, CorrectedHeadingReading corrected) {
    // When valid offline declination is applied, align dial to True North
    final displayHeading = corrected.isAvailable && corrected.trueHeading != null
        ? corrected.trueHeading!
        : (reading.hasValidHeading ? reading.heading! : 0.0);

    final angleRad = -displayHeading * (math.pi / 180.0);

    return Container(
      width: 190,
      height: 190,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppColors.creamBackground,
        border: Border.all(
          color: reading.state == HeadingSensorState.lowAccuracy
              ? AppColors.draftWarningBorder
              : (corrected.isAvailable ? Colors.teal.shade400 : AppColors.saffronPrimary.withAlpha(80)),
          width: 3,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Rotating dial ring with 8 cardinal marks
          Transform.rotate(
            angle: angleRad,
            child: CustomPaint(
              size: const Size(180, 180),
              painter: _CompassDialPainter(isTrueNorth: corrected.isAvailable),
            ),
          ),
          // Fixed Lubber Line (top indicator)
          Positioned(
            top: 6,
            child: Container(
              width: 4,
              height: 12,
              decoration: BoxDecoration(
                color: corrected.isAvailable ? Colors.teal.shade700 : AppColors.saffronPrimary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          // Center Readout
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (reading.hasValidHeading) ...[
                Text(
                  '${displayHeading.toStringAsFixed(0)}°',
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textDarkPrimary,
                  ),
                ),
                Text(
                  _cardinalLabel(displayHeading),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: corrected.isAvailable ? Colors.teal.shade800 : AppColors.saffronPrimary,
                  ),
                ),
                Text(
                  corrected.isAvailable ? 'True North' : 'Magnetic',
                  style: TextStyle(
                    fontSize: 9.5,
                    fontWeight: FontWeight.w500,
                    color: corrected.isAvailable ? Colors.teal.shade600 : AppColors.textDarkMuted,
                  ),
                ),
              ] else ...[
                Icon(
                  reading.state == HeadingSensorState.unavailable
                      ? Icons.sensors_off
                      : Icons.explore_outlined,
                  size: 36,
                  color: AppColors.textDarkMuted,
                ),
                const SizedBox(height: 4),
                Text(
                  reading.state == HeadingSensorState.unavailable
                      ? 'Unavailable'
                      : reading.state == HeadingSensorState.permissionDenied
                          ? 'Denied'
                          : 'Stopped',
                  style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeadingReadout(
    HeadingReading reading,
    CorrectedHeadingReading corrected,
    DeclinationResult? declination,
  ) {
    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 6,
          runSpacing: 6,
          children: [
            // Sensor Badge (Measured Reference)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppColors.goldLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: AppColors.goldPrimary),
              ),
              child: Text(
                reading.reference.label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textDarkPrimary,
                ),
              ),
            ),

            // Corrected True Heading Badge (if declination applied)
            if (corrected.isAvailable)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.teal.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.teal.shade300),
                ),
                child: Text(
                  'TRUE NORTH (${declination?.modelName ?? "WMM"})',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.teal.shade800,
                  ),
                ),
              ),

            // Declination Badge (if available)
            if (declination != null && declination.isValid)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.blueGrey.shade50,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: Colors.blueGrey.shade300),
                ),
                child: Text(
                  'DECLINATION: ${declination.formattedDeclination}',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey.shade800,
                  ),
                ),
              ),

            // Sensor Accuracy Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: reading.accuracy == HeadingAccuracy.high
                    ? Colors.green.shade50
                    : reading.accuracy == HeadingAccuracy.medium
                        ? Colors.blue.shade50
                        : AppColors.draftWarningLight,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: reading.accuracy == HeadingAccuracy.high
                      ? Colors.green.shade300
                      : reading.accuracy == HeadingAccuracy.medium
                          ? Colors.blue.shade300
                          : AppColors.draftWarningBorder,
                ),
              ),
              child: Text(
                reading.accuracy.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: reading.accuracy == HeadingAccuracy.high
                      ? Colors.green.shade800
                      : reading.accuracy == HeadingAccuracy.medium
                          ? Colors.blue.shade800
                          : AppColors.draftWarning,
                ),
              ),
            ),
          ],
        ),

        // Subtitle Provenance Information
        if (corrected.isAvailable && declination != null) ...[
          const SizedBox(height: 6),
          Text(
            'Measured Sensor: ${reading.heading!.toStringAsFixed(1)}° Mag • Origin: ${declination.originNameWithProvenance}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 10.5, color: AppColors.textDarkSecondary),
          ),
        ] else if (widget.state.selectedOrigin == null) ...[
          const SizedBox(height: 6),
          const Text(
            'Select an approximate city origin to calculate geomagnetic declination for True North.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 10.5, color: AppColors.textDarkMuted),
          ),
        ],

        if (reading.state == HeadingSensorState.stale) ...[
          const SizedBox(height: 6),
          const Text(
            'Stale reading — sensor updates paused. Move device gently.',
            style: TextStyle(fontSize: 11, color: AppColors.draftWarning, fontWeight: FontWeight.w600),
          ),
        ],
      ],
    );
  }

  Widget _buildAlignmentNotice(
    HeadingReading reading,
    CorrectedHeadingReading corrected,
    DeclinationResult? declination,
    BearingResult? bearing,
    RelativeSacredAlignment? alignment,
  ) {
    if (widget.selectedTemple == null || bearing == null || !bearing.isAvailable) {
      return const SizedBox.shrink();
    }

    // Case A: Corrected True Heading available & alignment evaluated
    if (corrected.isAvailable && alignment != null) {
      if (!_showApproximateAlignment) {
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: Colors.amber.shade300),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.shield_outlined, size: 16, color: Colors.amber.shade900),
                  const SizedBox(width: 6),
                  Text(
                    'Magnetic vs True North Notice',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber.shade900,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Destination Coordinate Safeguard',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                'Your device compass measures Magnetic North. The sacred bearing to ${widget.selectedTemple!.name} is '
                'calculated relative to True Geographic North (${bearing.degrees!.toStringAsFixed(1)}° True). '
                'Destination coordinates are marked PENDING verification (${widget.selectedTemple!.pointType.label}). '
                'Turn-angle alignment is withheld by default.',
                style: TextStyle(fontSize: 11, color: Colors.brown.shade800, height: 1.35),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => setState(() => _showApproximateAlignment = true),
                  icon: const Icon(Icons.compass_calibration_outlined, size: 16),
                  label: const Text('Show Approximate Alignment Comparison'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.saffronDark,
                    side: const BorderSide(color: AppColors.saffronPrimary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    textStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        );
      }

      // Devotee has opted in to view approximate alignment comparison
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.teal.shade300, width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.explore_rounded, size: 18, color: AppColors.saffronDark),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'APPROXIMATE TEMPLE-COMPLEX ALIGNMENT',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: AppColors.saffronDark,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Hide approximate alignment',
                  icon: const Icon(Icons.visibility_off_outlined, size: 18, color: AppColors.textDarkMuted),
                  onPressed: () => setState(() => _showApproximateAlignment = false),
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Large relative turn guidance
            Center(
              child: Column(
                children: [
                  Text(
                    alignment.formattedGuidance,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: alignment.hasValidTurnAngle && alignment.turnAngleDegrees!.abs() <= 5.0
                          ? Colors.teal.shade900
                          : AppColors.saffronDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Current: ${corrected.trueHeading!.toStringAsFixed(1)}° True • Temple: ${bearing.degrees!.toStringAsFixed(1)}° True',
                    style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),

            // Dual uncertainty disclaimer
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withAlpha(180),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.teal.shade100),
              ),
              child: Text(
                alignment.dualUncertaintyDisclaimer,
                style: TextStyle(fontSize: 10, color: Colors.teal.shade900, height: 1.3),
              ),
            ),
          ],
        ),
      );
    }

    // Case B: No origin selected
    if (widget.state.selectedOrigin == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.creamBackground,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.chandanBorder),
        ),
        child: Text(
          'Select an approximate city origin to calculate geomagnetic declination and enable sacred alignment comparison to ${widget.selectedTemple!.name}.',
          style: const TextStyle(fontSize: 11, color: AppColors.textDarkSecondary, height: 1.3),
        ),
      );
    }

    // Case C: Magnetic fallback when declination unavailable or reading uncorrected
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.draftWarningLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.draftWarningBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.info_outline, size: 16, color: AppColors.draftWarning),
              SizedBox(width: 6),
              Text(
                'Magnetic vs True North Notice',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.draftWarning,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Your device compass measures Magnetic North. The sacred bearing to ${widget.selectedTemple!.name} is calculated relative to True Geographic North (${bearing.degrees!.toStringAsFixed(1)}° True). '
            '${corrected.unavailabilityReason ?? "Turn-angle alignment is withheld until True North correction is available."}',
            style: TextStyle(
              fontSize: 11,
              color: Colors.brown.shade800,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInterferenceGuidance(HeadingReading reading) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Text(
        'Calibration & Interference: Nearby metallic cases or electronic devices affect compass readings. If accuracy is low, wave device in a gentle figure-8 motion.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 10.5, color: AppColors.textDarkMuted, height: 1.3),
      ),
    );
  }

  Widget _buildActionButtons(bool isActive, HeadingReading reading) {
    if (reading.state == HeadingSensorState.unavailable) {
      return Column(
        children: [
          const Text(
            'Compass sensor hardware is unavailable in this environment.',
            style: TextStyle(fontSize: 12, color: AppColors.textDarkMuted),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      );
    }

    if (!isActive) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () => _compassService.startCompass(),
          icon: const Icon(Icons.play_arrow_rounded),
          label: const Text('Start Live Compass'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.saffronPrimary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () => _compassService.stopCompass(),
        icon: const Icon(Icons.stop_rounded, color: AppColors.saffronDark),
        label: const Text('Stop Compass'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.saffronDark,
          side: const BorderSide(color: AppColors.saffronPrimary),
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
      ),
    );
  }

  String _cardinalLabel(double deg) {
    if (deg >= 337.5 || deg < 22.5) return 'N (Uttara)';
    if (deg >= 22.5 && deg < 67.5) return 'NE (Ishanya)';
    if (deg >= 67.5 && deg < 112.5) return 'E (Purva)';
    if (deg >= 112.5 && deg < 157.5) return 'SE (Agneya)';
    if (deg >= 157.5 && deg < 202.5) return 'S (Dakshina)';
    if (deg >= 202.5 && deg < 247.5) return 'SW (Nairruti)';
    if (deg >= 247.5 && deg < 292.5) return 'W (Pashchima)';
    return 'NW (Vayavya)';
  }
}

/// Custom painter rendering the 8-cardinal compass rose dial.
class _CompassDialPainter extends CustomPainter {
  final bool isTrueNorth;

  const _CompassDialPainter({this.isTrueNorth = false});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    final tickPaint = Paint()
      ..color = AppColors.chandanBorder
      ..strokeWidth = 1.5;

    final northPaint = Paint()
      ..color = isTrueNorth ? Colors.teal.shade700 : AppColors.saffronPrimary
      ..strokeWidth = 2.5;

    // Draw cardinal ticks
    for (int i = 0; i < 8; i++) {
      final angle = i * (math.pi / 4);
      final isNorth = i == 0;
      final tickLength = isNorth ? 14.0 : 8.0;

      final start = Offset(
        center.dx + (radius - tickLength) * math.sin(angle),
        center.dy - (radius - tickLength) * math.cos(angle),
      );
      final end = Offset(
        center.dx + radius * math.sin(angle),
        center.dy - radius * math.cos(angle),
      );

      canvas.drawLine(start, end, isNorth ? northPaint : tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _CompassDialPainter oldDelegate) =>
      oldDelegate.isTrueNorth != isTrueNorth;
}
