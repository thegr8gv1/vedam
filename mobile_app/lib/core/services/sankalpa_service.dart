import 'package:shared_preferences/shared_preferences.dart';
import '../models/panchangam_data.dart';
import '../models/sankalpa_model.dart';

/// Service responsible for generating authentic Vedic Sankalpa recitations.
///
/// Binds universal cosmic time/space (Desha & Kala), daily astronomical Panchangam,
/// devotee lineage (Gotra & Nama), and ritual purpose (Prayojana).
class SankalpaService {
  static const String keyGotra = 'vedam_sankalpa_gotra';
  static const String keyName = 'vedam_sankalpa_name';
  static const String keyGender = 'vedam_sankalpa_gender';
  static const String keyRiverBasin = 'vedam_sankalpa_river_basin';
  static const String keyDeity = 'vedam_sankalpa_deity';

  final SharedPreferences? _injectedPrefs;
  SharedPreferences? _prefs;

  SankalpaService({SharedPreferences? prefs}) : _injectedPrefs = prefs;

  Future<SharedPreferences> _getPrefs() async {
    if (_prefs != null) return _prefs!;
    if (_injectedPrefs != null) {
      _prefs = _injectedPrefs;
      return _prefs!;
    }
    _prefs = await SharedPreferences.getInstance();
    return _prefs!;
  }

  /// Load saved devotee Sankalpa profile preferences from local storage.
  Future<SankalpaInput> loadSavedProfile({
    DateTime? date,
    DailyPanchangamData? panchangam,
    SankalpaPurpose purpose = SankalpaPurpose.dailySadhana,
  }) async {
    final prefs = await _getPrefs();
    final gotra = prefs.getString(keyGotra) ?? 'Vishnu';
    final name = prefs.getString(keyName) ?? 'Devotee';
    final genderStr = prefs.getString(keyGender) ?? 'unspecified';
    final riverStr = prefs.getString(keyRiverBasin) ?? 'pavitraDeshe';
    final deity = prefs.getString(keyDeity) ?? 'Sri Parameshwara / Narayana';

    SankalpaGender gender = SankalpaGender.unspecified;
    if (genderStr == 'male') gender = SankalpaGender.male;
    if (genderStr == 'female') gender = SankalpaGender.female;

    RiverBasinOption river = RiverBasinOption.pavitraDeshe;
    for (final r in RiverBasinOption.values) {
      if (r.name == riverStr) {
        river = r;
        break;
      }
    }

    return SankalpaInput(
      gotra: gotra,
      devoteeName: name,
      gender: gender,
      purpose: purpose,
      riverBasin: river,
      deityName: deity,
      date: date ?? DateTime.now(),
      panchangam: panchangam,
    );
  }

  /// Save devotee Sankalpa profile preferences locally.
  Future<void> saveProfile({
    required String gotra,
    required String devoteeName,
    required SankalpaGender gender,
    required RiverBasinOption riverBasin,
    required String deityName,
  }) async {
    final prefs = await _getPrefs();
    await prefs.setString(keyGotra, gotra.trim());
    await prefs.setString(keyName, devoteeName.trim());
    await prefs.setString(keyGender, gender.name);
    await prefs.setString(keyRiverBasin, riverBasin.name);
    await prefs.setString(keyDeity, deityName.trim());
  }

  /// Generate complete, structured Vedic Sankalpa based on input parameters.
  SankalpaOutput generateSankalpa(SankalpaInput input) {
    final date = input.date;

    // 1. Calculate astronomical variables
    final samvatsara = _calculateSamvatsara(date);
    final ayana = _calculateAyana(date);
    final ritu = _calculateRitu(date);
    final masa = _calculateMasa(date, input.panchangam);
    final paksha = input.panchangam?.paksha ?? _approximatePaksha(date);
    final tithi = input.panchangam?.tithi.sanskritName ?? _approximateTithi(date);
    final vara = input.panchangam?.vara.sanskritName ?? _calculateVara(date);
    final nakshatra = input.panchangam?.nakshatra.sanskritName ?? _approximateNakshatra(date);

    // 2. Format devotee identity strings
    final gotraFormatted = input.gotra.trim().isNotEmpty ? input.gotra.trim() : 'विष्णु';
    final devoteeFormatted = input.devoteeName.trim().isNotEmpty ? input.devoteeName.trim() : 'भक्त';

    String gotraSanskrit;
    String gotraIast;
    String gotraEnglish;
    if (gotraFormatted.toLowerCase().contains('gotra') || gotraFormatted.contains('गोत्र')) {
      gotraSanskrit = '$gotraFormatted-गोत्रोत्पन्नस्य';
      gotraIast = '${_toIast(gotraFormatted)}-gotrotpannasya';
      gotraEnglish = 'born of $gotraFormatted gotra';
    } else {
      gotraSanskrit = '$gotraFormatted-गोत्रस्य';
      gotraIast = '${_toIast(gotraFormatted)}-gotrasya';
      gotraEnglish = 'of $gotraFormatted gotra';
    }

    String nameSanskrit;
    String nameIast;
    if (input.gender == SankalpaGender.female) {
      nameSanskrit = '$devoteeFormatted नामधेयायाः';
      nameIast = '${_toIast(devoteeFormatted)} nāmadheyāyāḥ';
    } else if (input.gender == SankalpaGender.male) {
      nameSanskrit = '$devoteeFormatted शर्मणः';
      nameIast = '${_toIast(devoteeFormatted)} śarmaṇaḥ';
    } else {
      nameSanskrit = '$devoteeFormatted नामधेयस्य';
      nameIast = '${_toIast(devoteeFormatted)} nāmadheyasya';
    }

    // 3. Construct Section 1: Cosmic Time (Universal Invocation)
    final comp1 = const SankalpaComponent(
      sectionTitle: 'Cosmic Invocation & Epoch (कालोद्देश)',
      sanskritText: 'ॐ विष्णुर्विष्णुर्विष्णुः श्रीमद्भगवतो महापुरुषस्य विष्णोराज्ञया प्रवर्तमानस्य '
          'अद्य ब्रह्मणो द्वितीयपरार्धे श्रीश्वेतवाराहकल्पे वैवस्वतमन्वन्तरे अष्टाविंशतितमे '
          'कलियुगे कलिप्रथमचरणे',
      iastText: 'oṃ viṣṇur-viṣṇur-viṣṇuḥ śrīmad-bhagavato mahāpuruṣasya viṣṇor-ājñayā pravartamānasya '
          'adya brahmaṇo dvitīya-parārdhe śrī-śveta-vārāha-kalpe vaivasvata-manvantare aṣṭā-viṃśatitame '
          'kali-yuge kali-prathama-caraṇe',
      englishMeaning: 'Om. In supreme remembrance of Lord Vishnu, under the divine governance of the Cosmic Being, '
          'in the second half of Brahma’s cosmic life, in the Sveta Varaha Kalpa, in the Vaivasvata Manvantara, '
          'in the 28th Kali Yuga, in its first quarter...',
    );

    // 4. Construct Section 2: Sacred Geography (Desha)
    final riverSanskrit = input.riverBasin.sanskritPhrase;
    final riverIast = input.riverBasin.iastPhrase;
    final riverEnglish = input.riverBasin.displayName;

    final comp2 = SankalpaComponent(
      sectionTitle: 'Sacred Geography (देशनिर्देश)',
      sanskritText: 'जम्बूद्वीपे भारतवर्षे भरतखण्डे मेरोः दक्षिणे पार्श्वे $riverSanskrit '
          'अस्मिन् वर्तमाने व्यावहारिक चान्द्रमानेन',
      iastText: 'jambūdvīpe bhāratavarṣe bharatakhaṇḍe meroḥ dakṣiṇe pārśve $riverIast '
          'asmin vartamāne vyāvahārika cāndramānena',
      englishMeaning: 'In the sacred realm of Jambu Dweepa, in Bharata Varsha, in Bharata Khanda, '
          'to the south of Mount Meru, in $riverEnglish, in this current civil and lunar reckoning...',
    );

    // 5. Construct Section 3: Panchangam Astronomical Coordinates (Kala)
    final comp3 = SankalpaComponent(
      sectionTitle: 'Daily Panchangam Coordinates (पञ्चाङ्ग)',
      sanskritText: '$samvatsara नाम संवत्सरे, $ayana अयने, $ritu ऋतौ, $masa मासे, $paksha पक्षे, '
          '$tithi शुभतिथौ, $vara वासरे, $nakshatra शुभनक्षत्रे, शुभयोगे शुभकरणे एवं गुणविशेषण विशिष्टायां शुभपुण्यतिथौ',
      iastText: '${_toIast(samvatsara)} nāma saṃvatsare, ${_toIast(ayana)} ayane, ${_toIast(ritu)} ṛtau, '
          '${_toIast(masa)} māse, ${_toIast(paksha)} pakṣe, ${_toIast(tithi)} śubha-tithau, '
          '${_toIast(vara)} vāsare, ${_toIast(nakshatra)} śubha-nakṣatre, śubha-yoge śubha-karaṇe '
          'evaṃ guṇa-viśeṣaṇa viśiṣṭāyāṃ śubha-puṇya-tithau',
      englishMeaning: 'In the $samvatsara year, during $ayana, in the $ritu season, in the month of $masa, '
          'in $paksha, on the auspicious lunar day of $tithi, on $vara, under the $nakshatra asterism, '
          'blessed with auspicious yoga and karana, on this sacred day endowed with all divine virtues...',
    );

    // 6. Construct Section 4: Lineage & Devotee Identity (Yajamana)
    final comp4 = SankalpaComponent(
      sectionTitle: 'Lineage & Devotee Identity (यजमानगोत्रनाम)',
      sanskritText: '$gotraSanskrit $nameSanskrit मम आत्मनः श्रुतिस्मृतिपुराणोक्त फलप्राप्त्यर्थं '
          'मम सहकुटुम्बस्य क्षेमस्थैर्यधैर्यवीर्यविजयायुरारोग्यैश्वर्याभिवृद्ध्यर्थं समस्तदुरितक्षयद्वारा',
      iastText: '$gotraIast $nameIast mama ātmanaḥ śruti-smṛti-purāṇokta phala-prāptyarthaṃ '
          'mama sahakuṭumbasya kṣema-sthairya-dhairya-vīrya-vijayāyur-ārogyaiśvaryābhivṛddhyarthaṃ samasta-durita-kṣaya-dvārā',
      englishMeaning: '$gotraEnglish, known as $devoteeFormatted, for the attainment of the fruits promised in '
          'the Sruti, Smriti, and Puranas, for the cultivation of peace, courage, steadfastness, victory, '
          'longevity, radiant health, and spiritual abundance for myself and family, and through the dissolution '
          'of all accumulated afflictions...',
    );

    // 7. Construct Section 5: Prayojana (Ritual Purpose)
    final prayojana = _constructPrayojana(input);
    final comp5 = SankalpaComponent(
      sectionTitle: 'Devotional Purpose (सङ्कल्पप्रयोजन)',
      sanskritText: prayojana.sanskrit,
      iastText: prayojana.iast,
      englishMeaning: prayojana.english,
    );

    final allComponents = [comp1, comp2, comp3, comp4, comp5];

    final sanskritFull = allComponents.map((c) => c.sanskritText).join(' ');
    final iastFull = allComponents.map((c) => c.iastText).join(' ');
    final englishFull = allComponents.map((c) => c.englishMeaning).join(' ');

    // 8. Construct Short Sankalpa for rapid daily recitation
    final shortPurposeSanskrit = _shortPurposeSanskrit(input.purpose);
    final shortPurposeIast = _shortPurposeIast(input.purpose);
    final shortPurposeEnglish = _shortPurposeEnglish(input.purpose);

    final shortSanskrit = 'ॐ अद्य $tithi तिथौ $vara वासरे $gotraSanskrit $nameSanskrit '
        'मम समस्तदुरितक्षयपूर्वकं श्री ${input.deityName} प्रीत्यर्थं $shortPurposeSanskrit करिष्ये ॥';
    final shortIast = 'oṃ adya ${_toIast(tithi)} tithau ${_toIast(vara)} vāsare $gotraIast $nameIast '
        'mama samasta-durita-kṣaya-pūrvakaṃ śrī ${input.deityName} prītyarthaṃ $shortPurposeIast kariṣye ||';
    final shortEnglish = 'Om. On this $tithi lunar day, on $vara, $gotraEnglish, $devoteeFormatted, '
        'for the dissolution of all obstacles and the supreme grace of ${input.deityName}, '
        'I resolve to perform $shortPurposeEnglish.';

    return SankalpaOutput(
      components: allComponents,
      sanskritFull: sanskritFull,
      iastFull: iastFull,
      englishFull: englishFull,
      shortSanskrit: shortSanskrit,
      shortIast: shortIast,
      shortEnglish: shortEnglish,
      samvatsara: samvatsara,
      ayana: ayana,
      ritu: ritu,
      masa: masa,
      paksha: paksha,
      tithi: tithi,
      vara: vara,
      nakshatra: nakshatra,
      date: date,
    );
  }

  // --- Helper Methods ---

  static const List<String> _samvatsaras = [
    'प्रभव', 'विभव', 'शुक्ल', 'प्रमोद', 'प्रजापति', 'अङ्गिरस', 'श्रीमुख', 'भाव', 'युव', 'धातु',
    'ईश्वर', 'बहुधान्य', 'प्रमाथी', 'विक्रम', 'वृष', 'चित्रभानु', 'सुभानु', 'तारण', 'पार्थिव', 'व्यय',
    'सर्वजित्', 'सर्वधारी', 'विरोधी', 'विकृति', 'खर', 'नन्दन', 'विजय', 'जय', 'मन्मथ', 'दुर्मुख',
    'हेविलम्बि', 'विलम्बि', 'विकारी', 'शार्वरी', 'प्लव', 'शुभकृत्', 'शोभकृत्', 'क्रोधी', 'विश्वावसु', 'पराभव',
    'प्लवङ्ग', 'कीलक', 'सौम्य', 'साधारण', 'विरोधकृत्', 'परिधावि', 'प्रमादी', 'आनन्द', 'राक्षस', 'नल',
    'पिङ्गल', 'कालयुक्त', 'सिद्धार्थी', 'रौद्र', 'दुर्मति', 'दुन्दुभि', 'रुधिरोद्गारी', 'रक्ताक्षी', 'क्रोधन', 'क्षय'
  ];

  String _calculateSamvatsara(DateTime date) {
    // Gregorian to Hindu Jovian Samvatsara index calculation
    // Epoch: Kali Yuga 5125 corresponds to Krodhi (#38) starting Chaitra 2024.
    // Index offset formula: (Year + 9) % 60 gives traditional Samvatsara index.
    int year = date.year;
    // Before Chaitra (approx March 25 - April 10), it belongs to previous samvatsara
    if (date.month < 4 || (date.month == 4 && date.day < 9)) {
      year -= 1;
    }
    int index = (year + 9) % 60;
    if (index < 0) index += 60;
    return _samvatsaras[index];
  }

  String _calculateAyana(DateTime date) {
    // Uttarayana: Makara Sankranti (approx Jan 14) to Karka Sankranti (approx Jul 16)
    final dayOfYear = date.difference(DateTime(date.year, 1, 1)).inDays + 1;
    if (dayOfYear >= 14 && dayOfYear < 197) {
      return 'उत्तरायण';
    } else {
      return 'दक्षिणायन';
    }
  }

  String _calculateRitu(DateTime date) {
    // 6 Vedic Seasons (Vasanta, Grishma, Varsha, Sharad, Hemanta, Shishira)
    final m = date.month;
    if (m == 3 || m == 4) return 'वसन्त'; // Chaitra - Vaishakha
    if (m == 5 || m == 6) return 'ग्रीष्म'; // Jyeshtha - Ashadha
    if (m == 7 || m == 8) return 'वर्षा'; // Shravana - Bhadrapada
    if (m == 9 || m == 10) return 'शरद्'; // Ashvina - Kartika
    if (m == 11 || m == 12) return 'हेमन्त'; // Margashirsha - Pausha
    return 'शिशिर'; // Magha - Phalguna (Jan - Feb)
  }

  String _calculateMasa(DateTime date, DailyPanchangamData? panchangam) {
    if (panchangam != null && panchangam.observances.isNotEmpty) {
      for (final obs in panchangam.observances) {
        if (obs.name.contains('Masa') || obs.name.contains('मास') || obs.sanskritName.contains('मास')) {
          return obs.name;
        }
      }
    }
    // Solar / Lunar month approximation based on calendar month
    const masasList = [
      'पौष / माघ', 'माघ / फाल्गुन', 'फाल्गुन / चैत्र', 'चैत्र / वैशाख',
      'वैशाख / ज्येष्ठ', 'ज्येष्ठ / आषाढ', 'आषाढ / श्रावण', 'श्रावण / भाद्रपद',
      'भाद्रपद / आश्विन', 'आश्विन / कार्तिक', 'कार्तिक / मार्गशीर्ष', 'मार्गशीर्ष / पौष'
    ];
    return masasList[(date.month - 1) % 12];
  }

  String _calculateVara(DateTime date) {
    switch (date.weekday) {
      case DateTime.monday:
        return 'इन्दु / सोम';
      case DateTime.tuesday:
        return 'भौम / मङ्गल';
      case DateTime.wednesday:
        return 'सौम्य / बुध';
      case DateTime.thursday:
        return 'गुरु / बृहस्पति';
      case DateTime.friday:
        return 'भृगु / शुक्र';
      case DateTime.saturday:
        return 'स्थिर / मन्द / शनि';
      case DateTime.sunday:
      default:
        return 'भानु / रवि';
    }
  }

  String _approximatePaksha(DateTime date) {
    // Synodic lunar phase approximation (29.530588 days)
    // Reference new moon: Jan 11, 2024 11:57 UTC
    final refNewMoon = DateTime.utc(2024, 1, 11, 11, 57);
    final diffDays = date.toUtc().difference(refNewMoon).inSeconds / 86400.0;
    final phaseDays = diffDays % 29.530588;
    return phaseDays < 14.765 ? 'शुक्ल' : 'कृष्ण';
  }

  String _approximateTithi(DateTime date) {
    final refNewMoon = DateTime.utc(2024, 1, 11, 11, 57);
    final diffDays = date.toUtc().difference(refNewMoon).inSeconds / 86400.0;
    final phaseDays = diffDays % 29.530588;
    final tithiIndex = ((phaseDays / 29.530588) * 30).floor() % 30;
    const tithis = [
      'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पञ्चमी', 'षष्ठी', 'सप्तमी', 'अष्टमी',
      'नवमी', 'दशमी', 'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी', 'पूर्णिमा',
      'प्रतिपदा', 'द्वितीया', 'तृतीया', 'चतुर्थी', 'पञ्चमी', 'षष्ठी', 'सप्तमी', 'अष्टमी',
      'नवमी', 'दशमी', 'एकादशी', 'द्वादशी', 'त्रयोदशी', 'चतुर्दशी', 'अमावस्या'
    ];
    return tithis[tithiIndex];
  }

  String _approximateNakshatra(DateTime date) {
    const nakshatras = [
      'अश्विनी', 'भरणी', 'कृत्तिका', 'रोहिणी', 'मृगशिरा', 'आर्द्रा', 'पुनर्वसु', 'पुष्य',
      'आश्लेषा', 'मघा', 'पूर्वाफाल्गुनी', 'उत्तराफाल्गुनी', 'हस्त', 'चित्रा', 'स्वाती',
      'विशाखा', 'अनुराधा', 'ज्येष्ठा', 'मूल', 'पूर्वाषाढा', 'उत्तराषाढा', 'श्रवण',
      'धनिष्ठा', 'शतभिषा', 'पूर्वाभाद्रपदा', 'उत्तराभाद्रपदा', 'रेवती'
    ];
    // Sidereal Moon orbital period is ~27.321661 days
    final refEpoch = DateTime.utc(2024, 1, 1, 0, 0);
    final days = date.toUtc().difference(refEpoch).inSeconds / 86400.0;
    final index = (days % 27.321661 / (27.321661 / 27)).floor() % 27;
    return nakshatras[index];
  }

  ({String sanskrit, String iast, String english}) _constructPrayojana(SankalpaInput input) {
    final deity = input.deityName.trim().isNotEmpty ? input.deityName.trim() : 'श्रीपरमेश्वर';
    switch (input.purpose) {
      case SankalpaPurpose.dailySadhana:
        return (
          sanskrit: 'श्री $deity प्रीत्यर्थं प्रातः/सायं नित्यकर्म नित्यसाधनां करिष्ये ॥',
          iast: 'śrī ${_toIast(deity)} prītyarthaṃ prātaḥ/sāyaṃ nitya-karma nitya-sādhanāṃ kariṣye ||',
          english: 'For the divine grace and pleasure of Sri $deity, I resolve to undertake my daily devotional contemplation and sadhana.',
        );
      case SankalpaPurpose.japaPractice:
        return (
          sanskrit: 'भगवतः श्री $deity प्रसादेन कायिकवाचिकमानसिक पापनिवृत्त्यर्थं अभीष्टसिद्धये एकाग्रचित्तेन मन्त्रजपं करिष्ये ॥',
          iast: 'bhagavataḥ śrī ${_toIast(deity)} prasādena kāyika-vācika-mānasika pāpa-nivṛttyarthaṃ abhīṣṭa-siddhaye ekāgra-cittena mantra-japaṃ kariṣye ||',
          english: 'By the grace of Sri $deity, for the purification of body, speech, and mind, and the attainment of righteous spiritual fulfillment, with one-pointed focus I resolve to perform sacred mantra japa.',
        );
      case SankalpaPurpose.shodashopacharaPuja:
        return (
          sanskrit: 'श्री $deity प्रीत्यर्थं यथामिलितोपचारैः भक्तिश्रद्धायुतेन षोडशोपचार पूजां करिष्ये ॥',
          iast: 'śrī ${_toIast(deity)} prītyarthaṃ yathā-militopacāraiḥ bhakti-śraddhāyutena ṣoḍaśopacāra pūjāṃ kariṣye ||',
          english: 'For the supreme pleasure of Sri $deity, with available sacred offerings and imbued with sincere faith and devotion, I resolve to perform the 16-step (Shodashopachara) worship.',
        );
      case SankalpaPurpose.vratObservance:
        return (
          sanskrit: 'श्री $deity प्रीत्यर्थं अन्तःकरणशुद्धये व्रत/उपवास नियमधारणं करिष्ये ॥',
          iast: 'śrī ${_toIast(deity)} prītyarthaṃ antaḥ-karaṇa-śuddhaye vrata/upavāsa niyama-dhāraṇaṃ kariṣye ||',
          english: 'For the supreme pleasure of Sri $deity, and for inner mental and spiritual purification, I resolve to undertake this sacred vrat and fasting observance.',
        );
      case SankalpaPurpose.sandhyavandanam:
        return (
          sanskrit: 'मम उपात्त समस्तदुरितक्षयद्वारा श्रीपरमेश्वरप्रीत्यर्थं सन्ध्यावन्दनं करिष्ये ॥',
          iast: 'mama upātta samasta-durita-kṣaya-dvārā śrī-parameśvara-prītyarthaṃ sandhyāvandanaṃ kariṣye ||',
          english: 'For the dissolution of all accumulated misdeeds and the eternal grace of the Supreme Lord, I resolve to perform sacred Sandhyavandanam.',
        );
      case SankalpaPurpose.custom:
        final custom = input.customIntention?.trim();
        if (custom != null && custom.isNotEmpty) {
          return (
            sanskrit: '$custom सङ्कल्पपूर्वकं श्री $deity प्रीत्यर्थं करिष्ये ॥',
            iast: '${_toIast(custom)} saṅkalpa-pūrvakaṃ śrī ${_toIast(deity)} prītyarthaṃ kariṣye ||',
            english: 'With the focused personal intention of "$custom", for the supreme pleasure and grace of Sri $deity, I resolve to perform this sacred practice.',
          );
        }
        return (
          sanskrit: 'श्री $deity प्रीत्यर्थं शुभसङ्कल्पं करिष्ये ॥',
          iast: 'śrī ${_toIast(deity)} prītyarthaṃ śubha-saṅkalpaṃ kariṣye ||',
          english: 'For the supreme grace and divine pleasure of Sri $deity, I formulate this auspicious intention.',
        );
    }
  }

  String _shortPurposeSanskrit(SankalpaPurpose p) {
    switch (p) {
      case SankalpaPurpose.dailySadhana:
        return 'नित्यसाधनां';
      case SankalpaPurpose.japaPractice:
        return 'मन्त्रजपं';
      case SankalpaPurpose.shodashopacharaPuja:
        return 'षोडशोपचार पूजां';
      case SankalpaPurpose.vratObservance:
        return 'व्रतनियमधारणं';
      case SankalpaPurpose.sandhyavandanam:
        return 'सन्ध्यावन्दनं';
      case SankalpaPurpose.custom:
        return 'सङ्कल्पकर्म';
    }
  }

  String _shortPurposeIast(SankalpaPurpose p) {
    switch (p) {
      case SankalpaPurpose.dailySadhana:
        return 'nitya-sādhanāṃ';
      case SankalpaPurpose.japaPractice:
        return 'mantra-japaṃ';
      case SankalpaPurpose.shodashopacharaPuja:
        return 'ṣoḍaśopacāra pūjāṃ';
      case SankalpaPurpose.vratObservance:
        return 'vrata-niyama-dhāraṇaṃ';
      case SankalpaPurpose.sandhyavandanam:
        return 'sandhyāvandanaṃ';
      case SankalpaPurpose.custom:
        return 'saṅkalpa-karma';
    }
  }

  String _shortPurposeEnglish(SankalpaPurpose p) {
    switch (p) {
      case SankalpaPurpose.dailySadhana:
        return 'daily sadhana';
      case SankalpaPurpose.japaPractice:
        return 'mantra japa';
      case SankalpaPurpose.shodashopacharaPuja:
        return 'shodashopachara worship';
      case SankalpaPurpose.vratObservance:
        return 'vrat observance';
      case SankalpaPurpose.sandhyavandanam:
        return 'sandhyavandanam';
      case SankalpaPurpose.custom:
        return 'sacred contemplation';
    }
  }

  String _toIast(String devanagariText) {
    // Practical phonetic transliteration dictionary for key liturgical terms
    final map = {
      'प्रभव': 'prabhava', 'विभव': 'vibhava', 'शुक्ल': 'śukla', 'प्रमोद': 'pramoda',
      'प्रजापति': 'prajāpati', 'अङ्गिरस': 'aṅgirasa', 'श्रीमुख': 'śrīmukha', 'भाव': 'bhāva',
      'युव': 'yuva', 'धातु': 'dhātu', 'ईश्वर': 'īśvara', 'बहुधान्य': 'bahudhānya',
      'प्रमाथी': 'pramāthī', 'विक्रम': 'vikrama', 'वृष': 'vṛṣa', 'चित्रभानु': 'citrabhānu',
      'सुभानु': 'subhānu', 'तारण': 'tāraṇa', 'पार्थिव': 'pārthiva', 'व्यय': 'vyaya',
      'सर्वजित्': 'sarvajit', 'सर्वधारी': 'sarvadhārī', 'विरोधी': 'virodhī', 'विकृति': 'vikṛti',
      'खर': 'khara', 'नन्दन': 'nandana', 'विजय': 'vijaya', 'जय': 'jaya', 'मन्मथ': 'manmatha',
      'दुर्मुख': 'durmukha', 'हेविलम्बि': 'hevilambi', 'विलम्बि': 'vilambi', 'विकारी': 'vikārī',
      'शार्वरी': 'śārvarī', 'प्लव': 'plava', 'शुभकृत्': 'śubhakṛt', 'शोभकृत्': 'śobhakṛt',
      'क्रोधी': 'krodhī', 'विश्वावसु': 'viśvāvasu', 'पराभव': 'parābhava', 'प्लवङ्ग': 'plavaṅga',
      'कीलक': 'kīlaka', 'सौम्य': 'saumya', 'साधारण': 'sādhāraṇa', 'विरोधकृत्': 'virodhakṛt',
      'परिधावि': 'paridhāvi', 'प्रमादी': 'pramādī', 'आनन्द': 'ānanda', 'राक्षस': 'rākṣasa',
      'नल': 'nala', 'पिङ्गल': 'piṅgala', 'कालयुक्त': 'kālayukta', 'सिद्धार्थी': 'siddhārthī',
      'रौद्र': 'raudra', 'दुर्मति': 'durmati', 'दुन्दुभि': 'dundubhi', 'रुधिरोद्गारी': 'rudhirodgārī',
      'रक्ताक्षी': 'raktākṣī', 'क्रोधन': 'krodhana', 'क्षय': 'kṣaya',
      'उत्तरायण': 'uttarāyaṇa', 'दक्षिणायन': 'dakṣiṇāyana',
      'वसन्त': 'vasanta', 'ग्रीष्म': 'grīṣma', 'वर्षा': 'varṣā', 'शरद्': 'śarad',
      'हेमन्त': 'hemanta', 'शिशिर': 'śiśira',
      'कृष्ण': 'kṛṣṇa',
      'प्रतिपदा': 'pratipadā', 'द्वितीया': 'dvitīyā', 'तृतीया': 'tṛtīyā', 'चतुर्थी': 'caturthī',
      'पञ्चमी': 'pañcamī', 'षष्ठी': 'ṣaṣṭhī', 'सप्तमी': 'saptamī', 'अष्टमी': 'aṣṭamī',
      'नवमी': 'navamī', 'दशमी': 'daśamī', 'एकादशी': 'ekādaśī', 'द्वादशी': 'dvādaśī',
      'त्रयोदशी': 'trayodaśī', 'चतुर्दशी': 'caturdaśī', 'पूर्णिमा': 'pūrṇimā', 'अमावस्या': 'amāvāsyā',
      'इन्दु / सोम': 'indu / soma', 'भौम / मङ्गल': 'bhauma / maṅgala', 'सौम्य / बुध': 'saumya / budha',
      'गुरु / बृहस्पति': 'guru / bṛhaspati', 'भृगु / शुक्र': 'bhṛgu / śukra',
      'स्थिर / मन्द / शनि': 'sthira / manda / śani', 'भानु / रवि': 'bhānu / ravi',
      'विष्णु': 'viṣṇu', 'शिव': 'śiva', 'कश्यप': 'kaśyapa', 'भारद्वाज': 'bhāradvāja',
      'वसिष्ठ': 'vasiṣṭha', 'गौतम': 'gautama', 'विश्वामित्र': 'viśvāmitra', 'जमदग्नि': 'jamadagni',
      'अत्रि': 'atri', 'अङ्गिरा': 'aṅgirā', 'श्रीपरमेश्वर': 'śrī-parameśvara',
    };

    if (map.containsKey(devanagariText)) return map[devanagariText]!;

    // Return original if unknown (preserves user-inputted Roman script cleanly)
    return devanagariText;
  }
}
