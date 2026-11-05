import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/models/devotee_preferences.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../data/repositories/panchangam_repository.dart';
import '../../../state/app_state.dart';
import '../../../state/audio_state.dart';
import '../../../state/panchangam_state.dart';
import '../../../state/personalization_state.dart';
import '../../../state/sadhana_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/script_selector_modal.dart';
import '../../widgets/section_header.dart';
import '../onboarding/onboarding_wizard_screen.dart';
import '../panchangam/widgets/location_selector_modal.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;
  final PersonalizationState? personalizationState;
  final PanchangamState? panchangamState;
  final PanchangamRepository? panchangamRepository;
  final AudioState? audioState;
  final SadhanaState? sadhanaState;

  const SettingsScreen({
    super.key,
    required this.appState,
    this.personalizationState,
    this.panchangamState,
    this.panchangamRepository,
    this.audioState,
    this.sadhanaState,
  });

  void _showDevotionalInterestsDialog(BuildContext context, PersonalizationState pz, bool isDark) {
    final selectedIds = Set<String>.from(pz.selectedDeityIds);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
              title: Row(
                children: [
                  const Icon(Icons.temple_hindu, color: AppColors.saffronPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text('Devotional Focus', style: AppTextStyles.titleMedium(isDark)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: DevotionalDeity.allDeities.length,
                  itemBuilder: (context, index) {
                    final deity = DevotionalDeity.allDeities[index];
                    final isChecked = selectedIds.contains(deity.id);

                    return CheckboxListTile(
                      dense: true,
                      value: isChecked,
                      activeColor: AppColors.saffronPrimary,
                      secondary: Icon(deity.icon, size: 20, color: isChecked ? AppColors.saffronPrimary : Colors.grey),
                      title: Text(deity.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text(deity.sanskritName, style: TextStyle(fontSize: 11, color: isDark ? AppColors.goldLight : AppColors.goldDark)),
                      onChanged: (val) {
                        setDialogState(() {
                          if (val == true) {
                            selectedIds.add(deity.id);
                          } else if (selectedIds.length > 1) {
                            selectedIds.remove(deity.id);
                          }
                        });
                      },
                    );
                  },
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    pz.setDevotionalInterests(selectedIds);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Focus'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showSadhanaGoalsDialog(BuildContext context, PersonalizationState pz, bool isDark) {
    var goals = pz.sadhanaGoals;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
              title: Row(
                children: [
                  const Icon(Icons.self_improvement, color: AppColors.goldPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text('Daily Sadhana Targets', style: AppTextStyles.titleMedium(isDark)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SwitchListTile(
                      dense: true,
                      title: const Text('Daily Puja', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: goals.hasPujaGoal,
                      activeThumbColor: AppColors.saffronPrimary,
                      onChanged: (val) => setDialogState(() => goals = goals.copyWith(hasPujaGoal: val)),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Scripture Reading', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      subtitle: Text('${goals.scriptureMinutes} minutes daily'),
                      value: goals.hasScriptureGoal,
                      activeThumbColor: AppColors.saffronPrimary,
                      onChanged: (val) => setDialogState(() => goals = goals.copyWith(hasScriptureGoal: val)),
                    ),
                    if (goals.hasScriptureGoal)
                      Wrap(
                        spacing: 6,
                        children: [5, 10, 15, 30].map((mins) {
                          final isSel = goals.scriptureMinutes == mins;
                          return ChoiceChip(
                            label: Text('$mins m', style: const TextStyle(fontSize: 11)),
                            selected: isSel,
                            onSelected: (val) {
                              if (val) setDialogState(() => goals = goals.copyWith(scriptureMinutes: mins));
                            },
                          );
                        }).toList(),
                      ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Meditation / Dhyana', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: goals.hasMeditationGoal,
                      activeThumbColor: AppColors.saffronPrimary,
                      onChanged: (val) => setDialogState(() => goals = goals.copyWith(hasMeditationGoal: val)),
                    ),
                    SwitchListTile(
                      dense: true,
                      title: const Text('Vrat & Fasting Tracking', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      value: goals.hasVratGoal,
                      activeThumbColor: AppColors.saffronPrimary,
                      onChanged: (val) => setDialogState(() => goals = goals.copyWith(hasVratGoal: val)),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    pz.setSadhanaGoals(goals);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Targets'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showJapaTargetDialog(BuildContext context, PersonalizationState pz, bool isDark) {
    const presets = [11, 21, 27, 54, 108, 111, 1008];
    int selected = pz.japaTarget;
    final customController = TextEditingController(text: selected.toString());
    bool isCustom = !presets.contains(selected);

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
              title: Row(
                children: [
                  const Icon(Icons.repeat, color: AppColors.saffronPrimary, size: 20),
                  const SizedBox(width: 8),
                  Text('Preferred Japa Target', style: AppTextStyles.titleMedium(isDark)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Select your primary chanting target for Japa sessions:', style: TextStyle(fontSize: 12)),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        ...presets.map((p) {
                          final isSel = !isCustom && selected == p;
                          return ChoiceChip(
                            label: Text(p == 108 ? '108 (Mala)' : (p == 54 ? '54 (Half)' : '$p')),
                            selected: isSel,
                            selectedColor: AppColors.saffronPrimary.withAlpha(isDark ? 80 : 40),
                            onSelected: (val) {
                              if (val) {
                                setDialogState(() {
                                  isCustom = false;
                                  selected = p;
                                });
                              }
                            },
                          );
                        }),
                        ChoiceChip(
                          label: const Text('Custom'),
                          selected: isCustom,
                          selectedColor: AppColors.goldPrimary.withAlpha(isDark ? 80 : 40),
                          onSelected: (val) {
                            if (val) setDialogState(() => isCustom = true);
                          },
                        ),
                      ],
                    ),
                    if (isCustom) ...[
                      const SizedBox(height: 12),
                      TextField(
                        controller: customController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Custom Count (1 - 100,000)',
                          isDense: true,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        ),
                        onChanged: (val) {
                          final count = int.tryParse(val.trim());
                          if (count != null && count > 0 && count <= 100000) {
                            selected = count;
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.saffronPrimary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () {
                    pz.setJapaTarget(selected);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Save Target'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showLanguageDialog(BuildContext context, PersonalizationState pz, bool isDark) {
    const supportedLangs = [
      {'code': 'en', 'label': 'English', 'native': 'English'},
      {'code': 'sa', 'label': 'Sanskrit', 'native': 'संस्कृतम्'},
      {'code': 'te', 'label': 'Telugu', 'native': 'తెలుగు'},
      {'code': 'ta', 'label': 'Tamil', 'native': 'தமிழ்'},
      {'code': 'kn', 'label': 'Kannada', 'native': 'ಕನ್ನಡ'},
      {'code': 'ml', 'label': 'Malayalam', 'native': 'മലയാളം'},
    ];

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
          title: Text('Interface Language', style: AppTextStyles.titleMedium(isDark)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: supportedLangs.map((lang) {
              final isSel = pz.interfaceLanguage == lang['code'];
              return ListTile(
                dense: true,
                leading: Icon(isSel ? Icons.check_circle : Icons.language, size: 20, color: isSel ? AppColors.goldPrimary : Colors.grey),
                title: Text(lang['label']!, style: TextStyle(fontWeight: isSel ? FontWeight.bold : FontWeight.normal)),
                subtitle: Text(lang['native']!, style: const TextStyle(fontSize: 11)),
                onTap: () {
                  pz.setInterfaceLanguage(lang['code']!);
                  Navigator.pop(ctx);
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _showResetConfirmationDialog(BuildContext context, PersonalizationState pz, bool isDark) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? AppColors.nightSurface : AppColors.ivorySurface,
          title: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: AppColors.saffronDark, size: 22),
              const SizedBox(width: 8),
              Text('Reset Personalization?', style: AppTextStyles.titleMedium(isDark)),
            ],
          ),
          content: const Text(
            'This will reset your devotional focus deities, daily targets, and location back to defaults.\n\n'
            'Your saved scripture bookmarks, reading progress, Japa Mala chanting history, and personal Vrat observances will NOT be erased.',
            style: TextStyle(fontSize: 13, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.saffronDark,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await pz.resetPersonalization();
                if (ctx.mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Personalization preferences reset to defaults.')),
                  );
                }
              },
              child: const Text('Reset Preferences'),
            ),
          ],
        );
      },
    );
  }

  void _restartOnboarding(BuildContext context, PersonalizationState pz) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingWizardScreen(
          personalizationState: pz,
          panchangamRepository: panchangamRepository,
          onFinish: () => Navigator.pop(context),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final pz = personalizationState ??
        PersonalizationState(
          appState: appState,
          panchangamState: panchangamState,
          audioState: audioState,
        );

    final listenables = <Listenable>[appState, pz];

    return ListenableBuilder(
      listenable: Listenable.merge(listenables),
      builder: (context, _) {
        final goals = pz.sadhanaGoals;
        final selectedDeityNames = pz.selectedDeities.map((d) => d.name).join(', ');

        return Scaffold(
          appBar: const SacredAppBar(
            title: 'Settings',
            subtitle: 'विन्यासः एवं विवरणम्',
            showLogo: false,
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              // 1. Reading & Script Preferences
              SectionHeader(
                title: 'Reading & Script (लिपि)',
                subtitle: 'Customize script and typography for chanting and contemplation',
              ),
              Card(
                child: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.translate, color: AppColors.saffronPrimary),
                      title: const Text('Primary Scripture Script'),
                      subtitle: Text(
                        '${appState.activeScript.label} (${appState.activeScript.nativeLabel})',
                        style: TextStyle(
                          color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        ScriptSelectorModal.show(
                          context,
                          currentScript: appState.activeScript,
                          onScriptSelected: (s) {
                            appState.setActiveScript(s);
                            pz.setScriptureScript(s);
                          },
                        );
                      },
                    ),
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.format_size, color: AppColors.goldPrimary),
                      title: const Text('Text Size Scale'),
                      subtitle: Text('${appState.textScalePreference.label} (${(appState.fontScale * 100).toInt()}%)'),
                      trailing: DropdownButton<TextScalePreference>(
                        value: appState.textScalePreference,
                        underline: const SizedBox(),
                        items: TextScalePreference.values.map((p) {
                          return DropdownMenuItem(
                            value: p,
                            child: Text(p.label, style: const TextStyle(fontSize: 13)),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) appState.setTextScalePreference(val);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // 2. Appearance & Devotional Theme
              SectionHeader(
                title: 'Devotional Atmosphere',
                subtitle: 'Sacred Light & Temple Night aesthetics',
              ),
              Card(
                child: RadioGroup<ThemePreference>(
                  groupValue: appState.themePreference,
                  onChanged: (val) {
                    if (val != null) appState.setThemePreference(val);
                  },
                  child: Column(
                    children: ThemePreference.values.map((theme) {
                      final isSelected = theme == appState.themePreference;
                      return RadioListTile<ThemePreference>(
                        value: theme,
                        activeColor: AppColors.saffronPrimary,
                        title: Text(
                          theme.label,
                          style: TextStyle(
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),

              // 3. Personalization & Practices Section
              SectionHeader(
                title: 'Personalization & Practices (अभ्यास एवं रुचि)',
                subtitle: 'Deity focus, daily sadhana targets, and sacred routine preferences',
              ),
              Card(
                child: Column(
                  children: [
                    // A. Devotional Focus
                    ListTile(
                      leading: const Icon(Icons.temple_hindu, color: AppColors.saffronPrimary),
                      title: const Text('Devotional Focus (इष्टदेवता)'),
                      subtitle: Text(
                        selectedDeityNames.isEmpty ? 'Universal Practice' : selectedDeityNames,
                        style: TextStyle(
                          color: isDark ? AppColors.goldLight : AppColors.saffronDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showDevotionalInterestsDialog(context, pz, isDark),
                    ),
                    const Divider(height: 1),

                    // B. Daily Sadhana Goals
                    ListTile(
                      leading: const Icon(Icons.self_improvement, color: AppColors.goldPrimary),
                      title: const Text('Daily Sadhana Targets'),
                      subtitle: Text(
                        'Japa: ${goals.japaTarget} • Puja: ${goals.hasPujaGoal ? "On" : "Off"} • Reading: ${goals.hasScriptureGoal ? "${goals.scriptureMinutes}m" : "Off"}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showSadhanaGoalsDialog(context, pz, isDark),
                    ),
                    const Divider(height: 1),

                    // C. Preferred Japa Target
                    ListTile(
                      leading: const Icon(Icons.repeat, color: AppColors.saffronPrimary),
                      title: const Text('Preferred Japa Target'),
                      subtitle: Text(
                        '${pz.japaTarget} repetitions (${pz.japaTarget == 108 ? "One Mala" : (pz.japaTarget == 54 ? "Half Mala" : "Session Target")})',
                        style: TextStyle(
                          color: isDark ? AppColors.goldLight : AppColors.goldDark,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showJapaTargetDialog(context, pz, isDark),
                    ),
                    const Divider(height: 1),

                    // D. Panchangam Location
                    ListTile(
                      leading: const Icon(Icons.location_on_outlined, color: AppColors.goldPrimary),
                      title: const Text('Panchangam Location'),
                      subtitle: Text(
                        pz.panchangamLocation.name,
                        style: const TextStyle(fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () {
                        final repo = panchangamRepository ?? PanchangamRepositoryImpl();
                        LocationSelectorModal.show(
                          context: context,
                          currentLocation: pz.panchangamLocation,
                          repository: repo,
                          onLocationSelected: (loc) => pz.setPanchangamLocation(loc),
                        );
                      },
                    ),
                    const Divider(height: 1),

                    // E. Devotional Reminders Toggle
                    SwitchListTile(
                      secondary: Icon(
                        pz.remindersEnabled ? Icons.notifications_active : Icons.notifications_off_outlined,
                        color: pz.remindersEnabled ? AppColors.saffronPrimary : Colors.grey,
                      ),
                      title: const Text('Devotional Reminders', style: TextStyle(fontSize: 14)),
                      subtitle: Text(
                        pz.remindersEnabled ? 'Morning (6:00 AM) & Evening (6:30 PM)' : 'Disabled (Local only)',
                        style: const TextStyle(fontSize: 12),
                      ),
                      value: pz.remindersEnabled,
                      activeThumbColor: AppColors.saffronPrimary,
                      onChanged: (val) async {
                        final success = await pz.setRemindersEnabled(val);
                        if (!success && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Notifications permission was denied by device.')),
                          );
                        }
                      },
                    ),
                    const Divider(height: 1),

                    // F. Interface Language
                    ListTile(
                      leading: const Icon(Icons.language, color: AppColors.goldPrimary),
                      title: const Text('Interface Language'),
                      subtitle: Text(
                        pz.interfaceLanguage.toUpperCase(),
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _showLanguageDialog(context, pz, isDark),
                    ),
                    const Divider(height: 1),

                    // G. Restart Onboarding
                    ListTile(
                      leading: const Icon(Icons.restart_alt, color: AppColors.saffronDark),
                      title: const Text('Restart Devotee Onboarding'),
                      subtitle: const Text('Re-run the step-by-step setup wizard', style: TextStyle(fontSize: 12)),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 14),
                      onTap: () => _restartOnboarding(context, pz),
                    ),
                    const Divider(height: 1),

                    // H. Reset Personalization Preferences
                    ListTile(
                      leading: const Icon(Icons.restore, color: Colors.redAccent),
                      title: const Text('Reset Personalization Preferences', style: TextStyle(fontSize: 13, color: Colors.redAccent)),
                      subtitle: const Text('Restores default focus & goals without deleting bookmarks or history', style: TextStyle(fontSize: 11)),
                      onTap: () => _showResetConfirmationDialog(context, pz, isDark),
                    ),
                  ],
                ),
              ),

              // 4. Multilingual Translation Notice
              SectionHeader(
                title: 'Multilingual Architecture',
                subtitle: 'Regional translations and scholarly accreditation tiers',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.verified_outlined, size: 18, color: AppColors.goldPrimary),
                          const SizedBox(width: 8),
                          Text(
                            'Authentic Governance Policy',
                            style: AppTextStyles.titleSmall(isDark),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Vedam supports multi-script phonetics across Sanskrit, Telugu, Tamil, Kannada, and Malayalam. Full verse meanings in Eighth Schedule languages are rolled out progressively under Section 8 scholar council review. Unverified translations are never presented as authoritative doctrine.',
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                    ],
                  ),
                ),
              ),

              // 5. About Vedam & Governance
              SectionHeader(
                title: 'About Vedam',
                subtitle: 'Vision, scholarly charter, and preservation standards',
              ),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppColors.saffronPrimary, AppColors.goldPrimary],
                              ),
                            ),
                            child: const Center(
                              child: Text(
                                'ॐ',
                                style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${AppConstants.appName} • ${AppConstants.appSanskritName}',
                                style: AppTextStyles.titleMedium(isDark),
                              ),
                              Text(
                                AppConstants.appVersion,
                                style: AppTextStyles.caption(isDark),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        AppConstants.aboutAppDescription,
                        style: AppTextStyles.bodySmall(isDark),
                      ),
                      const Divider(height: 24),
                      Text(
                        'Section 8 Authentic Editorial Governance:',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldGlow : AppColors.saffronDark,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        AppConstants.section8NoticeBody,
                        style: AppTextStyles.caption(isDark).copyWith(height: 1.45),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
