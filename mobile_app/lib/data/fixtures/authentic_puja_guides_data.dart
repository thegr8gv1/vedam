import '../../core/models/puja_guide.dart';

/// Authentic Curated Collection of Guided Pujas and Devotional Practices.
/// Sourced from traditional Grihya and domestic worship paddhatis (Pancha Upachara).
/// Every guide carries explicit editorial status, sourcing disclosure, and sampradaya variance notes.
class AuthenticPujaGuidesData {
  static const List<PujaGuide> allGuides = [
    // 1. GANESHA PUJA
    PujaGuide(
      id: 'guide_ganesh_puja',
      title: 'Daily Ganesha Pancha Upachara Puja',
      sanskritTitle: 'श्री गणेश पञ्चोपचार पूजा',
      deity: 'Ganesha',
      tradition: 'Pancha Upachara (Five-fold Worship)',
      shortIntro:
          'A simple, revered domestic worship ritual offered to Lord Ganesha to remove obstacles, bestow wisdom, and consecrate the day.',
      purposeAndContext:
          'In Sanatana Dharma, Lord Ganesha is the Prathama Pujya (first revered). This five-fold offering (Gandha, Pushpa, Dhupa, Deepa, Naivedya) is the classic daily household paddhati accessible to any devotee without requiring complex priest ordination.',
      preparation: [
        'Clean the home altar or quiet prayer corner.',
        'Bathe or wash hands, feet, and face with clean water.',
        'Sit comfortably facing east or north on a clean mat (asana).',
        'Light a traditional ghee or sesame oil lamp (diya) and an incense stick.',
      ],
      materialsList: [
        'Murti or picture of Lord Ganesha',
        'Clean water in a cup (Achamana patra) with a small spoon',
        'Sandalwood paste (Chandan) and Kumkum',
        'Fresh flower(s) or unbroken yellow rice (Akshata)',
        'Incense stick (Dhupa) and Lit oil lamp (Deepa)',
        'Clean fruit, jaggery, or sweet offering (Naivedyam)',
      ],
      estimatedDurationMinutes: 10,
      editorialStatus: 'Verified Editorial Guide',
      contentVerificationStatus: 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: [
        'Mudgala Purana (Ganesha Dhyana Sloka)',
        'Baudhayana Grihya Sutra (Pancha Upachara Vidhi)',
        'Smartha Nitya Karma Paddhati',
      ],
      sourceInfo:
          'Based on classical Smartha and Grihya domestic worship manuals (Pancha Upachara Vidhi). Simplified for daily home reverence.',
      regionalVarianceNote:
          'Standard domestic Pancha Upachara format. Detailed Shodasha Upachara (16 steps) or Vedic Atharvashirsha Havanam may be performed on Vinayaka Chaturthi according to family lineage or temple tradition.',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Dhyānam & Prārthanā (Meditation & Invocation)',
          upacharaName: 'Dhyānam',
          actionDescription:
              'Sit with a straight posture. Bring palms together before your heart in Anjali Mudra. Visualize Lord Ganesha seated on a lotus, smiling with compassionate eyes.',
          sanskritMantra:
              'वक्रतुण्ड महाकाय सूर्यकोटि समप्रभ ।\nनिर्विघ्नं कुरु मे देव सर्वकार्येषु सर्वदा ॥',
          transliteration:
              'Vakratuṇḍa mahākāya sūryakoṭi samaprabha |\nNirvighnaṁ kuru me deva sarvakāryeṣu sarvadā ||',
          meaning:
              'O Lord of curved trunk and mighty form, whose radiance equals millions of suns: please remove all obstacles from all my endeavors, always.',
          scripturalSource: 'Mudgala Purana / Classical Smriti Invocation',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0454',
          linkedMantraTitle: 'Vakratunda Mahakaya',
          expandedInstructions: [
            'Take three slow, deep breaths.',
            'Let go of tension and bring mind to gentle stillness.',
            'Acknowledge Ganesha as the protector who clears inner and outer hurdles.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Gandham Samarpayāmi (Offering Sandalwood Paste)',
          upacharaName: 'Gandham',
          actionDescription:
              'Take a tiny dab of fragrant sandalwood paste (Chandan) and kumkum with your ring finger and gently apply it to the forehead or feet of the Ganesha image.',
          sanskritMantra:
              'ॐ श्री गणेशाय नमः ।\nदिव्य परिमलगन्धं समर्पयामि ॥',
          transliteration:
              'Om śrī gaṇeśāya namaḥ |\nDivya parimalagandhaṁ samarpayāmi ||',
          meaning:
              'Om, salutations to Lord Ganesha. I offer this divine fragrant sandalwood paste.',
          scripturalSource: 'Grihya Nitya Puja Paddhati',
          stepProvenance: 'traditional_grihya_action',
          linkedMantraId: 'VEDA-MTR-0446',
          linkedMantraTitle: 'Om Gam Ganapataye Namaha',
          expandedInstructions: [
            'Sandalwood represents coolness, calmness, and pure mind.',
            'If you don\'t have Chandan, unbroken rice mixed with turmeric (Akshata) is universally accepted.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Puṣpam Samarpayāmi (Offering Flowers / Akshata)',
          upacharaName: 'Puṣpam',
          actionDescription:
              'Offer a fresh red flower (hibiscus is dear to Ganesha) or a pinch of clean Akshata at the feet of the deity with reverence.',
          sanskritMantra:
              'ॐ श्री गणेशाय नमः ।\nनानाविध परिमलपुष्पाणि समर्पयामि ॥',
          transliteration:
              'Om śrī gaṇeśāya namaḥ |\nNānāvidha parimalapuṣpāṇi samarpayāmi ||',
          meaning:
              'Om, salutations to Lord Ganesha. I offer fresh, fragrant blossoms with loving devotion.',
          scripturalSource: 'Grihya Nitya Puja Paddhati',
          stepProvenance: 'traditional_grihya_action',
          linkedMantraId: 'VEDA-MTR-0426',
          linkedMantraTitle: 'Ganesha Shloka',
          expandedInstructions: [
            'Hold the flower between thumb and ring finger.',
            'Release gently at the sacred image\'s feet, not thrown from a distance.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dhūpam & Dīpam Darśayāmi (Incense & Lamp Offering)',
          upacharaName: 'Dhūpa & Dīpa',
          actionDescription:
              'Wave lit incense stick clockwise three times in front of the deity, followed by circular adoration with the ghee lamp.',
          sanskritMantra:
              'वनस्पतिरसो दिव्यो गन्धाढ्यः सुमनोहरः ।\nआघ्रेयः सर्वदेवानां धूपोऽयं प्रतिगृह्यताम् ॥',
          transliteration:
              'Vanaspati-raso divyo gandhāḍhyaḥ sumanoharaḥ |\nĀghreyaḥ sarvadevānāṁ dhūpo\'yaṁ pratigṛhyatām ||',
          meaning:
              'This fragrant essence of sacred botanicals, pleasing to all divine beings: may this holy incense be accepted.',
          scripturalSource: 'Agni Purana / Smriti Paddhati',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Incense reminds us to spread sweet noble fragrance wherever we go.',
            'The lamp reminds us to ignite spiritual wisdom, removing the darkness of ignorance.',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Naivedyam & Praṇāma (Sweet Offering & Surrender)',
          upacharaName: 'Naivedyam',
          actionDescription:
              'Place a piece of clean fresh fruit, jaggery, or pure water before the deity. Conclude with bowing down with both hands folded in total surrender.',
          sanskritMantra:
              'ॐ भूर्भुवः स्वः । तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ।\nदेव सवितः प्रसुव सत्यं त्वर्तेन परिषञ्चामि ।\nअमृतोपस्तरणमसि स्वाहा । ॐ श्री गणेशाय नमः नैवेद्यं समर्पयामि ॥',
          transliteration:
              'Om bhūrbhuvaḥ svaḥ | Tat-savitur-vareṇyaṁ bhargo devasya dhīmahi dhiyo yo naḥ pracodayāt |\nDeva savitaḥ prasuva satyaṁ tvar tena pariṣañcāmi |\nAmṛtopastaraṇamasi svāhā | Om śrī gaṇeśāya namaḥ naivedyaṁ samarpayāmi ||',
          meaning:
              'We sprinkle sacred water around the pure food and offer it with reverence. Salutations to Lord Ganesha, I offer this pure food offering.',
          scripturalSource: 'Maitrayani Samhita / Grihya Naivedya Vidhi',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0454',
          linkedMantraTitle: 'Vakratunda Mahakaya',
          expandedInstructions: [
            'Sprinkle a drop of water around the offering plate in a circle.',
            'Wave hand gently toward the murti inviting the Lord to accept the essence (Bhava).',
            'Bow down with forehead touching ground or palms on heart, praying for wisdom and upright conduct.',
          ],
        ),
      ],
    ),

    // 2. SHIVA PUJA
    PujaGuide(
      id: 'guide_shiva_puja',
      title: 'Daily Shiva Pancha Upachara Puja',
      sanskritTitle: 'श्री शिव पञ्चोपचार पूजा',
      deity: 'Shiva',
      tradition: 'Shaiva Grihya Paddhati',
      shortIntro:
          'A quiet, contemplative daily worship offered to Lord Shiva / Mahadeva for inner stillness, purity of intellect, and liberation.',
      purposeAndContext:
          'Lord Shiva represents the transcendent consciousness (Chaitanya) and stillness beneath life\'s turbulence. A simple daily offering of clean water, sacred ash (Bhasma), fragrant Chandan, and Bilva leaf clears worldly agitation and restores profound spiritual peace.',
      preparation: [
        'Clean the Shiva Linga or picture of Lord Shiva.',
        'Keep fresh clean water in an Arghya vessel.',
        'Have sacred ash (Vibhuti / Bhasma) and Chandan ready.',
        'Fresh Bilva leaves (three-petal leaf) or white blossoms.',
        'Light a ghee lamp.',
      ],
      materialsList: [
        'Shiva Linga or image of Mahadeva',
        'Pure water for Abhishekam in a small pot with spoon',
        'Vibhuti (Sacred Ash) and Sandalwood paste',
        'Bilva leaves (Tridalam) or white flowers',
        'Lit incense and ghee lamp',
        'Fresh fruit or milk offering',
      ],
      estimatedDurationMinutes: 12,
      editorialStatus: 'Verified Editorial Guide',
      contentVerificationStatus: 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: [
        'Bilvashtakam (Classical Shaiva Stotra)',
        'Rigveda Mandala 7.59.12 (Maha Mrityunjaya)',
        'Shaiva Grihya Agama Paddhati',
      ],
      sourceInfo:
          'Based on traditional Shaiva Grihya worship paddhatis and classical Stotra literature.',
      regionalVarianceNote:
          'Standard domestic Pancha Upachara format. Detailed Rudra Abhisheka with Vedic Chamakam is traditionally performed in temples or by trained priests; this guide is an accessible personal daily practice.',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Dhyānam (Meditation on the Supreme Auspiciousness)',
          upacharaName: 'Dhyānam',
          actionDescription:
              'Close your eyes and visualize Lord Shiva seated in deep meditation on Mount Kailash, serene and compassionate.',
          sanskritMantra:
              'ध्यायेन्नित्यं महेशं रजतगिरिनिभं चारुचन्द्रावतंसं\nरत्‍नाकल्पोज्ज्वलाङ्गं परशुमृगवराभीतिहस्तं प्रसन्नम् ॥',
          transliteration:
              'Dhyāyennityaṁ maheśaṁ rajatagirinibhaṁ cārucandrāvataṁsaṁ\nRatnākalpojjvalāṅgaṁ paraśumṛgavarābhītihastaṁ prasannam ||',
          meaning:
              'Always meditate upon the Great Lord Mahesha, resplendent like a mountain of silver, adorned with the crescent moon, four-armed holding deer, axe, and bestowing fearlessness, ever joyful.',
          scripturalSource: 'Classical Shaiva Dhyana Sloka',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0429',
          linkedMantraTitle: 'Om Namah Shivaya',
          expandedInstructions: [
            'Breathe in stillness. Remember that Shiva resides as the silent witness within your heart.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Jala Abhiṣekam (Offering Pure Water)',
          upacharaName: 'Snānam',
          actionDescription:
              'Gently pour a small trickle of pure water over the Shiva Linga (or sprinkle on the sacred image) using a spoon.',
          sanskritMantra:
              'ॐ नमः शिवाय ।\nगङ्गादिसर्वतीर्थेभ्य आनीतं तोयमुत्तमम् ।\nस्नानार्थं ते प्रदास्यामि गृहाण परमेश्वर ॥',
          transliteration:
              'Om namaḥ śivāya |\nGaṅgādisarvatīrthebhya ānītaṁ toyamuttamam |\nSnānārthaṁ te pradāsyāmi gṛhāṇa parameśvara ||',
          meaning:
              'Om Namah Shivaya. This pure water gathered from sacred holy rivers I offer for your bath; please accept it, O Supreme Lord.',
          scripturalSource: 'Shaiva Grihya Snana Paddhati',
          stepProvenance: 'traditional_grihya_action',
          expandedInstructions: [
            'Water poured over Shiva symbolizes cooling the heat of worldly desires and cleansing the mind.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Bhasma & Bilva Samarpaṇam (Sacred Ash & Bilva Leaf)',
          upacharaName: 'Gandham & Puṣpam',
          actionDescription:
              'Apply a three-line mark of sacred ash (Tripundra) with Chandan. Offer a Bilva leaf with the stem pointed away, or white blossoms.',
          sanskritMantra:
              'त्रिदलं त्रिगुणाकारं त्रिनेत्रं च त्रियायुधम् ।\nत्रिजन्मपापसंहारं एकबिल्वं शिवार्पणम् ॥',
          transliteration:
              'Tridalaṁ triguṇākāraṁ trinetraṁ ca triyāyudham |\nTrijanmapāpasaṁhāraṁ ekabilvaṁ śivārpaṇam ||',
          meaning:
              'The trifoliate Bilva leaf represents the three Gunas, the three eyes of Shiva, and the weapon of truth. I offer this single Bilva leaf to Lord Shiva, destroying the sins of three lifetimes.',
          scripturalSource: 'Bilvashtakam Verse 1',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'If fresh Bilva is unavailable, any clean fragrant flower offered with genuine reverence is fully accepted.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dhūpa-Dīpa Samarpaṇam (Incense and Light)',
          upacharaName: 'Dhūpa & Dīpa',
          actionDescription:
              'Wave the incense stick and lit lamp in circles before the Shiva Linga.',
          sanskritMantra:
              'ॐ नमः शिवाय ।\nधूपं दीपं च समर्पयामि ॥',
          transliteration:
              'Om namaḥ śivāya |\nDhūpaṁ dīpaṁ ca samarpayāmi ||',
          meaning:
              'Salutations to Shiva. I offer sacred incense and the divine flame.',
          scripturalSource: 'Grihya Nitya Puja Paddhati',
          stepProvenance: 'traditional_grihya_action',
          expandedInstructions: [
            'Look into the quiet flame and reflect upon Shiva as the eternal light shining within all living beings.',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Mahāmṛtyuñjaya Japa & Praṇāma (Peace and Surrender)',
          upacharaName: 'Praṇāma',
          actionDescription:
              'Sit quietly and chant the Mahamrityunjaya Mantra three times. Bow down in prostration.',
          sanskritMantra:
              'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\nउर्वारुकमिव बन्धनान्मृत्योर्मुक्षीय मामृतात् ॥',
          transliteration:
              'Om tryambakaṁ yajāmahe sugandhiṁ puṣṭivardhanam |\nUrvārukamiva bandhanān mṛtyor mukṣīya māmṛtāt ||',
          meaning:
              'We worship the Three-Eyed One, fragrant and nourishing all beings. As a ripe cucumber is freed from its stem, may we be liberated from death, not from immortality.',
          scripturalSource: 'Rigveda Mandala 7.59.12 / Shukla Yajurveda 3.60',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0413',
          linkedMantraTitle: 'Maha Mrityunjaya Mantra',
          expandedInstructions: [
            'Rest in silence for a few breaths after chanting.',
            'Offer all thoughts and activities of the day to Shiva.',
          ],
        ),
      ],
    ),

    // 3. VISHNU PUJA
    PujaGuide(
      id: 'guide_vishnu_puja',
      title: 'Daily Vishnu Pancha Upachara Puja',
      sanskritTitle: 'श्री विष्णु पञ्चोपचार पूजा',
      deity: 'Vishnu',
      tradition: 'Pancha Upachara (Five-fold Worship)',
      shortIntro:
          'A gentle, devotional daily worship offered to Lord Vishnu / Narayana, sustaining righteousness, inner peace, and divine harmony.',
      purposeAndContext:
          'Lord Vishnu is the sustainer of the universe (Sthiti-karta). Worshipping Lord Narayana with pure water, sacred Tulasi leaves, yellow flowers, and sweet names nurtures compassion, noble conduct (Sattva), and unwavering spiritual refuge.',
      preparation: [
        'Clean the altar area.',
        'Keep fresh water and Tulasi leaves (if available) ready.',
        'Sit facing east or north.',
        'Light a ghee lamp.',
      ],
      materialsList: [
        'Image or Shaligram of Lord Vishnu / Krishna',
        'Water for Achamanam',
        'Sandalwood paste (Chandan)',
        'Tulasi leaves or yellow flowers',
        'Incense, ghee lamp, and fruit offering',
      ],
      estimatedDurationMinutes: 12,
      editorialStatus: 'Verified Editorial Guide',
      contentVerificationStatus: 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: [
        'Vishnu Sahasranama Stotram Dhyana Sloka',
        'Tulasi Stotram (Padma Purana)',
        'Vaishnava Grihya Paddhati',
      ],
      sourceInfo:
          'Based on classical Vaishnava Grihya worship manuals and Bhagavata devotional traditions.',
      regionalVarianceNote:
          'Domestic devotional format. Detailed temple Agama pujas (Pancharatra or Vaikhanasa) follow extensive ritual mudras; this guide provides a sincere, accessible daily home contemplation.',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Dhyānam (Meditation on the Cosmic Sustainer)',
          upacharaName: 'Dhyānam',
          actionDescription:
              'Close your eyes and meditate on Lord Vishnu resting upon the cosmic serpent Ananta, peaceful and smiling, radiating serene blue grace.',
          sanskritMantra:
              'शान्ताकारं भुजगशयनं पद्मनाभं सुरेशं\nविश्वाधारं गगनसदृशं मेघवर्णं शुभाङ्गम् ।\nलक्ष्मीकान्तं कमलनयनं योगिभिर्ध्यानगम्यं\nवन्दे विष्णुं भवभयहरं सर्वलोकैकनाथम् ॥',
          transliteration:
              'Śāntākāraṁ bhujagaśayanaṁ padmanābhaṁ sureśaṁ\nViśvādhāraṁ gaganasadṛśaṁ meghavarṇaṁ śubhāṅgam |\nLakṣmīkāntaṁ kamalanayanaṁ yogibhirdhyānagamyaṁ\nVande viṣṇuṁ bhavabhayaharaṁ sarvalokaikanātham ||',
          meaning:
              'I bow to Lord Vishnu, of peaceful demeanor, resting on the serpent, from whose navel springs the lotus, the Lord of gods, the support of the cosmos, boundless as the sky, cloud-complexioned, beloved of Lakshmi, lotus-eyed, attainable by yogis in meditation, the remover of worldly fear, the sole Lord of all realms.',
          scripturalSource: 'Vishnu Sahasranama Stotram Dhyana Sloka',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0378',
          linkedMantraTitle: 'Achyutam Keshavam',
          expandedInstructions: [
            'Allow the serene presence of Narayana to quiet all worries of the day.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Ācamana & Gandha (Purification & Sandalwood)',
          upacharaName: 'Gandham',
          actionDescription:
              'Sip a drop of clean water for inner purification. Apply fragrant sandalwood paste to the Lord.',
          sanskritMantra:
              'ॐ नमो नारायणाय नमः ।\nपरमानन्द सान्द्राय गन्धं दिव्यं समर्पयामि ॥',
          transliteration:
              'Om namo nārāyaṇāya namaḥ |\nParamānanda sāndrāya gandhaṁ divyaṁ samarpayāmi ||',
          meaning:
              'Salutations to Lord Narayana. I offer divine fragrant sandalwood to the embodiment of supreme bliss.',
          scripturalSource: 'Vaishnava Grihya Upachara Mantra',
          stepProvenance: 'traditional_grihya_action',
          expandedInstructions: [
            'Chandan represents fragrant coolness and clarity of devotion.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Tulasī & Puṣpam (Offering Sacred Tulasi & Flowers)',
          upacharaName: 'Puṣpam',
          actionDescription:
              'Offer a green Tulasi leaf or sprig at the feet of Lord Vishnu, with yellow marigolds or fragrant blossoms.',
          sanskritMantra:
              'तुलसी दलमात्रेण जलस्य चुलुकेन वा ।\nविक्रीणीते स्वमात्मानं भक्तेभ्यो भक्तवत्सलः ॥',
          transliteration:
              'Tulasī dalamātreṇa jalasya culukena vā |\nVikrīṇīte svamātmānaṁ bhaktebhyo bhaktavatsalaḥ ||',
          meaning:
              'With merely a single Tulasi leaf and a palmful of water, the Lord, lover of devotees, surrenders His very Self to His loving devotees.',
          scripturalSource: 'Padma Purana / Bhagavata Smriti',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Tulasi is dearest to Lord Narayana, embodying pure spiritual devotion (Bhakti).',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dhūpa & Dīpa (Incense & Lamp)',
          upacharaName: 'Dhūpa & Dīpa',
          actionDescription:
              'Wave fragrant incense and a lit ghee lamp in circles before the altar.',
          sanskritMantra:
              'ॐ नमो भगवते वासुदेवाय ।\nधूपं दीपं च दर्शयामि ॥',
          transliteration:
              'Om namo bhagavate vāsudevāya |\nDhūpaṁ dīpaṁ ca darśayāmi ||',
          meaning:
              'Salutations to Bhagavan Vasudeva. I show sacred incense and the divine lamp.',
          scripturalSource: 'Srimad Bhagavatam / Grihya Vidhi',
          stepProvenance: 'traditional_grihya_action',
          expandedInstructions: [
            'The pure flame reveals the beauty of Bhagavan in your heart.',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Naivedyam & Praṇāma (Sweet Offering & Bowing)',
          upacharaName: 'Naivedyam',
          actionDescription:
              'Offer clean fruit, sweet rice, or water. Bow down with complete faith in the protective shelter of Vishnu.',
          sanskritMantra:
              'कायेन वाचा मनसेन्द्रियैर्वा बुद्ध्यात्मना वा प्रकृतिस्वभावात् ।\nकरोमि यद्यत् सकलं परस्मै नारायणायेति समर्पयामि ॥',
          transliteration:
              'Kāyena vācā manasendriyairvā buddhyātmanā vā prakṛtisvabhāvāt |\nKaromi yadyat sakalaṁ parasmai nārāyaṇāyeti samarpayāmi ||',
          meaning:
              'Whatever I perform through body, speech, mind, senses, intellect, or inherited nature: all of that I surrender to the supreme Lord Narayana.',
          scripturalSource: 'Srimad Bhagavatam 11.2.36 / Mukundamala Stotram',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0403',
          linkedMantraTitle: 'Hare Krishna Mahamantra',
          expandedInstructions: [
            'This traditional surrender prayer consecrates all actions of your day to the Divine.',
          ],
        ),
      ],
    ),

    // 4. LAKSHMI PUJA
    PujaGuide(
      id: 'guide_lakshmi_puja',
      title: 'Daily Mahalakshmi Prarthana & Puja',
      sanskritTitle: 'श्री महालक्ष्मी प्रार्थना व पूजा',
      deity: 'Lakshmi',
      tradition: 'Devi Grihya Paddhati',
      shortIntro:
          'A graceful daily prayer dedicated to Mother Mahalakshmi, welcoming purity, spiritual light, nobility, and benevolent abundance into the home.',
      purposeAndContext:
          'Goddess Mahalakshmi is the divine consort of Lord Vishnu and the embodiment of auspiciousness, grace, and noble prosperity (Dharma-sampatti). Worshipping Devi with clean light and fragrant flowers cleanses home energy and fills the heart with grateful humility.',
      preparation: [
        'Ensure the prayer space is tidy and bright.',
        'Light a pure oil or ghee lamp (symbol of Lakshmi).',
        'Keep fresh flowers, sandalwood, and Kumkum.',
      ],
      materialsList: [
        'Image of Sri Mahalakshmi',
        'Ghee lamp and incense',
        'Kumkum, Chandan, and fresh blossoms (lotus or red/pink flowers)',
        'Clean water and sweet offering (fruits, raisins, or kheer)',
      ],
      estimatedDurationMinutes: 10,
      editorialStatus: 'Verified Editorial Guide',
      contentVerificationStatus: 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: [
        'Taittiriya Aranyaka 10.1 (Lakshmi Gayatri)',
        'Padma Purana Sanatkumara Samhita (Mahalakshmyashtakam)',
        'Sri Sukta Khilani (Rigveda)',
      ],
      sourceInfo:
          'Based on traditional Devi Grihya paddhatis and classical Sri Sukta / Stotram verses.',
      regionalVarianceNote:
          'This guide provides a universal domestic adoration practice. Specialized festivals (like Varalakshmi Vratam or Diwali) have elaborate rituals; this guide supports daily domestic reverence.',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Dhyānam & Mahālakṣmī Gāyatrī',
          upacharaName: 'Dhyānam',
          actionDescription:
              'Sit before the lamp. Fold palms and envision Mother Lakshmi seated upon a golden lotus, blessing with fearlessness and boundless grace.',
          sanskritMantra:
              'ॐ महालक्ष्म्यै च विद्महे विष्णुपत्नी च धीमहि ।\nतन्नो लक्ष्मीः प्रचोदयात् ॥',
          transliteration:
              'Om mahālakṣmyai ca vidmahe viṣṇupatnī ca dhīmahi |\nTanno lakṣmīḥ pracodayāt ||',
          meaning:
              'Om, let us meditate on the Great Goddess Mahalakshmi, the eternal consort of Lord Vishnu. May that auspicious Lakshmi illuminate our intellect and path.',
          scripturalSource: 'Taittiriya Aranyaka 10.1 / Mahanarayana Upanishad',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0415',
          linkedMantraTitle: 'Mahalakshmi Gayatri',
          expandedInstructions: [
            'Focus on feelings of deep gratitude for food, shelter, family, and spiritual seeking.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Kuṅkuma & Gandham (Offering Kumkum & Sandalwood)',
          upacharaName: 'Gandham',
          actionDescription:
              'Apply fragrant Chandan and a dot of auspicious Kumkum to the lotus feet of Mother Lakshmi.',
          sanskritMantra:
              'ॐ श्रीं ह्रीं क्लीं महालक्ष्म्यै नमः ।\nहरिद्रा-कुङ्कुम-गन्धं समर्पयामि ॥',
          transliteration:
              'Om śrīṁ hrīṁ klīṁ mahālakṣmyai namaḥ |\nHaridrā-kuṅkuma-gandhaṁ samarpayāmi ||',
          meaning:
              'Salutations to the Great Goddess Mahalakshmi. I offer holy turmeric, auspicious kumkum, and fragrant sandalwood.',
          scripturalSource: 'Devi Grihya Upachara Mantra',
          stepProvenance: 'traditional_grihya_action',
          expandedInstructions: [
            'Kumkum is the emblem of auspiciousness and spiritual awakening.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Puṣpa Samarpaṇam (Offering Fresh Flowers)',
          upacharaName: 'Puṣpam',
          actionDescription:
              'Offer fresh pink, red, or fragrant flowers at the feet of the Goddess with two hands.',
          sanskritMantra:
              'पद्मासनस्थितां देवीं पद्मनाभहृत्प्रियाम् ।\nपद्मपत्राक्षीं ध्यायेत् पद्मसम्भवपूजिताम् ॥',
          transliteration:
              'Padmāsanasthitāṁ devīṁ padmanābhahṛtpriyām |\nPadmapatrākṣīṁ dhyāyet padmasambhavapūjitām ||',
          meaning:
              'I meditate on the Devi who sits upon a lotus, beloved to the heart of Padmanabha, with eyes like lotus petals, revered by Brahma.',
          scripturalSource: 'Padma Purana / Classical Dhyana Sloka',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'A flower symbolizes the blossoming of devotion from the mud of worldly existence.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dīpa Samarpaṇam (Offering the Sacred Flame)',
          upacharaName: 'Dīpam',
          actionDescription:
              'Reverently circle the oil lamp before the image of Mahalakshmi.',
          sanskritMantra:
              'साज्यं च वर्तिसंयुक्तं वह्निना योजितं मया ।\nदीपं गृहाण देवेशि त्रैलोक्यतिमिरापहम् ॥',
          transliteration:
              'Sājyaṁ ca vartisaṁyuktaṁ vahninā yojitaṁ mayā |\nDīpaṁ gṛhāṇa deveśi trailokyatimirāpaham ||',
          meaning:
              'Prepared with pure ghee and cotton wick, ignited with sacred fire: please accept this lamp, O Goddess of gods, which dispels darkness from the three realms.',
          scripturalSource: 'Classical Devi Puja Paddhati',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0268',
          linkedMantraTitle: 'Sri Sukta Khilani',
          expandedInstructions: [
            'The lamp is herself the form of Lakshmi (Deepa Lakshmi).',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Mahālakṣmyaṣṭakam & Praṇāma (Prayer of Gratitude)',
          upacharaName: 'Praṇāma',
          actionDescription:
              'Recite the famous verse from the Mahalakshmyashtakam and bow down with surrender.',
          sanskritMantra:
              'नमस्तेऽस्तु महामाये श्रीपीठे सुरपूजिते ।\nशङ्खचक्रगदाहस्ते महालक्ष्मि नमोऽस्तु ते ॥',
          transliteration:
              'Namaste\'stu mahāmāye śrīpīṭhe surapūjite |\nŚaṅkhacakragadāhaste mahālakṣmi namo\'stu te ||',
          meaning:
              'Salutations unto You, O Great Enchantress, seated on the sacred throne, worshipped by all celestial beings, holding conch, discus, and mace; O Mother Mahalakshmi, salutations to You.',
          scripturalSource: 'Padma Purana Sanatkumara Samhita (Mahalakshmyashtakam 1)',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Bow down with complete trust in the divine benevolence of Mother Lakshmi.',
          ],
        ),
      ],
    ),

    // 5. MORNING PRAYER (PRATAH SMARANAM)
    PujaGuide(
      id: 'guide_morning_prayer',
      title: 'Prātah Smaraṇam (Daily Morning Prayer)',
      sanskritTitle: 'प्रातः स्मरणम्',
      deity: 'Universal',
      tradition: 'Vedic / Smartha Nitya Karma',
      shortIntro:
          'A quiet 5-minute morning sequence traditionally recited immediately upon waking to align body, mind, and spirit with cosmic harmony before entering daily activities.',
      purposeAndContext:
          'Traditional Hindu mornings begin before dawn with remembrance of the divine in one\'s hands (action), asking forgiveness from Mother Earth for walking upon her, and praying for intellectual illumination through the solar power of Savitr.',
      preparation: [
        'Awaken peacefully.',
        'Sit up in bed or on a clean seat before beginning active chores.',
        'Rub palms together gently.',
      ],
      materialsList: [
        'No physical materials required; can be performed anywhere.',
      ],
      estimatedDurationMinutes: 5,
      editorialStatus: 'Verified Editorial Guide',
      contentVerificationStatus: 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: [
        'Subhashita Ratna Bhandagara (Kara Darshanam)',
        'Vishnu Smriti / Grihya Prayoga (Bhumi Vandana)',
        'Rigveda Mandala 3.62.10 (Savitr Gayatri)',
        'Brihadaranyaka Upanishad 1.3.28 (Pavamana Mantra)',
      ],
      sourceInfo:
          'Classical Vedic Smriti and Subhashita morning prayers recited across generations in Hindu households.',
      regionalVarianceNote:
          'Universal across Smartha, Vaishnava, and Shaiva sampradayas with minor word orders across regional lineages. An essential part of daily domestic Hindu mindfulness (Dinacharya).',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Kara Darśanam (Beholding the Palms upon Waking)',
          upacharaName: 'Smaraṇam',
          actionDescription:
              'Bring both palms together open like a book. Look at your palms while reciting the sacred prayer.',
          sanskritMantra:
              'कराग्रे वसते लक्ष्मीः करमध्ये सरस्वती ।\nकरमूले तु गोविन्दः प्रभाते करदर्शनम् ॥',
          transliteration:
              'Karāgre vasate lakṣmīḥ karamadhye sarasvatī |\nKaramūle tu govindaḥ prabhāte karadarśanam ||',
          meaning:
              'At the fingertips dwells Lakshmi (abundance); in the middle of the palms dwells Saraswati (wisdom); at the base of the palms dwells Govinda (the divine sustainer). Thus, in the morning, I gaze upon my hands.',
          scripturalSource: 'Classical Subhashita / Nitya Karma Dinacharya',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Remind yourself that your hands are instruments for honest work, learning, and divine service today.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Bhūmi Vandanā (Asking Forgiveness of Mother Earth)',
          upacharaName: 'Praṇāma',
          actionDescription:
              'Before touching feet to the ground upon getting out of bed, touch the floor reverently with your right hand and touch hand to forehead.',
          sanskritMantra:
              'समुद्रवसने देवि पर्वतस्तनमण्डले ।\nविष्णुपत्नि नमस्तुभ्यं पादस्पर्शं क्षमस्व मे ॥',
          transliteration:
              'Samudravasane devi parvatastanamaṇḍale |\nViṣṇupatni namastubhyaṁ pādasparśaṁ kṣamasva me ||',
          meaning:
              'O Mother Earth, who has oceans for your garments and mountains for your bosom, consort of Lord Vishnu: salutations unto you; please forgive me for touching you with my feet.',
          scripturalSource: 'Vishnu Smriti / Traditional Grihya Nitya Karma',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Cultivate ecological humility and reverence toward the Earth that cradles and feeds us.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Sūrya Prārthanā & Gāyatrī (Solar Illumination)',
          upacharaName: 'Japa',
          actionDescription:
              'Turn toward the east (or imagine the rising golden sun) and chant the Gayatri Mantra three times.',
          sanskritMantra:
              'ॐ भूर्भुवः स्वः ।\nतत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि ।\nधियो यो नः प्रचोदयात् ॥',
          transliteration:
              'Om bhūrbhuvaḥ svaḥ |\nTat savitur vareṇyaṁ bhargo devasya dhīmahi |\nDhiyo yo naḥ pracodayāt ||',
          meaning:
              'Om, across the physical, astral, and celestial realms: let us meditate upon the supreme adorable brilliance of Savitr (the divine Sun of consciousness). May that supreme light awaken and guide our intellect toward truth.',
          scripturalSource: 'Rigveda Mandala 3.62.10 / Yajurveda / Samaveda',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0399',
          linkedMantraTitle: 'Gayatri Mantra',
          expandedInstructions: [
            'Internalize the intention to think clearly, act kindly, and live truthfully.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Pavamāna Mantra (Prayer for Transcendence)',
          upacharaName: 'Prārthanā',
          actionDescription:
              'Conclude with hands folded in Anjali Mudra, seeking truth, light, and immortality.',
          sanskritMantra:
              'ॐ असतो मा सद्गमय । तमसो मा ज्योतिर्गमय ।\nमृत्यॊर्मा अमृतं गमय । ॐ शान्तिः शान्तिः शान्तिः ॥',
          transliteration:
              'Om asato mā sad gamaya | Tamaso mā jyotir gamaya |\nMṛtyormā amṛtaṁ gamaya | Om śāntiḥ śāntiḥ śāntiḥ ||',
          meaning:
              'Lead me from the unreal to the real. Lead me from darkness (ignorance) to light (wisdom). Lead me from death (mortality) to immortality. Om Peace, Peace, Peace.',
          scripturalSource: 'Brihadaranyaka Upanishad 1.3.28',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0384',
          linkedMantraTitle: 'Asato Ma Sad Gamaya (Pavamana Mantra)',
          expandedInstructions: [
            'Step into your day grounded, calm, and consecrated.',
          ],
        ),
      ],
    ),

    // 6. EVENING PRAYER (SANDHYA DEEPA PRARTHANA)
    PujaGuide(
      id: 'guide_evening_prayer',
      title: 'Sandhyā Dīpa Prārthanā (Daily Evening Prayer)',
      sanskritTitle: 'सन्ध्या दीप प्रार्थना',
      deity: 'Universal',
      tradition: 'Vedic / Smartha Sandhya Karma',
      shortIntro:
          'A quiet dusk ritual of lighting the household lamp, dispelling negative thoughts, and thanking the Divine for the gifts of the passing day.',
      purposeAndContext:
          'Dusk (Sandhyakala) is a transitional threshold where day meets night. Lighting a lamp at sunset brings auspiciousness (Subham) and dispels darkness both outwardly and inwardly, creating a sanctified transition toward restful nocturnal peace.',
      preparation: [
        'Wash hands and feet after returning from daily work.',
        'Clean the lamp and pour fresh oil or ghee.',
        'Light the wick at sunset (Godhuli vela).',
      ],
      materialsList: [
        'Oil or ghee lamp (Diya)',
        'Incense stick (optional)',
      ],
      estimatedDurationMinutes: 6,
      editorialStatus: 'Verified Editorial Guide',
      contentVerificationStatus: 'Curated Traditional Grihya Paddhati',
      primarySourceReferences: [
        'Traditional Deepa Sukta / Subhashita',
        'Smriti Sandhyavandana Karma',
        'Brihadaranyaka Upanishad 5.1.1 (Shanti Patha)',
      ],
      sourceInfo:
          'Classical Sanskrit Deepa Stotras recited traditionally at sunset in Indian homes.',
      regionalVarianceNote:
          'Common to almost all traditional Hindu domestic households across North and South India with regional sampradaya and lineage phrasing variations.',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Dīpa Prajvalanam (Lighting the Sacred Lamp)',
          upacharaName: 'Dīpam',
          actionDescription:
              'Light the lamp at twilight. Fold hands and look into the gentle flame with a tranquil heart.',
          sanskritMantra:
              'दीपज्योतिः परं ब्रह्म दीपज्योतिर्जनार्दनः ।\nदीपो हरतु मे पापं दीपज्योतिर्नमोऽस्तु ते ॥',
          transliteration:
              'Dīpajyotiḥ paraṁ brahma dīpajyotirjanārdanaḥ |\nDīpo haratu me pāpaṁ dīpajyotirnamo\'stu te ||',
          meaning:
              'The light of the lamp is Supreme Brahman; the light of the lamp is Janardana (the Lord). May this sacred light remove my errors and shortcomings; salutations to the divine lamp.',
          scripturalSource: 'Traditional Deepa Sloka / Subhashita',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Observe how a small flame dispels deep darkness effortlessly.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Śubhaṁ Karoti (Prayer for Inner Illumination)',
          upacharaName: 'Prārthanā',
          actionDescription:
              'Bow gently toward the flame and pray for health, prosperity, and the removal of harmful thoughts.',
          sanskritMantra:
              'शुभं करोति कल्याणमारोग्यं धनसम्पदः ।\nशत्रुबुद्धिविनाशाय दीपज्योतिर्नमोऽस्तु ते ॥',
          transliteration:
              'Śubhaṁ karoti kalyāṇam ārogyaṁ dhanasampadaḥ |\nŚatrubuddhivināśāya dīpajyotirnamo\'stu te ||',
          meaning:
              'I bow to the light of the lamp that bestows auspiciousness, well-being, health, and spiritual abundance, and destroys inimical and impure thoughts.',
          scripturalSource: 'Traditional Sandhya Stotra',
          stepProvenance: 'canonical_verse',
          expandedInstructions: [
            'Inimical thoughts refer primarily to anger, jealousy, greed, and delusion inside ourselves.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Śānti Pāṭha (Universal Peace Invocation)',
          upacharaName: 'Śānti',
          actionDescription:
              'Close your eyes in stillness. Conclude by sending peaceful vibrations to all living beings.',
          sanskritMantra:
              'ॐ सर्वे भवन्तु सुखिनः सर्वे सन्तु निरामयाः ।\nसर्वे भद्राणि पश्यन्तु मा कश्चिद्दुःखभाग्भवेत् ।\nॐ शान्तिः शान्तिः शान्तिः ॥',
          transliteration:
              'Om sarve bhavantu sukhinaḥ sarve santu nirāmayāḥ |\nSarve bhadrāṇi paśyantu mā kaścid duḥkhabhāg bhavet |\nOm śāntiḥ śāntiḥ śāntiḥ ||',
          meaning:
              'May all beings be happy. May all beings be free from illness. May all behold what is auspicious. May no one suffer. Om Peace, Peace, Peace.',
          scripturalSource: 'Brihadaranyaka Upanishad / Traditional Shanti Patha',
          stepProvenance: 'canonical_verse',
          linkedMantraId: 'VEDA-MTR-0448',
          linkedMantraTitle: 'Universal Peace Mantra',
          expandedInstructions: [
            'Let the peace of the evening settle in your heart before family dinner and rest.',
          ],
        ),
      ],
    ),
  ];

  static PujaGuide? getGuideById(String id) {
    try {
      return allGuides.firstWhere((g) => g.id == id);
    } catch (_) {
      return null;
    }
  }
}
