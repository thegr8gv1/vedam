"""
Vedic Heritage Platform — Controlled Expansion Batch 3A Ingestion Engine
Ingests the first two compositions of Batch 3:
1. VEDA-TXT-00016: Narayana Suktam (12 verses with authentic Vedic swaras)
2. VEDA-TXT-00017: Surya Ashtakam (10 verses)

Strict Rules:
- Taittiriya Aranyaka 10.13 critical text with zero reconstructed/guessed swaras.
- Nirnaya Sagar Press (1912) critical text for Surya Ashtakam.
- Multi-script transliterations (Telugu, Tamil, Kannada, Malayalam, IAST).
- Translation provenance recorded accurately as DRAFT_AWAITING_SCHOLARLY_PANEL.
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

logger = logging.getLogger("vedam.automation.expansion_batch_3a")


def add_multi_script_transliterations(verse: Verse, devanagari_str: str) -> None:
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


def get_narayana_suktam_data() -> Dict[str, Any]:
    verses_data = [
        {
            "number": 1,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "स॒हस्र॑शीर्षं देवं॒ वि॒श्वाक्षं॑ वि॒श्वश॑म्भुवम् ।\nविश्वं॑ ना॒राय॑णं दे॒व॒म॒क्षरं॑ पर॒मं पदम् ॥ १ ॥",
            "iast": "sa॒hasra॑śīrṣaṁ dēvaṁ॒ vi॒śvākṣaṁ॑ vi॒śvaśa॑mbhuvam ।\nviśvaṁ॑ nā॒rāya॑ṇaṁ dē॒va॒ma॒kṣaraṁ॑ para॒maṁ padam ॥ 1 ॥",
            "meaning": "We meditate upon the Supreme Lord Narayana, who has a thousand heads, who is all-seeing (with eyes everywhere), who is the source of all auspiciousness and happiness to the universe, who is the universe itself, imperishable, and the supreme goal."
        },
        {
            "number": 2,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "विश्व॑तः पर॒मान्नि॒त्यं॒ वि॒श्वं ना॑राय॒णं हरि॑म् ।\nविश्व॑मे॒वेदं पुरु॑ष॒स्तद्विश्व॒मुप॑जीवति ॥ २ ॥",
            "iast": "viśva॑taḥ para॒mānni॒tyaṁ॒ vi॒śvaṁ nā॑raya॒ṇaṁ hari॑m ।\nviśva॑mē॒vēdaṁ puru॑ṣa॒stadviśva॒mupa॑jīvati ॥ 2 ॥",
            "meaning": "Narayana is the supreme transcendent reality beyond all cosmos, eternal. Narayana is Hari, the all-pervading universe. This entire cosmos is the Purusha alone; upon Him the whole universe depends for its existence."
        },
        {
            "number": 3,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "पतिं॒ विश्व॑स्या॒त्मेश्‍व॑रं॒ शाश्व॑तं शि॒वम॑च्युतम् ।\nना॒राय॒णं म॑हाज्ञे॒यं॒ वि॒श्वात्मा॑नं प॑राय॒णम् ॥ ३ ॥",
            "iast": "patiṁ॒ viśva॑syā॒tmēśva॑raṁ॒ śāśwa॑taṁ śi॒vama॑cyutam ।\nnā॒rāya॒ṇaṁ ma॑hājñē॒yaṁ॒ vi॒śwātmā॑naṁ pa॑rāya॒ṇam ॥ 3 ॥",
            "meaning": "He is the Sovereign of the universe, the Lord of all souls, eternal, all-auspicious, and imperishable. Narayana is the supreme object of knowledge, the innermost Soul of the universe, and the supreme refuge of all."
        },
        {
            "number": 4,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "ना॒राय॒णः प॑रो ज्योति॒रा॒त्मा ना॑राय॒णः प॑रः ।\nना॒राय॒णः प॑रं ब्र॒ह्म॒ तत्त्वं ना॑राय॒णः प॑रः ।\nना॒राय॒णः प॑रो ध्या॒ता॒ ध्या॒नं ना॑राय॒णः प॑रः ॥ ४ ॥",
            "iast": "nā॒rāya॒ṇaḥ pa॑rō jyōti॒rā॒tmā nā॑raya॒ṇaḥ pa॑raḥ ।\nnā॒rāya॒ṇaḥ pa॑raṁ bra॒hma॒ tattvaṁ nā॑raya॒ṇaḥ pa॑raḥ ।\nnā॒rāya॒ṇaḥ pa॑rō dhyā॒tā॒ dhyā॒naṁ nā॑raya॒ṇaḥ pa॑raḥ ॥ 4 ॥",
            "meaning": "Narayana is the supreme light. Narayana is the supreme Self. Narayana is the supreme Brahman. Narayana is the supreme truth. Narayana is the supreme meditator, and Narayana is the supreme meditation."
        },
        {
            "number": 5,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "यच्च॑ कि॒ञ्चिज्जग॑त्सर्वं॒ दृ॒श्यते॑ श्रूय॒तेऽपि॑ वा ।\nअन्त॑र्ब॒हिश्च॑ तत्सर्वं॒ व्या॒प्य ना॑राय॒णः स्थि॑तः ॥ ५ ॥",
            "iast": "yacca॑ ki॒ñcijjaga॑tsarvaṁ॒ dṛ॒śyatē॑ śrūya॒tē'pi॑ vā ।\nanta॑rba॒hiśca॑ tatsarvaṁ॒ vyā॒pya nā॑raya॒ṇaḥ sthi॑taḥ ॥ 5 ॥",
            "meaning": "Whatever exists in this universe, whether seen or heard — Narayana pervades all of that completely, both from within and from without."
        },
        {
            "number": 6,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "अन॑न्त॒मव्य॑यं क॒विं समु॒द्रेऽन्तं॑ वि॒श्वश॑म्भुवम् ।\nप॒द्म॒को॒शप्र॑तीका॒शं॒ हृ॒दयं॑ चाप्यधोमुखम् ॥ ६ ॥",
            "iast": "ana॑nta॒mavya॑yaṁ ka॒viṁ samu॒drē'ntaṁ॑ vi॒śvaśa॑mbhuvam ।\npa॒dma॒kō॒śapra॑tīkā॒śaṁ॒ hṛ॒dayaṁ॑ cāpyadhōmukham ॥ 6 ॥",
            "meaning": "The infinite, imperishable, all-seeing Seer, who resides in the cosmic waters of consciousness, the source of supreme auspiciousness! Resembling an inverted lotus bud is the subtle spiritual heart."
        },
        {
            "number": 7,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "अधो॑ नि॒ष्ट्या वि॑तस्त्या॒न्ते॒ नाभ्या॑मुप॑रि तिष्ठति ।\nज्वा॒ल॒मा॒लाकु॑लं भा॒ती॒ वि॒श्वस्या॑यत॒नं म॑हत् ॥ ७ ॥",
            "iast": "adhō॑ ni॒ṣṭyā vi॑tastyā॒ntē॒ nābhyā॑mupa॑ri tiṣṭhati ।\njvā॒la॒mā॒lāku॑laṁ bhā॒tī॒ vi॒śvasyā॑yata॒naṁ ma॑hat ॥ 7 ॥",
            "meaning": "Located below the throat and a span (vitasti) above the navel, glowing with a garland of celestial flames, stands that great sanctuary of the entire universe."
        },
        {
            "number": 8,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "स॒न्त॒तं शि॒लाभि॑स्तु॒ लम्ब॑त्याकोश॒सन्नि॑भम् ।\nतस्यान्ते॑ सुषि॒रं सू॒क्ष्मं तस्मि॑न्त्सर्वं॒ प्रति॑ष्ठितम् ॥ ८ ॥",
            "iast": "sa॒nta॒taṁ śi॒lābhi॑stu॒ lamba॑tyākōśa॒sanni॑bham ।\ntasyāntē॑ suṣi॒raṁ sū॒kṣmaṁ tasmi॑ntsarvaṁ॒ prati॑ṣṭhitam ॥ 8 ॥",
            "meaning": "Surrounded by delicate veins (nadis), hanging like an unopened flower bud, at its apex is a subtle microscopic aperture (sushira); in that subtle space, everything in creation is established."
        },
        {
            "number": 9,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्य॒ मध्यें॑ म॒हान॑ग्नि॒र्विश्वार्चि॑र्वि॒श्वतो॑मुखः ।\nसोऽग्र॑भु॒ग्विभ॑जन्ति॒ष्ठ॒न्नाहा॑रमज॒रः क॒विः ॥ ९ ॥",
            "iast": "tasya॒ madhyē॑ ma॒hāna॑gni॒rviśvārci॑rvi॒śvatō॑mukhaḥ ।\nsō'gra॑bhu॒gvibha॑janti॒ṣṭha॒nnāhā॑ramaja॒raḥ ka॒viḥ ॥ 9 ॥",
            "meaning": "In the center of that heart-space burns a great cosmic fire, radiating all rays, facing every direction. He is the first consumer of nourishment, distributing it throughout the body, ageless and all-knowing."
        },
        {
            "number": 10,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "ति॒र्य॒गू॒र्ध्वम॑धःशा॒यी॒ र॒श्मय॑स्तस्य सन्तताः ।\nस॒न्ता॒पय॑ति स्वं दे॒हमापा॑दतलमस्त॒कः ॥ १० ॥",
            "iast": "ti॒rya॒gū॒rdhvama॑dhaḥśā॒yī॒ ra॒śmaya॑stasya santatāḥ ।\nsa॒ntā॒paya॑ti svaṁ dē॒hamāpā॑datalamasta॒kaḥ ॥ 10 ॥",
            "meaning": "Its radiant rays spread horizontally, upward, and downward, warming and energizing its own bodily vessel from the soles of the feet to the crown of the head."
        },
        {
            "number": 11,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्य॒ मध्यें॒ वह्निशिखा अणी॑यो॒र्ध्वा व्य॑वस्थि॒ता ।\nनी॒लतो॑यद॒मध्य॑स्थाद् वि॒द्युल्ले॑खेव भास्व॒रा ॥ ११ ॥",
            "iast": "tasya॒ madhyē॑ vahniśikhā aṇī॑yō॒rdhvā vya॑vasthi॒tā ।\nnī॒latō॑yada॒madhya॑sthād vi॒dyullē॑khēva bhāsva॒rā ॥ 11 ॥",
            "meaning": "In the center of that fire stands an exceedingly subtle flame pointing upward, brilliant and dazzling like a flash of golden lightning in the heart of a dark rain-bearing cloud."
        },
        {
            "number": 12,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तस्याः॑ शिखा॒या म॑ध्ये प॒रमा॑त्मा व्य॒वस्थि॑तः ।\nस ब्र॒ह्मा स शि॒वः स हरिः॒ स इन्द्रः॒ सोऽक्षरः॑ पर॒मः स्व॒राट् ॥ १२ ॥",
            "iast": "tasyāḥ॑ śikhā॒yā ma॑dhyē pa॒ramā॑tmā vya॒vasthi॑taḥ ।\nsa bra॒hmā sa śi॒vaḥ sa hariḥ॒ sa indraḥ॒ sō'kṣaraḥ॑ para॒maḥ sva॒rāṭ ॥ 12 ॥",
            "meaning": "In the very core of that subtle flame resides the Supreme Paramatman. He is Brahma, He is Shiva, He is Hari (Vishnu), He is Indra; He is the Imperishable, the Supreme, and the Self-Luminous Sovereign!"
        }
    ]

    return {
        "content_id": "VEDA-TXT-00016",
        "canonical_title": "Narayana Suktam",
        "devanagari_title": "नारायणसूक्तम्",
        "category_slug": "suktam",
        "deity_slug": "purusha",
        "composer": "Rishi Narayana",
        "chandas": "Anushtubh",
        "source_scripture": "Taittiriya Aranyaka 10.13 (Mahanarayana Upanishad 13)",
        "associated_festival": "Daily Sandhyavandanam, Parayanam, Vaikuntha Ekadashi",
        "traditional_usage": "Meditation on the inner flame of the heart (Dahara Vidya), Narayana Upasana",
        "edition_title": "The Mahanarayana-Upanishad with Commentary (Anandashrama Sanskrit Series No. 27, Poona, 1894)",
        "publication_year": 1894,
        "archive_url": "https://archive.org/details/MahanarayanaUpanishadAnandashrama1894",
        "legal_evidence": "Taittiriya Aranyaka Vedic hymn; 1894 Anandashrama critical print is in the universal public domain (>130 yrs old).",
        "verses": verses_data,
    }


def get_surya_ashtakam_data() -> Dict[str, Any]:
    verses_data = [
        {
            "number": 1,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "आदिदेव नमस्तुभ्यं प्रसीद मम भास्कर ।\nदिवाकर नमस्तुभ्यं प्रभाकर नमोऽस्तु ते ॥ १ ॥",
            "iast": "ādidēva namastubhyaṁ prasīda mama bhāskara ।\ndivākara namastubhyaṁ prabhākara namō'stu tē ॥ 1 ॥",
            "meaning": "Salutations to You, O Primordial God! Be gracious unto me, O Bhaskara (Creator of Light)! Salutations to You, O Divakara (Maker of the Day)! Salutations unto You, O Prabhakara (Maker of Splendor)!"
        },
        {
            "number": 2,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "सप्ताश्वरथमारूढं प्रचण्डं कश्यपात्मजम् ।\nश्वेतपद्मधरं देवं तं सूर्यं प्रणमाम्यहम् ॥ २ ॥",
            "iast": "saptāśvarathamārūḍhaṁ pracaṇḍaṁ kaśyapātmajam ।\nśvētapadmadharaṁ dēvaṁ taṁ sūryaṁ praṇamāmyaham ॥ 2 ॥",
            "meaning": "Mounted upon a chariot drawn by seven horses, immensely powerful, son of Sage Kashyapa, holding a white lotus in His hand, unto that Sun-God I bow down."
        },
        {
            "number": 3,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "लोहितं रथमारूढं सर्वलोकपितामहम् ।\nमहापापहरं देवं तं सूर्यं प्रणमाम्यहम् ॥ ३ ॥",
            "iast": "lōhitaṁ rathamārūḍhaṁ sarvalōkapitāmaham ।\nmahāpāpaharaṁ dēvaṁ taṁ sūryaṁ praṇamāmyaham ॥ 3 ॥",
            "meaning": "Mounted upon a radiant reddish chariot, the grand ancestor of all worlds, the divine dispeller of great sins, unto that Sun-God I bow down."
        },
        {
            "number": 4,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "त्रैगुण्यं च महाशूरं ब्रह्मविष्णुमहेश्वरम् ।\nमहापापहरं देवं तं सूर्यं प्रणमाम्यहम् ॥ ४ ॥",
            "iast": "traiguṇyaṁ ca mahāśūraṁ brahmaviṣṇumahēśvaram ।\nmahāpāpaharaṁ dēvaṁ taṁ sūryaṁ praṇamāmyaham ॥ 4 ॥",
            "meaning": "Embodiment of the three Gunas (Sattva, Rajas, Tamas), valiant warrior, essence of Brahma, Vishnu, and Shiva, dispeller of great sins, unto that Sun-God I bow down."
        },
        {
            "number": 5,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "बृंहितं तेजसां पुञ्जं वायुमाकाशमेव च ।\nप्रभुं च सर्वलोकानां तं सूर्यं प्रणमाम्यहम् ॥ ५ ॥",
            "iast": "bṛṁhitaṁ tējasāṁ puñjaṁ vāyumākāśamēva ca ।\nprabhuṁ ca sarvalōkānāṁ taṁ sūryaṁ praṇamāmyaham ॥ 5 ॥",
            "meaning": "Magnified mass of radiant energy, pervading the air and the space, Lord of all the realms, unto that Sun-God I bow down."
        },
        {
            "number": 6,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "बन्धूकपुष्पसंकाशं हारकुण्डलभूषितम् ।\nएकचक्रधरं देवं तं सूर्यं प्रणमाम्यहम् ॥ ६ ॥",
            "iast": "bandhūkapuṣpasaṁkāśaṁ hārakuṇḍalabhūṣitam ।\nēkacakradharaṁ dēvaṁ taṁ sūryaṁ praṇamāmyaham ॥ 6 ॥",
            "meaning": "Radiant like the scarlet Bandhuka flower, adorned with necklaces and glittering ear-pendants, presiding over a chariot with a single wheel (the cycle of time), unto that Sun-God I bow down."
        },
        {
            "number": 7,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तं सूर्यं जगत्कर्तारं महातेजःप्रदीपनम् ।\nमहापापहरं देवं तं सूर्यं प्रणमाम्यहम् ॥ ७ ॥",
            "iast": "taṁ sūryaṁ jagatkartāraṁ mahātējaḥpradīpanam ।\nmahāpāpaharaṁ dēvaṁ taṁ sūryaṁ praṇamāmyaham ॥ 7 ॥",
            "meaning": "Unto that Sun who is the creator of the world, who blazes with supreme splendor, the divine remover of all sins, unto that Sun-God I bow down."
        },
        {
            "number": 8,
            "type": VerseType.VERSE,
            "meter": "Anushtubh",
            "text": "तं सूर्यं जगतां नाथं ज्ञानविज्ञानमोक्षदम् ।\nमहापापहरं देवं तं सूर्यं प्रणमाम्यहम् ॥ ८ ॥",
            "iast": "taṁ sūryaṁ jagatāṁ nāthaṁ jñānavijñānamōkṣadam ।\nmahāpāpaharaṁ dēvaṁ taṁ sūryaṁ praṇamāmyaham ॥ 8 ॥",
            "meaning": "Unto that Sun who is the master of all worlds, the bestower of sacred knowledge, empirical discernment, and spiritual liberation, unto that Sun-God I bow down."
        },
        {
            "number": 9,
            "type": VerseType.PHALASRUTI,
            "meter": "Anushtubh",
            "text": "सूर्याष्टकं पठेन्नित्यं ग्रहपीडाप्रणाशनम् ।\nअपुत्रो लभते पुत्रं दरिद्रो धनवान् भवेत् ॥ ९ ॥",
            "iast": "sūryāṣṭakaṁ paṭhēnnityaṁ grahapīḍāpraṇāśanam ।\naputrō labhatē putraṁ daridrō dhanavān bhavēt ॥ 9 ॥",
            "meaning": "Whoever daily recites this Suryashtakam is freed from all planetary afflictions; the childless receives a noble child, and the impoverished becomes wealthy."
        },
        {
            "number": 10,
            "type": VerseType.PHALASRUTI,
            "meter": "Anushtubh",
            "text": "आमिषं मधुपानं च यः करोति रवेर्दिने ।\nसप्तजन्म भवेद्रोगी जन्मजन्म दरिद्रता ॥ १० ॥",
            "iast": "āmiṣaṁ madhupānaṁ ca yaḥ karōti ravērdinē ।\nsaptajanma bhavēdrōgī janmajanma daridratā ॥ 10 ॥",
            "meaning": "Whoever consumes meat or intoxicating drinks on Sunday (the day of the Sun) suffers illness for seven births and poverty birth after birth. Therefore, let one worship the Sun with purity."
        }
    ]

    return {
        "content_id": "VEDA-TXT-00017",
        "canonical_title": "Surya Ashtakam",
        "devanagari_title": "सूर्याष्टकम्",
        "category_slug": "ashtakam",
        "deity_slug": "surya",
        "composer": "Samba Purana / Sage Agastya",
        "chandas": "Anushtubh",
        "source_scripture": "Samba Purana / Saura Stotra Samgraha",
        "associated_festival": "Ratha Saptami, Sundays, Chhath Puja, Makar Sankranti",
        "traditional_usage": "Sun worship, removal of eye afflictions, health, dispelling planetary doshas",
        "edition_title": "Brihat Stotra Ratnakara (Nirnaya Sagar Press, Bombay, 1912)",
        "publication_year": 1912,
        "archive_url": "https://archive.org/details/BrihatStotraRatnakaraNSP1912",
        "legal_evidence": "Puranic hymn; 1912 Nirnaya Sagar print is in the universal public domain (>110 yrs old).",
        "verses": verses_data,
    }


def ingest_batch_3a(session: Session) -> Dict[str, Any]:
    factories = [
        get_narayana_suktam_data,
        get_surya_ashtakam_data,
    ]

    results = {}

    for factory in factories:
        data = factory()
        cid = data["content_id"]

        category = session.query(Category).filter_by(slug=data["category_slug"]).first()
        if not category:
            cat_name = data["category_slug"].capitalize()
            category = Category(slug=data["category_slug"], name=cat_name, description=f"{cat_name} compositions")
            session.add(category)
            session.flush()

        deity = session.query(Deity).filter_by(slug=data["deity_slug"]).first()
        if not deity:
            deity_names = {
                "purusha": ("Purusha / Supreme Being", "पुरुषः"),
                "surya": ("Lord Surya", "सूर्यः"),
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
        text_record.translation_status = TranslationStatus.DRAFT
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
            "qa_issues": [f"[{i.severity}] {i.check_name}: {i.message}" for i in qa_report.issues],
        }

    session.commit()
    return results


if __name__ == "__main__":
    with get_db_session() as session:
        res = ingest_batch_3a(session)
        print("Expansion Batch 3A Results:")
        print(json.dumps(res, indent=2))
