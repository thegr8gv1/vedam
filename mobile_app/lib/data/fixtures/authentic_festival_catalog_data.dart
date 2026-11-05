import '../../core/models/festival_event.dart';
import '../../core/models/vrat_observance.dart';

/// Authentic curated catalog of Hindu festivals, observances, and regional holy days.
/// Every event carries explicit scriptural provenance, calculation convention, and regional variation notes.
class AuthenticFestivalCatalogData {
  static const List<FestivalEvent> allEvents = [
    // --- NOVEMBER 2026 ---
    FestivalEvent(
      id: 'fest_rama_ekadashi_2026',
      name: 'Rama Ekadashi Vratam',
      sanskritName: 'रमा एकादशी व्रतम्',
      category: FestivalCategory.ekadashi,
      targetDate: '2026-11-05',
      deity: 'Krishna / Vishnu',
      masa: 'Kartika (Purnimanta) / Ashvina (Amanta)',
      paksha: 'Krishna Paksha',
      tithi: 'Ekadashi',
      nakshatra: 'Uttara Phalguni',
      timingRule: 'Udaya Tithi (Sunrise)',
      timingWindow: 'Prevailing sunrise tithi through next day sunrise',
      significance:
          'Dedicated to Lord Narayana and Mother Lakshmi (Rama). Devotees practice fasting, contemplation, and scriptural recitation to cleanse mind and karma.',
      calculationConvention: 'Drik Ganita / Lahiri Ayanamsa (Udaya Tithi)',
      sourceName: 'Nirnaya Sindhu (Pariccheda 2, Ekadashi Nirnaya)',
      sourceReference: 'Brahmavaivarta Purana, Kartika Krishna Ekadashi Mahatmya',
      regionalVariations:
          'North Indian calendars denote this as Kartika Krishna Ekadashi; South and Western Indian (Amanta) calendars denote it as Ashvina Krishna Ekadashi.',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0378',
      suggestedVratType: VratType.ekadashi,
      suggestedChecklist: [
        VratChecklistItem(
          id: 'chk_re_fast',
          title: 'Sattvic fasting (phalahara or water-only) according to health capacity.',
          category: 'fasting',
        ),
        VratChecklistItem(
          id: 'chk_re_puja',
          title: 'Offer Vishnu Pancha Upachara with Tulasi leaves and fragrant chandan.',
          category: 'ritual',
        ),
        VratChecklistItem(
          id: 'chk_re_japa',
          title: 'Chant Vishnu Sahasranama or Om Namo Narayanaya (108 repetitions).',
          category: 'contemplation',
        ),
      ],
    ),
    FestivalEvent(
      id: 'fest_shani_pradosham_nov_2026',
      name: 'Shani Pradosha Vratam',
      sanskritName: 'शनि प्रदोष व्रतम्',
      category: FestivalCategory.pradosham,
      targetDate: '2026-11-07',
      deity: 'Shiva',
      masa: 'Kartika / Ashvina',
      paksha: 'Krishna Paksha',
      tithi: 'Trayodashi',
      nakshatra: 'Hasta',
      timingRule: 'Pradosha Sandhyakala (Sunset)',
      timingWindow: '05:30 PM - 07:45 PM (Sunset window)',
      significance:
          'Twilight adoration of Lord Shiva and Nandi Bhagavan occurring on a Saturday (Shani). Revered for mitigating sorrow, malefic planetary influences, and granting inner tranquility.',
      calculationConvention: 'Drik Ganita Sunset Sandhyakala (Trayodashi at sunset)',
      sourceName: 'Skanda Purana (Shiva Rahasya Khanda)',
      sourceReference: 'Dharma Sindhu, Pradosha Vrata Prakarana',
      regionalVariations:
          'Observed across all Shaiva and Smartha traditions. When Trayodashi touches sunset on Saturday, it is celebrated with special Abhishekam.',
      associatedPujaGuideId: 'guide_shiva_puja',
      associatedMantraId: 'VEDA-MTR-0429',
      suggestedVratType: VratType.pradosham,
      suggestedChecklist: [
        VratChecklistItem(
          id: 'chk_sp_fast',
          title: 'Daytime fasting until sunset sandhyakala.',
          category: 'fasting',
        ),
        VratChecklistItem(
          id: 'chk_sp_puja',
          title: 'Perform Shiva Upachara puja during sunset with Bilva leaves.',
          category: 'ritual',
        ),
        VratChecklistItem(
          id: 'chk_sp_japa',
          title: 'Maha Mrityunjaya mantra or Om Namah Shivaya Japa.',
          category: 'contemplation',
        ),
      ],
    ),
    FestivalEvent(
      id: 'fest_deepavali_2026',
      name: 'Deepavali / Sri Lakshmi Puja',
      sanskritName: 'दीपावली / श्री महालक्ष्मी पूजा',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-11-08',
      deity: 'Lakshmi / Ganesha',
      masa: 'Kartika (Purnimanta) / Ashvina (Amanta)',
      paksha: 'Krishna Paksha',
      tithi: 'Amavasya',
      nakshatra: 'Chitra / Svati',
      timingRule: 'Pradosha & Nishita Vyapti',
      timingWindow: '06:15 PM - 08:30 PM (Lakshmi Puja Muhurta)',
      significance:
          'The sacred festival of lights celebrating the triumph of divine illumination over darkness, righteousness over ignorance, and welcoming Mahalakshmi into sanctified homes.',
      calculationConvention: 'Amavasya prevailing during Pradoshakala (Drik Ganita)',
      sourceName: 'Nirnaya Sindhu, Kartika Amavasya Nirnaya',
      sourceReference: 'Skanda Purana, Sanatkumara Samhita',
      regionalVariations:
          'In South India, Naraka Chaturdashi is observed in the pre-dawn hours of Amavasya; in Bengal, Shyama / Kali Puja is performed at Nishita midnight.',
      associatedPujaGuideId: 'guide_lakshmi_puja',
      associatedMantraId: 'VEDA-MTR-0415',
      suggestedVratType: VratType.custom,
      suggestedChecklist: [
        VratChecklistItem(
          id: 'chk_dp_diyas',
          title: 'Cleanse household, arrange auspicious Rangoli, and light oil deepas.',
          category: 'preparation',
        ),
        VratChecklistItem(
          id: 'chk_dp_puja',
          title: 'Perform Sri Mahalakshmi & Ganesha Pancha Upachara worship.',
          category: 'ritual',
        ),
        VratChecklistItem(
          id: 'chk_dp_stotra',
          title: 'Recite Sri Suktam or Kanakadhara Stotram for universal peace.',
          category: 'contemplation',
        ),
      ],
    ),
    FestivalEvent(
      id: 'fest_kartika_amavasya_2026',
      name: 'Kartika Amavasya (Pitru Tarpanam)',
      sanskritName: 'कार्तिक अमावस्या (पितृ तर्पणम्)',
      category: FestivalCategory.amavasya,
      targetDate: '2026-11-08',
      deity: 'Universal / Ancestral Remembrance',
      masa: 'Kartika / Ashvina',
      paksha: 'Krishna Paksha',
      tithi: 'Amavasya',
      nakshatra: 'Chitra',
      timingRule: 'Aparahna (Mid-afternoon)',
      timingWindow: '12:45 PM - 03:15 PM',
      significance:
          'Dark moon day sacred for spiritual introspection, ancestral contemplation, charity, and honoring departed forebears with grateful mindfulness.',
      calculationConvention: 'Aparahna Vyapini Amavasya (Drik Ganita)',
      sourceName: 'Dharma Sindhu, Amavasya Shraddha Nirnaya',
      sourceReference: 'Matsya Purana, Pitru Kalpa',
      regionalVariations:
          'Coincides with Deepavali Lakshmi Puja in the evening. Ancestral offerings are performed earlier in the day during Aparahna.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0448',
      suggestedVratType: VratType.amavasya,
    ),
    FestivalEvent(
      id: 'fest_govardhan_puja_2026',
      name: 'Govardhan Puja / Annakut',
      sanskritName: 'गोवर्धन पूजा / अन्नकूटोत्सवः',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-11-09',
      deity: 'Krishna',
      masa: 'Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Pratipada',
      nakshatra: 'Vishakha',
      timingRule: 'Pratah / Madhyahna',
      timingWindow: '07:30 AM - 11:30 AM',
      significance:
          'Celebrates Lord Krishna lifting Mount Govardhan to shield the inhabitants of Vraja. Devotees prepare Annakut (mountain of food offerings) and venerate mother cows.',
      calculationConvention: 'Kartika Shukla Pratipada (Drik Ganita)',
      sourceName: 'Srimad Bhagavatam (Canto 10, Chapter 24-25)',
      sourceReference: 'Nirnaya Sindhu, Govardhanotsava Vidhi',
      regionalVariations:
          'Celebrated as Bali Pratipada / Dyuta Pratipada in Maharashtra and Karnataka; celebrated as Gujarati New Year (Bestu Varas) in Gujarat.',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0378',
      suggestedVratType: VratType.custom,
    ),
    FestivalEvent(
      id: 'fest_bhai_dooj_2026',
      name: 'Bhai Dooj / Yama Dvitiya',
      sanskritName: 'भाई दूज / यम द्वितीया',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-11-11',
      deity: 'Yama / Yamuna',
      masa: 'Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Dvitiya',
      nakshatra: 'Jyeshtha',
      timingRule: 'Aparahna (Afternoon)',
      timingWindow: '01:15 PM - 03:30 PM',
      significance:
          'Sacred celebration honoring the bond between brothers and sisters, grounded in the puranic account of Yamuna welcoming her brother Yama with love and prayer.',
      calculationConvention: 'Aparahna Vyapini Kartika Shukla Dvitiya',
      sourceName: 'Padma Purana (Uttara Khanda)',
      sourceReference: 'Dharma Sindhu, Yama Dvitiya Nirnaya',
      regionalVariations:
          'Known as Bhav-Bij in Maharashtra, Bhai Phota in Bengal, and Bhatri Dvitiya across North India.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0448',
    ),
    FestivalEvent(
      id: 'fest_chhath_puja_2026',
      name: 'Chhath Puja (Sandhya Arghya)',
      sanskritName: 'छठ पूजा (संध्या अर्घ्य)',
      category: FestivalCategory.regionalObservance,
      targetDate: '2026-11-15',
      deity: 'Surya / Chhathi Maiya',
      masa: 'Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Shashthi',
      nakshatra: 'Uttara Ashadha',
      timingRule: 'Suryastakala (Sunset)',
      timingWindow: '04:45 PM - 05:45 PM',
      significance:
          'Ancient Vedic solar reverence dedicated to Bhagavan Surya and Usha (Chhathi Maiya) for health, longevity, righteous progeny, and planetary gratitude.',
      calculationConvention: 'Kartika Shukla Shashthi at Sunset (Drik Ganita)',
      sourceName: 'Rigveda (Solar Hymns), Mahabharata (Draupadi Chhath Vrata)',
      sourceReference: 'Rashtriya Panchang, Positional Astronomy Centre',
      regionalVariations:
          'Vastly celebrated in Bihar, Jharkhand, Eastern UP, and global diaspora with strict 36-hour waterless Nirjala fasting.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0005',
      suggestedVratType: VratType.custom,
    ),
    FestivalEvent(
      id: 'fest_skanda_sashti_2026',
      name: 'Skanda Sashti / Soorasamharam',
      sanskritName: 'स्कन्द षष्ठी (कन्द षष्टि)',
      category: FestivalCategory.regionalObservance,
      targetDate: '2026-11-15',
      deity: 'Subrahmanya / Murugan',
      masa: 'Aippasi / Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Shashthi',
      nakshatra: 'Uttara Ashadha',
      timingRule: 'Shashthi Tithi',
      timingWindow: 'All day observance',
      significance:
          'Commemorates Lord Murugan (Skanda) vanquishing the demonic forces of ego (Soorapadman), establishing righteous order and spiritual valor.',
      calculationConvention: 'Tamil Solar Calendar (Aippasi) / Drik Ganita',
      sourceName: 'Skanda Purana (Sankara Samhita)',
      sourceReference: 'Tamil Saiva Siddhanta Paddhati',
      regionalVariations:
          'Celebrated primarily in Tamil Nadu, Sri Lanka, Malaysia, and Murugan shrines worldwide with 6-day fasting and Kanda Sashti Kavam recitation.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0448',
      suggestedVratType: VratType.custom,
    ),
    FestivalEvent(
      id: 'fest_prabodhini_ekadashi_2026',
      name: 'Prabodhini / Devuthani Ekadashi',
      sanskritName: 'प्रबोधिनी / देवोत्थान एकादशी',
      category: FestivalCategory.ekadashi,
      targetDate: '2026-11-20',
      deity: 'Vishnu',
      masa: 'Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Ekadashi',
      nakshatra: 'Revati',
      timingRule: 'Udaya Tithi (Sunrise)',
      timingWindow: 'Sunrise through Dvadashi Parana',
      significance:
          'Marks the spiritual awakening of Lord Vishnu from the four-month contemplative slumber (Chaturmasya). Inception of the sacred Tulasi Vivaha season.',
      calculationConvention: 'Kartika Shukla Ekadashi (Drik Ganita)',
      sourceName: 'Padma Purana (Uttara Khanda)',
      sourceReference: 'Nirnaya Sindhu, Prabodhini Nirnaya',
      regionalVariations:
          'In Maharashtra, the great Kartiki Pandharpur Wari yatra concludes on this day; celebrated with sugar-cane mandaps and Tulasi marriage.',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0378',
      suggestedVratType: VratType.ekadashi,
    ),
    FestivalEvent(
      id: 'fest_dev_deepavali_2026',
      name: 'Dev Deepavali (Varanasi Ghats)',
      sanskritName: 'देव दीपावली (काशी)',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-11-24',
      deity: 'Shiva (Tripurantaka)',
      masa: 'Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Purnima',
      nakshatra: 'Krittika',
      timingRule: 'Pradosha Sandhyakala',
      timingWindow: '05:15 PM - 08:30 PM',
      significance:
          'Celebrates Lord Shiva destroying the three demon citadels (Tripurasura). Millions of earthen lamps are illuminated along the 84 ghats of the Ganges in Kashi.',
      calculationConvention: 'Kartika Purnima at Pradosha (Drik Ganita)',
      sourceName: 'Shiva Purana (Rudra Samhita, Yuddha Khanda)',
      sourceReference: 'Kashi Khanda (Skanda Purana)',
      regionalVariations:
          'Centric to Varanasi (Kashi) with worldwide devotion; celebrated as Kartika Deepam in Tamil Nadu with sacred beacon on Arunachala.',
      associatedPujaGuideId: 'guide_shiva_puja',
      associatedMantraId: 'VEDA-MTR-0429',
      suggestedVratType: VratType.purnima,
    ),
    FestivalEvent(
      id: 'fest_kartika_purnima_2026',
      name: 'Kartika Purnima Vratam',
      sanskritName: 'कार्तिक पूर्णिमा व्रतम्',
      category: FestivalCategory.purnima,
      targetDate: '2026-11-24',
      deity: 'Vishnu (Matsya Avatar) / Shiva',
      masa: 'Kartika',
      paksha: 'Shukla Paksha',
      tithi: 'Purnima',
      nakshatra: 'Krittika',
      timingRule: 'Udaya & Purnima Moonrise',
      timingWindow: 'All day and night',
      significance:
          'One of the holiest full moons of the year. Commemorates Lord Vishnu manifesting as Matsya Avatara to salvage the Vedas from cosmic dissolution.',
      calculationConvention: 'Kartika Shukla Purnima (Drik Ganita)',
      sourceName: 'Matsya Purana (Matsya Jayanti Chapters)',
      sourceReference: 'Dharma Sindhu, Kartika Purnima Vidhi',
      regionalVariations:
          'Celebrated as Boita Bandana in Odisha; sacred snana (bath) in holy rivers (Ganga, Yamuna, Godavari, Kaveri) is deeply revered.',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0415',
      suggestedVratType: VratType.purnima,
    ),
    FestivalEvent(
      id: 'fest_sankashti_nov_2026',
      name: 'Ganadhipa Sankashti Chaturthi',
      sanskritName: 'गणाधिप संकष्टी चतुर्थी',
      category: FestivalCategory.sankashtiChaturthi,
      targetDate: '2026-11-28',
      deity: 'Ganesha',
      masa: 'Margashirsha (Purnimanta) / Kartika (Amanta)',
      paksha: 'Krishna Paksha',
      tithi: 'Chaturthi',
      nakshatra: 'Punarvasu',
      timingRule: 'Chandrodaya (Moonrise)',
      timingWindow: '08:45 PM Moonrise Puja',
      significance:
          'Monthly day of fasting dedicated to Lord Ganesha to dispel obstacles, relieve afflictions, and invoke clarity. Concluded upon seeing the moon.',
      calculationConvention: 'Chaturthi prevailing at Chandrodaya (Drik Ganita)',
      sourceName: 'Ganesha Purana (Upasana Khanda)',
      sourceReference: 'Dharma Sindhu, Sankashti Chaturthi Nirnaya',
      regionalVariations:
          'When falling on a Tuesday, celebrated as Angaraki Chaturthi with heightened auspiciousness.',
      associatedPujaGuideId: 'guide_ganesh_puja',
      associatedMantraId: 'VEDA-MTR-0454',
      suggestedVratType: VratType.sankashtiChaturthi,
    ),

    // --- DECEMBER 2026 ---
    FestivalEvent(
      id: 'fest_mokshada_ekadashi_2026',
      name: 'Mokshada Ekadashi / Gita Jayanti',
      sanskritName: 'मोक्षदा एकादशी / श्रीमद्भगवद्गीता जयन्ती',
      category: FestivalCategory.ekadashi,
      targetDate: '2026-12-20',
      deity: 'Krishna',
      masa: 'Margashirsha',
      paksha: 'Shukla Paksha',
      tithi: 'Ekadashi',
      nakshatra: 'Bharani',
      timingRule: 'Udaya Tithi (Sunrise)',
      timingWindow: 'Sunrise through Dvadashi',
      significance:
          'Commemorates the sacred day Lord Krishna imparted the Bhagavad Gita to Arjuna on the battlefield of Kurukshetra. Celebrated as Vaikuntha Ekadashi in South India.',
      calculationConvention: 'Margashirsha Shukla Ekadashi (Drik Ganita)',
      sourceName: 'Mahabharata (Bhishma Parva, Bhagavad Gita)',
      sourceReference: 'Nirnaya Sindhu, Mokshada Vrata Vidhi',
      regionalVariations:
          'Celebrated as Vaikuntha Ekadashi in Tirupati, Srirangam, and Vaishnava temples with opening of the Paramapada Vasal (Gateway to Vaikuntha).',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0378',
      suggestedVratType: VratType.ekadashi,
      suggestedChecklist: [
        VratChecklistItem(
          id: 'chk_gj_gita',
          title: 'Read all 18 chapters or a selected chapter of the Bhagavad Gita.',
          category: 'contemplation',
        ),
        VratChecklistItem(
          id: 'chk_gj_puja',
          title: 'Offer flowers and light to Lord Krishna and Sri Gita book.',
          category: 'ritual',
        ),
      ],
    ),
    FestivalEvent(
      id: 'fest_margashirsha_purnima_2026',
      name: 'Margashirsha Purnima / Dattatreya Jayanti',
      sanskritName: 'दत्तात्रेय जयन्ती / मार्गशीर्ष पूर्णिमा',
      category: FestivalCategory.purnima,
      targetDate: '2026-12-23',
      deity: 'Dattatreya (Brahma-Vishnu-Shiva Trimurti)',
      masa: 'Margashirsha',
      paksha: 'Shukla Paksha',
      tithi: 'Purnima',
      nakshatra: 'Mrigashirsha',
      timingRule: 'Pradosha / Moonrise',
      timingWindow: 'All day and evening',
      significance:
          'Celebrates the appearance of Bhagavan Dattatreya, the primordial master (Adi Guru) embodying Brahma, Vishnu, and Shiva, teacher of supreme Avadhuta wisdom.',
      calculationConvention: 'Margashirsha Purnima at Pradosha (Drik Ganita)',
      sourceName: 'Markandeya Purana, Sandilya Upanishad',
      sourceReference: 'Dharma Sindhu, Dattatreya Jayanti Nirnaya',
      regionalVariations:
          'Celebrated with profound devotion in Maharashtra, Karnataka, and Gujarat at Ganagapur, Narsobawadi, and Girnar shrines.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0448',
      suggestedVratType: VratType.purnima,
    ),

    // --- RECURRENT & MAJOR ANCHOR EVENTS (2026/2027) ---
    FestivalEvent(
      id: 'fest_makara_sankranti_2027',
      name: 'Makara Sankranti / Pongal / Uttarayan',
      sanskritName: 'मकर संक्रान्ति / उत्तरायण पुण्यकाल',
      category: FestivalCategory.majorFestival,
      targetDate: '2027-01-14',
      deity: 'Surya',
      masa: 'Makara Solar Month / Pausha',
      paksha: 'Shukla Paksha',
      tithi: 'Saptami',
      nakshatra: 'Uttara Ashadha',
      timingRule: 'Surya Sankranti Transition (Ingress)',
      timingWindow: '08:15 AM - 04:30 PM (Punya Kala Window)',
      significance:
          'Marks the astronomical transition of the Sun into the zodiacal sign of Makara (Capricorn) and commencement of Uttarayana (northern movement). Sacred for charity, sesame offerings, and gratitude.',
      calculationConvention: 'Sayana / Nirayana Solar Ingress (Lahiri Ayanamsa)',
      sourceName: 'Surya Siddhanta, Sankranti Prakarana',
      sourceReference: 'Nirnaya Sindhu, Makara Sankranti Nirnaya',
      regionalVariations:
          'Celebrated as Pongal in Tamil Nadu, Uttarayan in Gujarat, Maghi in Punjab, and Magh Bihu in Assam.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0005',
    ),
    FestivalEvent(
      id: 'fest_maha_shivaratri_2026',
      name: 'Maha Shivaratri (The Great Night of Shiva)',
      sanskritName: 'महाशिवरात्रिः (निशीथकाल पूजा)',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-02-15',
      deity: 'Shiva',
      masa: 'Phalguna (Purnimanta) / Magha (Amanta)',
      paksha: 'Krishna Paksha',
      tithi: 'Chaturdashi',
      nakshatra: 'Shravana / Dhanishta',
      timingRule: 'Nishita Kala (Midnight Vyapti)',
      timingWindow: '11:45 PM - 12:35 AM (Midnight Nishita Kala)',
      significance:
          'The paramount sacred nocturnal vigil honoring Lord Shiva. Devotees fast, remain vigilantly awake (Jagaran), and offer continuous Abhishekam with Bilva leaves to the Shiva Lingam.',
      calculationConvention: 'Krishna Chaturdashi prevailing at local Nishita Kala (Drik Ganita)',
      sourceName: 'Shiva Purana (Kotirudra Samhita, Chapter 37-40)',
      sourceReference: 'Nirnaya Sindhu, Maha Shivaratri Nirnaya',
      regionalVariations:
          'Observed identically across Northern and Southern traditions based on the Nishita midnight rule, though month naming differs (Phalguna vs Magha).',
      associatedPujaGuideId: 'guide_shiva_puja',
      associatedMantraId: 'VEDA-MTR-0429',
      suggestedVratType: VratType.custom,
      suggestedChecklist: [
        VratChecklistItem(
          id: 'chk_ms_fast',
          title: 'Complete day and night fasting (Nirjala or fruit/milk according to capacity).',
          category: 'fasting',
        ),
        VratChecklistItem(
          id: 'chk_ms_abhisheka',
          title: 'Four-quarter (Prahar) Shiva Linga Abhishekam with water, milk, and Bilva.',
          category: 'ritual',
        ),
        VratChecklistItem(
          id: 'chk_ms_japa',
          title: 'Chant Om Namah Shivaya throughout the nocturnal hours.',
          category: 'contemplation',
        ),
      ],
    ),
    FestivalEvent(
      id: 'fest_holi_2026',
      name: 'Holi / Dhulandi (Festival of Colors)',
      sanskritName: 'होलिकोत्सवः / धुलण्डी',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-03-04',
      deity: 'Krishna / Prahlada / Narasimha',
      masa: 'Phalguna / Chaitra',
      paksha: 'Krishna Paksha',
      tithi: 'Pratipada',
      nakshatra: 'Uttara Phalguni',
      timingRule: 'Pratah / Daytime',
      timingWindow: 'Morning and afternoon joyous gathering',
      significance:
          'Joyous spring celebration of brotherhood, forgiveness, and renewal. Follows Holika Dahan which symbolizes the burning of unrighteousness and salvation of Bhakta Prahlada.',
      calculationConvention: 'Phalguna Purnima (Holika Dahan) & Chaitra Krishna Pratipada (Colors)',
      sourceName: 'Bhavishya Purana, Uttara Parva',
      sourceReference: 'Nirnaya Sindhu, Holika Nirnaya',
      regionalVariations:
          'Celebrated as Lathmar Holi in Barsana/Nandgaon, Dol Jatra in Bengal, and Shigmo in Goa.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0378',
    ),
    FestivalEvent(
      id: 'fest_ugadi_gudi_padwa_2026',
      name: 'Ugadi / Gudi Padwa / Chaitra Navaratri',
      sanskritName: 'युगादि / गुढीपाडवा / चैत्र नवरात्रारम्भः',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-03-19',
      deity: 'Brahma / Durga',
      masa: 'Chaitra',
      paksha: 'Shukla Paksha',
      tithi: 'Pratipada',
      nakshatra: 'Revati',
      timingRule: 'Udaya Tithi (Sunrise)',
      timingWindow: 'Morning auspicious inauguration',
      significance:
          'Traditional Hindu Lunar New Year marking the day Lord Brahma began the creation of the cosmos. Inception of the nine sacred days of Chaitra Vasanta Navaratri.',
      calculationConvention: 'Chaitra Shukla Pratipada at Sunrise (Drik Ganita)',
      sourceName: 'Brahma Purana, Creation Annals',
      sourceReference: 'Dharma Sindhu, Vatsarambha Nirnaya',
      regionalVariations:
          'Celebrated as Ugadi in Andhra Pradesh, Telangana, and Karnataka; Gudi Padwa in Maharashtra; Navreh in Kashmir; Sajibu Cheiraoba in Manipur.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0448',
      suggestedVratType: VratType.custom,
    ),
    FestivalEvent(
      id: 'fest_rama_navami_2026',
      name: 'Sri Rama Navami (Appearance of Bhagavan Rama)',
      sanskritName: 'श्रीरामनवमी (मध्याह्न जन्मकालः)',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-03-27',
      deity: 'Rama',
      masa: 'Chaitra',
      paksha: 'Shukla Paksha',
      tithi: 'Navami',
      nakshatra: 'Punarvasu',
      timingRule: 'Madhyahna (Midday 11:30 AM - 01:30 PM)',
      timingWindow: '11:15 AM - 01:45 PM (Rama Janma Muhurta)',
      significance:
          'Celebrates the midday birth of Maryada Purushottama Bhagavan Sri Rama in Ayodhya to establish righteousness (Dharma) and compassion on earth.',
      calculationConvention: 'Chaitra Shukla Navami prevailing at Madhyahna with Punarvasu nakshatra',
      sourceName: 'Valmiki Ramayana (Bala Kanda, Canto 18)',
      sourceReference: 'Nirnaya Sindhu, Sri Rama Navami Nirnaya',
      regionalVariations:
          'Celebrated across all Sanatana Dharma lineages with Akhanda Ramacharitmanas recitation, Panakam offering, and Kalyanotsavam in South India.',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0378',
      suggestedVratType: VratType.custom,
    ),
    FestivalEvent(
      id: 'fest_krishna_janmashtami_2026',
      name: 'Sri Krishna Janmashtami',
      sanskritName: 'श्रीकृष्ण जन्माष्टमी (निशीथ पूजा)',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-09-04',
      deity: 'Krishna',
      masa: 'Bhadrapada (Purnimanta) / Shravana (Amanta)',
      paksha: 'Krishna Paksha',
      tithi: 'Ashtami',
      nakshatra: 'Rohini',
      timingRule: 'Nishita Kala (Midnight)',
      timingWindow: '11:45 PM - 12:35 AM (Midnight Avatara Muhurta)',
      significance:
          'Commemorates the midnight appearance of Bhagavan Sri Krishna in Mathura as the supreme harbinger of divine love, grace, and Bhagavad Gita wisdom.',
      calculationConvention: 'Krishna Ashtami prevailing at midnight with Rohini nakshatra preference',
      sourceName: 'Srimad Bhagavatam (Canto 10, Chapter 3)',
      sourceReference: 'Nirnaya Sindhu, Janmashtami Nirnaya',
      regionalVariations:
          'Smartha and Vaishnava calendars frequently observe Janmashtami on successive days depending on Rohini nakshatra conjunction. Dahi Handi celebrated in Maharashtra.',
      associatedPujaGuideId: 'guide_vishnu_puja',
      associatedMantraId: 'VEDA-MTR-0378',
      suggestedVratType: VratType.custom,
    ),
    FestivalEvent(
      id: 'fest_ganesha_chaturthi_2026',
      name: 'Vinayaka / Ganesha Chaturthi',
      sanskritName: 'श्री गणेश चतुर्थी (मध्याह्न पूजा)',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-09-14',
      deity: 'Ganesha',
      masa: 'Bhadrapada',
      paksha: 'Shukla Paksha',
      tithi: 'Chaturthi',
      nakshatra: 'Hasta / Chitra',
      timingRule: 'Madhyahna (Midday)',
      timingWindow: '11:05 AM - 01:30 PM (Ganesha Sthapana Muhurta)',
      significance:
          'Revered domestic and public festival celebrating the manifestation of Lord Ganesha, embodiment of intellect, auspiciousness, and obstacle removal.',
      calculationConvention: 'Bhadrapada Shukla Chaturthi prevailing during Madhyahna',
      sourceName: 'Mudgala Purana, Ganesha Purana',
      sourceReference: 'Nirnaya Sindhu, Ganesha Chaturthi Nirnaya',
      regionalVariations:
          'Celebrated with clay murtis, 21 Modakas, Durva grass, and 10-day Anant Chaturdashi celebrations in Maharashtra, Goa, Karnataka, and Telangana.',
      associatedPujaGuideId: 'guide_ganesh_puja',
      associatedMantraId: 'VEDA-MTR-0454',
      suggestedVratType: VratType.sankashtiChaturthi,
    ),
    FestivalEvent(
      id: 'fest_dussehra_2026',
      name: 'Vijayadashami / Dussehra',
      sanskritName: 'विजयादशमी / दशहरा (अपराजिता पूजा)',
      category: FestivalCategory.majorFestival,
      targetDate: '2026-10-20',
      deity: 'Durga / Rama',
      masa: 'Ashvina',
      paksha: 'Shukla Paksha',
      tithi: 'Dashami',
      nakshatra: 'Shravana',
      timingRule: 'Aparajita Muhurta (Afternoon)',
      timingWindow: '01:45 PM - 02:35 PM (Aparajita Muhurta)',
      significance:
          'Celebrates Mother Durga vanquishing Mahishasura and Lord Rama vanquishing Ravana, signifying the ultimate victory of righteousness (Satya) over arrogance.',
      calculationConvention: 'Ashvina Shukla Dashami with Shravana Nakshatra & Aparajita Muhurta',
      sourceName: 'Devi Bhagavatam, Ramayana',
      sourceReference: 'Dharma Sindhu, Vijayadashami Nirnaya',
      regionalVariations:
          'Celebrated as Mysore Dasara in Karnataka, Kullu Dussehra in Himachal, and Sindoor Khela in Bengal.',
      associatedPujaGuideId: 'guide_morning_prayer',
      associatedMantraId: 'VEDA-MTR-0448',
    ),
  ];

  /// Find events matching a specific date (YYYY-MM-DD).
  static List<FestivalEvent> getEventsForDate(String dateStr) {
    return allEvents.where((e) => e.targetDate == dateStr).toList();
  }

  /// Find events for a specific month (year and month).
  static List<FestivalEvent> getEventsForMonth(int year, int month) {
    final prefix = '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}';
    return allEvents.where((e) => e.targetDate.startsWith(prefix)).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }

  /// Get event by its unique ID.
  static FestivalEvent? getEventById(String id) {
    try {
      return allEvents.firstWhere((e) => e.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search events by keyword or filter by category.
  static List<FestivalEvent> searchEvents({
    String? query,
    FestivalCategory? category,
  }) {
    return allEvents.where((e) {
      if (category != null && e.category != category) return false;
      if (query != null && query.isNotEmpty) {
        final q = query.toLowerCase();
        final match = e.name.toLowerCase().contains(q) ||
            e.sanskritName.contains(q) ||
            e.deity.toLowerCase().contains(q) ||
            e.tithi.toLowerCase().contains(q);
        if (!match) return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => a.targetDate.compareTo(b.targetDate));
  }
}
