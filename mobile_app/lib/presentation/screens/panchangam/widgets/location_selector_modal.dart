import 'package:flutter/material.dart';
import '../../../../core/models/panchangam_data.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/text_styles.dart';
import '../../../../data/repositories/panchangam_repository.dart';

class LocationSelectorModal extends StatefulWidget {
  final PanchangamLocation currentLocation;
  final PanchangamRepository repository;
  final ValueChanged<PanchangamLocation> onLocationSelected;

  const LocationSelectorModal({
    super.key,
    required this.currentLocation,
    required this.repository,
    required this.onLocationSelected,
  });

  static Future<void> show({
    required BuildContext context,
    required PanchangamLocation currentLocation,
    required PanchangamRepository repository,
    required ValueChanged<PanchangamLocation> onLocationSelected,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => LocationSelectorModal(
        currentLocation: currentLocation,
        repository: repository,
        onLocationSelected: onLocationSelected,
      ),
    );
  }

  @override
  State<LocationSelectorModal> createState() => _LocationSelectorModalState();
}

class _LocationSelectorModalState extends State<LocationSelectorModal> {
  final TextEditingController _searchController = TextEditingController();
  List<PanchangamLocation> _locations = [];
  bool _isLoading = true;
  bool _showCustomInput = false;

  // Custom coordinate controllers
  final TextEditingController _customNameController = TextEditingController();
  final TextEditingController _customLatController = TextEditingController();
  final TextEditingController _customLonController = TextEditingController();
  final TextEditingController _customTzController = TextEditingController(text: 'Asia/Kolkata');

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  Future<void> _loadLocations([String? query]) async {
    setState(() => _isLoading = true);
    final results = await widget.repository.getCuratedLocations(query: query);
    setState(() {
      _locations = results;
      _isLoading = false;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _customNameController.dispose();
    _customLatController.dispose();
    _customLonController.dispose();
    _customTzController.dispose();
    super.dispose();
  }

  void _submitCustomCoordinates() {
    final name = _customNameController.text.trim();
    final lat = double.tryParse(_customLatController.text.trim());
    final lon = double.tryParse(_customLonController.text.trim());
    final tz = _customTzController.text.trim();

    if (name.isEmpty || lat == null || lon == null || tz.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter valid name, coordinates (-90 to 90, -180 to 180), and timezone.')),
      );
      return;
    }

    if (lat < -90.0 || lat > 90.0 || lon < -180.0 || lon > 180.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Coordinates out of range: Latitude [-90, 90], Longitude [-180, 180].')),
      );
      return;
    }

    final loc = PanchangamLocation(
      name: name,
      latitude: lat,
      longitude: lon,
      timezone: tz,
    );
    widget.onLocationSelected(loc);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 44,
            height: 4,
            decoration: BoxDecoration(
              color: isDark ? Colors.white24 : Colors.black12,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'SELECT LOCATION',
                      style: AppTextStyles.metadataTag(isDark).copyWith(
                        color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                        letterSpacing: 1.0,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Panchangam Calculation Coordinates',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ],
                ),
                TextButton.icon(
                  onPressed: () {
                    setState(() => _showCustomInput = !_showCustomInput);
                  },
                  icon: Icon(
                    _showCustomInput ? Icons.list : Icons.pin_drop_outlined,
                    size: 16,
                    color: AppColors.goldPrimary,
                  ),
                  label: Text(
                    _showCustomInput ? 'Curated' : 'Custom Coords',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.goldGlow : AppColors.goldDark,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          if (_showCustomInput)
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Astronomical Coordinates',
                      style: AppTextStyles.titleMedium(isDark).copyWith(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter precise latitude, longitude, and IANA timezone for accurate astronomical sunrise and Pancha Anga calculations.',
                      style: AppTextStyles.verseMeaning(isDark).copyWith(fontSize: 13),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _customNameController,
                      decoration: const InputDecoration(
                        labelText: 'Location Name (e.g. My Home Temple)',
                        prefixIcon: Icon(Icons.home_outlined),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customLatController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Latitude (-90 to 90)',
                              hintText: 'e.g. 13.0827',
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _customLonController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                            decoration: const InputDecoration(
                              labelText: 'Longitude (-180 to 180)',
                              hintText: 'e.g. 80.2707',
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _customTzController,
                      decoration: const InputDecoration(
                        labelText: 'IANA Timezone (e.g. Asia/Kolkata, America/New_York)',
                        prefixIcon: Icon(Icons.access_time),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _submitCustomCoordinates,
                        icon: const Icon(Icons.check_circle_outline),
                        label: const Text('Apply Custom Coordinates'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.goldPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else ...[
            // Search field
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: TextField(
                controller: _searchController,
                onChanged: _loadLocations,
                decoration: InputDecoration(
                  hintText: 'Search city or sacred pilgrimage site...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _loadLocations();
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF7F4EF),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    ),
                  ),
                ),
              ),
            ),

            // Location list
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator(color: AppColors.goldPrimary))
                  : ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: _locations.length,
                      separatorBuilder: (_, _) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final loc = _locations[index];
                        final isSelected = loc.name == widget.currentLocation.name;

                        return ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          leading: CircleAvatar(
                            backgroundColor: isSelected
                                ? AppColors.goldPrimary
                                : (isDark ? AppColors.nightSurfaceElevated : const Color(0xFFEFE8DD)),
                            child: Icon(
                              isSelected ? Icons.check : Icons.temple_hindu_outlined,
                              size: 18,
                              color: isSelected
                                  ? Colors.white
                                  : (isDark ? AppColors.goldGlow : AppColors.saffronDark),
                            ),
                          ),
                          title: Text(
                            loc.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              color: isSelected
                                  ? (isDark ? AppColors.goldGlow : AppColors.goldDark)
                                  : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                            ),
                          ),
                          subtitle: Text(
                            'Lat: ${loc.latitude.toStringAsFixed(3)}°, Lon: ${loc.longitude.toStringAsFixed(3)}° • ${loc.timezone}',
                            style: AppTextStyles.caption(isDark).copyWith(fontSize: 11),
                          ),
                          onTap: () {
                            widget.onLocationSelected(loc);
                            Navigator.of(context).pop();
                          },
                        );
                      },
                    ),
            ),
          ],
        ],
      ),
    );
  }
}
