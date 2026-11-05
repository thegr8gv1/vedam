import '../../core/models/vrat_observance.dart';
import '../../core/models/devotional_reminder.dart';

/// Pre-curated, non-prescriptive Vrat and Observance templates.
/// These serve as respectful starting points for personal devotional planning,
/// fully acknowledging that fasting rules and traditions vary widely by sampradaya.
class DefaultVratTemplatesData {
  static VratObservance createTemplate(
    VratType type, {
    required String targetDate,
    required String location,
    CalendarConvention convention = CalendarConvention.traditionalRegional,
    VratPanchangamSnapshot? panchangamSnapshot,
  }) {
    final timestamp = DateTime.now().toIso8601String();
    final dateClean = targetDate.replaceAll('-', '');

    switch (type) {
      case VratType.ekadashi:
        return VratObservance(
          id: 'vrat_${dateClean}_ekadashi',
          type: VratType.ekadashi,
          title: 'Ekadashi Devotional Vrat',
          sanskritTitle: 'एकादशी व्रतम्',
          targetDate: targetDate,
          location: location,
          tradition: 'Vaishnava / Smartha',
          calendarConvention: convention,
          personalIntention: 'Cultivating Sattvic tranquility, mental clarity, and divine remembrance.',
          associatedPujaGuideId: 'guide_vishnu_puja',
          associatedMantraId: 'VEDA-MTR-0378',
          panchangamSnapshot: panchangamSnapshot,
          createdAt: timestamp,
          checklist: const [
            VratChecklistItem(
              id: 'chk_eka_prep',
              title: 'Dashami evening: Light meal, restful sleep, and quiet mental resolution.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_eka_altar',
              title: 'Clean the prayer altar and arrange fresh water and Tulasi leaves.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_eka_fasting',
              title: 'Sattvic simplicity: water/fruits or fasting suited to personal health.',
              category: 'fasting',
            ),
            VratChecklistItem(
              id: 'chk_eka_puja',
              title: 'Offer Vishnu Pancha Upachara Puja or chant Narayana mantras.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_eka_study',
              title: 'Scriptural reflection: read a passage from the Bhagavad Gita.',
              category: 'contemplation',
            ),
            VratChecklistItem(
              id: 'chk_eka_parana',
              title: 'Dvadashi morning: Conclude with prayer and mindful meal (Parana).',
              category: 'ritual',
            ),
          ],
        );

      case VratType.pradosham:
        return VratObservance(
          id: 'vrat_${dateClean}_pradosham',
          type: VratType.pradosham,
          title: 'Pradosha Vrat (Twilight Adoration)',
          sanskritTitle: 'प्रदोष व्रतम्',
          targetDate: targetDate,
          location: location,
          tradition: 'Shaiva Grihya',
          calendarConvention: convention,
          personalIntention: 'Inner purification, releasing stress, and resting in the stillness of Shiva.',
          associatedPujaGuideId: 'guide_shiva_puja',
          associatedMantraId: 'VEDA-MTR-0429',
          panchangamSnapshot: panchangamSnapshot,
          createdAt: timestamp,
          checklist: const [
            VratChecklistItem(
              id: 'chk_pra_mind',
              title: 'Mindful daytime: Peaceful conduct, restraint in speech and ego.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_pra_materials',
              title: 'Gather sacred ash (Bhasma), Bilva leaf, and clean water.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_pra_twilight',
              title: 'Pradosha twilight (Godhuli): bathe and light the household lamp.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_pra_japa',
              title: 'Chant Om Namah Shivaya or Maha Mrityunjaya with steady breathing.',
              category: 'contemplation',
            ),
            VratChecklistItem(
              id: 'chk_pra_prasadam',
              title: 'Conclude with heartfelt prostration and simple Sattvic food.',
              category: 'fasting',
            ),
          ],
        );

      case VratType.purnima:
        return VratObservance(
          id: 'vrat_${dateClean}_purnima',
          type: VratType.purnima,
          title: 'Purnima Gratitude & Adoration',
          sanskritTitle: 'पूर्णिमा व्रतम्',
          targetDate: targetDate,
          location: location,
          tradition: 'Smartha / Universal',
          calendarConvention: convention,
          personalIntention: 'Gratitude for divine abundance, spiritual radiance, and benevolence.',
          associatedPujaGuideId: 'guide_lakshmi_puja',
          associatedMantraId: 'VEDA-MTR-0415',
          panchangamSnapshot: panchangamSnapshot,
          createdAt: timestamp,
          checklist: const [
            VratChecklistItem(
              id: 'chk_pur_morning',
              title: 'Morning prayer: welcome the full moon day with fresh flowers and clean light.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_pur_dana',
              title: 'Selfless charity: share food, aid, or kindness with others in need.',
              category: 'contemplation',
            ),
            VratChecklistItem(
              id: 'chk_pur_puja',
              title: 'Perform Sri Mahalakshmi Prarthana or Satyanarayana contemplation.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_pur_moon',
              title: 'Evening silence: meditate under the luminous full moon.',
              category: 'contemplation',
            ),
          ],
        );

      case VratType.amavasya:
        return VratObservance(
          id: 'vrat_${dateClean}_amavasya',
          type: VratType.amavasya,
          title: 'Amavasya Pitru Smriti & Peace',
          sanskritTitle: 'अमावस्या शान्ति स्मरणम्',
          targetDate: targetDate,
          location: location,
          tradition: 'Universal / Pitru Smriti',
          calendarConvention: convention,
          personalIntention: 'Honoring ancestors, seeking universal peace, and cultivating humble introspection.',
          associatedPujaGuideId: 'guide_morning_prayer',
          associatedMantraId: 'VEDA-MTR-0448',
          panchangamSnapshot: panchangamSnapshot,
          createdAt: timestamp,
          checklist: const [
            VratChecklistItem(
              id: 'chk_ama_morning',
              title: 'Quiet morning awakening: offer gratitude for the lineage of life.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_ama_tarpan',
              title: 'Silent prayer or water offering for the peace of departed souls.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_ama_service',
              title: 'Compassion in action: feed birds, animals, or help those in need.',
              category: 'contemplation',
            ),
            VratChecklistItem(
              id: 'chk_ama_shanti',
              title: 'Chant universal peace mantra (Om Shanti Shanti Shanti).',
              category: 'contemplation',
            ),
          ],
        );

      case VratType.sankashtiChaturthi:
        return VratObservance(
          id: 'vrat_${dateClean}_sankashti',
          type: VratType.sankashtiChaturthi,
          title: 'Sankashti Chaturthi Observance',
          sanskritTitle: 'संकष्टी चतुर्थी व्रतम्',
          targetDate: targetDate,
          location: location,
          tradition: 'Ganapatya / Smartha',
          calendarConvention: convention,
          personalIntention: 'Overcoming difficult obstacles, attaining wisdom, and steady devotion.',
          associatedPujaGuideId: 'guide_ganesh_puja',
          associatedMantraId: 'VEDA-MTR-0454',
          panchangamSnapshot: panchangamSnapshot,
          createdAt: timestamp,
          checklist: const [
            VratChecklistItem(
              id: 'chk_san_sankalpa',
              title: 'Morning intention: dedicate today\'s endeavors to Bhagavan Ganesha.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_san_diet',
              title: 'Simple daytime meal or fruit fasting according to personal capacity.',
              category: 'fasting',
            ),
            VratChecklistItem(
              id: 'chk_san_puja',
              title: 'Perform Ganesha Pancha Upachara with red blossoms and Modak/fruit.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_san_moon',
              title: 'Evening moonrise: gaze upon the moon and offer respectful Arghya.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_san_prasada',
              title: 'Partake of consecrated prasadam with family in joy.',
              category: 'fasting',
            ),
          ],
        );

      case VratType.custom:
        return VratObservance(
          id: 'vrat_${dateClean}_custom_${DateTime.now().millisecondsSinceEpoch % 1000}',
          type: VratType.custom,
          title: 'Personal Devotional Observance',
          sanskritTitle: 'व्यक्तिगत व्रतम्',
          targetDate: targetDate,
          location: location,
          tradition: 'Personal Tradition',
          calendarConvention: convention,
          personalIntention: 'Dedicated personal spiritual practice and contemplation.',
          panchangamSnapshot: panchangamSnapshot,
          createdAt: timestamp,
          checklist: const [
            VratChecklistItem(
              id: 'chk_cus_intention',
              title: 'Formulate personal Sankalpa (intention) for the day.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_cus_altar',
              title: 'Clean prayer space and light an auspicious lamp.',
              category: 'preparation',
            ),
            VratChecklistItem(
              id: 'chk_cus_chant',
              title: 'Chant your chosen mantra or stotra with calm devotion.',
              category: 'ritual',
            ),
            VratChecklistItem(
              id: 'chk_cus_gratitude',
              title: 'Conclude the day with quiet gratitude and peaceful contemplation.',
              category: 'contemplation',
            ),
          ],
        );
    }
  }

  static List<DevotionalReminder> defaultReminders = [
    const DevotionalReminder(
      id: 'rem_morning_sadhana',
      type: ReminderType.morningSadhana,
      title: 'Prātah Sadhana',
      body: 'Peaceful time for your morning prayer and contemplation.',
      hour: 6,
      minute: 30,
      isEnabled: false, // User must explicitly opt in
      repeatDaily: true,
    ),
    const DevotionalReminder(
      id: 'rem_evening_sandhya',
      type: ReminderType.eveningPrayer,
      title: 'Sandhyā Dīpa Prayer',
      body: 'Sunset twilight: light the sacred lamp and reflect in stillness.',
      hour: 18,
      minute: 30,
      isEnabled: false,
      repeatDaily: true,
    ),
  ];
}
