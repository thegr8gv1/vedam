import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/text_styles.dart';
import '../../../state/app_state.dart';
import '../../widgets/sacred_app_bar.dart';
import '../../widgets/section_header.dart';

class SadhanaScreen extends StatefulWidget {
  final AppState appState;
  final VoidCallback? onOpenMantras;
  final VoidCallback? onOpenPanchangam;

  const SadhanaScreen({
    super.key,
    required this.appState,
    this.onOpenMantras,
    this.onOpenPanchangam,
  });

  @override
  State<SadhanaScreen> createState() => _SadhanaScreenState();
}

class _SadhanaScreenState extends State<SadhanaScreen> {
  int _japaCount = 0;
  final int _targetJapa = 108;

  void _incrementJapa() {
    setState(() {
      if (_japaCount < _targetJapa) {
        _japaCount++;
      }
    });
  }

  void _resetJapa() {
    setState(() {
      _japaCount = 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: SacredAppBar(
        title: 'Daily Sadhana',
        subtitle: 'नित्य पूजा एवं साधना',
        showLogo: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.onOpenMantras != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.saffronPrimary.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                  child: InkWell(
                    onTap: widget.onOpenMantras,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.saffronPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.music_note, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Mantra Library & Audio Japa',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Chant with 455 Master Recordings & 108 Beads',
                                  style: AppTextStyles.caption(isDark),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.saffronPrimary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (widget.onOpenPanchangam != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                child: Card(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: AppColors.goldPrimary.withAlpha(120),
                      width: 1,
                    ),
                  ),
                  color: isDark ? AppColors.nightSurfaceElevated : AppColors.creamBackground,
                  child: InkWell(
                    onTap: widget.onOpenPanchangam,
                    borderRadius: BorderRadius.circular(16),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.goldPrimary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.wb_sunny_outlined, color: Colors.white, size: 24),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Daily Panchangam & Muhurtas',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Location-Aware Tithi, Nakshatra & Rahu Kalam',
                                  style: AppTextStyles.caption(isDark),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.goldPrimary),
                        ],
                      ),
                    ),
                  ),
                ),
              ),


            // 1. Japa Mala Counter Card
            Card(
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
                side: BorderSide(
                  color: isDark ? AppColors.goldDark.withValues(alpha: 0.5) : AppColors.goldPrimary.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.circle_outlined, size: 16, color: AppColors.saffronPrimary),
                            const SizedBox(width: 8),
                            Text(
                              'DIGITAL JAPA MALA COUNTER',
                              style: AppTextStyles.metadataTag(isDark).copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ],
                        ),
                        IconButton(
                          icon: const Icon(Icons.refresh, size: 20),
                          tooltip: 'Reset Counter',
                          onPressed: _resetJapa,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$_japaCount',
                      style: TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.goldGlow : AppColors.saffronPrimary,
                      ),
                    ),
                    Text(
                      'Target: $_targetJapa Repetitions',
                      style: AppTextStyles.caption(isDark).copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: _japaCount / _targetJapa,
                      backgroundColor: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF0EAE1),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.saffronPrimary),
                      borderRadius: BorderRadius.circular(8),
                      minHeight: 8,
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.fingerprint),
                        label: const Text(
                          'CHANT & COUNT BEAD',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.saffronPrimary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        onPressed: _incrementJapa,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // 2. Daily Worship Practices
            SectionHeader(
              title: 'Nitya Karma (Daily Practice)',
              subtitle: 'Traditional liturgical disciplines for devotees',
            ),

            _PracticeCard(
              title: 'Prātah Smaraṇam (Morning Remembrance)',
              sanskrit: 'कराग्रे वसते लक्ष्मीः करमध्ये सरस्वती । करमूले तु गोविन्दः प्रभाते करदर्शनम् ॥',
              description: 'Recited upon waking before placing feet upon the earth, seeking forgiveness from Mother Earth.',
              icon: Icons.wb_twilight,
              isDark: isDark,
            ),

            _PracticeCard(
              title: 'Gayatri Mahamantra Japa',
              sanskrit: 'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥',
              description: 'The supreme Vedic illumination mantra for mental clarity, spiritual vitality, and intellect.',
              icon: Icons.wb_sunny_outlined,
              isDark: isDark,
            ),

            _PracticeCard(
              title: 'Daily Sankalpam Overview',
              sanskrit: 'मम आत्मनः श्रुतिस्मृतिपुराणोक्त फलप्राप्त्यर्थं...',
              description: 'Setting sacred consecrated intention before performing prayer, meditation, or scripture study.',
              icon: Icons.spa_outlined,
              isDark: isDark,
            ),

            _PracticeCard(
              title: 'Shanti Patha (Universal Peace)',
              sanskrit: 'ॐ द्यौः शान्तिरन्तरिक्षं शान्तिः पृथिवी शान्तिरापः शान्तिरोषधयः शान्तिः...',
              description: 'Vedic prayer for peace in the cosmos, atmosphere, earth, waters, herbs, and all beings.',
              icon: Icons.public,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }
}

class _PracticeCard extends StatelessWidget {
  final String title;
  final String sanskrit;
  final String description;
  final IconData icon;
  final bool isDark;

  const _PracticeCard({
    required this.title,
    required this.sanskrit,
    required this.description,
    required this.icon,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 20, color: AppColors.saffronPrimary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTextStyles.titleSmall(isDark),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurfaceElevated : const Color(0xFFF9F5EE),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                sanskrit,
                style: AppTextStyles.verseDevanagari(isDark, scale: 0.85),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              style: AppTextStyles.bodySmall(isDark),
            ),
          ],
        ),
      ),
    );
  }
}
