import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/bearing_result.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/state/divyadishi_state.dart';
import 'live_compass_sheet.dart';

/// Modal bottom sheet displaying detailed temple information, coordinate provenance,
/// transparency disclaimers, and calculated geographic initial bearing.
class TempleDetailModal extends StatelessWidget {
  final Temple temple;
  final DivyaDishiState state;
  final VoidCallback? onSelectOriginPressed;

  const TempleDetailModal({
    super.key,
    required this.temple,
    required this.state,
    this.onSelectOriginPressed,
  });

  static Future<void> show(
    BuildContext context, {
    required Temple temple,
    required DivyaDishiState state,
    VoidCallback? onSelectOriginPressed,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => TempleDetailModal(
        temple: temple,
        state: state,
        onSelectOriginPressed: onSelectOriginPressed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bearing = state.calculateBearing(temple);
    final theme = Theme.of(context);

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
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: AppColors.chandanBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header: Temple Name & Alternate Name
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        temple.name,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDarkPrimary,
                        ),
                      ),
                      if (temple.alternateNames.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          temple.alternateNames.join(' • '),
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: AppColors.saffronPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textDarkMuted),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Deity & Tradition
            Row(
              children: [
                const Icon(Icons.temple_hindu, size: 16, color: AppColors.saffronPrimary),
                const SizedBox(width: 6),
                Text(
                  temple.deity,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkPrimary,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.saffronLight,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: AppColors.saffronPrimary.withAlpha(50)),
                  ),
                  child: Text(
                    temple.tradition.label,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.saffronDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 16, color: AppColors.textDarkMuted),
                const SizedBox(width: 6),
                Text(
                  '${temple.city}, ${temple.state}, ${temple.country}',
                  style: const TextStyle(
                    color: AppColors.textDarkSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Sacred Bearing Card
            _buildBearingCard(context, bearing),
            const SizedBox(height: 16),

            // Coordinate Provenance & Transparency Notice
            _buildCoordinateProvenanceCard(context),
            const SizedBox(height: 16),

            // Festivals & Sacred Notes
            if (temple.primaryFestivals.isNotEmpty) ...[
              const Text(
                'Major Observances & Festivals',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: temple.primaryFestivals.map((fest) {
                  return Chip(
                    label: Text(
                      fest,
                      style: const TextStyle(fontSize: 12, color: AppColors.textDarkPrimary),
                    ),
                    backgroundColor: AppColors.goldLight,
                    side: const BorderSide(color: AppColors.goldPrimary, width: 0.8),
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
            ],

            if (temple.notes != null && temple.notes!.isNotEmpty) ...[
              const Text(
                'Historical & Architectural Notes',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: AppColors.textDarkPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                temple.notes!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textDarkSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildBearingCard(BuildContext context, BearingResult bearing) {
    if (!bearing.isAvailable) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.creamBackground,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.chandanBorder),
        ),
        child: Column(
          children: [
            const Icon(Icons.explore_outlined, color: AppColors.saffronPrimary, size: 32),
            const SizedBox(height: 8),
            const Text(
              'Sacred Direction (DivyaDishi)',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: AppColors.textDarkPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              state.selectedOrigin == null
                  ? 'Select an approximate city origin to calculate sacred bearing & distance.'
                  : bearing.unavailabilityReason ?? 'Direction unavailable for this coordinate pair.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textDarkSecondary,
              ),
            ),
            const SizedBox(height: 12),
            if (onSelectOriginPressed != null)
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  onSelectOriginPressed!();
                },
                icon: const Icon(Icons.location_city, size: 16),
                label: const Text('Set Approximate Origin'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
          ],
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.creamBackground,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.saffronPrimary.withAlpha(70)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.explore, color: AppColors.saffronPrimary, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Sacred Bearing & Direction',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: AppColors.textDarkPrimary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              if (bearing.isApproximate) ...[
                Container(
                  margin: const EdgeInsets.only(right: 6),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.draftWarningLight,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppColors.draftWarningBorder),
                  ),
                  child: const Text(
                    'APPROX',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: AppColors.draftWarning,
                    ),
                  ),
                ),
              ],
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.saffronLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${bearing.degrees!.toStringAsFixed(1)}° ${bearing.cardinalDirection}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.saffronDark,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildBearingStat(
                label: 'Traditional Dishā',
                value: bearing.sanskritDirection ?? '—',
                subValue: bearing.dikpala != null ? 'Guardian: ${bearing.dikpala}' : null,
              ),
              _buildBearingStat(
                label: 'Great-Circle Distance',
                value: '${bearing.distanceKm!.toStringAsFixed(0)} km',
                subValue: 'Direct geodesic path',
              ),
            ],
          ),
          if (bearing.traditionVariant != null) ...[
            const SizedBox(height: 8),
            Center(
              child: Text(
                'Variant Tradition: ${bearing.traditionVariant}',
                style: const TextStyle(
                  fontSize: 11,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textDarkSecondary,
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.ivorySurface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.chandanBorder),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'From: ${state.selectedOrigin!.name} (±${state.selectedOrigin!.accuracyRadiusKm.toStringAsFixed(0)} km centroid uncertainty)',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  bearing.provisionalDisclaimer ??
                      'Great-circle forward azimuth calculation. Provided as an aid for devotional orientation, not a mandatory ritual injunction.',
                  style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textDarkSecondary,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                LiveCompassSheet.show(
                  context,
                  state: state,
                  selectedTemple: temple,
                );
              },
              icon: const Icon(Icons.explore_outlined, size: 18),
              label: const Text('Open Live Compass (Optional)'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.saffronDark,
                side: const BorderSide(color: AppColors.saffronPrimary),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBearingStat({
    required String label,
    required String value,
    String? subValue,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(fontSize: 11, color: AppColors.textDarkMuted),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: AppColors.textDarkPrimary,
          ),
        ),
        if (subValue != null) ...[
          const SizedBox(height: 1),
          Text(
            subValue,
            style: const TextStyle(fontSize: 10, color: AppColors.textDarkSecondary),
          ),
        ],
      ],
    );
  }

  Widget _buildCoordinateProvenanceCard(BuildContext context) {
    final statusColor = temple.verificationStatus == CoordinateVerificationStatus.verified
        ? Colors.green.shade700
        : AppColors.draftWarning;
    final statusBgColor = temple.verificationStatus == CoordinateVerificationStatus.verified
        ? Colors.green.shade50
        : AppColors.draftWarningLight;
    final statusBorderColor = temple.verificationStatus == CoordinateVerificationStatus.verified
        ? Colors.green.shade300
        : AppColors.draftWarningBorder;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusBgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: statusBorderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                temple.verificationStatus == CoordinateVerificationStatus.verified
                    ? Icons.verified_outlined
                    : Icons.warning_amber_rounded,
                color: statusColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  temple.verificationStatus.label.toUpperCase(),
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: statusColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.ivorySurface,
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: statusBorderColor),
                ),
                child: Text(
                  temple.pointType.label,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDarkSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Coordinates: ${temple.coordinate.formatted} (${temple.coordinate.latitude.toStringAsFixed(6)}°, ${temple.coordinate.longitude.toStringAsFixed(6)}°)',
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textDarkPrimary,
              fontFamily: 'monospace',
            ),
          ),
          if (temple.hasCoordinateChanged) ...[
            const SizedBox(height: 4),
            Text(
              'Original Record: ${temple.originalCoordinate!.formatted} (Refined site preserved in audit ledger)',
              style: TextStyle(
                fontSize: 11,
                fontStyle: FontStyle.italic,
                color: Colors.brown.shade700,
                fontFamily: 'monospace',
              ),
            ),
          ],
          const SizedBox(height: 8),
          if (temple.sourceName.isNotEmpty) ...[
            Text(
              'Source Authority: ${temple.sourceName}',
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textDarkPrimary,
              ),
            ),
          ],
          if (temple.sourceUrl != null) ...[
            const SizedBox(height: 2),
            Text(
              'Reference URL: ${temple.sourceUrl}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textDarkSecondary,
                fontFamily: 'monospace',
              ),
            ),
          ],
          if (temple.corroborationSources.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              'Corroboration: ${temple.corroborationSources.join(" • ")}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textDarkSecondary,
              ),
            ),
          ],
          if (temple.verificationNotes != null && temple.verificationNotes!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              temple.verificationNotes!,
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textDarkSecondary,
                height: 1.35,
              ),
            ),
          ],
          if (temple.verificationDate != null) ...[
            const SizedBox(height: 4),
            Text(
              'Audit Date: ${temple.verificationDate!.toIso8601String().split("T").first}',
              style: const TextStyle(
                fontSize: 10,
                color: AppColors.textDarkMuted,
              ),
            ),
          ],
          const SizedBox(height: 8),
          const Divider(height: 12),
          const Text(
            'GEODETIC TRANSPARENCY NOTICE: Coordinate identifies the temple compound / architectural complex center derived from official trust and archaeological records. Subterranean Garbhagriha geodetic benchmark ground-truthing remains pending before final certification.',
            style: TextStyle(
              fontSize: 10.5,
              color: AppColors.textDarkPrimary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
