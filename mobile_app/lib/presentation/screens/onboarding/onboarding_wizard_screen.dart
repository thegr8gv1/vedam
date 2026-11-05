import 'package:flutter/material.dart';
import '../../../core/models/devotee_preferences.dart';
import '../../../core/models/panchangam_data.dart';
import '../../../core/models/verse.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/panchangam_repository.dart';
import '../../../state/personalization_state.dart';

/// Multi-step, respectful, welcoming Devotee Onboarding & Personalization Wizard.
///
/// Steps:
/// 0. Welcome & Purpose
/// 1. Devotional Interests (Deity selection)
/// 2. Language & Scripture Script Preferences
/// 3. Daily Sadhana Goals (Japa targets, puja, scripture, meditation)
/// 4. Panchangam Location (Manual city selection, no GPS requirement)
/// 5. Devotional Reminders (Opt-in local notifications)
/// 6. Review & Finish
class OnboardingWizardScreen extends StatefulWidget {
  final PersonalizationState personalizationState;
  final PanchangamRepository? panchangamRepository;
  final VoidCallback onFinish;
  final int initialStep;

  const OnboardingWizardScreen({
    super.key,
    required this.personalizationState,
    this.panchangamRepository,
    required this.onFinish,
    this.initialStep = 0,
  });

  @override
  State<OnboardingWizardScreen> createState() => _OnboardingWizardScreenState();
}

class _OnboardingWizardScreenState extends State<OnboardingWizardScreen> {
  int _currentStep = 0;
  final int _totalSteps = 7;

  // Staging state during onboarding
  late Set<String> _stagingDeityIds;
  late String _stagingLanguage;
  late ScriptOption _stagingScript;
  late DailySadhanaGoals _stagingGoals;
  late PanchangamLocation _stagingLocation;
  late bool _stagingReminders;

  // Custom Japa target entry controller
  late TextEditingController _customJapaController;
  bool _isCustomJapaSelected = false;

  // Location search
  final TextEditingController _citySearchController = TextEditingController();
  List<PanchangamLocation> _curatedLocations = [];
  bool _isLoadingLocations = true;

  @override
  void initState() {
    super.initState();
    _currentStep = widget.initialStep.clamp(0, _totalSteps - 1);
    final p = widget.personalizationState.preferences;
    _stagingDeityIds = Set.from(p.selectedDeityIds);
    _stagingLanguage = p.interfaceLanguage;
    _stagingScript = p.scriptureScript;
    _stagingGoals = p.sadhanaGoals;
    _stagingLocation = p.panchangamLocation;
    _stagingReminders = p.remindersEnabled;

    final isStandardPreset = [11, 21, 27, 54, 108, 111, 1008].contains(_stagingGoals.japaTarget);
    _isCustomJapaSelected = !isStandardPreset;
    _customJapaController = TextEditingController(
      text: _isCustomJapaSelected ? _stagingGoals.japaTarget.toString() : '108',
    );

    _loadCuratedLocations();
  }

  @override
  void dispose() {
    _customJapaController.dispose();
    _citySearchController.dispose();
    super.dispose();
  }

  Future<void> _loadCuratedLocations() async {
    final repo = widget.panchangamRepository ?? PanchangamRepositoryImpl();
    final locs = await repo.getCuratedLocations();
    if (mounted) {
      setState(() {
        _curatedLocations = locs;
        _isLoadingLocations = false;
      });
    }
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() => _currentStep++);
    } else {
      _finishOnboarding();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
    }
  }

  Future<void> _skipOnboarding() async {
    await widget.personalizationState.skipOnboarding();
    widget.onFinish();
  }

  Future<void> _finishOnboarding() async {
    // Commit all staged values to state & SharedPreferences
    await widget.personalizationState.setDevotionalInterests(_stagingDeityIds);
    await widget.personalizationState.setInterfaceLanguage(_stagingLanguage);
    await widget.personalizationState.setScriptureScript(_stagingScript);
    await widget.personalizationState.setSadhanaGoals(_stagingGoals);
    await widget.personalizationState.setPanchangamLocation(_stagingLocation);
    await widget.personalizationState.setRemindersEnabled(_stagingReminders);
    await widget.personalizationState.completeOnboarding();
    widget.onFinish();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.nightBackground : AppColors.creamBackground,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
        elevation: 0,
        leading: _currentStep > 0
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: _previousStep,
              )
            : null,
        title: Text(
          'Step ${_currentStep + 1} of $_totalSteps',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
            color: isDark ? AppColors.goldLight : AppColors.saffronDark,
          ),
        ),
        actions: [
          if (_currentStep < _totalSteps - 1)
            TextButton(
              onPressed: _skipOnboarding,
              child: Text(
                'Skip for Now',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppColors.goldLight : AppColors.saffronPrimary,
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Linear Progress Indicator
            LinearProgressIndicator(
              value: (_currentStep + 1) / _totalSteps,
              backgroundColor: isDark ? AppColors.nightSurfaceElevated : AppColors.chandanBorder.withAlpha(50),
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
              minHeight: 3,
            ),

            // Step Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: _buildCurrentStep(isDark),
                  ),
                ),
              ),
            ),

            // Bottom Navigation Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
                border: Border(
                  top: BorderSide(
                    color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
                    width: 0.8,
                  ),
                ),
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 680),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (_currentStep > 0)
                        OutlinedButton(
                          onPressed: _previousStep,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                            side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('Back'),
                        )
                      else
                        TextButton(
                          onPressed: _skipOnboarding,
                          child: Text(
                            'Explore as Guest',
                            style: TextStyle(
                              color: isDark ? AppColors.textLightMuted : AppColors.textDarkMuted,
                              fontSize: 13,
                            ),
                          ),
                        ),
                      ElevatedButton(
                        onPressed: _nextStep,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 1,
                        ),
                        child: Text(
                          _currentStep == _totalSteps - 1
                              ? 'Finish Setup & Enter Vedam'
                              : (_currentStep == 0 ? 'Get Started' : 'Continue'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentStep(bool isDark) {
    switch (_currentStep) {
      case 0:
        return _buildStep0Welcome(isDark);
      case 1:
        return _buildStep1DevotionalInterests(isDark);
      case 2:
        return _buildStep2LanguageAndScript(isDark);
      case 3:
        return _buildStep3SadhanaGoals(isDark);
      case 4:
        return _buildStep4PanchangamLocation(isDark);
      case 5:
        return _buildStep5Reminders(isDark);
      case 6:
        return _buildStep6ReviewAndFinish(isDark);
      default:
        return const SizedBox.shrink();
    }
  }

  // --------------------------------------------------------------------------
  // STEP 0: Welcome & Purpose
  // --------------------------------------------------------------------------
  Widget _buildStep0Welcome(bool isDark) {
    return Column(
      children: [
        const SizedBox(height: 12),
        // Sacred Emblem
        Container(
          width: 84,
          height: 84,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.saffronPrimary, AppColors.goldPrimary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.saffronPrimary.withAlpha(isDark ? 80 : 40),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Center(
            child: Text(
              'ॐ',
              style: TextStyle(
                fontSize: 42,
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Welcome to Vedam',
          style: AppTextStyles.titleLarge(isDark).copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 0.5,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          'सनातन धर्म • भक्ति • साधना',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Vedam is a sanctified digital sanctuary created to support your personal Hindu spiritual discipline (Sadhana), scripture study, daily domestic worship (Puja), and astronomical calendar (Panchangam).',
          style: AppTextStyles.bodyMedium(isDark).copyWith(height: 1.5),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 24),
        _buildWelcomePillar(
          isDark,
          Icons.menu_book,
          'Authentic Scripture Study',
          'Explore verified verses with multi-script transliteration and transparent translation governance.',
        ),
        const SizedBox(height: 12),
        _buildWelcomePillar(
          isDark,
          Icons.self_improvement,
          'Personal Sadhana & Japa',
          'Practice mindful repetition with mala counters, domestic puja guides, and devotional audio.',
        ),
        const SizedBox(height: 12),
        _buildWelcomePillar(
          isDark,
          Icons.wb_sunny_outlined,
          'Astronomical Panchangam & Vrats',
          'Location-aware tithi, nakshatra, and festival schedules computed transparently from ephemeris models.',
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.privacy_tip_outlined, size: 18, color: AppColors.goldPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Private & Respectful: All personalization is kept locally on your device. Vedam requires no account, collects no telemetry, and tracks no personal coordinates.',
                  style: AppTextStyles.caption(isDark).copyWith(height: 1.35),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWelcomePillar(bool isDark, IconData icon, String title, String description) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
          width: 0.8,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isDark ? Colors.black26 : AppColors.creamBackground,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: AppColors.saffronPrimary, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: AppTextStyles.caption(isDark).copyWith(height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // STEP 1: Devotional Interests (Deity selection)
  // --------------------------------------------------------------------------
  Widget _buildStep1DevotionalInterests(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Choose Your Devotional Interests',
          style: AppTextStyles.titleMedium(isDark).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Select the deities or spiritual paths you hold close in your daily prayers. This personalizes dashboard shortcuts and devotional discovery.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 12),
        // Theological Disclaimer Notice
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1710) : const Color(0xFFFBF6EE),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 16, color: AppColors.goldPrimary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'एकं सद्विप्रा बहुधा वदन्ति — In Hindu tradition, all divine forms express the One Supreme Reality. You may choose any combination or general practice.',
                  style: TextStyle(
                    fontSize: 11,
                    fontStyle: FontStyle.italic,
                    color: isDark ? AppColors.goldLight : AppColors.goldDark,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Deity Selection Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 320,
            mainAxisExtent: 88,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: DevotionalDeity.allDeities.length,
          itemBuilder: (context, index) {
            final deity = DevotionalDeity.allDeities[index];
            final isSelected = _stagingDeityIds.contains(deity.id);

            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected) {
                    if (_stagingDeityIds.length > 1) {
                      _stagingDeityIds.remove(deity.id);
                    }
                  } else {
                    _stagingDeityIds.add(deity.id);
                  }
                });
              },
              borderRadius: BorderRadius.circular(12),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF2C1E14) : const Color(0xFFFFF7ED))
                      : (isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected ? AppColors.saffronPrimary : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
                    width: isSelected ? 1.8 : 0.8,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      deity.icon,
                      color: isSelected ? AppColors.saffronPrimary : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                      size: 26,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            deity.name,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: isSelected ? AppColors.saffronPrimary : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            deity.sanskritName,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark ? AppColors.goldLight : AppColors.goldDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Checkbox(
                      value: isSelected,
                      activeColor: AppColors.saffronPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      onChanged: (val) {
                        setState(() {
                          if (val == true) {
                            _stagingDeityIds.add(deity.id);
                          } else if (_stagingDeityIds.length > 1) {
                            _stagingDeityIds.remove(deity.id);
                          }
                        });
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STEP 2: Language & Scripture Script Preferences
  // --------------------------------------------------------------------------
  Widget _buildStep2LanguageAndScript(bool isDark) {
    const supportedLangs = [
      {'code': 'en', 'label': 'English', 'native': 'English'},
      {'code': 'sa', 'label': 'Sanskrit', 'native': 'संस्कृतम्'},
      {'code': 'te', 'label': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'kn', 'label': 'Kannada', 'native': 'ಕನ್ನಡ'},
      {'code': 'ml', 'label': 'Malayalam', 'native': 'മലയാളം'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Language & Script Preferences',
          style: AppTextStyles.titleMedium(isDark).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Customize your interface language and primary scripture reading script.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 16),

        // Section A: Primary Scripture Script
        Row(
          children: [
            const Icon(Icons.translate, size: 18, color: AppColors.saffronPrimary),
            const SizedBox(width: 8),
            Text(
              'Primary Scripture Display Script',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.goldLight : AppColors.saffronDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Verses and mantras will render in this script by default throughout the reader and prayer screens.',
          style: AppTextStyles.caption(isDark),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ScriptOption.values.map((script) {
            final isSelected = _stagingScript == script;
            return ChoiceChip(
              label: Text('${script.label} (${script.nativeLabel})'),
              selected: isSelected,
              selectedColor: AppColors.saffronPrimary.withAlpha(isDark ? 80 : 35),
              side: BorderSide(
                color: isSelected ? AppColors.saffronPrimary : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
              ),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppColors.goldGlow : AppColors.saffronDark)
                    : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
              ),
              onSelected: (val) {
                if (val) setState(() => _stagingScript = script);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Section B: Interface Language
        Row(
          children: [
            const Icon(Icons.language, size: 18, color: AppColors.goldPrimary),
            const SizedBox(width: 8),
            Text(
              'Interface Language',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? AppColors.goldLight : AppColors.saffronDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'App menus, dashboard labels, and instructions will display in this language.',
          style: AppTextStyles.caption(isDark),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: supportedLangs.map((lang) {
            final isSelected = _stagingLanguage == lang['code'];
            return ChoiceChip(
              label: Text('${lang['label']} (${lang['native']})'),
              selected: isSelected,
              selectedColor: AppColors.goldPrimary.withAlpha(isDark ? 80 : 35),
              side: BorderSide(
                color: isSelected ? AppColors.goldPrimary : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
              ),
              labelStyle: TextStyle(
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected
                    ? (isDark ? AppColors.goldLight : AppColors.goldDark)
                    : (isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary),
              ),
              onSelected: (val) {
                if (val) setState(() => _stagingLanguage = lang['code']!);
              },
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        // Section C: Scholarly Translation Disclaimer
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF8F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.verified_outlined, size: 18, color: AppColors.goldPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Scholarly Translation Charter: Selecting a script does not guarantee every scripture has word-for-word translation in that language. Unverified draft translations are never presented as authoritative doctrine without Section 8 scholar council review.',
                  style: AppTextStyles.caption(isDark).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STEP 3: Daily Sadhana Goals
  // --------------------------------------------------------------------------
  Widget _buildStep3SadhanaGoals(bool isDark) {
    const japaPresets = [11, 21, 27, 54, 108, 111, 1008];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Sadhana & Chanting Goals',
          style: AppTextStyles.titleMedium(isDark).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Set gentle, pressure-free spiritual goals for your daily routine. All goals are optional and can be adjusted anytime.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 16),

        // Goal 1: Japa Repetitions
        Card(
          elevation: 0,
          color: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Mantra Japa Goal', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text(
                    'Target: ${_stagingGoals.japaTarget} repetitions',
                    style: TextStyle(fontSize: 12, color: isDark ? AppColors.goldLight : AppColors.saffronDark),
                  ),
                  value: _stagingGoals.hasJapaGoal,
                  activeThumbColor: AppColors.saffronPrimary,
                  onChanged: (val) {
                    setState(() {
                      _stagingGoals = _stagingGoals.copyWith(hasJapaGoal: val);
                    });
                  },
                ),
                if (_stagingGoals.hasJapaGoal) ...[
                  const Divider(height: 16),
                  Text('Choose Target Repetitions:', style: AppTextStyles.caption(isDark)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      ...japaPresets.map((preset) {
                        final isSelected = !_isCustomJapaSelected && _stagingGoals.japaTarget == preset;
                        return ChoiceChip(
                          label: Text(preset == 108 ? '108 (Mala)' : (preset == 54 ? '54 (Half)' : '$preset')),
                          selected: isSelected,
                          selectedColor: AppColors.saffronPrimary.withAlpha(isDark ? 80 : 40),
                          onSelected: (val) {
                            if (val) {
                              setState(() {
                                _isCustomJapaSelected = false;
                                _stagingGoals = _stagingGoals.copyWith(japaTarget: preset);
                              });
                            }
                          },
                        );
                      }),
                      ChoiceChip(
                        label: const Text('Custom Count'),
                        selected: _isCustomJapaSelected,
                        selectedColor: AppColors.goldPrimary.withAlpha(isDark ? 80 : 40),
                        onSelected: (val) {
                          if (val) {
                            setState(() => _isCustomJapaSelected = true);
                          }
                        },
                      ),
                    ],
                  ),
                  if (_isCustomJapaSelected) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _customJapaController,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: 'Custom Repetitions (1 - 100,000)',
                              isDense: true,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (val) {
                              final count = int.tryParse(val.trim());
                              if (count != null && count > 0 && count <= 100000) {
                                setState(() {
                                  _stagingGoals = _stagingGoals.copyWith(japaTarget: count);
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 12),

        // Goal 2: Daily Puja
        SwitchListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
          ),
          tileColor: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
          secondary: const Icon(Icons.wb_twighlight, color: AppColors.saffronPrimary),
          title: const Text('Daily Puja & Upachara', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('Include domestic morning/evening puja guide in your daily routine', style: TextStyle(fontSize: 12)),
          value: _stagingGoals.hasPujaGoal,
          activeThumbColor: AppColors.saffronPrimary,
          onChanged: (val) => setState(() => _stagingGoals = _stagingGoals.copyWith(hasPujaGoal: val)),
        ),

        const SizedBox(height: 10),

        // Goal 3: Scripture Reading
        Card(
          elevation: 0,
          color: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.auto_stories, color: AppColors.goldPrimary),
                  title: const Text('Daily Scripture Reading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  subtitle: Text('Goal: ${_stagingGoals.scriptureMinutes} minutes daily', style: const TextStyle(fontSize: 12)),
                  value: _stagingGoals.hasScriptureGoal,
                  activeThumbColor: AppColors.saffronPrimary,
                  onChanged: (val) => setState(() => _stagingGoals = _stagingGoals.copyWith(hasScriptureGoal: val)),
                ),
                if (_stagingGoals.hasScriptureGoal) ...[
                  Row(
                    children: [5, 10, 15, 30].map((mins) {
                      final isSelected = _stagingGoals.scriptureMinutes == mins;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text('$mins mins'),
                          selected: isSelected,
                          onSelected: (val) {
                            if (val) setState(() => _stagingGoals = _stagingGoals.copyWith(scriptureMinutes: mins));
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 10),

        // Goal 4: Meditation & Contemplation
        SwitchListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
          ),
          tileColor: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
          secondary: const Icon(Icons.self_improvement, color: AppColors.saffronDark),
          title: const Text('Meditation & Contemplation (Dhyana)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('Quiet reflection or dharana before or after prayers', style: TextStyle(fontSize: 12)),
          value: _stagingGoals.hasMeditationGoal,
          activeThumbColor: AppColors.saffronPrimary,
          onChanged: (val) => setState(() => _stagingGoals = _stagingGoals.copyWith(hasMeditationGoal: val)),
        ),

        const SizedBox(height: 10),

        // Goal 5: Vrat & Observance Tracking
        SwitchListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder, width: 0.8),
          ),
          tileColor: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
          secondary: const Icon(Icons.calendar_month, color: AppColors.goldGlow),
          title: const Text('Vrat & Fasting Observances', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          subtitle: const Text('Track upcoming Ekadashi, Pradosham, and sacred observances', style: TextStyle(fontSize: 12)),
          value: _stagingGoals.hasVratGoal,
          activeThumbColor: AppColors.saffronPrimary,
          onChanged: (val) => setState(() => _stagingGoals = _stagingGoals.copyWith(hasVratGoal: val)),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STEP 4: Panchangam Preferences (Location)
  // --------------------------------------------------------------------------
  Widget _buildStep4PanchangamLocation(bool isDark) {
    final filteredLocations = _citySearchController.text.trim().isEmpty
        ? _curatedLocations
        : _curatedLocations
            .where((loc) => loc.name.toLowerCase().contains(_citySearchController.text.trim().toLowerCase()))
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select Panchangam Location',
          style: AppTextStyles.titleMedium(isDark).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Hindu astronomical timings (sunrise, tithi, nakshatra, Rahu Kalam) depend on geographic location. Select your home city or nearest holy center.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 14),

        // Strict Privacy Banner: No GPS Permission Required
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1B231A) : const Color(0xFFF2F9F0),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? const Color(0xFF2E462B) : const Color(0xFFBCE0B8),
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.shield_outlined, size: 20, color: Color(0xFF388E3C)),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No GPS Tracking Required',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Vedam respects devotee privacy. We never collect or transmit precise device coordinates. Timing calculations use approximate coordinates for the city you select manually below.',
                      style: AppTextStyles.caption(isDark).copyWith(height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Currently Selected Location Card
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C1E14) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.saffronPrimary, width: 1.2),
          ),
          child: Row(
            children: [
              const Icon(Icons.location_on, color: AppColors.saffronPrimary, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Selected Location:',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      _stagingLocation.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.textLightPrimary : AppColors.textDarkPrimary,
                      ),
                    ),
                    Text(
                      'Lat: ${_stagingLocation.latitude.toStringAsFixed(2)}°, Lon: ${_stagingLocation.longitude.toStringAsFixed(2)}° • ${_stagingLocation.timezone}',
                      style: AppTextStyles.caption(isDark),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 16),

        // Search Filter
        TextField(
          controller: _citySearchController,
          decoration: InputDecoration(
            hintText: 'Search holy centers or cities...',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _citySearchController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _citySearchController.clear();
                      setState(() {});
                    },
                  )
                : null,
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
          ),
          onChanged: (_) => setState(() {}),
        ),

        const SizedBox(height: 12),

        // Curated City List
        if (_isLoadingLocations)
          const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator()))
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: filteredLocations.length,
            itemBuilder: (context, index) {
              final loc = filteredLocations[index];
              final isSelected = _stagingLocation.name == loc.name;

              return ListTile(
                dense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                leading: Icon(
                  isSelected ? Icons.check_circle : Icons.location_city,
                  color: isSelected ? AppColors.saffronPrimary : (isDark ? AppColors.textLightMuted : AppColors.textDarkMuted),
                  size: 20,
                ),
                title: Text(
                  loc.name,
                  style: TextStyle(
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                    color: isSelected ? AppColors.saffronPrimary : null,
                  ),
                ),
                subtitle: Text(
                  '${loc.latitude.toStringAsFixed(2)}°N, ${loc.longitude.toStringAsFixed(2)}°E (${loc.timezone})',
                  style: const TextStyle(fontSize: 11),
                ),
                onTap: () {
                  setState(() => _stagingLocation = loc);
                },
              );
            },
          ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STEP 5: Devotional Reminders (Opt-in local notifications)
  // --------------------------------------------------------------------------
  Widget _buildStep5Reminders(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Daily Devotional Reminders',
          style: AppTextStyles.titleMedium(isDark).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Receive gentle, local reminders for morning prayer and evening sandhya. You can change or disable these anytime.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 16),

        // Big Toggle Card
        Card(
          elevation: 0,
          color: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: BorderSide(
              color: _stagingReminders ? AppColors.saffronPrimary : (isDark ? AppColors.nightBorder : AppColors.chandanBorder),
              width: _stagingReminders ? 1.6 : 0.8,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _stagingReminders
                          ? AppColors.saffronPrimary.withAlpha(isDark ? 80 : 30)
                          : (isDark ? Colors.black26 : AppColors.creamBackground),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.notifications_active,
                      color: _stagingReminders ? AppColors.saffronPrimary : Colors.grey,
                      size: 24,
                    ),
                  ),
                  title: const Text('Enable Devotional Reminders', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  subtitle: const Text('Local device notifications only • No cloud sync', style: TextStyle(fontSize: 12)),
                  value: _stagingReminders,
                  activeThumbColor: AppColors.saffronPrimary,
                  onChanged: (val) {
                    setState(() => _stagingReminders = val);
                  },
                ),
                if (_stagingReminders) ...[
                  const Divider(height: 20),
                  _buildReminderPreviewItem(
                    isDark,
                    Icons.wb_sunny_outlined,
                    'Prātah Smaraṇam (Morning Prayer)',
                    '6:00 AM • Daily invocation, Gayatri, and domestic puja',
                  ),
                  const SizedBox(height: 10),
                  _buildReminderPreviewItem(
                    isDark,
                    Icons.nights_stay_outlined,
                    'Sāndhya Vandanā (Evening Prayer)',
                    '6:30 PM • Sunset prayer, mantra japa, and stillness',
                  ),
                ],
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Transparent Permission Notice
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFFBF8F2),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: isDark ? AppColors.nightBorder : AppColors.chandanBorder,
              width: 0.8,
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.info_outline, size: 18, color: AppColors.goldPrimary),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Permission Transparency: System notification permission is requested only if you leave reminders enabled and click Continue. Notifications are scheduled locally by your operating system without external servers.',
                  style: AppTextStyles.caption(isDark).copyWith(height: 1.4),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReminderPreviewItem(bool isDark, IconData icon, String title, String subtitle) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppColors.goldPrimary),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              Text(subtitle, style: AppTextStyles.caption(isDark)),
            ],
          ),
        ),
      ],
    );
  }

  // --------------------------------------------------------------------------
  // STEP 6: Review & Finish
  // --------------------------------------------------------------------------
  Widget _buildStep6ReviewAndFinish(bool isDark) {
    final selectedDeityList = _stagingDeityIds
        .map((id) => DevotionalDeity.getById(id))
        .whereType<DevotionalDeity>()
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Review Your Spiritual Preferences',
          style: AppTextStyles.titleMedium(isDark).copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          'Here is a summary of your personal configuration. You can change any of these at any time in Settings.',
          style: AppTextStyles.bodySmall(isDark),
        ),
        const SizedBox(height: 16),

        // Summary Card: Devotional Interests
        _buildReviewCard(
          isDark,
          title: 'Devotional Focus',
          icon: Icons.temple_hindu,
          onEdit: () => setState(() => _currentStep = 1),
          content: Wrap(
            spacing: 6,
            runSpacing: 6,
            children: selectedDeityList.map((d) {
              return Chip(
                avatar: Icon(d.icon, size: 16, color: AppColors.saffronPrimary),
                label: Text(d.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                backgroundColor: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                side: BorderSide(color: isDark ? AppColors.nightBorder : AppColors.chandanBorder),
              );
            }).toList(),
          ),
        ),

        const SizedBox(height: 12),

        // Summary Card: Language & Script
        _buildReviewCard(
          isDark,
          title: 'Language & Script',
          icon: Icons.translate,
          onEdit: () => setState(() => _currentStep = 2),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Scripture Script: ${_stagingScript.label} (${_stagingScript.nativeLabel})', style: const TextStyle(fontSize: 13)),
              const SizedBox(height: 2),
              Text('Interface Language: ${_stagingLanguage.toUpperCase()}', style: AppTextStyles.caption(isDark)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Summary Card: Daily Sadhana Goals
        _buildReviewCard(
          isDark,
          title: 'Daily Sadhana Goals',
          icon: Icons.self_improvement,
          onEdit: () => setState(() => _currentStep = 3),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_stagingGoals.hasJapaGoal)
                Text('• Japa Repetitions: ${_stagingGoals.japaTarget} per session', style: const TextStyle(fontSize: 12)),
              if (_stagingGoals.hasPujaGoal)
                const Text('• Daily Puja & Upachara included', style: TextStyle(fontSize: 12)),
              if (_stagingGoals.hasScriptureGoal)
                Text('• Scripture Reading: ${_stagingGoals.scriptureMinutes} minutes daily', style: const TextStyle(fontSize: 12)),
              if (_stagingGoals.hasMeditationGoal)
                Text('• Meditation: ${_stagingGoals.meditationMinutes} minutes daily', style: const TextStyle(fontSize: 12)),
              if (_stagingGoals.hasVratGoal)
                const Text('• Vrat & fasting day tracking active', style: TextStyle(fontSize: 12)),
            ],
          ),
        ),

        const SizedBox(height: 12),

        // Summary Card: Panchangam Location
        _buildReviewCard(
          isDark,
          title: 'Panchangam Location',
          icon: Icons.location_on,
          onEdit: () => setState(() => _currentStep = 4),
          content: Text(
            '${_stagingLocation.name}\n${_stagingLocation.timezone} (Manually selected)',
            style: const TextStyle(fontSize: 12),
          ),
        ),

        const SizedBox(height: 12),

        // Summary Card: Reminders
        _buildReviewCard(
          isDark,
          title: 'Reminders & Notifications',
          icon: Icons.notifications,
          onEdit: () => setState(() => _currentStep = 5),
          content: Text(
            _stagingReminders ? 'Enabled: Morning (6:00 AM) & Evening (6:30 PM)' : 'Disabled / Opted out (silent)',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: _stagingReminders ? (isDark ? AppColors.goldLight : AppColors.saffronDark) : Colors.grey,
            ),
          ),
        ),

        const SizedBox(height: 20),

        // Completion Invocation Shloka
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF2C1E14) : const Color(0xFFFFF7ED),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.saffronPrimary, width: 1.0),
          ),
          child: Column(
            children: [
              const Text(
                'सर्वे भवन्तु सुखिनः सर्वे सन्तु निरामयाः ।\nसर्वे भद्राणि पश्यन्तु मा कश्चिद्दुःखभाग्भवेत् ॥',
                style: TextStyle(
                  fontFamily: 'serif',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: AppColors.saffronPrimary,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                'May all beings be peaceful, happy, and free from suffering.',
                style: AppTextStyles.caption(isDark),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewCard(
    bool isDark, {
    required String title,
    required IconData icon,
    required Widget content,
    required VoidCallback onEdit,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurfaceElevated : AppColors.ivorySurface,
        borderRadius: BorderRadius.circular(12),
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
              Row(
                children: [
                  Icon(icon, size: 18, color: AppColors.saffronPrimary),
                  const SizedBox(width: 8),
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                    ),
                  ),
                ],
              ),
              InkWell(
                onTap: onEdit,
                borderRadius: BorderRadius.circular(6),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.edit, size: 12, color: isDark ? AppColors.goldLight : AppColors.saffronPrimary),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldLight : AppColors.saffronPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
