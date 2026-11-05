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
      sourceInfo:
          'Based on classical Smartha and Grihya domestic worship manuals (Pancha Upachara Vidhi). Simplified for daily home reverence.',
      regionalVarianceNote:
          'This guide provides a universal domestic format. Specific Vedic lineages (paramparas) may include Sankalpa, Nyasa, and detailed Mudras. This guide serves as an earnest personal devotional aid rather than an authoritative temple agamic prescription.',
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
              'O Lord of the curved trunk and immense cosmic form, radiant like millions of suns, please make all my endeavors free from obstacles, at all times.',
          linkedMantraId: 'VEDA-MTR-0454',
          linkedMantraTitle: 'Vakratunda Mahakaya',
          expandedInstructions: [
            'Breathe slowly and deeply three times.',
            'Let go of anxiety about external affairs and settle your mind in reverence.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Āvāhanam & Praṇāma (Welcoming the Divine Presence)',
          upacharaName: 'Āvāhanam',
          actionDescription:
              'Bow head slightly. Fold hands and invite the Lord\'s benevolent grace into the sacred representation before you.',
          sanskritMantra:
              'शुक्लाम्बरधरं विष्णुं शशिवर्णं चतुर्भुजम् ।\nप्रसन्नवदनं ध्यायेत् सर्वविघ्नोपशान्तये ॥',
          transliteration:
              'Śuklāmbaradharaṁ viṣṇuṁ śaśivarṇaṁ caturbhujam |\nPrasannavadanaṁ dhyāyet sarvavighnopaśāntaye ||',
          meaning:
              'Meditate upon the Lord adorned in white garments, all-pervading, effulgent like the moon, four-armed, and bearing a serene, joyful countenance, for the pacification of all obstacles.',
          linkedMantraId: 'VEDA-MTR-0446',
          linkedMantraTitle: 'Shuklambaradharam',
          expandedInstructions: [
            'Feel that the Divine is present, receiving your heartfelt prayer.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Gandha & Akṣata (Offering Fragrance & Consecrated Rice)',
          upacharaName: 'Gandham',
          actionDescription:
              'Dip the ring finger of your right hand in sandalwood paste (Chandan) and gently apply a tilak to Ganesha\'s forehead or feet. Offer a pinch of Kumkum and unbroken yellow rice (Akshata).',
          sanskritMantra:
              'ॐ श्री गणेशाय नमः ।\nदिव्य परिमळ गन्धं अक्षतांश्च समर्पयामि ॥',
          transliteration:
              'Om śrī gaṇeśāya namaḥ |\nDivya parimala gandhaṁ akṣatāṁśca samarpayāmi ||',
          meaning:
              'Salutations to auspicious Ganesha. I offer fragrant divine sandalwood paste and sacred unbroken rice.',
          expandedInstructions: [
            'Sandalwood symbolizes cool serenity, cooling worldly agitated thoughts.',
            'Akshata signifies wholeness, abundance, and steadfast dedication.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Puṣpa Samarpaṇam (Offering of Fresh Flowers)',
          upacharaName: 'Puṣpam',
          actionDescription:
              'Take a fresh red or yellow flower (or fresh petals) in both hands. Offer it at the feet of Lord Ganesha with reverence.',
          sanskritMantra:
              'ॐ गं गणपतये नमः ।\nनानाविध सुगन्धि पुष्पाणि समर्पयामि ॥',
          transliteration:
              'Om gaṁ gaṇapataye namaḥ |\nNānāvidha sugandhi puṣpāṇi samarpayāmi ||',
          meaning:
              'Salutations to Lord Ganapati. I offer diverse fragrant blossoms with devotion.',
          expandedInstructions: [
            'Red flowers (like hibiscus) or Durva grass blades are traditionally favored, but any fresh, pure flower offered with devotion is completely acceptable.',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Dhūpa & Dīpa Darśanam (Offering Fragrant Incense & Light)',
          upacharaName: 'Dhūpam & Dīpam',
          actionDescription:
              'Gently wave the burning incense stick in clockwise circles before the deity three times, then wave the lit oil lamp in clockwise circles, illuminating the form of Ganesha.',
          sanskritMantra:
              'ॐ गं गणपतये नमः ।\nधूपं आघ्रापयामि, प्रत्यक्ष दीपं दर्शयामि ॥',
          transliteration:
              'Om gaṁ gaṇapataye namaḥ |\nDhūpaṁ āghrāpayāmi, pratyakṣa dīpaṁ darśayāmi ||',
          meaning:
              'Salutations to Ganapati. I offer fragrant sacred incense and present the holy luminous flame.',
          expandedInstructions: [
            'Incense represents surrendering desires that dissipate into the air.',
            'The lamp represents the light of true inner wisdom destroying spiritual ignorance.',
          ],
        ),
        PujaStep(
          stepNumber: 6,
          stepName: 'Naivedya Samarpaṇam (Offering of Food & Water)',
          upacharaName: 'Naivedyam',
          actionDescription:
              'Place a small fruit, jaggery piece, or sweet before Ganesha. Sprinkle a drop of clean water around the plate as a sacred boundary (parishinchana) and offer it.',
          sanskritMantra:
              'ॐ गं गणपतये नमः ।\nदिव्य नैवेद्यं निवेदयामि, मध्ये अमृतपानीयं समर्पयामि ॥',
          transliteration:
              'Om gaṁ gaṇapataye namaḥ |\nDivya naivedyaṁ nivedayāmi, madhye amṛtapānīyaṁ samarpayāmi ||',
          meaning:
              'Salutations to Ganapati. I offer pure food offering and sacred nectar water for your contentment.',
          expandedInstructions: [
            'Mentally offer the pure essence (bhava) of the food to God. After the prayer, this becomes sanctified prasada.',
          ],
        ),
        PujaStep(
          stepNumber: 7,
          stepName: 'Nāma Japa & Praṇāma (Chanting & Surrender of Fruits)',
          upacharaName: 'Namaskāra',
          actionDescription:
              'Chant the Mula Mantra of Ganesha peacefully. Bow down with deep gratitude and surrender all fruits of the puja to the Divine.',
          sanskritMantra:
              'ॐ गं गणपतये नमः ॥\nसर्वमङ्गल माङ्गल्ये शिवे सर्वार्थ साधिके ।',
          transliteration:
              'Om gaṁ gaṇapataye namaḥ ||\nSarvamaṅgala māṅgalye śive sarvārtha sādhike |',
          meaning:
              'Salutations unto Lord Ganapati. May all auspiciousness, peace, and noble purpose be fulfilled.',
          linkedMantraId: 'VEDA-MTR-0426',
          linkedMantraTitle: 'Om Gam Ganapataye Namah',
          expandedInstructions: [
            'Optional: Tap "Chant Mantra" below to perform a 108 or 21 bead Japa with the master audio recording.',
            'Conclude by bowing your head and asking for guidance on the path of righteousness (Dharma).',
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
      tradition: 'Pancha Upachara (Five-fold Worship)',
      shortIntro:
          'A serene daily worship offered to Bhagavan Shiva, cultivating inner stillness, detachment, and supreme peace.',
      purposeAndContext:
          'Lord Shiva represents pristine consciousness and auspiciousness (Mangalam). Daily worship with clean water, sacred ash (Bhasma), Bilva leaf, and the sacred Panchakshari mantra dissolves mental agitations and anchors the soul in transcendent stillness.',
      preparation: [
        'Clean the Shiva Linga or picture of Shiva.',
        'Keep clean water (or Gangajal) ready in an achamana patra.',
        'Sit in a quiet space with an upright spine.',
        'Light a ghee lamp.',
      ],
      materialsList: [
        'Shiva Linga or representation of Lord Shiva',
        'Clean water for sacred bath (Jala Abhisheka)',
        'Bhasma (sacred ash) or Chandan',
        'Bilva leaf or fresh white flowers',
        'Lit incense and ghee lamp',
        'Fruit or milk offering (Naivedyam)',
      ],
      estimatedDurationMinutes: 12,
      editorialStatus: 'Verified Editorial Guide',
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
          expandedInstructions: [
            'If fresh Bilva is unavailable, any clean fragrant flower offered with genuine reverence is fully accepted.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dhūpa & Dīpa (Offering Fragrant Smoke & Light)',
          upacharaName: 'Dhūpam & Dīpam',
          actionDescription:
              'Wave incense and the lit lamp in three clockwise circles before Lord Shiva.',
          sanskritMantra:
              'ॐ नमः शिवाय ।\nवनस्पतिरसोद्भूतो गन्धाढ्यो गन्ध उत्तमः ।\nआघ्रेयः सर्वदेवानां धूपोऽयं प्रतिगृह्यताम् ॥',
          transliteration:
              'Om namaḥ śivāya |\nVanaspati-rasodbhūto gandhāḍhyo gandha uttamaḥ |\nĀghreyaḥ sarvadevānāṁ dhūpo\'yaṁ pratigṛhyatām ||',
          meaning:
              'Born from forest plants, fragrant and sublime, pleasing to all divinities; please accept this incense, O Shiva.',
          expandedInstructions: [
            'Observe the quiet flame. Reflect on the steady flame of inner consciousness.',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Naivedya & Karpoora Harati (Offering Food & Camphor Light)',
          upacharaName: 'Naivedyam & Ārati',
          actionDescription:
              'Offer fruit, water, or milk. Wave the sacred camphor flame or lamp, singing or reciting the Karpooragauram stotram.',
          sanskritMantra:
              'कर्पूरगौरं करुणावतारं संसारसारं भुजगेन्द्रहारम् ।\nसदावसन्तं हृदयारविन्दे भवं भवानीसहितं नमामि ॥',
          transliteration:
              'Karpūragauram karuṇāvatāraṁ saṁsārasāraṁ bhujagendrahāram |\nSadāvasantaṁ hṛdayāravinde bhavaṁ bhavānīsahitaṁ namāmi ||',
          meaning:
              'White as camphor, the very embodiment of compassion, the essence of cosmic existence, wearing the serpent king as garland; residing eternally in the lotus of the heart, I bow to Shiva together with Mother Bhavani.',
          expandedInstructions: [
            'Cup your hands over the holy flame and touch your eyes to receive the warmth of divine grace.',
          ],
        ),
        PujaStep(
          stepNumber: 6,
          stepName: 'Mahā Mṛtyuñjaya Japa & Samarpaṇam',
          upacharaName: 'Japa & Praṇāma',
          actionDescription:
              'Sit silently and chant the Maha Mrityunjaya Mantra for protection, healing, and liberation.',
          sanskritMantra:
              'ॐ त्र्यम्बकं यजामहे सुगन्धिं पुष्टिवर्धनम् ।\nउर्वारुकमिव बन्धनान्मृ त्योर्मुक्षीय मामृतात् ॥',
          transliteration:
              'Om tryambakaṁ yajāmahe sugandhiṁ puṣṭivardhanam |\nUrvārukamiva bandhanān mṛtyor mukṣīya māmṛtāt ||',
          meaning:
              'We worship the Three-Eyed Lord who is fragrant and nourishes all beings. May He liberate us from death for the sake of immortality, even as a ripe cucumber is gently released from its stalk.',
          linkedMantraId: 'VEDA-MTR-0413',
          linkedMantraTitle: 'Maha Mrityunjaya Mantra',
          expandedInstructions: [
            'Optional: Tap "Chant Mantra" to open the 108-repetition Japa mala session.',
            'Conclude with: "Om Shantih, Shantih, Shantih".',
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
      sourceInfo:
          'Based on classical Vaishnava Grihya worship manuals and Bhagavata devotional traditions.',
      regionalVarianceNote:
          'Domestic devotional format. Detailed temple Agama pujas (Pancharatra or Vaikhanasa) follow extensive ritual mudras; this guide provides a sincere, accessible daily home contemplation.',
      lastReviewedDate: '2026-11-05',
      steps: [
        PujaStep(
          stepNumber: 1,
          stepName: 'Dhyānam (Meditation on Lord Narayana)',
          upacharaName: 'Dhyānam',
          actionDescription:
              'Close your eyes and meditate on Lord Vishnu resting upon the cosmic serpent Ananta, peaceful and smiling, radiating serene blue grace.',
          sanskritMantra:
              'शान्ताकारं भुजगशयनं पद्मनाभं सुरेशं\nविश्वाधारं गगनसदृशं मेघवर्णं शुभाङ्गम् ।\nलक्ष्मीकान्तं कमलनयनं योगिभिर्ध्यानगम्यं\nवन्दे विष्णुं भवभयहरं सर्वलोकैकनाथम् ॥',
          transliteration:
              'Śāntākāraṁ bhujagaśayanaṁ padmanābhaṁ sureśaṁ\nViśvādhāraṁ gaganasadṛśaṁ meghavarṇaṁ śubhāṅgam |\nLakṣmīkāntaṁ kamalanayanaṁ yogibhirdhyānagamyaṁ\nVande viṣṇuṁ bhavabhayaharaṁ sarvalokaikanātham ||',
          meaning:
              'I bow to Lord Vishnu, of peaceful demeanor, resting on the serpent, from whose navel springs the lotus, the Lord of gods, the support of the cosmos, boundless as the sky, cloud-complexioned, beloved of Lakshmi, lotus-eyed, attainable by yogis in meditation, the remover of worldly fear, the sole Lord of all realms.',
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
          expandedInstructions: [
            'Chandan represents fragrant coolness and clarity of devotion.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Tulasī & Puṣpa Samarpaṇam (Offering Tulasi & Flowers)',
          upacharaName: 'Puṣpam',
          actionDescription:
              'Offer sacred Tulasi leaves (beloved of Vishnu) and fresh yellow blossoms at the Lord\'s feet.',
          sanskritMantra:
              'तुलसीदलमात्रेण जलस्य चुलुकेन वा ।\nविक्रीयते स्वयं देवः भक्तेभ्यो भक्तवत्सलः ॥',
          transliteration:
              'Tulasīdalamātreṇa jalasya culukena vā |\nVikrīyate svayaṁ devaḥ bhaktebhyo bhaktavatsalaḥ ||',
          meaning:
              'By even a single leaf of Tulasi or a single palmful of water offered with pure love, the Lord who cherishes his devotees gives Himself entirely to them.',
          expandedInstructions: [
            'If Tulasi is not present in your home, any clean fresh flower or heartfelt contemplation is accepted by Vishnu.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dhūpa, Dīpa & Naivedyam (Incense, Light & Food)',
          upacharaName: 'Dhūpam, Dīpam, Naivedyam',
          actionDescription:
              'Offer the lit incense and lamp in circles. Place sweet fruit or milk offering before the Lord.',
          sanskritMantra:
              'ॐ नमो भगवते वासुदेवाय ।\nधूपं दीपं च नैवेद्यं भक्त्या निवेदयामि ॥',
          transliteration:
              'Om namo bhagavate vāsudevāya |\nDhūpaṁ dīpaṁ ca naivedyaṁ bhaktyā nivedayāmi ||',
          meaning:
              'Salutations to the Supreme Lord Vasudeva. With devotion, I offer sacred fragrance, luminous light, and pure sustenance.',
          expandedInstructions: [
            'Pray that your thoughts, words, and actions are nourished by divine grace.',
          ],
        ),
        PujaStep(
          stepNumber: 5,
          stepName: 'Harikīrtana & Mahāmantra Japa',
          upacharaName: 'Kīrtanam & Praṇāma',
          actionDescription:
              'Chant the sacred names of the Lord. Recline in heartfelt remembrance and surrender all pride at His feet.',
          sanskritMantra:
              'हरे कृष्ण हरे कृष्ण कृष्ण कृष्ण हरे हरे ।\nहरे राम हरे राम राम राम हरे हरे ॥',
          transliteration:
              'Hare kṛṣṇa hare kṛṣṇa kṛṣṇa kṛṣṇa hare hare |\nHare rāma hare rāma rāma rāma hare hare ||',
          meaning:
              'O Divine Lord Krishna, O Supreme Lord Rama, O Divine Mother Hara; please engage my heart in your selfless devotional service.',
          linkedMantraId: 'VEDA-MTR-0403',
          linkedMantraTitle: 'Hare Krishna Maha Mantra',
          expandedInstructions: [
            'Optional: Tap "Chant Mantra" to open the 108 repetition counter.',
            'Conclude with: "Kāyena vācā manasendriyair vā... nārāyaṇāyeti samarpayāmi" (All I do, I surrender to Narayana).',
          ],
        ),
      ],
    ),

    // 4. LAKSHMI PUJA
    PujaGuide(
      id: 'guide_lakshmi_puja',
      title: 'Daily Mahalakshmi Prarthana & Puja',
      sanskritTitle: 'श्री महालक्ष्मी पूजा एवं प्रार्थना',
      deity: 'Lakshmi',
      tradition: 'Pancha Upachara (Devi Worship)',
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
              'May we know the Supreme Mother Mahalakshmi, and meditate upon the divine consort of Vishnu; may that auspicious Lakshmi inspire and illuminate our intellect.',
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
              'Meditate on the Goddess seated on a lotus, beloved of Lord Padmanabha, with lotus-petal eyes, worshipped by Lord Brahma.',
          expandedInstructions: [
            'Flowers symbolize opening the petals of the human heart to divine love.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Dīpa Darśanam & Naivedyam (Light & Offering)',
          upacharaName: 'Dīpam & Naivedyam',
          actionDescription:
              'Wave the lit lamp before Mother Lakshmi. Offer pure fruits or sweets with reverence.',
          sanskritMantra:
              'ॐ महालक्ष्म्यै नमः ।\nदीपं दर्शयामि, दिव्य नैवेद्यं समर्पयामि ॥',
          transliteration:
              'Om mahālakṣmyai namaḥ |\nDīpaṁ darśayāmi, divya naivedyaṁ samarpayāmi ||',
          meaning:
              'Salutations to Goddess Mahalakshmi. I present the sacred flame and offer pure sweet sustenance.',
          linkedMantraId: 'VEDA-MTR-0268',
          linkedMantraTitle: 'Lakshmi',
          expandedInstructions: [
            'Pray for righteous prosperity (Dharma-dhana) that benefits family, community, and the poor.',
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
          expandedInstructions: [
            'Remind yourself that your hands are instruments for honest work, learning, and divine service today.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Bhūmi Vandanam (Reverence to Mother Earth)',
          upacharaName: 'Kṣamāpaṇam',
          actionDescription:
              'Before placing your feet upon the floor, touch the ground with your right hand and bow your head, asking Mother Earth\'s forgiveness.',
          sanskritMantra:
              'समुद्रवसने देवि पर्वतस्तनमण्डले ।\nविष्णुपत्नि नमस्तुभ्यं पादस्पर्शं क्षमस्व मे ॥',
          transliteration:
              'Samudravasane devi parvatastanamaṇḍale |\nViṣṇupatni namastubhyaṁ pādasparśaṁ kṣamasva me ||',
          meaning:
              'O Mother Earth, clothed by the oceans, crowned by the mountains, consort of Lord Vishnu; salutations unto You. Please forgive me for stepping upon You with my feet.',
          expandedInstructions: [
            'Cultivates profound ecological reverence, humility, and gratitude for the living planet.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'Gāyatrī Mahāmantra (Contemplation on Divine Light)',
          upacharaName: 'Japa',
          actionDescription:
              'Sit quietly facing east. Breathe smoothly and recite the supreme Vedic illumination mantra.',
          sanskritMantra:
              'ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं\nभर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥',
          transliteration:
              'Om bhūrbhuvaḥ svaḥ tatsaviturvareṇyaṁ\nBhargo devasya dhīmahi dhiyo yo naḥ pracodayāt ||',
          meaning:
              'We meditate upon the glorious radiance of the Divine Sun (Savitr) who permeates the physical, subtle, and celestial realms. May That luminous Light inspire and awaken our intellect.',
          linkedMantraId: 'VEDA-MTR-0399',
          linkedMantraTitle: 'Gayatri Mantra',
          expandedInstructions: [
            'Optional: Tap "Chant Mantra" to chant with the master audio recording.',
            'Feel light filling your body and brain with vital clarity.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Pavamāna Sukta (The Aspiration for Truth)',
          upacharaName: 'Prārthanā',
          actionDescription:
              'Recite the ancient prayer from the Brihadaranyaka Upanishad for truth, light, and immortality.',
          sanskritMantra:
              'ॐ असतो मा सद्गमय ।\nतमसो मा ज्योतिर्गमय ।\nमृत्योर्मा अमृतं गमय ॥\nॐ शान्तिः शान्तिः शान्तिः ॥',
          transliteration:
              'Om asato mā sadgamaya |\nTamaso mā jyotirgamaya |\nMṛtyormā amṛtaṁ gamaya ||\nOm śāntiḥ śāntiḥ śāntiḥ ||',
          meaning:
              'Lead me from the unreal to the Real. Lead me from darkness to Light. Lead me from mortality to Immortality. Om, Peace, Peace, Peace.',
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
          expandedInstructions: [
            'Observe how a small flame dispels deep darkness effortlessly.',
          ],
        ),
        PujaStep(
          stepNumber: 2,
          stepName: 'Śubhaṁ Karoti Kalyāṇam (Prayer for Health & Well-being)',
          upacharaName: 'Prārthanā',
          actionDescription:
              'Recite the beloved prayer for family well-being, good intellect, and removal of hostility.',
          sanskritMantra:
              'शुभं करोति कल्याणमारोग्यं धनसम्पदाम् ।\nशत्रुबुद्धिविनाशाय दीपज्योतिर्नमोऽस्तु ते ॥',
          transliteration:
              'Śubhaṁ karoti kalyāṇam ārogyaṁ dhanasampadām |\nŚatrubuddhivināśāya dīpajyotirnamo\'stu te ||',
          meaning:
              'The light of the lamp brings auspiciousness, welfare, good health, and true spiritual wealth. For the destruction of hostile, divisive intellect, salutations to the holy lamp.',
          expandedInstructions: [
            '"Hostile intellect" primarily refers to internal inner enemies: greed, anger, jealousy, and arrogance.',
          ],
        ),
        PujaStep(
          stepNumber: 3,
          stepName: 'So \'Haṁ (Quiet Breath Contemplation)',
          upacharaName: 'Dhyānam',
          actionDescription:
              'Sit silently for two minutes before the flame. Inhale observing "So", exhale observing "Ham".',
          sanskritMantra:
              'ॐ सोऽहं हंसः ।\nअहमात्मा साक्षी शान्तः ॥',
          transliteration:
              'Om so\'haṁ haṁsaḥ |\nAhamātmā sākṣī śāntaḥ ||',
          meaning:
              'I am That Supreme Reality. I am the silent witness, tranquil and free.',
          linkedMantraId: 'VEDA-MTR-0448',
          linkedMantraTitle: 'So Hum',
          expandedInstructions: [
            'Let go of the day\'s fatigue, debates, and stress.',
            'Optional: Tap "Chant Mantra" to listen to the gentle So Hum contemplation.',
          ],
        ),
        PujaStep(
          stepNumber: 4,
          stepName: 'Sarve Bhavantu Sukhinaḥ (Universal Blessing)',
          upacharaName: 'Śāntiḥ',
          actionDescription:
              'Conclude the evening with the timeless Vedic prayer wishing happiness to all beings in creation.',
          sanskritMantra:
              'ॐ सर्वे भवन्तु सुखिनः सर्वे सन्तु निरामयाः ।\nसर्वे भद्राणि पश्यन्तु मा कश्चिद्दुःखभाग्भवेत् ॥\nॐ शान्तिः शान्तिः शान्तिः ॥',
          transliteration:
              'Om sarve bhavantu sukhinaḥ sarve santu nirāmayāḥ |\nSarve bhadrāṇi paśyantu mā kaścid duḥkhabhāg bhavet ||\nOm śāntiḥ śāntiḥ śāntiḥ ||',
          meaning:
              'May all beings be happy. May all beings be free from disease. May all perceive what is auspicious and noble. May no one suffer. Om Peace, Peace, Peace.',
          expandedInstructions: [
            'Breathe in universal peace and close your evening prayers.',
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
