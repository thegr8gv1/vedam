import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/models/panchangam_data.dart';
import '../../../../core/models/sankalpa_model.dart';
import '../../../../core/services/sankalpa_service.dart';
import '../../../../core/theme/app_colors.dart';

/// Interactive modal sheet for generating authentic Vedic Sankalpa recitations.
///
/// Integrates live Panchangam coordinates, devotee lineage, sacred river basins,
/// and traditional ritual intentions (Sadhana, Japa, Puja, Vrat, Sandhya).
class SankalpaGeneratorModal extends StatefulWidget {
  final DailyPanchangamData? panchangam;
  final SankalpaPurpose initialPurpose;
  final String? initialDeity;
  final VoidCallback? onCompleted;

  const SankalpaGeneratorModal({
    super.key,
    this.panchangam,
    this.initialPurpose = SankalpaPurpose.dailySadhana,
    this.initialDeity,
    this.onCompleted,
  });

  static Future<void> show({
    required BuildContext context,
    DailyPanchangamData? panchangam,
    SankalpaPurpose initialPurpose = SankalpaPurpose.dailySadhana,
    String? initialDeity,
    VoidCallback? onCompleted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => SankalpaGeneratorModal(
        panchangam: panchangam,
        initialPurpose: initialPurpose,
        initialDeity: initialDeity,
        onCompleted: onCompleted,
      ),
    );
  }

  @override
  State<SankalpaGeneratorModal> createState() => _SankalpaGeneratorModalState();
}

class _SankalpaGeneratorModalState extends State<SankalpaGeneratorModal> {
  final SankalpaService _service = SankalpaService();
  late TextEditingController _gotraController;
  late TextEditingController _nameController;
  late TextEditingController _deityController;
  late TextEditingController _customIntentionController;

  late SankalpaPurpose _purpose;
  late RiverBasinOption _riverBasin;
  late SankalpaGender _gender;
  bool _useIast = false;
  bool _useShortVersion = false;
  bool _showCustomization = false;
  bool _showStructuralBreakdown = false;
  bool _isProfileLoaded = false;

  SankalpaOutput? _generatedOutput;

  @override
  void initState() {
    super.initState();
    _purpose = widget.initialPurpose;
    _riverBasin = RiverBasinOption.pavitraDeshe;
    _gender = SankalpaGender.unspecified;
    _gotraController = TextEditingController(text: 'Vishnu');
    _nameController = TextEditingController(text: 'Devotee');
    _deityController = TextEditingController(text: widget.initialDeity ?? 'Sri Parameshwara / Narayana');
    _customIntentionController = TextEditingController();

    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final saved = await _service.loadSavedProfile(
      date: DateTime.now(),
      panchangam: widget.panchangam,
      purpose: widget.initialPurpose,
    );

    if (mounted) {
      setState(() {
        _gotraController.text = saved.gotra;
        _nameController.text = saved.devoteeName;
        _gender = saved.gender;
        _riverBasin = saved.riverBasin;
        if (widget.initialDeity == null || widget.initialDeity!.isEmpty) {
          _deityController.text = saved.deityName;
        }
        _isProfileLoaded = true;
        _regenerate();
      });
    }
  }

  void _regenerate() {
    final input = SankalpaInput(
      gotra: _gotraController.text.trim(),
      devoteeName: _nameController.text.trim(),
      gender: _gender,
      purpose: _purpose,
      riverBasin: _riverBasin,
      deityName: _deityController.text.trim(),
      customIntention: _customIntentionController.text.trim(),
      date: DateTime.now(),
      panchangam: widget.panchangam,
    );

    setState(() {
      _generatedOutput = _service.generateSankalpa(input);
    });
  }

  Future<void> _saveProfileLocally() async {
    await _service.saveProfile(
      gotra: _gotraController.text.trim(),
      devoteeName: _nameController.text.trim(),
      gender: _gender,
      riverBasin: _riverBasin,
      deityName: _deityController.text.trim(),
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Devotee lineage and preferences saved for future Sankalpas.'),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label copied to clipboard.'),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _gotraController.dispose();
    _nameController.dispose();
    _deityController.dispose();
    _customIntentionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: MediaQuery.of(context).size.height * 0.90,
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(
          color: isDark ? AppColors.goldDark.withValues(alpha: 0.3) : AppColors.chandanBorder,
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          _buildDragHandle(isDark),
          _buildHeader(isDark),
          Expanded(
            child: _isProfileLoaded && _generatedOutput != null
                ? ListView(
                    key: const Key('sankalpa_scroll_view'),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    children: [
                      _buildPurposeSelector(isDark),
                      const SizedBox(height: 12),
                      _buildPanchangamSummaryChip(isDark),
                      const SizedBox(height: 14),
                      _buildRecitationCard(isDark),
                      const SizedBox(height: 14),
                      _buildTogglesRow(isDark),
                      const SizedBox(height: 14),
                      _buildCustomizationAccordion(isDark),
                      const SizedBox(height: 14),
                      _buildStructuralBreakdownAccordion(isDark),
                      const SizedBox(height: 24),
                    ],
                  )
                : const Center(child: CircularProgressIndicator()),
          ),
          _buildFooterActions(isDark),
        ],
      ),
    );
  }

  Widget _buildDragHandle(bool isDark) {
    return Center(
      child: Container(
        margin: const EdgeInsets.only(top: 10, bottom: 4),
        width: 44,
        height: 4,
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.saffronPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.wb_sunny_outlined, color: AppColors.saffronPrimary, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Vedic Sankalpa Generator',
                  style: TextStyle(
                    fontFamily: 'Cinzel',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.goldGlow : AppColors.terracotta,
                  ),
                ),
                Text(
                  'Sacred Intention & Panchangam Alignment',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? Colors.grey[400] : AppColors.textDarkSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _buildPurposeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'PURPOSE OF CONTEMPLATION (प्रयोजन)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.8,
            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
          ),
        ),
        const SizedBox(height: 8),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: SankalpaPurpose.values.map((purpose) {
              final isSelected = _purpose == purpose;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text(
                    purpose.displayName,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.grey[300] : AppColors.textDarkPrimary),
                    ),
                  ),
                  selected: isSelected,
                  selectedColor: AppColors.saffronPrimary,
                  backgroundColor: isDark ? AppColors.nightSurfaceElevated : Colors.grey[100],
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _purpose = purpose;
                        _regenerate();
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildPanchangamSummaryChip(bool isDark) {
    final out = _generatedOutput!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.goldLight.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : AppColors.chandanBorder,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.calendar_month, color: AppColors.goldPrimary, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${out.samvatsara} • ${out.ayana} • ${out.ritu} • ${out.paksha} • ${out.tithi} • ${out.vara}',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.grey[300] : AppColors.textDarkPrimary,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecitationCard(bool isDark) {
    final out = _generatedOutput!;
    final recitationText = _useShortVersion
        ? (_useIast ? out.shortIast : out.shortSanskrit)
        : (_useIast ? out.iastFull : out.sanskritFull);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.goldLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppColors.goldDark.withValues(alpha: 0.4) : AppColors.goldPrimary.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.04),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.auto_stories, color: AppColors.saffronPrimary, size: 16),
                  const SizedBox(width: 6),
                  Text(
                    _useShortVersion ? 'SANKALPA (CONCISE)' : 'VEDIC SANKALPA (SACRED TEXT)',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                    ),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 18, color: AppColors.goldPrimary),
                tooltip: 'Copy Recitation',
                onPressed: () => _copyToClipboard(recitationText, 'Sankalpa text'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SelectableText(
            recitationText,
            style: TextStyle(
              fontFamily: _useIast ? null : 'Sanskrit',
              fontSize: _useIast ? 13.5 : 15.5,
              height: 1.7,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.amber[50] : const Color(0xFF2C1810),
            ),
            textAlign: TextAlign.justify,
          ),
          const SizedBox(height: 12),
          Divider(color: isDark ? Colors.grey[800] : AppColors.chandanBorder, height: 1),
          const SizedBox(height: 10),
          Text(
            'ENGLISH MEANING & PRAYER INTENTION:',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.7,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            _useShortVersion ? out.shortEnglish : out.englishFull,
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              fontStyle: FontStyle.italic,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTogglesRow(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Script toggle (Devanagari vs IAST)
        Row(
          children: [
            Text(
              'Devanagari',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: !_useIast ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.grey[300] : AppColors.textDarkPrimary,
              ),
            ),
            Switch(
              key: const Key('switch_iast'),
              value: _useIast,
              activeThumbColor: AppColors.goldPrimary,
              onChanged: (val) {
                setState(() {
                  _useIast = val;
                });
              },
            ),
            Text(
              'IAST',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: _useIast ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.grey[300] : AppColors.textDarkPrimary,
              ),
            ),
          ],
        ),

        // Length toggle (Full vs Concise)
        Row(
          children: [
            Text(
              'Full',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: !_useShortVersion ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.grey[300] : AppColors.textDarkPrimary,
              ),
            ),
            Switch(
              key: const Key('switch_short'),
              value: _useShortVersion,
              activeThumbColor: AppColors.saffronPrimary,
              onChanged: (val) {
                setState(() {
                  _useShortVersion = val;
                });
              },
            ),
            Text(
              'Short',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: _useShortVersion ? FontWeight.bold : FontWeight.normal,
                color: isDark ? Colors.grey[300] : AppColors.textDarkPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCustomizationAccordion(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : AppColors.chandanBorder,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: _showCustomization,
        onExpansionChanged: (val) {
          setState(() {
            _showCustomization = val;
          });
        },
        leading: const Icon(Icons.person_pin, color: AppColors.saffronPrimary, size: 20),
        title: Text(
          'Personalize Gotra, Name & Kshetra',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textDarkPrimary,
          ),
        ),
        subtitle: Text(
          '${_gotraController.text} • ${_nameController.text} • ${_riverBasin.displayName.split(' ')[0]}',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: [
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _gotraController,
                  decoration: const InputDecoration(
                    labelText: 'Devotee Gotra',
                    hintText: 'e.g. Kashyapa / Vishnu',
                    isDense: true,
                  ),
                  onChanged: (_) => _regenerate(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Devotee Name',
                    hintText: 'e.g. Ramesh',
                    isDense: true,
                  ),
                  onChanged: (_) => _regenerate(),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<RiverBasinOption>(
                  initialValue: _riverBasin,
                  decoration: const InputDecoration(
                    labelText: 'Sacred River / Kshetra',
                    isDense: true,
                  ),
                  items: RiverBasinOption.values.map((river) {
                    return DropdownMenuItem(
                      value: river,
                      child: Text(river.displayName, style: const TextStyle(fontSize: 12)),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _riverBasin = val;
                        _regenerate();
                      });
                    }
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DropdownButtonFormField<SankalpaGender>(
                  initialValue: _gender,
                  decoration: const InputDecoration(
                    labelText: 'Declension Suffix',
                    isDense: true,
                  ),
                  items: const [
                    DropdownMenuItem(value: SankalpaGender.unspecified, child: Text('Universal (नामधेयस्य)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: SankalpaGender.male, child: Text('Male (शर्मणः)', style: TextStyle(fontSize: 12))),
                    DropdownMenuItem(value: SankalpaGender.female, child: Text('Female (नामधेयायाः)', style: TextStyle(fontSize: 12))),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _gender = val;
                        _regenerate();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _deityController,
            decoration: const InputDecoration(
              labelText: 'Dedicated Deity / Ishta Devata',
              hintText: 'e.g. Sri Shiva / Ganesha / Narayana',
              isDense: true,
            ),
            onChanged: (_) => _regenerate(),
          ),
          if (_purpose == SankalpaPurpose.custom) ...[
            const SizedBox(height: 12),
            TextField(
              controller: _customIntentionController,
              decoration: const InputDecoration(
                labelText: 'Personal Intention (Prayojana)',
                hintText: 'e.g. For peace of mind and righteous progress',
                isDense: true,
              ),
              onChanged: (_) => _regenerate(),
            ),
          ],
          const SizedBox(height: 14),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _saveProfileLocally,
              icon: const Icon(Icons.bookmark_outline, size: 16),
              label: const Text('Save as Default Profile', style: TextStyle(fontSize: 12)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStructuralBreakdownAccordion(bool isDark) {
    final out = _generatedOutput!;
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : Colors.grey[50],
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : AppColors.chandanBorder,
        ),
      ),
      child: ExpansionTile(
        key: const Key('tile_structural_breakdown'),
        initiallyExpanded: _showStructuralBreakdown,
        onExpansionChanged: (val) {
          setState(() {
            _showStructuralBreakdown = val;
          });
        },
        leading: const Icon(Icons.account_tree_outlined, color: AppColors.goldPrimary, size: 20),
        title: Text(
          'Structural Breakdown & Scholarly Notes',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textDarkPrimary,
          ),
        ),
        subtitle: Text(
          'Understand the 5 Vedic components of Sankalpa',
          style: TextStyle(fontSize: 11, color: isDark ? Colors.grey[400] : Colors.grey[600]),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        children: out.components.map((c) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.sectionTitle.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.6,
                    color: AppColors.saffronPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _useIast ? c.iastText : c.sanskritText,
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    fontFamily: _useIast ? null : 'Sanskrit',
                    color: isDark ? Colors.grey[200] : AppColors.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  c.englishMeaning,
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? Colors.grey[400] : Colors.grey[700],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildFooterActions(bool isDark) {
    final out = _generatedOutput;
    final recitationText = out == null
        ? ''
        : (_useShortVersion
            ? (_useIast ? out.shortIast : out.shortSanskrit)
            : (_useIast ? out.iastFull : out.sanskritFull));

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        border: Border(top: BorderSide(color: isDark ? Colors.grey[800]! : AppColors.chandanBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: out == null ? null : () => _copyToClipboard(recitationText, 'Sankalpa'),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('COPY TEXT'),
              style: OutlinedButton.styleFrom(
                foregroundColor: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                side: BorderSide(color: isDark ? AppColors.goldDark : AppColors.saffronPrimary),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            flex: 2,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.of(context).pop();
                if (widget.onCompleted != null) {
                  widget.onCompleted!();
                }
              },
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: const Text('PROCEED WITH PRACTICE'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronPrimary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
                elevation: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
