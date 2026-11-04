"""
Vedic Heritage Platform — Sanskrit Terminology Glossary Engine
Part C.3: Common terminology database maintaining consistent liturgical, theological,
philosophical, and ritual terms across all target languages.

Categories:
1. Deity names
2. Vedic terminology
3. Ritual terminology
4. Philosophical concepts
5. Sanskrit grammatical terms
6. Mantra-specific terminology
7. Puja terminology
8. Traditional calendar terminology
"""

from dataclasses import dataclass, field
import enum
import json
import os
from typing import Any, Dict, List, Optional


class TerminologyCategory(str, enum.Enum):
    DEITY_NAMES = "DEITY_NAMES"
    VEDIC_TERMS = "VEDIC_TERMS"
    RITUAL_TERMS = "RITUAL_TERMS"
    PHILOSOPHICAL_CONCEPTS = "PHILOSOPHICAL_CONCEPTS"
    GRAMMATICAL_TERMS = "GRAMMATICAL_TERMS"
    MANTRA_TERMS = "MANTRA_TERMS"
    PUJA_TERMS = "PUJA_TERMS"
    CALENDAR_TERMS = "CALENDAR_TERMS"


@dataclass
class GlossaryTerm:
    term_id: str
    sanskrit_term: str          # Devanagari original (e.g. महालक्ष्म्यै, प्राणायामः, सङ्कल्पः)
    iast: str                   # Lossless Roman transliteration
    category: TerminologyCategory
    english_definition: str
    translations: Dict[str, str] = field(default_factory=dict)  # {"hi": "...", "te": "...", "ta": "...", "kn": "..."}
    regional_variants: Dict[str, List[str]] = field(default_factory=dict)
    notes: Optional[str] = None


class SanskritTerminologyGlossary:
    """Master repository of standardized multilingual spiritual terms."""

    CORE_TERMS: List[GlossaryTerm] = [
        # 1. Deity Names
        GlossaryTerm(
            term_id="TERM-DEI-001",
            sanskrit_term="गणेशः",
            iast="Gaṇēśaḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="Lord of the Ganas, remover of obstacles, first-worshipped deity.",
            translations={
                "hi": "गणेश",
                "te": "గణేశుడు / వినాయకుడు",
                "ta": "விநாயகர் / கணபதி",
                "kn": "ಗಣೇಶ / ವಿನಾಯಕ",
            },
            regional_variants={"ta": ["பிள்ளையார்", "கணபதி"], "te": ["విఘ్నేశ్వరుడు"]},
        ),
        GlossaryTerm(
            term_id="TERM-DEI-002",
            sanskrit_term="शिवः",
            iast="Śivaḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="The Auspicious One, the Supreme Lord of transformation and dissolution.",
            translations={
                "hi": "शिव / महादेव",
                "te": "శివుడు / మహేశ్వరుడు",
                "ta": "சிவன் / மகாதேவன்",
                "kn": "ಶಿವ / ಮಹಾದೇವ",
            },
            regional_variants={"ta": ["ஈசன்", "சிவபெருமான்"], "te": ["పరమేశ్వరుడు"]},
        ),
        GlossaryTerm(
            term_id="TERM-DEI-003",
            sanskrit_term="महालक्ष्मीः",
            iast="Mahālakṣmīḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="Supreme Goddess of spiritual and material abundance, consort of Vishnu.",
            translations={
                "hi": "महालक्ष्मी",
                "te": "మహాలక్ష్మి",
                "ta": "மகாலட்சுமி",
                "kn": "ಮಹಾಲಕ್ಷ್ಮಿ",
            },
            regional_variants={"ta": ["திருமகள்", "அலைமகள்"], "te": ["సిరి", "లక్ష్మీదేవి"]},
        ),
        GlossaryTerm(
            term_id="TERM-DEI-004",
            sanskrit_term="वेङ्कटेश्वरः",
            iast="Vēṅkaṭēśvaraḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="Lord of Venkatachala, destroyer of sins, presiding deity of Tirumala.",
            translations={
                "hi": "वेंकटेश्वर / बालाजी",
                "te": "వేంకటేశ్వరుడు / శ్రీనివాసుడు",
                "ta": "வேங்கடேஸ்வரர் / பாலாஜி",
                "kn": "ವೆಂಕಟೇಶ್ವರ / ಶ್ರೀನಿವಾಸ",
            },
            regional_variants={"te": ["ఏడుకొండలవాడు", "గోవిందుడు"], "ta": ["திருவேங்கடமுடையான்"]},
        ),
        # 2. Vedic Terminology
        GlossaryTerm(
            term_id="TERM-VED-001",
            sanskrit_term="ऋक्",
            iast="Ṛk",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Sacred verse or metrical hymn of the Rigveda.",
            translations={"hi": "ऋचा", "te": "ఋక్కు", "ta": "ருக்கு (வேத மந்திரம்)", "kn": "ಋಕ್ಕು"},
            notes="Fundamental metrical unit of the Rigveda.",
        ),
        GlossaryTerm(
            term_id="TERM-VED-002",
            sanskrit_term="उदात्तः",
            iast="Udāttaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="High-pitched musical tone in Vedic recitation.",
            translations={"hi": "उदात्त स्वर", "te": "ఉదాత్త స్వరము", "ta": "உதாத்த ஸ்வரம்", "kn": "ಉದಾತ್ತ ಸ್ವರ"},
        ),
        GlossaryTerm(
            term_id="TERM-VED-003",
            sanskrit_term="अनुदात्तः",
            iast="Anudāttaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Low pitch musical accent in Vedic recitation, marked with a lower horizontal bar.",
            translations={"hi": "अनुदात्त स्वर", "te": "అనుదాత్త స్వరము", "ta": "அனுதாத்த ஸ்வரம்", "kn": "ಅನುದಾತ್ತ ಸ್ವರ"},
        ),
        GlossaryTerm(
            term_id="TERM-VED-004",
            sanskrit_term="स्वरितः",
            iast="Svaritaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Circumflex or falling tone in Vedic recitation, marked with an upper vertical stroke.",
            translations={"hi": "स्वरित स्वर", "te": "స్వరిత స్వరము", "ta": "ஸ்வரித ஸ்வரம்", "kn": "ಸ್ವರಿತ ಸ್ವರ"},
        ),
        # 3. Ritual Terminology
        GlossaryTerm(
            term_id="TERM-RIT-001",
            sanskrit_term="सङ्कल्पः",
            iast="Saṅkalpaḥ",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Formal solemn vow or sacred intention declared at the commencement of any ritual.",
            translations={"hi": "संकल्प", "te": "సంకల్పము", "ta": "சங்கல்பம்", "kn": "ಸಂಕಲ್ಪ"},
        ),
        GlossaryTerm(
            term_id="TERM-RIT-002",
            sanskrit_term="प्राणायामः",
            iast="Prāṇāyāmaḥ",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Ritual breath regulation purifying the subtle vital energies before worship.",
            translations={"hi": "प्राणायाम", "te": "ప్రాణాయామము", "ta": "பிராணாயாமம்", "kn": "ಪ್ರಾಣಾಯಾಮ"},
        ),
        # 4. Philosophical Concepts
        GlossaryTerm(
            term_id="TERM-PHI-001",
            sanskrit_term="मोक्षः",
            iast="Mōkṣaḥ",
            category=TerminologyCategory.PHILOSOPHICAL_CONCEPTS,
            english_definition="Final spiritual liberation, freedom from the cycle of birth and death (Samsara).",
            translations={"hi": "मोक्ष", "te": "మోక్షము", "ta": "மோட்சம் / முக்தி", "kn": "ಮೋಕ್ಷ"},
        ),
        GlossaryTerm(
            term_id="TERM-PHI-002",
            sanskrit_term="धर्मः",
            iast="Dharmaḥ",
            category=TerminologyCategory.PHILOSOPHICAL_CONCEPTS,
            english_definition="Cosmic order, righteousness, moral duty, spiritual law.",
            translations={"hi": "धर्म", "te": "ధర్మము", "ta": "தர்மம் / அறம்", "kn": "ಧರ್ಮ"},
            regional_variants={"ta": ["அறம்"]},
        ),
        # 5. Grammatical Terms
        GlossaryTerm(
            term_id="TERM-GRA-001",
            sanskrit_term="पदच्छेदः",
            iast="Padacchēdaḥ",
            category=TerminologyCategory.GRAMMATICAL_TERMS,
            english_definition="Word-by-word separation resolving sandhi phonetic junctions in a verse.",
            translations={"hi": "पदच्छेद", "te": "పదచ్ఛేదము", "ta": "பதச்சேதம்", "kn": "ಪದಚ್ಛೇದ"},
        ),
        GlossaryTerm(
            term_id="TERM-GRA-002",
            sanskrit_term="अन्वयः",
            iast="Anvayaḥ",
            category=TerminologyCategory.GRAMMATICAL_TERMS,
            english_definition="Syntactical reordering of words in poetic verse into natural prose order.",
            translations={"hi": "अन्वय", "te": "అన్వయము", "ta": "அன்வயம்", "kn": "ಅನ್ವಯ"},
        ),
        # 6. Mantra Terms
        GlossaryTerm(
            term_id="TERM-MAN-001",
            sanskrit_term="बीजम्",
            iast="Bījam",
            category=TerminologyCategory.MANTRA_TERMS,
            english_definition="Seed syllable embodying the concentrated potency of a mantra.",
            translations={"hi": "बीज मंत्र", "te": "బీజాక్షరము", "ta": "பீஜாட்சரம்", "kn": "ಬೀಜಾಕ್ಷರ"},
        ),
        GlossaryTerm(
            term_id="TERM-MAN-002",
            sanskrit_term="विनियोगः",
            iast="Viniyōgaḥ",
            category=TerminologyCategory.MANTRA_TERMS,
            english_definition="Preliminary liturgical statement specifying the Rishi, Chandas, Devata, and purpose of a mantra.",
            translations={"hi": "विनियोग", "te": "వినియోగము", "ta": "வினியோகம்", "kn": "ವಿನಿಯೋಗ"},
        ),
        # 7. Puja Terms
        GlossaryTerm(
            term_id="TERM-PUJ-001",
            sanskrit_term="षोडशोपचारः",
            iast="Ṣōḍaśōpacāraḥ",
            category=TerminologyCategory.PUJA_TERMS,
            english_definition="The sixteen traditional reverential offerings presented to the deity.",
            translations={"hi": "षोडशोपचार पूजा", "te": "షోడశోపచార పూజ", "ta": "ஷோடசோபசார பூஜை", "kn": "ಷೋಡಶೋಪಚಾರ ಪೂಜೆ"},
        ),
        GlossaryTerm(
            term_id="TERM-PUJ-002",
            sanskrit_term="अभिषेकः",
            iast="Abhiṣēkaḥ",
            category=TerminologyCategory.PUJA_TERMS,
            english_definition="Sacred ceremonial bathing of the deity accompanied by Vedic chanting.",
            translations={"hi": "अभिषेक", "te": "అభిషేకము", "ta": "அபிஷேகம் / திருமுழுக்கு", "kn": "ಅಭಿಷೇಕ"},
        ),
        # 8. Calendar Terms
        GlossaryTerm(
            term_id="TERM-CAL-001",
            sanskrit_term="तिथिः",
            iast="Tithiḥ",
            category=TerminologyCategory.CALENDAR_TERMS,
            english_definition="Lunar day in the Vedic Panchanga, defined as a 12-degree elongation of the Moon from the Sun.",
            translations={"hi": "तिथि", "te": "తిథి", "ta": "திதி", "kn": "ತಿಥಿ"},
        ),
        GlossaryTerm(
            term_id="TERM-CAL-002",
            sanskrit_term="नक्षत्रम्",
            iast="Nakṣatram",
            category=TerminologyCategory.CALENDAR_TERMS,
            english_definition="One of the 27 lunar mansions traversing the ecliptic.",
            translations={"hi": "नक्षत्र", "te": "నక్షత్రము", "ta": "நட்சத்திரம்", "kn": "ನಕ್ಷತ್ರ"},
        ),
    ]

    @classmethod
    def get_all_terms(cls) -> List[GlossaryTerm]:
        return cls.CORE_TERMS

    @classmethod
    def find_term(cls, query: str) -> Optional[GlossaryTerm]:
        q = query.lower().strip()
        for t in cls.CORE_TERMS:
            if t.sanskrit_term == query or t.iast.lower() == q or t.term_id.lower() == q:
                return t
        return None

    @classmethod
    def get_terms_by_category(cls, category: TerminologyCategory) -> List[GlossaryTerm]:
        return [t for t in cls.CORE_TERMS if t.category == category]

    @classmethod
    def get_translation(cls, term_id: str, lang_code: str) -> Optional[str]:
        term = cls.find_term(term_id)
        if term:
            return term.translations.get(lang_code)
        return None
