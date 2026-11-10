import 'package:flutter/material.dart';
import 'package:vedam_app/core/models/bearing_result.dart';
import 'package:vedam_app/core/models/sacred_origin.dart';
import 'package:vedam_app/core/models/temple.dart';
import 'package:vedam_app/core/theme/app_colors.dart';
import 'package:vedam_app/state/divyadishi_state.dart';
import 'widgets/live_compass_sheet.dart';
import 'widgets/temple_detail_modal.dart';

/// Screen presenting the DivyaDishi Sacred Temple Directory.
/// Allows browsing, searching, filtering, approximate origin selection,
/// and viewing provisional coordinate provenance and great-circle sacred bearings.
class TempleDirectoryScreen extends StatefulWidget {
  final DivyaDishiState? state;

  const TempleDirectoryScreen({super.key, this.state});

  @override
  State<TempleDirectoryScreen> createState() => _TempleDirectoryScreenState();
}

class _TempleDirectoryScreenState extends State<TempleDirectoryScreen> {
  late final DivyaDishiState _state;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _state = widget.state ?? DivyaDishiState();
    _searchController.text = _state.searchQuery;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showOriginDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.location_city, color: AppColors.saffronPrimary),
              SizedBox(width: 8),
              Expanded(
                child: Text('Select Origin Point', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Choose an approximate municipal city centroid to calculate great-circle directions. Zero device location permissions are requested; each origin carries ±15 km uncertainty.',
                  style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                ),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView(
                    shrinkWrap: true,
                    children: [
                      ListTile(
                        leading: const Icon(Icons.clear, color: AppColors.textDarkMuted),
                        title: const Text('No Origin (Clear Selection)'),
                        selected: _state.selectedOrigin == null,
                        onTap: () {
                          _state.setOrigin(null);
                          Navigator.of(ctx).pop();
                        },
                      ),
                      const Divider(height: 1),
                      ...SacredOrigin.canonicalCities.map((origin) {
                        final isSelected = _state.selectedOrigin?.name == origin.name;
                        return ListTile(
                          leading: Icon(
                            isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                            color: isSelected ? AppColors.saffronPrimary : AppColors.textDarkMuted,
                          ),
                          title: Text(
                            origin.name,
                            style: TextStyle(
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              color: isSelected ? AppColors.saffronPrimary : AppColors.textDarkPrimary,
                            ),
                          ),
                          subtitle: Text(
                            'Approx: ${origin.coordinate.latitude.toStringAsFixed(2)}°, ${origin.coordinate.longitude.toStringAsFixed(2)}° (±${origin.accuracyRadiusKm.toStringAsFixed(0)} km • ${origin.region})',
                            style: const TextStyle(fontSize: 11),
                          ),
                          onTap: () {
                            _state.setOrigin(origin);
                            Navigator.of(ctx).pop();
                          },
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _state,
      builder: (context, _) {
        final temples = _state.temples;
        final selectedOrigin = _state.selectedOrigin;

        return Scaffold(
          appBar: AppBar(
            title: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'DivyaDishi Directory',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                ),
                Text(
                  'Provisional Sacred Temples',
                  style: TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                ),
              ],
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.explore_outlined, color: AppColors.saffronPrimary),
                tooltip: 'Live Sacred Compass',
                onPressed: () {
                  LiveCompassSheet.show(
                    context,
                    state: _state,
                  );
                },
              ),
              TextButton.icon(
                onPressed: _showOriginDialog,
                icon: const Icon(Icons.location_on, size: 16, color: AppColors.saffronPrimary),
                label: Text(
                  selectedOrigin?.name ?? 'Set Origin',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.saffronPrimary,
                  ),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // 1. Prominent Warning Notice Banner
              _buildProvisionalNoticeBanner(),

              // 2. Origin Status Bar
              _buildOriginStatusBar(selectedOrigin),

              // 3. Search Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Search by temple, deity, or city...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear, size: 18),
                            onPressed: () {
                              _searchController.clear();
                              _state.setSearchQuery('');
                            },
                          )
                        : null,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                  onChanged: (val) => _state.setSearchQuery(val),
                ),
              ),

              // 4. Country & Tradition Filters
              _buildFilterChips(),

              // 5. Temple List
              Expanded(
                child: temples.isEmpty
                    ? _buildEmptyState()
                    : ListView.builder(
                        itemCount: temples.length,
                        padding: const EdgeInsets.only(bottom: 24),
                        itemBuilder: (ctx, index) {
                          final temple = temples[index];
                          final bearing = _state.calculateBearing(temple);
                          return _buildTempleCard(temple, bearing);
                        },
                      ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProvisionalNoticeBanner() {
    return Container(
      width: double.infinity,
      color: AppColors.draftWarningLight,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, size: 18, color: AppColors.draftWarning),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'AUDITED DIRECTORY: Coordinates identify temple compound complexes from trust & survey records (Garbhagriha geodetic ground-truthing pending). Bearing calculations are geographic orientation aids.',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.brown.shade800,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginStatusBar(SacredOrigin? origin) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      color: AppColors.creamBackground,
      child: Row(
        children: [
          Icon(
            origin != null ? Icons.my_location : Icons.location_off_outlined,
            size: 16,
            color: origin != null ? AppColors.saffronPrimary : AppColors.textDarkMuted,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              origin != null
                  ? 'Reference Origin: ${origin.name} (Approximate)'
                  : 'No origin selected (Bearings uncalculated)',
              style: TextStyle(
                fontSize: 12,
                fontWeight: origin != null ? FontWeight.w600 : FontWeight.normal,
                color: origin != null ? AppColors.textDarkPrimary : AppColors.textDarkMuted,
              ),
            ),
          ),
          InkWell(
            onTap: _showOriginDialog,
            borderRadius: BorderRadius.circular(4),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
              child: Text(
                origin != null ? 'Change' : 'Set City',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saffronPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final countries = ['All', ..._state.availableCountries];
    final selectedCountry = _state.selectedCountry ?? 'All';

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          ...countries.map((c) {
            final isSelected = selectedCountry == c;
            return Padding(
              padding: const EdgeInsets.only(right: 6),
              child: ChoiceChip(
                label: Text(c, style: const TextStyle(fontSize: 12)),
                selected: isSelected,
                selectedColor: AppColors.saffronLight,
                labelStyle: TextStyle(
                  color: isSelected ? AppColors.saffronDark : AppColors.textDarkSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                ),
                onSelected: (selected) {
                  if (selected) {
                    _state.setCountryFilter(c == 'All' ? null : c);
                  }
                },
              ),
            );
          }),
          const SizedBox(width: 4),
          // Tradition dropdown
          DropdownButton<TempleTradition?>(
            value: _state.selectedTradition,
            hint: const Text('Tradition', style: TextStyle(fontSize: 12)),
            underline: const SizedBox(),
            isDense: true,
            items: [
              const DropdownMenuItem<TempleTradition?>(
                value: null,
                child: Text('All Traditions', style: TextStyle(fontSize: 12)),
              ),
              ...TempleTradition.values.map((t) {
                return DropdownMenuItem<TempleTradition?>(
                  value: t,
                  child: Text(t.label, style: const TextStyle(fontSize: 12)),
                );
              }),
            ],
            onChanged: (t) => _state.setTraditionFilter(t),
          ),
        ],
      ),
    );
  }

  Widget _buildTempleCard(Temple temple, BearingResult bearing) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          TempleDetailModal.show(
            context,
            temple: temple,
            state: _state,
            onSelectOriginPressed: _showOriginDialog,
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
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
                          temple.name,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textDarkPrimary,
                          ),
                        ),
                        if (temple.alternateNames.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            temple.alternateNames.join(' • '),
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.saffronPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // Provenance Tag
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: temple.verificationStatus == CoordinateVerificationStatus.verified
                              ? Colors.green.shade50
                              : AppColors.draftWarningLight,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: temple.verificationStatus == CoordinateVerificationStatus.verified
                                ? Colors.green.shade300
                                : AppColors.draftWarningBorder,
                          ),
                        ),
                        child: Text(
                          temple.verificationStatus == CoordinateVerificationStatus.verified
                              ? 'VERIFIED'
                              : temple.verificationStatus == CoordinateVerificationStatus.pendingVerification
                                  ? 'PENDING'
                                  : 'UNVERIFIED',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: temple.verificationStatus == CoordinateVerificationStatus.verified
                                ? Colors.green.shade700
                                : AppColors.draftWarning,
                            letterSpacing: 0.4,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        temple.pointType.label,
                        style: const TextStyle(
                          fontSize: 9.5,
                          color: AppColors.textDarkMuted,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.temple_hindu, size: 14, color: AppColors.saffronPrimary),
                  const SizedBox(width: 4),
                  Text(
                    temple.deity,
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '•  ${temple.tradition.label}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textDarkMuted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      '${temple.city}, ${temple.state}, ${temple.country}',
                      style: const TextStyle(fontSize: 12, color: AppColors.textDarkSecondary),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              if (bearing.isAvailable) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.saffronLight,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.saffronPrimary.withAlpha(50)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.explore, size: 16, color: AppColors.saffronPrimary),
                      const SizedBox(width: 6),
                      Text(
                        '${bearing.degrees!.toStringAsFixed(1)}° ${bearing.cardinalDirection}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: AppColors.saffronDark,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '(${bearing.sanskritDirection ?? ''})',
                        style: const TextStyle(fontSize: 11, color: AppColors.saffronDark),
                      ),
                      if (bearing.isApproximate) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: AppColors.draftWarningLight,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: const Text(
                            'approx',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: AppColors.draftWarning,
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      Text(
                        '${bearing.distanceKm!.toStringAsFixed(0)} km',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textDarkPrimary,
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
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search_off, size: 48, color: AppColors.textDarkMuted),
            const SizedBox(height: 12),
            const Text(
              'No Sacred Temples Found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            const Text(
              'Try adjusting your search terms or filter selection.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textDarkSecondary),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                _state.resetFilters();
              },
              child: const Text('Reset Filters'),
            ),
          ],
        ),
      ),
    );
  }
}
