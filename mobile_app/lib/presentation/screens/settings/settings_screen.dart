import 'package:flutter/material.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/models/app_settings.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../state/app_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/script_selector_modal.dart';
import '../../widgets/section_header.dart';

class SettingsScreen extends StatelessWidget {
  final AppState appState;

  const SettingsScreen({super.key, required this.appState});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ListenableBuilder(
      listenable: appState,
      builder: (context, _) {
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
                          onScriptSelected: (s) => appState.setActiveScript(s),
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

              // 3. Multilingual Translation Notice
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

              // 4. About Vedam & Governance
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
