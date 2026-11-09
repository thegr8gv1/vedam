import '../../core/models/guided_sadhana.dart';
import '../../core/models/sadhana_practice.dart';

/// Authentic curated Sadhana plans based on classical Smartha and Grihya traditions.
/// Each plan features sequential devotional steps, source disclosures, and Japa integration.
class AuthenticSadhanaPlansData {
  static const List<GuidedSadhanaPlan> allPlans = [
    // 1. Morning Pratah Sadhana
    GuidedSadhanaPlan(
      id: 'sadhana_pratah_smriti',
      title: 'Prātah Nitya Sadhana',
      sanskritTitle: 'प्रातः नित्य साधना',
      category: SadhanaCategory.morningPrayer,
      deity: 'Savitr / Universal',
      shortDescription: 'Classical morning awakening, solar illumination, and peaceful mind cultivation.',
      purposeAndContext:
          'In traditional Sanatana Dharma, the Brahma Muhurta and dawn twilight represent the pristine threshold '
          'for centering consciousness. This structured sequence combines waking reverence, Vedic solar contemplation, '
          'sacred Gayatri Japa, and silent reflection.',
      estimatedMinutes: 20,
      sourceAttribution: 'Classical Smartha Nitya Karma Paddhati & Taittiriya Aranyaka',
      preparation: [
        'Perform morning ablutions (clean hands, face, or bath).',
        'Wear clean, comfortable clothing.',
        'Sit facing east on a clean mat (asana) in a quiet room.',
        'Optionally light a ghee lamp (diya) and incense.',
      ],
      steps: [
        GuidedSadhanaStep(
          id: 'step_pratah_1_shaucha',
          stepNumber: 1,
          title: 'Shaucha & Asana Sthira (Quiet Preparation)',
          sanskritTitle: 'शौच एवं आसन स्थिरता',
          description:
              'Sit comfortably with spine erect, shoulders relaxed, and palms resting on knees in Chin Mudra. '
              'Take three slow, deep breaths to release sleepiness and center your awareness.',
          stepType: SadhanaStepType.preparation,
          estimatedMinutes: 2,
          materials: ['Clean prayer mat (asana)', 'Lit ghee lamp (optional)'],
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_pratah_2_smaranam',
          stepNumber: 2,
          title: 'Kara Darshanam & Bhumi Vandanam',
          sanskritTitle: 'कर दर्शनम् एवं भूमि वन्दनम्',
          description:
              'Open your palms before your eyes and contemplate the divine presence in righteous action, '
              'followed by gentle reverence to Mother Earth who sustains all life.',
          stepType: SadhanaStepType.scriptureReading,
          sanskritMantra:
              'कराग्रे वसते लक्ष्मीः करमध्ये सरस्वती ।\n'
              'करमूले तु गोविन्दः प्रभाते करदर्शनम् ॥\n\n'
              'समुद्रवसने देवि पर्वतस्तनमण्डले ।\n'
              'विष्णुपत्नि नमस्तुभ्यं पादस्पर्शं क्षमस्व मे ॥',
          transliteration:
              'Karāgre vasate lakṣmīḥ karamadhye sarasvatī |\n'
              'Karamūle tu govindaḥ prabhāte karadarśanam ||\n\n'
              'Samudravasane devi parvatastanamaṇḍale |\n'
              'Viṣṇupatni namastubhyaṁ pādasparśaṁ kṣamasva me ||',
          meaning:
              'At the tip of the hand resides Lakshmi (prosperity); in the middle Saraswati (wisdom); '
              'at the base resides Govinda (divine sustenance). In the morning, I gaze upon my hands.\n\n'
              'O Mother Earth, draped with the oceans and adorned with mountains, consort of Lord Vishnu: '
              'Salutations unto you; please forgive me for touching you with my feet.',
          scripturalSource: 'Traditional Smriti & Grihya Morning Invocation',
          estimatedMinutes: 3,
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_pratah_3_gayatri_japa',
          stepNumber: 3,
          title: 'Gayatri Mahamantra Japa',
          sanskritTitle: 'गायत्री महामन्त्र जप',
          description:
              'Chant the venerable Vedic Gayatri mantra with reverence, contemplating the supreme light '
              'that illuminates the universe and guides the intellect toward righteousness.',
          stepType: SadhanaStepType.japa,
          sanskritMantra:
              'ॐ भूर्भुवः स्वः ।\n'
              'तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि ।\n'
              'धियो यो नः प्रचोदयात् ॥',
          transliteration:
              'Oṁ bhūr bhuvaḥ svaḥ |\n'
              'Tat savitur vareṇyaṁ bhargo devasya dhīmahi |\n'
              'Dhiyo yo naḥ pracodayāt ||',
          meaning:
              'We meditate upon that radiant splendour of the divine Sun, the supreme Source of all existence. '
              'May that luminous divine power inspire and awaken our intellect.',
          scripturalSource: 'Rigveda Mandala 3, Sukta 62, Verse 10',
          linkedMantraId: 'VEDA-MTR-0399',
          targetRepetitions: 108,
          estimatedMinutes: 10,
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_pratah_4_svadhyaya',
          stepNumber: 4,
          title: 'Svādhyāya (Scripture Contemplation)',
          sanskritTitle: 'स्वाध्याय (शास्त्र मनन)',
          description:
              'Spend quiet moments reflecting on spiritual wisdom, elevating the mind above daily agitation '
              'and grounding yourself in spiritual discrimination.',
          stepType: SadhanaStepType.scriptureReading,
          sanskritMantra:
              'नासतो विद्यते भावो नाभावो विद्यते सतः ।\n'
              'उभयोरपि दृष्टोऽन्तस्त्वनयोस्तत्त्वदर्शिभिः ॥',
          transliteration:
              'Nāsato vidyate bhāvo nābhāvo vidyate sataḥ |\n'
              'Ubhayor api dṛṣṭo \'ntas tv anayos tattva-darśibhiḥ ||',
          meaning:
              'The unreal has no enduring existence, and the real never ceases to be. '
              'The eternal truth of both has been perceived by seers of ultimate reality.',
          scripturalSource: 'Bhagavad Gita Chapter 2, Verse 16',
          estimatedMinutes: 3,
          isOptional: true,
        ),
        GuidedSadhanaStep(
          id: 'step_pratah_5_shanti',
          stepNumber: 5,
          title: 'Shanti Patha & Silent Reflection',
          sanskritTitle: 'शान्ति पाठ एवं मौन ध्यान',
          description:
              'Close your eyes and dwell in stillness. Conclude by sending blessings of peace to all beings '
              'throughout the physical, atmospheric, and celestial realms.',
          stepType: SadhanaStepType.reflection,
          sanskritMantra:
              'ॐ द्यौः शान्तिरन्तरिक्षं शान्तिः\n'
              'पृथिवी शान्तिरापः शान्तिरोषधयः शान्तिः ।\n'
              'वनस्पतयः शान्तिर्विश्वेदेवाः शान्तिर्ब्रह्म शान्तिः\n'
              'सर्वं शान्तिः शान्तिरेव शान्तिः सा मा शान्तिरेधि ॥\n'
              'ॐ शान्तिः शान्तिः शान्तिः ॥',
          transliteration:
              'Oṁ dyauḥ śāntir antarikṣaṁ śāntiḥ\n'
              'Pṛthivī śāntir āpaḥ śāntir oṣadhayaḥ śāntiḥ |\n'
              'Vanaspatayaḥ śāntir viśvedevāḥ śāntir brahma śāntiḥ\n'
              'Sarvaṁ śāntiḥ śāntir eva śāntiḥ sā mā śāntir edhi ||\n'
              'Oṁ śāntiḥ śāntiḥ śāntiḥ ||',
          meaning:
              'May peace radiate through celestial realms, peace in the atmosphere, peace on earth, '
              'peace in the waters, peace in herbs and plants. May peace abide in all divine powers and in Brahman. '
              'May universal peace prevail. Om Peace, Peace, Peace.',
          scripturalSource: 'Yajurveda 36.17 (Vedic Shanti Mantra)',
          estimatedMinutes: 2,
          isOptional: false,
        ),
      ],
    ),

    // 2. Evening Sandhya Dhyana Sadhana
    GuidedSadhanaPlan(
      id: 'sadhana_sandhya_dhyana',
      title: 'Sandhyā Dhyāna Sadhana',
      sanskritTitle: 'सन्ध्या ध्यान साधना',
      category: SadhanaCategory.eveningPrayer,
      deity: 'Lord Shiva / Universal',
      shortDescription: 'Twilight lamp lighting, Shiva Panchakshara Japa, and inner peaceful stillness.',
      purposeAndContext:
          'The evening twilight (Sayana Sandhya) is the classical domestic time for releasing daily activities, '
          'cleansing the mind of fatigue, and centering devotion in Lord Shiva through sacred sound.',
      estimatedMinutes: 18,
      sourceAttribution: 'Classical Shaiva Grihya Paddhati & Smriti Sandhya Vidhi',
      preparation: [
        'Wash hands and face with cool water.',
        'Light a pure sesame oil or ghee lamp at the altar.',
        'Sit facing north or east in a calm posture.',
      ],
      steps: [
        GuidedSadhanaStep(
          id: 'step_sandhya_1_deepa',
          stepNumber: 1,
          title: 'Dīpa Prārthanā (Auspicious Lamp Lighting)',
          sanskritTitle: 'दीप प्रार्थना',
          description:
              'Light the sacred flame and gaze gently upon it. Acknowledge the light that dispels darkness, '
              'sorrow, and ignorance, ushering in auspiciousness.',
          stepType: SadhanaStepType.preparation,
          sanskritMantra:
              'शुभं करोति कल्याणमारोग्यं धनसम्पदः ।\n'
              'शत्रुबुद्धिविनाशाय दीपज्योतिर्नमोऽस्तु ते ॥',
          transliteration:
              'Śubhaṁ karoti kalyāṇam ārogyaṁ dhanasampadaḥ |\n'
              'Śatrubuddhivināśāya dīpajyotir namo\'stu te ||',
          meaning:
              'Salutations to the light of the lamp, which bestows auspiciousness, welfare, health, '
              'and noble abundance, and dispels discordant tendencies from the intellect.',
          scripturalSource: 'Traditional Smartha Evening Deepa Sloka',
          estimatedMinutes: 2,
          materials: ['Lit ghee or sesame oil lamp (diya)'],
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_sandhya_2_shiva_japa',
          stepNumber: 2,
          title: 'Shiva Panchakshara Japa',
          sanskritTitle: 'शिव पञ्चाक्षर जप',
          description:
              'Chant the five sacred syllables of Lord Shiva with steady breath and tranquil devotion. '
              'Each repetition brings serenity and purifies inner awareness.',
          stepType: SadhanaStepType.japa,
          sanskritMantra: 'ॐ नमः शिवाय ।',
          transliteration: 'Oṁ namaḥ śivāya |',
          meaning: 'Om, salutations to Lord Shiva, the embodiment of auspiciousness, grace, and inner stillness.',
          scripturalSource: 'Yajurveda Taittiriya Samhita (Shri Rudram)',
          linkedMantraId: 'VEDA-MTR-0001',
          targetRepetitions: 108,
          estimatedMinutes: 8,
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_sandhya_3_mrityunjaya',
          stepNumber: 3,
          title: 'Maha Mrityunjaya Contemplation',
          sanskritTitle: 'महामृत्युञ्जय मनन',
          description:
              'Contemplate the great nectarous healing mantra of Lord Shiva for freedom from inner fear, '
              'ailments, and spiritual bondage.',
          stepType: SadhanaStepType.scriptureReading,
          sanskritMantra:
              'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\n'
              'उर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात् ॥',
          transliteration:
              'Oṁ tryambakaṁ yajāmahe sugandhiṁ puṣṭivardhanam |\n'
              'Urvārukam iva bandhanān mṛtyor mukṣīya māmṛtāt ||',
          meaning:
              'We worship the Three-Eyed Lord Shiva, who is fragrant and nourishes all beings. '
              'As a ripe melon is effortlessly liberated from its vine, may we be released from mortality unto immortality.',
          scripturalSource: 'Rigveda Mandala 7, Sukta 59, Verse 12',
          linkedMantraId: 'VEDA-MTR-0413',
          estimatedMinutes: 4,
          isOptional: true,
        ),
        GuidedSadhanaStep(
          id: 'step_sandhya_4_samarpanam',
          stepNumber: 4,
          title: 'Ishvara Samarpanam & Silence',
          sanskritTitle: 'ईश्वर समर्पणम् एवं मौन ध्यान',
          description:
              'Surrender all deeds, joys, and anxieties of the day unto the supreme Divine presence. '
              'Remain seated in quiet meditation for three minutes before resuming household life.',
          stepType: SadhanaStepType.reflection,
          sanskritMantra:
              'कायेन वाचा मनसेन्द्रियैर्वा बुद्ध्यात्मना वा प्रकृतेः स्वभावात् ।\n'
              'करोमि यद्यत् सकलं परस्मै नारायणायेति समर्पयामि ॥',
          transliteration:
              'Kāyena vācā manasendriyair vā buddhyātmanā vā prakṛteḥ svabhāvāt |\n'
              'Karomi yad yat sakalaṁ parasmai nārāyaṇāyeti samarpayāmi ||',
          meaning:
              'Whatever action I perform with my body, speech, mind, senses, intellect, or through the '
              'impulses of nature: all of it I surrender entirely unto the Supreme Lord.',
          scripturalSource: 'Mukundamala Stotra / Shrimad Bhagavatam 11.2.36',
          estimatedMinutes: 4,
          isOptional: false,
        ),
      ],
    ),

    // 3. Ganesha Sankata Nashana Sadhana
    GuidedSadhanaPlan(
      id: 'sadhana_ganesh_aradhana',
      title: 'Ganesha Sankata Nashana Sadhana',
      sanskritTitle: 'श्री गणेश सङ्कट नाशन साधना',
      category: SadhanaCategory.dailyPuja,
      deity: 'Lord Ganesha',
      shortDescription: 'Clear obstacles, bestow auspicious wisdom, and cultivate peaceful mental clarity.',
      purposeAndContext:
          'Before embarking on any important undertaking or to resolve inner obstacles, devotees turn to Lord Ganesha '
          'with focused invocation and steady Japa chanting.',
      estimatedMinutes: 15,
      sourceAttribution: 'Mudgala Purana & Ganesha Sahasranama Paddhati',
      preparation: [
        'Sit peacefully facing East.',
        'Visualize Lord Ganesha with a benevolent, smiling countenance.',
      ],
      steps: [
        GuidedSadhanaStep(
          id: 'step_ganesh_1_dhyanam',
          stepNumber: 1,
          title: 'Vakratunda Mahakaya Dhyanam',
          sanskritTitle: 'वक्रतुण्ड महाकाय ध्यानम्',
          description:
              'Bring hands together before your heart in Anjali Mudra. Contemplate Lord Ganesha '
              'removing all hindrances from your thoughts and actions.',
          stepType: SadhanaStepType.preparation,
          sanskritMantra:
              'वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ ।\n'
              'निर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा ॥',
          transliteration:
              'Vakratuṇḍa mahākāya sūryakoṭi samaprabha |\n'
              'Nirvighnaṁ kuru me deva sarvakāryeṣu sarvadā ||',
          meaning:
              'O Lord of curved trunk and mighty form, whose radiance equals millions of suns: '
              'Please remove all obstacles from all my endeavors, always.',
          scripturalSource: 'Mudgala Purana Invocation',
          linkedMantraId: 'VEDA-MTR-0454',
          estimatedMinutes: 3,
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_ganesh_2_japa',
          stepNumber: 2,
          title: 'Ganesha Moola Mantra Japa',
          sanskritTitle: 'गणेश मूलमन्त्र जप',
          description:
              'Chant the root mantra of Bhagavan Ganesha. With every chant, feel inner clarity and auspiciousness '
              'displacing anxiety and distraction.',
          stepType: SadhanaStepType.japa,
          sanskritMantra: 'ॐ गं गणपतये नमः ।',
          transliteration: 'Oṁ gaṁ gaṇapataye namaḥ |',
          meaning: 'Om, salutations unto Lord Ganapati, ruler of all categories of beings.',
          scripturalSource: 'Ganapati Atharvashirsha Upanishad',
          linkedMantraId: 'VEDA-MTR-0446',
          targetRepetitions: 108,
          estimatedMinutes: 8,
          isOptional: false,
        ),
        GuidedSadhanaStep(
          id: 'step_ganesh_3_shanti',
          stepNumber: 3,
          title: 'Auspicious Blessing & Silence',
          sanskritTitle: 'मङ्गल प्रार्थना एवं शान्ति',
          description:
              'Rest quietly in the resonance of the sacred chant. Feel deep inner grounding and peace '
              'before returning to your daily responsibilities.',
          stepType: SadhanaStepType.reflection,
          sanskritMantra: 'ॐ शान्तिः शान्तिः शान्तिः ।',
          transliteration: 'Oṁ śāntiḥ śāntiḥ śāntiḥ |',
          meaning: 'Om Peace, Peace, Peace across all dimensions.',
          scripturalSource: 'Classical Upanishadic Conclusion',
          estimatedMinutes: 4,
          isOptional: false,
        ),
      ],
    ),
  ];

  static GuidedSadhanaPlan? getPlanById(String id) {
    try {
      return allPlans.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
