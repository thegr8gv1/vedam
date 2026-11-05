import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../core/models/vrat_observance.dart';
import '../../../data/fixtures/authentic_mantras_data.dart';
import '../../../data/fixtures/authentic_puja_guides_data.dart';
import '../../../data/fixtures/default_vrat_templates_data.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/vrat_state.dart';

class AddEditVratModal extends StatefulWidget {
  final VratState vratState;
  final PanchangamState? panchangamState;
  final VratObservance? existingObservance;

  const AddEditVratModal({
    super.key,
    required this.vratState,
    this.panchangamState,
    this.existingObservance,
  });

  static Future<void> show({
    required BuildContext context,
    required VratState vratState,
    PanchangamState? panchangamState,
    VratObservance? existingObservance,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddEditVratModal(
        vratState: vratState,
        panchangamState: panchangamState,
        existingObservance: existingObservance,
      ),
    );
  }

  @override
  State<AddEditVratModal> createState() => _AddEditVratModalState();
}

class _AddEditVratModalState extends State<AddEditVratModal> {
  late VratType _selectedType;
  late TextEditingController _titleController;
  late TextEditingController _sanskritTitleController;
  late TextEditingController _traditionController;
  late TextEditingController _locationController;
  late TextEditingController _intentionController;
  late DateTime _selectedDate;
  late CalendarConvention _selectedConvention;
  String? _selectedPujaGuideId;
  String? _selectedMantraId;

  @override
  void initState() {
    super.initState();
    final existing = widget.existingObservance;

    if (existing != null) {
      _selectedType = existing.type;
      _titleController = TextEditingController(text: existing.title);
      _sanskritTitleController = TextEditingController(text: existing.sanskritTitle);
      _traditionController = TextEditingController(text: existing.tradition);
      _locationController = TextEditingController(text: existing.location);
      _intentionController = TextEditingController(text: existing.personalIntention);
      _selectedDate = DateTime.tryParse(existing.targetDate) ?? DateTime.now();
      _selectedConvention = existing.calendarConvention;
      _selectedPujaGuideId = existing.associatedPujaGuideId;
      _selectedMantraId = existing.associatedMantraId;
    } else {
      _selectedType = VratType.ekadashi;
      _selectedDate = DateTime.now();
      _selectedConvention = CalendarConvention.traditionalRegional;
      _locationController = TextEditingController(text: 'Varanasi, India (25.3176°N, 82.9739°E)');
      _titleController = TextEditingController();
      _sanskritTitleController = TextEditingController();
      _traditionController = TextEditingController();
      _intentionController = TextEditingController();
      _applyTemplateDefaults(_selectedType);
    }
  }

  void _applyTemplateDefaults(VratType type) {
    final dateStr = _formatDate(_selectedDate);
    final template = DefaultVratTemplatesData.createTemplate(
      type,
      targetDate: dateStr,
      location: _locationController.text,
      convention: _selectedConvention,
    );

    _titleController.text = template.title;
    _sanskritTitleController.text = template.sanskritTitle;
    _traditionController.text = template.tradition;
    _intentionController.text = template.personalIntention;
    _selectedPujaGuideId = template.associatedPujaGuideId;
    _selectedMantraId = template.associatedMantraId;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _sanskritTitleController.dispose();
    _traditionController.dispose();
    _locationController.dispose();
    _intentionController.dispose();
    super.dispose();
  }

  String _formatDate(DateTime dt) {
    final y = dt.year.toString().padLeft(4, '0');
    final m = dt.month.toString().padLeft(2, '0');
    final d = dt.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _saveObservance() {
    if (_titleController.text.trim().isEmpty) return;

    final dateStr = _formatDate(_selectedDate);
    final isNew = widget.existingObservance == null;

    VratPanchangamSnapshot? snapshot;
    final currentData = widget.panchangamState?.data;
    if (currentData != null) {
      snapshot = VratPanchangamSnapshot(
        tithiName: currentData.tithi.name,
        paksha: currentData.paksha,
        nakshatraName: currentData.nakshatra.name,
        transitionTime: currentData.tithi.endTimeFormatted,
        calendarConvention: _selectedConvention.name,
      );
    }

    final VratObservance observance;
    if (isNew) {
      final baseTemplate = DefaultVratTemplatesData.createTemplate(
        _selectedType,
        targetDate: dateStr,
        location: _locationController.text.trim(),
        convention: _selectedConvention,
        panchangamSnapshot: snapshot,
      );

      observance = baseTemplate.copyWith(
        title: _titleController.text.trim(),
        sanskritTitle: _sanskritTitleController.text.trim(),
        tradition: _traditionController.text.trim(),
        personalIntention: _intentionController.text.trim(),
        associatedPujaGuideId: _selectedPujaGuideId,
        associatedMantraId: _selectedMantraId,
      );

      widget.vratState.addObservance(observance);
    } else {
      observance = widget.existingObservance!.copyWith(
        type: _selectedType,
        title: _titleController.text.trim(),
        sanskritTitle: _sanskritTitleController.text.trim(),
        targetDate: dateStr,
        location: _locationController.text.trim(),
        tradition: _traditionController.text.trim(),
        calendarConvention: _selectedConvention,
        personalIntention: _intentionController.text.trim(),
        associatedPujaGuideId: _selectedPujaGuideId,
        associatedMantraId: _selectedMantraId,
        panchangamSnapshot: snapshot ?? widget.existingObservance!.panchangamSnapshot,
      );

      widget.vratState.updateObservance(observance);
    }

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isNew = widget.existingObservance == null;

    return Container(
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Bar
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  isNew ? 'Plan Personal Observance' : 'Edit Observance',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textDarkPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Personal planning tool. Choose dates and traditions according to your household lineage.',
              style: AppTextStyles.caption(isDark),
            ),
            const SizedBox(height: 16),

            // Observance Type Selector
            Text('OBSERVANCE TYPE', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VratType.values.map((type) {
                final isSelected = _selectedType == type;
                String label;
                switch (type) {
                  case VratType.ekadashi:
                    label = 'Ekadashi';
                    break;
                  case VratType.pradosham:
                    label = 'Pradosham';
                    break;
                  case VratType.purnima:
                    label = 'Purnima';
                    break;
                  case VratType.amavasya:
                    label = 'Amavasya';
                    break;
                  case VratType.sankashtiChaturthi:
                    label = 'Sankashti';
                    break;
                  case VratType.custom:
                    label = 'Custom';
                    break;
                }

                return ChoiceChip(
                  label: Text(label),
                  selected: isSelected,
                  selectedColor: AppColors.saffronPrimary.withAlpha(200),
                  onSelected: (val) {
                    if (val) {
                      setState(() {
                        _selectedType = type;
                        if (isNew) _applyTemplateDefaults(type);
                      });
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Date Selection
            Text('OBSERVANCE DATE', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.withAlpha(100)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.calendar_today, size: 18, color: AppColors.saffronPrimary),
                        const SizedBox(width: 10),
                        Text(
                          _formatDate(_selectedDate),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                      ],
                    ),
                    const Text(
                      'CHANGE DATE',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.saffronPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Title
            Text('OBSERVANCE TITLE', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'e.g. Utpanna Ekadashi Vrat',
              ),
            ),
            const SizedBox(height: 12),

            // Sanskrit Title
            Text('SANSKRIT / TRADITIONAL TITLE', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _sanskritTitleController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'e.g. एकादशी व्रतम्',
              ),
            ),
            const SizedBox(height: 12),

            // Tradition & Lineage
            Text('TRADITION / SAMPRADAYA', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _traditionController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
                hintText: 'e.g. Vaishnava, Smartha, Shaiva, or Family Tradition',
              ),
            ),
            const SizedBox(height: 12),

            // Calendar Convention
            Text('CALENDAR CONVENTION', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<CalendarConvention>(
              initialValue: _selectedConvention,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: const [
                DropdownMenuItem(
                  value: CalendarConvention.traditionalRegional,
                  child: Text('Traditional Regional Lineage'),
                ),
                DropdownMenuItem(
                  value: CalendarConvention.amanta,
                  child: Text('Amanta (Month ends on Amavasya)'),
                ),
                DropdownMenuItem(
                  value: CalendarConvention.purnimanta,
                  child: Text('Purnimanta (Month ends on Purnima)'),
                ),
                DropdownMenuItem(
                  value: CalendarConvention.solarDrik,
                  child: Text('Solar Drik Astronomical System'),
                ),
                DropdownMenuItem(
                  value: CalendarConvention.custom,
                  child: Text('Custom Household Tradition'),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedConvention = val);
              },
            ),
            const SizedBox(height: 12),

            // Associated Guided Puja
            Text('LINKED GUIDED PUJA (OPTIONAL)', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              initialValue: _selectedPujaGuideId,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('None (Independent Observance)')),
                ...AuthenticPujaGuidesData.allGuides.map((g) => DropdownMenuItem(
                      value: g.id,
                      child: Text('${g.title} (${g.deity})'),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedPujaGuideId = val),
            ),
            const SizedBox(height: 12),

            // Associated Mantra
            Text('LINKED DEVOTIONAL MANTRA (OPTIONAL)', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String?>(
              initialValue: _selectedMantraId,
              decoration: const InputDecoration(border: OutlineInputBorder(), isDense: true),
              items: [
                const DropdownMenuItem(value: null, child: Text('None (General Prayer)')),
                ...AuthenticMantrasData.allMantras.take(20).map((m) => DropdownMenuItem(
                      value: m.id,
                      child: Text('${m.title} (${m.deity})'),
                    )),
              ],
              onChanged: (val) => setState(() => _selectedMantraId = val),
            ),
            const SizedBox(height: 12),

            // Personal Intention (Sankalpa)
            Text('PERSONAL INTENTION / SANKALPA', style: AppTextStyles.metadataTag(isDark)),
            const SizedBox(height: 6),
            TextField(
              controller: _intentionController,
              maxLines: 2,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'e.g. Cultivating calm patience and offering today to the Divine.',
              ),
            ),
            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.saffronPrimary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _saveObservance,
                child: Text(
                  isNew ? 'SAVE OBSERVANCE' : 'UPDATE OBSERVANCE',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
