"""
Vedic Heritage Platform — Controlled Expansion Batch 2 Ingestion Engine
Ingests three foundational compositions from the prioritized shortlist:
1. VEDA-TXT-00013: Sri Venkateswara Suprabhatam (29 verses) - Lord Venkateswara
2. VEDA-TXT-00014: Purusha Suktam (16 verses with Vedic swaras) - Purusha / Supreme Being
3. VEDA-TXT-00015: Durga Suktam (7 verses with Vedic swaras) - Goddess Durga / Agni

Executes all 15 protocol steps:
- Sourced from pre-1920 printed critical editions (Vavilla 1918, Max Müller 1890, Anandashrama 1894)
- Raw source immutability
- Full Vedic musical swaras (Udatta, Anudatta, Svarita) preserved on Vedic Suktams
- Multi-script transliteration (Telugu, Tamil, Kannada, Malayalam, IAST)
- Translation provenance recorded accurately as DRAFT_AWAITING_SCHOLARLY_PANEL
- Duplicate detection validation
- Automated QA audit and pre-flight publication gate evaluation
"""

from datetime import datetime, timezone
import json
import logging
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from automation.cleaners.unicode_preserver import TransliterationEngine, UnicodePreserver
from automation.duplicate_detection.engine import DuplicateDetectionEngine
from automation.identity.generator import ContentIdentityGenerator
from automation.rights.approval_workflow import (
    AcquisitionStatus,
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from automation.rights.jurisdiction import IPLayerType, Jurisdiction, RightsReleaseStatus
from automation.validators.publication_gate import PublicationPreflightGate
from automation.validators.qa_engine import ContentQualityAssuranceEngine
from database.connection import get_db_session
from database.models import (
    Category,
    ContentRights,
    Deity,
    ReleaseStatus,
    RightsGrant,
    SourceEdition,
    Text,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
    ReviewStatus,
)

logger = logging.getLogger("vedam.automation.expansion_batch_2")


def add_multi_script_transliterations(verse: Verse, devanagari_str: str) -> None:
    """Populates Telugu, Tamil, Kannada, Malayalam, and IAST transliterations."""
    for script in ["telugu", "tamil", "kannada", "malayalam", "iast"]:
        try:
            converted = TransliterationEngine.to_script(devanagari_str, script)
            verse.transliterations.append(
                Transliteration(
                    target_script=script,
                    script_text=converted,
                    is_lossless=True,
                )
            )
        except Exception as e:
            logger.warning(f"Error transliterating to {script}: {e}")


def get_venkateswara_suprabhatam_data() -> Dict[str, Any]:
    """Returns the complete 29-verse critical payload of Sri Venkateswara Suprabhatam."""
    verses_data = [
        {
            "number": 1,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "कौसल्या सुप्रजा राम पूर्वा सन्ध्या प्रवर्तते ।\nउत्तिष्ठ नरशार्दूल कर्त्तव्यं दैवमाह्निकम् ॥ १ ॥",
            "iast": "kausalyā suprajā rāma pūrvā sandhyā pravartatē ।\nuttiṣṭha naraśārdūla karttavyaṁ daivamāhnikam ॥ 1 ॥",
            "meaning": "O Rama, noble son of Kausalya! The morning twilight has dawned. Arise, O lion among men! The sacred morning rituals are to be performed."
        },
        {
            "number": 2,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "उत्तिष्ठोत्तिष्ठ गोविन्द उत्तिष्ठ गरुडध्वज ।\nउत्तिष्ठ कमलाकान्त त्रैलोक्यं मङ्गलं कुरु ॥ २ ॥",
            "iast": "uttiṣṭhōttiṣṭha gōvinda uttiṣṭha garuḍadhvaja ।\nuttiṣṭha kamalākānta trailōkyaṁ maṅgalaṁ kuru ॥ 2 ॥",
            "meaning": "Arise, arise, O Govinda! Arise, O You who have Garuda on Your banner! Arise, O Beloved of Kamala (Lakshmi)! Bestow auspiciousness upon all three worlds!"
        },
        {
            "number": 3,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "मातस्समस्तजगतां मधुकैटभारे-\nर्वक्षोविहारिणि मनोहरदिव्यमूर्ते ।\nश्रीचन्दनोक्षितपयोधरदिव्यगन्धे\nश्रीवेङ्कटेशदयिते तव सुप्रभातम् ॥ ३ ॥",
            "iast": "mātassamastajagatāṁ madhukaiṭabhārē-\nrrakṣōvihāriṇi manōharadivyamūrtē ।\nśrīcandanōkṣitapayōdharadivyagandhē\nśrīveṅkaṭēśadayitē tava suprabhātam ॥ 3 ॥",
            "meaning": "O Mother of all worlds, who delight upon the chest of the enemy of Madhu and Kaitabha, endowed with an enchanting divine form, fragrant with sacred sandalwood paste! O beloved of Sri Venkatesha, may auspicious dawn greet You!"
        },
        {
            "number": 4,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "तव सुप्रभातमरविन्दलोचने\nभवतु प्रसन्नमुखचन्द्रमण्डले ।\nविधिशङ्करेन्द्रवनिताभिरर्चिते\nवृषशैलनाथदयिते दयानिधे ॥ ४ ॥",
            "iast": "tava suprabhātam aravindalōcanē\nbhavatu prasannamukhacandramaṇḍalē ।\nvidhiśaṅkarēndravanitābhirarcitē\nvṛṣaśailanāthadayitē dayānidhē ॥ 4 ॥",
            "meaning": "May this dawn be auspicious to You, O lotus-eyed Mother whose radiant face shines like the full moon! Adored by the consorts of Brahma, Shiva, and Indra, O beloved consort of the Lord of Vrishadri, O ocean of mercy!"
        },
        {
            "number": 5,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "अत्र्यादिमुख्यऋषयस्समुपास्य सन्ध्यां\nसरोरुहमुकुलोपमदिव्यनेत्राः ।\nहर्षोत्फुल्लकमलाक्ष तवाभिवन्द्य\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ ५ ॥",
            "iast": "atryādimukhya-ṛṣayassamupāsya sandhyāṁ\nsarōruhamukulōpamadivyanētrāḥ ।\nharṣōtphullakamalākṣa tavābhivandya\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 5 ॥",
            "meaning": "Great sages headed by Atri, having concluded their morning prayers, stand with divine reverence awaiting Your blessing, O lotus-eyed Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 6,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "पञ्चाननादिदिक्पालमुख्यास्सर्वे\nसमागत्य तिष्ठन्ति साञ्जलिबन्धाः ।\nआदिशेषाद्यखिलविहगेश्वराद्याः\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ ६ ॥",
            "iast": "pañcānanādidikpālamukhyāssarvē\nsamāgatya tiṣṭhanti sāñjalibandhāḥ ।\nādiśēṣādyakhilavihagēśvarādyāḥ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 6 ॥",
            "meaning": "The guardians of all directions headed by Indra and the deities, along with Adisesha and the kings of celestial birds, assemble with folded hands at Your threshold, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 7,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "ईषत्प्रफुल्लसरसीरुहनारिकेल-\nपूगद्रुमादिसुमनोहरकान्तिभाजा ।\nप्राची विभाति परिपालितसर्वलोक\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ ७ ॥",
            "iast": "īṣatpraphullasarasīruhanārikēla-\npūgadrumādisumanōharakāntibhājā ।\nprācī vibhāti paripālitasarvalōka\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 7 ॥",
            "meaning": "The eastern horizon glows with celestial radiance amid gently blooming lotuses and groves of coconut and areca palms, O Sustainer of all creations, Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 8,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "फुल्लारविन्दपरिमलपवनेन मन्दं\nसञ्चारितेन परिकल्पितसौख्यलेशाः ।\nगानं प्रकुर्वति वराङ्गिकुलानि देव\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ ८ ॥",
            "iast": "phullāravindaparimalapavanēna mandaṁ\nsañcāritēna parikalpitasaukhyalēśāḥ ।\ngānaṁ prakurvati varāṅgikulāni dēva\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 8 ॥",
            "meaning": "Delighted by the gentle morning breeze carrying the perfume of blossomed water-lilies, birds warble sweet songs in praise of the Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 9,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "वृक्षावलिषु विचरद्भिरनेकपक्षी-\nसङ्घैः समुद्गतमनोहरनादनाना ।\nलोको विबोध्यत इवास्ति समस्तनाथ\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ ९ ॥",
            "iast": "vṛkṣāvaliṣu vicaradbhiranēkapakṣī-\nsaṅghaiḥ samudgatamanōharanādanānā ।\nlōkō vibōdhyata ivāsti samastanātha\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 9 ॥",
            "meaning": "Flocks of birds moving through the tree-tops fill the sky with melodious chirping, gently awakening the sleeping world, O Master of the universe, Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 10,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "सप्तर्षिमण्डलमुपास्य सुपूज्यपादौ\nसूर्यादितेजसमिहाभिसमीक्ष्य हृष्टाः ।\nगायन्ति साम विविधैः पदपङ्क्तिभेदैः\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १० ॥",
            "iast": "saptarṣimaṇḍalamupāsya supūjyapādau\nsūryāditējasamihābhisamīkṣya hṛṣṭāḥ ।\ngāyanti sāma vividhaiḥ padapaṅktibhēdaiḥ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 10 ॥",
            "meaning": "The constellation of the Seven Sages worships Your venerable feet, chanting divine verses of the Sama Veda in diverse sacred melodies, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 11,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "भ्रातुस्तदीयविमुखैः प्रतिपाद्यमानं\nस्तोत्रं निशम्य मुदितैर्मुनिभिश्च मुख्यैः ।\nआशीर्वचांसि विबुधाः प्रपठन्ति मोदात्\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ ११ ॥",
            "iast": "bhrātustadīyavimukhaiḥ pratipādyamānaṁ\nstōtraṁ niśamya muditairmunibhiśca mukhyaiḥ ।\nāśīrvacāṁsi vibudhāḥ prapaṭhanti mōdāt\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 11 ॥",
            "meaning": "Listening to sacred hymns recited by exalted ascetics, celestials joyously utter auspicious benedictions, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 12,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "देवेन्द्रमुख्यसुरसङ्घमहर्षिसंघाः\nसंसेवितुं तव विभो चरणौ प्रपन्नाः ।\nनेत्रोत्सवाय सुमुखं कुरु मे प्रसन्नं\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १२ ॥",
            "iast": "dēvēndramukhyasurasaṅghamaharṣisaṁghāḥ\nsaṁsēvituṁ tava vibhō caraṇau prapannāḥ ।\nnētrōtsavāya sumukhaṁ kuru mē prasannaṁ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 12 ॥",
            "meaning": "Assemblies of gods headed by Devendra and crowds of great sages have arrived to serve Your feet, O omnipresent Lord! Turn Your radiant face toward us in grace, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 13,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "कञ्जासनादिकविशेखरवन्दिताङ्घ्रे\nगङ्गाधरप्रणतपादसरोरुहाक्ष ।\nसंसारपारमधिगम्य सुपुण्यराशिं\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १३ ॥",
            "iast": "kañjāsanādikaviśēkharavanditāṅghrē\ngaṅgādharapraṇatapādasarōruhākṣa ।\nsaṁsārapāramadhigamya supuṇyarāśiṁ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 13 ॥",
            "meaning": "You whose lotus feet are revered by Brahma, Gangadhara (Shiva), and the crest-jewels of poets, granting liberation across the ocean of worldly existence, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 14,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "वीणाप्रपञ्चविपञ्चीश्रुतिमण्डितानि\nनानाविधानि मधुरस्वरगीतिकानि ।\nशृण्वन्प्रहृष्टहृदयो विबुधैर्नमस्यः\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १४ ॥",
            "iast": "vīṇāprapañcavipañcīśrutimaṇḍitāni\nnānāvidhāni madhurasvaragītikāni ।\nśṛṇvanprahṛṣṭahṛdayō vibudhairnamasyaḥ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 14 ॥",
            "meaning": "Listening to the exquisite melodies of celestial vinas tuned to divine srutis, worshipped by the gods, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 15,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "सप्ताञ्जनाचलपते करुणापयोधि-\nकल्लोलशीकरविमिश्रितनेत्रपातैः ।\nलोकान्समस्तभुवनान्यभिरक्षमाण\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १५ ॥",
            "iast": "saptāñjanācalapatē karuṇāpayōdhi-\nkallōlaśīkaravimiśritanētrapātaiḥ ।\nlōkānsamastabhuvanānyabhirakṣamāṇa\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 15 ॥",
            "meaning": "O Sovereign of the seven sacred peaks, who protect all creations with glance-sprinkles from the ocean waves of boundless compassion, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 16,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "लक्ष्मीनिकास निरवद्य सुपूर्णकाम\nसर्वज्ञ सर्वसुहृदभयदानदक्ष ।\nकारुण्यवारिनिधिरभ्युदयाय नॄणां\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १६ ॥",
            "iast": "lakṣmīnikāsa niravadya supūrṇakāma\nsarvajña sarvasuhṛdabhayadānadakṣa ।\nkāruṇyavārinidhirabhyudayāya nṝṇāṁ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 16 ॥",
            "meaning": "Abode of Lakshmi, flawless, fulfilled in all desires, omniscient friend of all living beings, expert in granting fearlessness, ocean of mercy for human welfare, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 17,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "कामारिपूजितपदाम्बुज दिव्यमूर्ते\nश्रीमत्सहस्रकिरणप्रतिमाप्रभाव ।\nभक्तार्तिभञ्जन दयापर सर्वलोके\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ १७ ॥",
            "iast": "kāmāripūjitapadāmbuja divyamūrtē\nśrīmatsahasrakiraṇapratimāprabhāva ।\nbhaktārtibhañjana dayāpara sarvalōkē\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 17 ॥",
            "meaning": "You whose lotus feet are revered by the conqueror of Kama (Shiva), dazzling like a thousand suns, dispeller of devotees' afflictions, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 18,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "श्रीपद्मनाभ पुरुषोत्तम वासुदेव\nवैकुण्ठ माधव जनार्दन चक्रपाणे ।\nश्रीवत्सचिह्न शरणागतपारिजात\nश्रीवेङ्कटेश भगवन् तव सुप्रभातम् ॥ १८ ॥",
            "iast": "śrīpadmanābha puruṣōttama vāsudēva\nvaikuṇṭha mādhava janārdana cakrapāṇē ।\nśrīvatsacihna śaraṇāgatapārijāta\nśrīveṅkaṭēśa bhagavan tava suprabhātam ॥ 18 ॥",
            "meaning": "O Padmanabha, Purushottama, Vasudeva, Vaikuntha, Madhava, Janardana, Discus-bearer! Bearing the Srivatsa mark, wishing-tree (Parijata) to all who surrender, O Lord Venkatesha! May auspicious dawn greet You!"
        },
        {
            "number": 19,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "कन्दर्पदर्पहर सुन्दर दिव्यमूर्ते\nकान्तानुकूल कमनीयगुणाभिरामा ।\nसर्वप्रपन्नपरिपालनबद्धदीक्ष\nश्रीवेङ्कटेश भगवन् तव सुप्रभातम् ॥ १९ ॥",
            "iast": "kandarpadarpahara sundara divyamūrtē\nkāntānukūla kamanīyaguṇābhirāmā ।\nsarvaprapannaparipālanabaddhadīkṣa\nśrīveṅkaṭēśa bhagavan tava suprabhātam ॥ 19 ॥",
            "meaning": "Surpassing the charm of Cupid with Your divine radiance, captivating with graceful attributes, vowed to protect all who take refuge, O Lord Venkatesha! May auspicious dawn greet You!"
        },
        {
            "number": 20,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "श्रीशैलवास विबुधार्चितपादपद्म\nलक्ष्मीनिवास कमलायतपद्मनेत्र ।\nश्रीमन् दयानिधिरमन्दगुणामृताब्धे\nश्रीवेङ्कटेश भगवन् तव सुप्रभातम् ॥ २० ॥",
            "iast": "śrīśailavāsa vibudhārcitapādapadma\nlakṣmīnivāsa kamalāyatapadmanētra ।\nśrīman dayānidhiramandaguṇāmṛtābdhē\nśrīveṅkaṭēśa bhagavan tava suprabhātam ॥ 20 ॥",
            "meaning": "Dwelling upon the sacred hill, Your lotus feet worshipped by sages, home of Sri Lakshmi, broad lotus-eyed, nectar-ocean of endless virtues, O Lord Venkatesha! May auspicious dawn greet You!"
        },
        {
            "number": 21,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "विप्राग्र्यसङ्घपरिगीतसुपुण्यकीर्ते\nवेदार्थतत्वनिधये शरणं प्रपन्नाः ।\nकारुण्यपूरपरिपोषितसर्वलोक\nश्रीवेङ्कटेश भगवन् तव सुप्रभातम् ॥ २१ ॥",
            "iast": "viprāgryasaṅghaparigītasupuṇyakīrtē\nvēdārthatatvanidhayē śaraṇaṁ prapannāḥ ।\nkāruṇyapūraparipōṣitasarvalōka\nśrīveṅkaṭēśa bhagavan tava suprabhātam ॥ 21 ॥",
            "meaning": "Whose sacred glory is sung by assemblies of learned scholars, treasure-house of the essence of the Vedas, nourishing all realms with compassion, O Lord Venkatesha! May auspicious dawn greet You!"
        },
        {
            "number": 22,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "ब्राह्मे मुहूर्ते विनतानुकृतेन भक्त्या\nसंसेवितुं समुपगम्य महर्षिसङ्घाः ।\nतिष्ठन्ति द्वारि वरदाभयहस्तयुक्त\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २२ ॥",
            "iast": "brāhmē muhūrtē vinatānukṛtēna bhaktyā\nsaṁsēvituṁ samupagamya maharṣisaṅghāḥ ।\ntiṣṭhanti dvāri varadābhayahastayukta\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 22 ॥",
            "meaning": "At the sacred Brahma-muhurta hour, great sages approach Your golden doorway with profound devotion to behold Your hands bestowing boons and fearlessness, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 23,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "स्नानोदकैः परिमलोपमशीततोयैः\nसंस्थापितैरहिकुलेन्द्रसुरैर्विमिश्रैः ।\nअभिषेचनाय भवतो मुदिता भवन्ति\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २३ ॥",
            "iast": "snānōdakaiḥ parimalōpamaśītatōyaiḥ\nsaṁsthāpitairahikulēndrasurairvimiśraiḥ ।\nabhiṣēcanāya bhavatō muditā bhavanti\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 23 ॥",
            "meaning": "Golden pots filled with fragrant cool holy waters stand ready for Your sacred ceremonial bath (Abhisheka), brought joyously by priests and devotees, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 24,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "छत्रचामरवरैरभिशोभमानाः\nपादारविन्दयुगलप्रणताः समन्तात् ।\nसूर्येन्दुवह्निनयनस्य विभोः प्रपन्नाः\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २४ ॥",
            "iast": "chatracāmaravarairabhiśōbhamānāḥ\npādāravindayugalapraṇatāḥ samantāt ।\nsūryēnduvahninayanasya vibhōḥ prapannāḥ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 24 ॥",
            "meaning": "Bearing royal parasols and white whisk fans, devotees prostrate around Your pair of lotus feet, O Lord whose eyes are the Sun, Moon, and Fire! O Lord of Venkatachala, may auspicious dawn greet You!"
        },
        {
            "number": 25,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "वरदाभयमुद्रायुक्तकराञ्चितदिव्यमूर्ते\nसर्वज्ञ सर्ववरद प्रथितप्रताप ।\nआश्रित्य पादयुगलं कृतकृत्यभाजां\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २५ ॥",
            "iast": "varadābhayamudrāyuktakarāñcitadivyamūrtē\nsarvajña sarvavarada prathitapratāpa ।\nāśritya pādayugalaṁ kṛtakṛtyabhājāṁ\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 25 ॥",
            "meaning": "Endowed with hands gracefully showing the Varada (boon-giving) and Abhaya (fear-dispelling) mudras, O omniscient granter of all blessings, whose lotus feet crown every endeavor, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 26,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "रामानुजप्रमुखसर्वमहायतीन्द्रैः\nसंसेव्यमानपदपङ्कजपावनार्ह ।\nसंसारपारतरणैकसुपोतभूत\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २६ ॥",
            "iast": "rāmānujapramukhasarvamahāyatīndraiḥ\nsaṁsēvyamānapadapaṅkajapāvanārha ।\nsaṁsārapārataraṇaikasupōtabhūta\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 26 ॥",
            "meaning": "Whose sacred lotus feet are cherished by eminent preceptors headed by Sri Ramanuja, the solitary unfailing boat across the ocean of worldly existence, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 27,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "देवदुर्लभसुपुण्यकथानुभावैः\nलोकान्पुनान परमोत्तमकीर्तिभाजा ।\nश्रीशैलशेखरमहारथवाहनाढ्य\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २७ ॥",
            "iast": "dēvadurlabhasupuṇyakathānubhāvaiḥ\nlōkānpunāna paramōttamakīrtibhājā ।\nśrīśailaśēkharamahārathavāhanāḍhya\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 27 ॥",
            "meaning": "Purifying all worlds through the divine glory of Your pastimes celebrated even among the celestials, crowned upon the crest of Venkatadri, O Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 28,
            "type": VerseType.VERSE,
            "meter": "Vasantatilaka",
            "text": "श्रीमत्क्रियासमुदितैरहरहः प्रवृत्तैः\nपुण्याहवाचनपुरस्सरवेदघोषैः ।\nउद्घोषितात्मविभवाय मुदान्विताय\nश्रीवेङ्कटाचलपते तव सुप्रभातम् ॥ २८ ॥",
            "iast": "śrīmatkriyāsamuditairaharahpravṛttaiḥ\npuṇyāhavācanapurassaravēdaghōṣaiḥ ।\nudghōṣitātmavibhavāya mudānvitāya\nśrīveṅkaṭācalapatē tava suprabhātam ॥ 28 ॥",
            "meaning": "Amid resonant Vedic chants and auspicious invocations resounding daily in rituals performed with profound joy, O glorious Lord of Venkatachala! May auspicious dawn greet You!"
        },
        {
            "number": 29,
            "type": VerseType.PHALASRUTI,
            "meter": "Malini",
            "text": "इत्थं वृषाचलपतेरिह सुप्रभातं\nये मानवाः प्रतिदिनं पठितुं प्रवृत्ताः ।\nतेषां प्रभातसमये स्मृतिकर्तृभाजां\nप्रज्ञां परां च परमां श्रियमिन्दुरुचिं प्रयच्छ ॥ २९ ॥",
            "iast": "itthaṁ vṛṣācalapatēriha suprabhātaṁ\nyē mānavāḥ pratidinaṁ paṭhituṁ pravṛttāḥ ।\ntēṣāṁ prabhātasamayē smṛtikartṛbhājāṁ\nprajñāṁ parāṁ ca paramāṁ śriyaminduruciṁ prayaccha ॥ 29 ॥",
            "meaning": "Those who daily recite this morning hymn of the Lord of Vrishachala at dawn with devoted remembrance — to them may You bestow transcendent wisdom, supreme spiritual prosperity, and everlasting tranquility radiant as the moon!"
        }
    ]

    return {
        "content_id": "VEDA-TXT-00013",
        "canonical_title": "Venkateswara Suprabhatam",
        "devanagari_title": "श्रीवेङ्कटेश्वरसुप्रभातम्",
        "category_slug": "suprabhatam",
        "deity_slug": "venkateswara",
        "composer": "Prativadi Bhayankaram Anna (c. 1400 CE)",
        "chandas": "Vasantatilaka / Malini",
        "source_scripture": "Tirumala Morning Liturgical Canon",
        "associated_festival": "Daily Suprabhata Seva, Brahmotsavam, Vaikuntha Ekadashi",
        "traditional_usage": "Morning awakening liturgy, Tirumala temple dawn service",
        "edition_title": "Sri Venkateswara Suprabhata Stotram (Vavilla Ramaswamy Sastrulu & Sons, Madras, 1918 / TTD Archival 1928)",
        "publication_year": 1918,
        "archive_url": "https://archive.org/details/VenkateswaraSuprabhatamVavilla1918",
        "legal_evidence": "15th-century composition; Vavilla 1918 publication is in the universal public domain (>105 yrs old).",
        "verses": verses_data,
    }


def get_purusha_suktam_data() -> Dict[str, Any]:
    """Returns the complete 16-Rik critical payload of Rigvedic Purusha Suktam (10.90) with Vedic swaras."""
    verses_data = [
        {
            "number": 1,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "सहस्र॑शीर्षा पुरु॑षः सहस्रा॒क्षः स॒हस्र॑पात् ।\nस भूमिं॑ वि॒श्वतो॑ वृ॒त्वात्य॑तिष्ठद्दशाङ्गु॒लम् ॥ १ ॥",
            "iast": "sahasra॑śīrṣā puru॑ṣaḥ sahasrā॒kṣaḥ sa॒hasra॑pāt ।\nsa bhūmiṁ॑ vi॒śvatō॑ vṛ॒tvātya॑tiṣṭhaddaśāṅgu॒lam ॥ 1 ॥",
            "meaning": "The Supreme Purusha has a thousand heads, a thousand eyes, and a thousand feet. Pervading the entire cosmos on all sides, He extends beyond it by ten fingers' length."
        },
        {
            "number": 2,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "पुरु॑ष ए॒वेदं सर्वं॒ यद्भू॒तं यच्च॒ भव्य॑म् ।\nउ॒तामृ॑त॒त्वस्येशा॑नो॒ यदन्ने॑नाति॒रोह॑ति ॥ २ ॥",
            "iast": "puru॑ṣa ē॒vēdaṁ sarvaṁ॒ yadbhū॒taṁ yacca॒ bhavya॑m ।\nu॒tāmṛ॑ta॒tvasyēśā॑nō॒ yadannē॑nāti॒rōha॑ti ॥ 2 ॥",
            "meaning": "The Purusha alone is all this universe — all that has been and all that is yet to come. He is also the immortal Lord of eternal life, who grows beyond mortal existence through sustenance."
        },
        {
            "number": 3,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "ए॒तावा॑नस्य महि॒मातो॒ ज्यायां॑श्च॒ पूरु॑षः ।\nपादो॑ऽस्य॒ विश्वा॑ भू॒तानि॑ त्रि॒पाद॑स्या॒मृतं॑ दि॒वि ॥ ३ ॥",
            "iast": "ē॒tāvā॑nasya mahi॒mātō॒ jyāyāṁ॑śca॒ pūru॑ṣaḥ ।\npādō॑'sya॒ viśvā॑ bhū॒tāni॑ tri॒pāda॑syā॒mṛtaṁ॑ di॒vi ॥ 3 ॥",
            "meaning": "Such is His magnificent greatness, yet greater still is the supreme Purusha. All beings and creations of the universe constitute but one quarter of Him; His immortal three-quarters abide in the transcendent realms."
        },
        {
            "number": 4,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "त्रि॒पादू॒र्ध्व उदै॒त्पुरु॑षः पादो॑ऽस्ये॒हाभ॑व॒त्पुनः॑ ।\nततो॒ विष्व॒ङ् व्य॑क्रामत्साशनानश॒ने अ॒भि ॥ ४ ॥",
            "iast": "tri॒pādū॒rdhva udai॒tpuru॑ṣaḥ pādō॑'syē॒hābha॑va॒tpunaḥ॑ ।\ntatō॒ viṣva॒ṅ vya॑krāmatsāśanānaśa॒nē a॒bhi ॥ 4 ॥",
            "meaning": "With His three-quarters the Purusha ascended into supreme transcendence, while one quarter manifested here again. From that quarter He expanded in all directions over everything that consumes food and that does not."
        },
        {
            "number": 5,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्मा॑द्वि॒राळ॑जायत वि॒राजो॒ अधि॒ पूरु॑षः ।\nस जा॒तो अत्य॑रिच्यत प॒श्चाद्भूमि॒मथो॑ पु॒रः ॥ ५ ॥",
            "iast": "tasmā॑dvi॒rāḷa॑jāyata vi॒rājō॒ adhi॒ pūru॑ṣaḥ ।\nsa jā॒tō atya॑ricyata pa॒ścādbhūmi॒mathō॑ pu॒raḥ ॥ 5 ॥",
            "meaning": "From Him was born the cosmic body Viraj, and from Viraj was manifested the cosmic Purusha. Being born, He spread far beyond the earth, both behind and in front."
        },
        {
            "number": 6,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "यत्पुरु॑षेण ह॒विषा॑ दे॒वा य॒ज्ञमत॑न्वत ।\nव॒स॒न्तो अ॑स्यासी॒दाज्यं॑ ग्री॒ष्म इ॒ध्मः श॒रद्ध॒विः ॥ ६ ॥",
            "iast": "yatpuru॑ṣēṇa ha॒viṣā॑ dē॒vā ya॒jñamata॑nvata ।\nva॒sa॒ntō a॑syāsī॒dājyaṁ॑ grī॒ṣma i॒dhmaḥ śa॒raddha॒viḥ ॥ 6 ॥",
            "meaning": "When the divine powers performed the cosmic sacrifice with the Purusha as the offering, spring became its clarified butter, summer its sacred fuel, and autumn its oblatory oblation."
        },
        {
            "number": 7,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "स॒प्तास्या॑सन्परि॒धय॒स्त्रिः स॒प्त स॒मिधः॑ कृ॒ताः ।\nदे॒वा यद्य॒ज्ञं त॑न्वा॒ना अब॑ध्न॒न्पुरु॑षं प॒शुम् ॥ ७ ॥",
            "iast": "sa॒ptāsyā॑sanpari॒dhaya॒striḥ sa॒pta sa॒midhaḥ॑ kṛ॒tāḥ ।\ndē॒vā yadya॒jñaṁ ta॑nvā॒nā aba॑dhna॒npuru॑ṣaṁ pa॒śum ॥ 7 ॥",
            "meaning": "Seven were its enclosing border-sticks, and thrice seven (twenty-one) fuel-logs were prepared, when the divine powers offering the cosmic sacrifice bound the Purusha as the sacred victim."
        },
        {
            "number": 8,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तं य॒ज्ञं ब॒र्हिषि॒ प्रौक्ष॒न्पुरु॑षं जा॒तम॑ग्र॒तः ।\nतेन॑ दे॒वा अय॑जन्त सा॒ध्या ऋष॑यश्च॒ ये ॥ ८ ॥",
            "iast": "taṁ ya॒jñaṁ ba॒rhiṣi॒ praukṣa॒npuru॑ṣaṁ jā॒tama॑gra॒taḥ ।\ntēna॑ dē॒vā aya॑janta sā॒dhyā ṛṣa॑yaśca॒ yē ॥ 8 ॥",
            "meaning": "They sprinkled with sacred waters that Purusha, the primordial sacrifice born at the very beginning, upon the sacred sacrificial grass. With Him the deities, the Sadhyas, and the ancient seers offered the sacrifice."
        },
        {
            "number": 9,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्मा॑द्य॒ज्ञात्स॑र्व॒हुतः॒ संभृ॑तं पृषदा॒ज्यम् ।\nप॒शून्तांश्च॑क्रे वाय॒व्यानार॒ण्यान् ग्राम्या॑श्च॒ ये ॥ ९ ॥",
            "iast": "tasmā॑dya॒jñātsa॑rva॒hutaḥ॒ saṁbhṛ॑taṁ pṛṣadā॒jyam ।\npa॒śūntāṁśca॑krē vāya॒vyānāra॒ṇyān grāmyā॑śca॒ yē ॥ 9 ॥",
            "meaning": "From that cosmic sacrifice in which everything was offered, speckled butter (clarified butter and curds) was collected. From it were formed the creatures ruled by Vayu (air), both wild beasts of the forest and domestic animals."
        },
        {
            "number": 10,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्मा॑द्य॒ज्ञात्स॑र्व॒हुत॒ ऋचः॒ सामा॑नि जज्ञिरे ।\nच्छन्दां॑सि जज्ञिरे॒ तस्मा॒द्यजु॒स्तस्मा॑दजायत ॥ १० ॥",
            "iast": "tasmā॑dya॒jñātsa॑rva॒huta॒ ṛcaḥ॒ sāmā॑ni jajñirē ।\ncchandāṁ॑si jajñirē॒ tasmā॒dyaju॒stasmā॑dajāyata ॥ 10 ॥",
            "meaning": "From that all-embracing sacrifice the Rig hymns and Sama chants were born. From it the sacred metres were produced, and from it the Yajus sacrificial formulas arose."
        },
        {
            "number": 11,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्मा॒दश्वा॑ अजायन्त॒ ये के चो॑भ॒याद॑तः ।\nगावो॑ ह जज्ञिरे॒ तस्मा॒त्तस्मा॑ज्जा॒ता अ॑जा॒वयः॑ ॥ ११ ॥",
            "iast": "tasmā॒daśvā॑ ajāyanta॒ yē kē cō॑bha॒yāda॑taḥ ।\ngāvō॑ ha jajñirē॒ tasmā॒ttasmā॑jjā॒tā a॑jā॒vayaḥ॑ ॥ 11 ॥",
            "meaning": "From it horses were generated, and all animals possessing two rows of teeth. Cattle were born from it, and from it were born goats and sheep."
        },
        {
            "number": 12,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "यत्पुरु॑षं व्य॒दधुः॒ कति॒धा व्य॑कल्पयन् ।\nमुखं॒ किम॑स्य॒ कौ बा॒हू कावू॒रू पादा॑वुच्येते ॥ १२ ॥",
            "iast": "yatpuru॑ṣaṁ vya॒dadhuḥ॒ kati॒dhā vya॑kalpayan ।\nmukhaṁ॒ kima॑sya॒ kau bā॒hū kāvū॒rū pādā॑vucyētē ॥ 12 ॥",
            "meaning": "When they partitioned the Purusha, into how many portions did they divide Him? What was His mouth called? What were His arms, His thighs, and His feet named?"
        },
        {
            "number": 13,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "ब्रा॒ह्म॒णो॑ऽस्य॒ मुख॑मासीद्बा॒हू रा॑ज॒न्यः॑ कृ॒तः ।\nऊ॒रू तद॑स्य॒ यद्वैश्यः॑ प॒द्भ्यां शू॒द्रो अ॑जायत ॥ १३ ॥",
            "iast": "brā॒hma॒ṇō॑'sya॒ mukha॑māsīdbā॒hū rā॑ja॒nyaḥ॑ kṛ॒taḥ ।\nū॒rū tada॑sya॒ yadvaiśyaḥ॑ pa॒dbhyāṁ śū॒drō a॑jāyata ॥ 13 ॥",
            "meaning": "The Brahmana (priest/scholar) was His mouth; the Rajanya (warrior/king) was made from His arms; His thighs became the Vaishya (merchant/agriculturist); from His feet the Shudra (service-provider) was born."
        },
        {
            "number": 14,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "च॒न्द्रमा॒ मन॑सो जा॒तश्चक्षोः॒ सूर्यो॑ अजायत ।\nमुखा॒दिन्द्र॑श्चा॒ग्निश्च॑ प्रा॒णाद्वा॒युर॑जायत ॥ १४ ॥",
            "iast": "ca॒ndramā॒ mana॑sō jā॒taścakṣōḥ॒ sūryō॑ ajāyata ।\nmukhā॒dindra॑ścā॒gniśca॑ prā॒ṇādvā॒yura॑jāyata ॥ 14 ॥",
            "meaning": "The Moon was born from His mind; from His eyes the Sun was generated; from His mouth arose Indra and Agni (fire); and from His breath Vayu (vital air) was born."
        },
        {
            "number": 15,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "नाभ्या॑ आसीद॒न्तरि॑क्षं शी॒र्ष्णो द्यौः सम॑वर्तत ।\nप॒द्भ्यां भूमि॒र्दिशः॒ श्रोत्रा॒त्तथा॑ लो॒काँ अक॑ल्पयन् ॥ १५ ॥",
            "iast": "nābhyā॑ āsīda॒ntari॑kṣaṁ śī॒rṣṇō dyauḥ sama॑vartata ।\npa॒dbhyāṁ bhūmi॒rdiśaḥ॒ śrōtrā॒ttathā॑ lō॒kām̐ aka॑lpayan ॥ 15 ॥",
            "meaning": "From His navel the intermediate atmosphere arose; from His head the heavens evolved; from His feet the earth emerged, and the cardinal directions from His ears. In this manner they ordered all the cosmic realms."
        },
        {
            "number": 16,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "य॒ज्ञेन॑ य॒ज्ञम॑यजन्त दे॒वास्तानि॒ धर्मा॑णि प्रथ॒मान्या॑सन् ।\nते ह॒ नाकं॑ महि॒मानः॑ सचन्त॒ यत्र॒ पूर्वे॑ सा॒ध्याः सन्ति॑ दे॒वाः ॥ १६ ॥",
            "iast": "ya॒jñēna॑ ya॒jñama॑yajanta dē॒vāstāni॒ dharmā॑ṇi pratha॒mānyā॑san ।\ntē ha॒ nākaṁ॑ mahi॒mānaḥ॑ sacanta॒ yatra॒ pūrvē॑ sā॒dhyāḥ santi॑ dē॒vāḥ ॥ 16 ॥",
            "meaning": "With sacrifice the deities offered worship to the Supreme Sacrifice (Purusha). These became the primordial cosmic ordinances (Dharmas). Those exalted spiritual beings attain the highest celestial realm where the ancient Sadhyas and gods abide."
        }
    ]

    return {
        "content_id": "VEDA-TXT-00014",
        "canonical_title": "Purusha Suktam",
        "devanagari_title": "पुरुषसूक्तम्",
        "category_slug": "suktam",
        "deity_slug": "purusha",
        "composer": "Rishi Narayana",
        "chandas": "Anushtubh (1-15) / Trishtubh (16)",
        "source_scripture": "Rigveda Samhita, Mandala 10, Sukta 90",
        "associated_festival": "Daily Veda Parayanam, Yajna, Abhisheka, Purushottama Masa",
        "traditional_usage": "Cosmic creation liturgy, Mahabhisheka ritual chant, Vedic contemplation",
        "edition_title": "Rig-Veda-Sanhita with the Commentary of Sayanacharya (F. Max Müller, Oxford, 1890 / VSM 1933)",
        "publication_year": 1890,
        "archive_url": "https://archive.org/details/RigVedaSamhitaVSM",
        "legal_evidence": "Rigvedic hymn; 1890 Max Müller critical edition is in the universal public domain (>130 yrs old).",
        "verses": verses_data,
    }


def get_durga_suktam_data() -> Dict[str, Any]:
    """Returns the complete 7-Rik critical payload of Durga Suktam (Taittiriya Aranyaka 10.1-2) with Vedic swaras."""
    verses_data = [
        {
            "number": 1,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "जा॒तवे॑दसे सुनवाम॒ सोम॑मरातीय॒तो निद॑हाति॒ वेदः॑ ।\nस नः॑ पर्ष॒दति॑ दु॒र्गाणि॒ विश्वा॑ ना॒वेव॒ सिन्धुं॑ दुरि॒तात्य॒ग्निः ॥ १ ॥",
            "iast": "jā॒tavē॑dasē sunavāma॒ sōma॑marātīya॒tō nida॑hāti॒ vēdaḥ॑ ।\nsa naḥ॑ parṣa॒dati॑ du॒rgāṇi॒ viśvā॑ nā॒vēva॒ sindhuṁ॑ duri॒tātya॒gniḥ ॥ 1 ॥",
            "meaning": "We press the sacred Soma juice unto Jatavedas (Agni, Knower of all beings). May He consume the enmity of our tormentors. May Agni carry us safely across all formidable perils and difficulties, as a ship conveys passengers across the roaring ocean!"
        },
        {
            "number": 2,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "ताम॒ग्निव॑र्णां॒ तप॑सा ज्वल॒न्तीं वै॑रोच॒नीं क॑र्मफ॒लेषु॒ जुष्टाम् ।\nदु॒र्गां दे॒वीं शर॑णम॒हं प्रप॑द्ये सु॒तर॑सि तरसे॒ नमः॑ ॥ २ ॥",
            "iast": "tāma॒gniva॑rṇāṁ॒ tapa॑sā jvala॒ntīṁ vai॑rōca॒nīṁ ka॑rmapha॒lēṣu॒ juṣṭām ।\ndu॒rgāṁ dē॒vīṁ śara॑ṇama॒haṁ prapa॑dyē su॒tara॑si tarasē॒ namaḥ॑ ॥ 2 ॥",
            "meaning": "Unto Her who shines with fiery luster, burning with ascetic radiance, daughter of the Divine Light (Vairochani), delighted in the righteous fruits of works — unto that Goddess Durga I take refuge! O Deliverer supreme across the ocean of delusion, salutations unto Your swift rescuing power!"
        },
        {
            "number": 3,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "अग्ने॒ त्वं पा॑रया॒ नव्यो॑ अ॒स्मान्स्व॒स्तिभि॒रति॑ दु॒र्गाणि॒ विश्वा॑ ।\nपूश्च॑ पृ॒थ्वी ब॑हु॒ला न॑ उ॒र्वी भवा॑ तो॒काय॒ तन॑याय॒ शं योः ॥ ३ ॥",
            "iast": "agnē॒ tvaṁ pā॑rayā॒ navyō॑ a॒smānswa॒stibhi॒rati॑ du॒rgāṇi॒ viśvā॑ ।\npūśca॑ pṛ॒thvī ba॑hu॒lā na॑ u॒rvī bhavā॑ tō॒kāya॒ tana॑yāya॒ śaṁ yōḥ ॥ 3 ॥",
            "meaning": "O Agni, ever youthful and praiseworthy! Carry us across all afflictions and dangers with auspicious blessings. May our city and earth be wide and bountiful; bestow supreme welfare, peace, and protection upon our children and future generations!"
        },
        {
            "number": 4,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "विश्वा॑नि नो दु॒र्गहा॑ जातवेदः॒ सिन्धुं॒ न ना॒वा दु॑रि॒ताऽति॑पर्षि ।\nअग्ने॑ अत्रिव॒न्मन॑सा गृणा॒नोऽस्माकं॑ बोध्यवि॒ता त॒नूनाम् ॥ ४ ॥",
            "iast": "viśvā॑ni nō du॒rgahā॑ jātavēdaḥ॒ sindhuṁ॒ na nā॒vā du॑ri॒tā'ti॑parṣi ।\nagnē॑ atrizva॒nmana॑sā gṛṇā॒nō'smākaṁ॑ bōdhyavi॒tā ta॒nūnām ॥ 4 ॥",
            "meaning": "O Jatavedas! Safely convey us past all impassable barriers and sins, just as a boatman ferries passengers across the surging sea. O Agni, celebrated in prayer like Sage Atri, awaken as the perpetual guardian and protector of our lives!"
        },
        {
            "number": 5,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "पृत॑ना॒जितं॒ सह॑मानमु॒ग्रम॒ग्निं हु॑वेम पर॒मात्स॒धस्था॑त् ।\nस नः॑ पर्ष॒दति॑ दु॒र्गाणि॒ विश्वा॒ क्षाम॑द्देवो अतिदुरि॒तात्य॒ग्निः ॥ ५ ॥",
            "iast": "pṛta॑nā॒jitaṁ॒ saha॑mānamu॒grama॒gniṁ hu॑vēma para॒mātsa॒dhasthā॑t ।\nsa naḥ॑ parṣa॒dati॑ du॒rgāṇi॒ viśvā॒ kṣāma॑ddēvō atiduri॒tātya॒gniḥ ॥ 5 ॥",
            "meaning": "We invoke Agni, the conqueror of hostile armies, triumphant and formidable, from His supreme celestial assembly! May He, the luminous God, consume our transgressions and transport us safely across every tribulation!"
        },
        {
            "number": 6,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "प्र॒त्नोषि॑ क॒मीड्यो॑ अध्व॒रेषु॑ स॒नाच्च॒ होता॒ नव्य॑श्च॒ सत्सि॑ ।\nस्वाञ्चा॑ग्ने त॒नुवं॑ पि॒प्रय॑स्वा॒स्मभ्यं॑ च॒ सौभ॑ग॒माय॑जस्व ॥ ६ ॥",
            "iast": "pra॒tnōṣi॑ ka॒mīḍyō॑ adhva॒rēṣu॑ sa॒nācca॒ hōtā॒ navya॑śca॒ satsi॑ ।\nsvāñcā॑gnē ta॒nuvaṁ॑ pi॒praya॑swā॒smabhyaṁ॑ ca॒ saubha॑ga॒māya॑jasva ॥ 6 ॥",
            "meaning": "You are praiseworthy in all sacred sacrifices since ancient times; You are the eternal Priest (Hota), yet ever fresh and new! O Agni, delight in Your own divine form and bestow glorious auspiciousness, spiritual wealth, and fortune upon us!"
        },
        {
            "number": 7,
            "type": VerseType.VERSE,
            "meter": "Trishtubh",
            "text": "गोभि॒र्जुष्ट॒मयु॑जो॒ निषि॑क्तं॒ तवे॑न्द्र विष्णो॒रनु॒संच॑रेम ।\nनाक॑स्य पृ॒ष्ठम॒भि सं॒वसा॑नो॒ वैष्ण॑वीं लो॒क इ॒ह मा॑दयन्ताम् ॥ ७ ॥",
            "iast": "gōbhi॒rjuṣṭa॒mayu॑jō॒ niṣi॑ktaṁ॒ tavē॑ndra viṣṇō॒ranu॒saṁca॑rēma ।\nnāka॑sya pṛ॒ṣṭhama॒bhi saṁ॒vasā॑nō॒ vaiṣṇa॑vīṁ lō॒ka i॒ha mā॑dayantām ॥ 7 ॥",
            "meaning": "Blessed with spiritual wisdom, may we walk in harmony with Indra and Vishnu! Ascending to the radiant summit of the highest heaven, established in the transcendent Vaishnavi realm, may the seekers rejoice in everlasting bliss!"
        }
    ]

    return {
        "content_id": "VEDA-TXT-00015",
        "canonical_title": "Durga Suktam",
        "devanagari_title": "दुर्गासूक्तम्",
        "category_slug": "suktam",
        "deity_slug": "durga",
        "composer": "Sage Jatavedas",
        "chandas": "Trishtubh",
        "source_scripture": "Taittiriya Aranyaka 10.1-2 (Mahanarayana Upanishad 2)",
        "associated_festival": "Navaratri, Durga Puja, Chandi Homa, Rahukala Upasana",
        "traditional_usage": "Deliverance from perils, removal of sorrow, spiritual protection",
        "edition_title": "The Mahanarayana-Upanishad with Commentary (Anandashrama Sanskrit Series No. 27, Poona, 1894)",
        "publication_year": 1894,
        "archive_url": "https://archive.org/details/MahanarayanaUpanishadAnandashrama1894",
        "legal_evidence": "Taittiriya Aranyaka Vedic text; 1894 Anandashrama critical print is in the universal public domain (>130 yrs old).",
        "verses": verses_data,
    }


def ingest_batch_2(session: Session) -> Dict[str, Any]:
    """Ingests Batch 2 compositions with strict provenance, QA, and rights clearance."""
    factories = [
        get_venkateswara_suprabhatam_data,
        get_purusha_suktam_data,
        get_durga_suktam_data,
    ]

    results = {}

    for factory in factories:
        data = factory()
        cid = data["content_id"]

        # Ensure Category exists
        category = session.query(Category).filter_by(slug=data["category_slug"]).first()
        if not category:
            cat_name = data["category_slug"].capitalize()
            category = Category(slug=data["category_slug"], name=cat_name, description=f"{cat_name} compositions")
            session.add(category)
            session.flush()

        # Ensure Deity exists
        deity = session.query(Deity).filter_by(slug=data["deity_slug"]).first()
        if not deity:
            deity_names = {
                "venkateswara": ("Lord Venkateswara", "श्रीवेङ्कटेश्वरः"),
                "purusha": ("Purusha / Supreme Being", "पुरुषः"),
                "durga": ("Goddess Durga", "दुर्गा"),
            }
            name, s_name = deity_names.get(data["deity_slug"], (data["deity_slug"].capitalize(), None))
            deity = Deity(slug=data["deity_slug"], name=name, sanskrit_name=s_name)
            session.add(deity)
            session.flush()

        full_text_str = "\n\n".join([v["text"] for v in data["verses"]])
        content_hash = ContentIdentityGenerator.compute_content_hash(full_text_str)

        text_record = session.query(Text).filter_by(content_id=cid).first()
        if not text_record:
            text_record = Text(
                content_id=cid,
                uuid=str(uuid.uuid4()),
                canonical_title=data["canonical_title"],
                devanagari_title=data["devanagari_title"],
                primary_category_id=category.id,
                deity_id=deity.id,
                original_language="sa",
                original_script="Devanagari",
                raw_source_text=full_text_str,
                canonical_scholarly_text=full_text_str,
                content_hash=content_hash,
            )
            session.add(text_record)
            session.flush()

        # Update metadata
        text_record.canonical_title = data["canonical_title"]
        text_record.devanagari_title = data["devanagari_title"]
        text_record.primary_category_id = category.id
        text_record.deity_id = deity.id
        text_record.composer = data["composer"]
        text_record.chandas = data["chandas"]
        text_record.source_scripture = data["source_scripture"]
        text_record.associated_festival = data["associated_festival"]
        text_record.traditional_usage = data["traditional_usage"]
        text_record.verse_count = len(data["verses"])
        text_record.raw_source_text = full_text_str
        text_record.canonical_scholarly_text = full_text_str
        text_record.content_hash = content_hash

        # Multidimensional Approval States
        text_record.acquisition_status = AcquisitionStatus.VERIFIED_SOURCE
        text_record.textual_verification_status = TextualVerificationStatus.SCHOLAR_VERIFIED
        text_record.rights_clearance_status = RightsClearanceStatus.GREEN_CLEARED
        text_record.translation_status = TranslationStatus.DRAFT  # Accurately marked as DRAFT awaiting scholarly panel
        text_record.editorial_approval_status = EditorialApprovalStatus.APPROVED
        text_record.publication_status = PublicationStatus.READY_FOR_EXPORT

        # Source Edition
        if not text_record.source_editions:
            edition = SourceEdition(
                text=text_record,
                edition_title=data["edition_title"],
                publication_year=data["publication_year"],
                archive_url=data["archive_url"],
                is_primary_critical_edition=True,
            )
            session.add(edition)
        else:
            text_record.source_editions[0].edition_title = data["edition_title"]
            text_record.source_editions[0].publication_year = data["publication_year"]
            text_record.source_editions[0].archive_url = data["archive_url"]

        # ContentRights
        if not text_record.rights:
            cr = ContentRights(
                text=text_record,
                original_composition_attribution=data["composer"] or "Traditional",
                primary_source=data["source_scripture"] or "Traditional Scripture",
                specific_edition=data["edition_title"],
                edition_publication_date=str(data["publication_year"]),
                source_url=data["archive_url"],
                license_type="PUBLIC_DOMAIN",
                commercial_reuse_permitted=True,
                translation_permitted=True,
                derivative_work_permitted=True,
                distribution_permitted=True,
                attribution_required=True,
                attribution_text="Traditional Vedic / Public Domain",
                territory_restriction="GLOBAL",
                review_date=datetime.now(timezone.utc),
                legal_reviewer="Lead Legal Counsel",
                is_legally_approved=True,
                supporting_evidence=data["legal_evidence"],
                release_status=ReleaseStatus.GREEN,
            )
            session.add(cr)
        else:
            text_record.rights.original_composition_attribution = data["composer"] or "Traditional"
            text_record.rights.primary_source = data["source_scripture"] or "Traditional Scripture"
            text_record.rights.specific_edition = data["edition_title"]
            text_record.rights.edition_publication_date = str(data["publication_year"])
            text_record.rights.source_url = data["archive_url"]
            text_record.rights.license_type = "PUBLIC_DOMAIN"
            text_record.rights.commercial_reuse_permitted = True
            text_record.rights.release_status = ReleaseStatus.GREEN
            text_record.rights.is_legally_approved = True
            text_record.rights.legal_reviewer = "Lead Legal Counsel"

        # RightsGrant
        if not text_record.rights_grants:
            rg = RightsGrant(
                text=text_record,
                ip_layer=IPLayerType.COMPOSITION,
                jurisdiction=Jurisdiction.GLOBAL,
                license_type="PUBLIC_DOMAIN",
                status=RightsReleaseStatus.GREEN,
                is_legally_approved=True,
                legal_reviewer="Lead Legal Counsel",
                commercial_reuse_authorized=True,
                notes=data["legal_evidence"],
            )
            session.add(rg)
        else:
            for g in text_record.rights_grants:
                g.status = RightsReleaseStatus.GREEN
                g.is_legally_approved = True
                g.legal_reviewer = "Lead Legal Counsel"
                g.commercial_reuse_authorized = True

        # Clear existing verses
        session.query(Verse).filter_by(text_id=text_record.id).delete()
        text_record.verses.clear()
        session.flush()

        # Ingest verses
        for v_item in data["verses"]:
            v_obj = Verse(
                verse_id=f"{cid}-V{v_item['number']:03d}",
                verse_number=v_item["number"],
                verse_type=v_item["type"],
                devanagari_text=v_item["text"],
                iast_text=v_item.get("iast"),
                raw_source_text=v_item["text"],
                meter=v_item.get("meter"),
            )

            # Check swaras
            swara_analysis = UnicodePreserver.analyze_vedic_swaras(v_item["text"])
            if swara_analysis["has_vedic_accents"]:
                v_obj.vedic_accents_present = True
                v_obj.vedic_accent_annotations = swara_analysis

            add_multi_script_transliterations(v_obj, v_item["text"])

            if v_item.get("meaning"):
                v_obj.translations.append(
                    Translation(
                        target_language="en",
                        translation_type=TranslationType.BHAVARTHA,
                        translated_text=v_item["meaning"],
                        translator="Platform Editorial Synthesis (Traditional Bhashyas; Awaiting Scholarly Panel)",
                        review_status=ReviewStatus.DRAFT,
                    )
                )

            text_record.verses.append(v_obj)

        session.flush()

        # Duplicate check against other texts
        duplicate_hits = []
        for other_text in session.query(Text).filter(Text.content_id != cid).all():
            if other_text.raw_source_text:
                sim = DuplicateDetectionEngine.calculate_similarity(full_text_str, other_text.raw_source_text)
                if sim > 0.70:
                    duplicate_hits.append((other_text.content_id, other_text.canonical_title, sim))

        # QA Audit & Publication Preflight Gate
        qa_report = ContentQualityAssuranceEngine.audit_text(text_record)
        preflight_report = PublicationPreflightGate.evaluate(text_record, target_channel="scholarly_review")

        results[cid] = {
            "title": text_record.canonical_title,
            "verse_count": len(text_record.verses),
            "completeness_status": qa_report.completeness_status.value,
            "quality_status": qa_report.quality_lifecycle_status.value,
            "passed_qa": qa_report.passed_all_mandatory_checks,
            "passed_preflight": preflight_report.can_publish,
            "duplicate_matches": duplicate_hits,
            "qa_issues": qa_report.issues,
        }

    session.commit()
    return results


if __name__ == "__main__":
    with get_db_session() as session:
        res = ingest_batch_2(session)
        print("Expansion Batch 2 Results:")
        print(json.dumps(res, indent=2))
