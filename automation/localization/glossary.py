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
    is_human_reviewed: bool = True


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
                "mr": "गणेश / गणपती",
                "bn": "গণেশ / গণপতি",
                "gu": "ગણેશ / ગણપતિ",
                "ml": "ഗണേശൻ / ഗണപതി",
                "or": "ଗଣେଶ / ଗଣପତି",
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
                "mr": "शिव / महादेव",
                "bn": "শিব / মহাদেব",
                "gu": "શિવ / મહાદેવ",
                "ml": "ശിവൻ / മഹാദേവൻ",
                "or": "ଶିବ / ମହାଦେବ",
            },
            regional_variants={"ta": ["ஈசன்", "சிவபெருமான்"], "te": ["పరమేశ్వరుడు"], "mr": ["शंकर", "भोलेनाथ"]},
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
                "mr": "महालक्ष्मी",
                "bn": "মহালক্ষ্মী",
                "gu": "મહાલક્ષ્મી",
                "ml": "മഹാലക്ഷ്മി",
                "or": "ମହାଲକ୍ଷ୍ମୀ",
            },
            regional_variants={"ta": ["திருமகள்", "அலைமகள்"], "te": ["సిరి", "లక్ష్మీదేవి"], "mr": ["आई अंबाबाई"]},
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
                "mr": "व्यंकटेश / बालाजी",
                "bn": "ভেঙ্কটেশ্বর / বালাজী",
                "gu": "વેંકટેશ્વર / બાલાજી",
                "ml": "വെങ്കിടേശ്വരൻ / ബാലാജി",
                "or": "ଭେଙ୍କଟେଶ୍ୱର / ବାଲାଜୀ",
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
            translations={
                "hi": "ऋचा", "te": "ఋక్కు", "ta": "ருக்கு (வேத மந்திரம்)", "kn": "ಋಕ್ಕು",
                "mr": "ऋचा", "bn": "ঋক / ঋচা", "gu": "ઋચા", "ml": "ഋക്ക്", "or": "ଋକ୍ / ଋଚା"
            },
            notes="Fundamental metrical unit of the Rigveda.",
        ),
        GlossaryTerm(
            term_id="TERM-VED-002",
            sanskrit_term="उदात्तः",
            iast="Udāttaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="High-pitched musical tone in Vedic recitation.",
            translations={
                "hi": "उदात्त स्वर", "te": "ఉదాత్త స్వరము", "ta": "உதாத்த ஸ்வரம்", "kn": "ಉದಾತ್ತ ಸ್ವರ",
                "mr": "उदात्त स्वर", "bn": "উদাত্ত স্বর", "gu": "ઉદાત્ત સ્વર", "ml": "ഉദാത്ത സ്വരം", "or": "ଉଦାତ୍ତ ସ୍ୱର"
            },
        ),
        GlossaryTerm(
            term_id="TERM-VED-003",
            sanskrit_term="अनुदात्तः",
            iast="Anudāttaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Low pitch musical accent in Vedic recitation, marked with a lower horizontal bar.",
            translations={
                "hi": "अनुदात्त स्वर", "te": "అనుదాత్త స్వరము", "ta": "அனுதாத்த ஸ்வரம்", "kn": "ಅನುದಾತ್ತ ಸ್ವರ",
                "mr": "अनुदात्त स्वर", "bn": "অনুদাত্ত স্বর", "gu": "અનુદાત્ત સ્વર", "ml": "അനുദാത്ത സ്വരം", "or": "ଅନୁଦାତ୍ତ ସ୍ୱର"
            },
        ),
        GlossaryTerm(
            term_id="TERM-VED-004",
            sanskrit_term="स्वरितः",
            iast="Svaritaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Circumflex or falling tone in Vedic recitation, marked with an upper vertical stroke.",
            translations={
                "hi": "स्वरित स्वर", "te": "స్వరిత స్వరము", "ta": "ஸ்வரித ஸ்வரம்", "kn": "ಸ್ವರಿತ ಸ್ವರ",
                "mr": "स्वरित स्वर", "bn": "স্বরিত স্বর", "gu": "સ્વરિત સ્વર", "ml": "സ്వరిത സ്വരം", "or": "ସ୍ୱରିତ ସ୍ୱର"
            },
        ),
        # 3. Ritual Terminology
        GlossaryTerm(
            term_id="TERM-RIT-001",
            sanskrit_term="सङ्कल्पः",
            iast="Saṅkalpaḥ",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Formal solemn vow or sacred intention declared at the commencement of any ritual.",
            translations={
                "hi": "संकल्प", "te": "సంకల్పము", "ta": "சங்கல்பம்", "kn": "ಸಂಕಲ್ಪ",
                "mr": "संकल्प", "bn": "সংকল্প", "gu": "સંકલ્પ", "ml": "സങ്കല്പം", "or": "ସଂକଳ୍ପ"
            },
        ),
        GlossaryTerm(
            term_id="TERM-RIT-002",
            sanskrit_term="प्राणायामः",
            iast="Prāṇāyāmaḥ",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Ritual breath regulation purifying the subtle vital energies before worship.",
            translations={
                "hi": "प्राणायाम", "te": "ప్రాణాయామము", "ta": "பிராணாயாமம்", "kn": "ಪ್ರಾಣಾಯಾಮ",
                "mr": "प्राणायाम", "bn": "প্রাণায়াম", "gu": "પ્રાણાયામ", "ml": "പ്രാണായാമം", "or": "ପ୍ରାଣାୟାମ"
            },
        ),
        # 4. Philosophical Concepts
        GlossaryTerm(
            term_id="TERM-PHI-001",
            sanskrit_term="मोक्षः",
            iast="Mōkṣaḥ",
            category=TerminologyCategory.PHILOSOPHICAL_CONCEPTS,
            english_definition="Final spiritual liberation, freedom from the cycle of birth and death (Samsara).",
            translations={
                "hi": "मोक्ष", "te": "మోక్షము", "ta": "மோட்சம் / முக்தி", "kn": "ಮೋಕ್ಷ",
                "mr": "मोक्ष", "bn": "মোক্ষ / মুক্তি", "gu": "મોક્ષ", "ml": "മോക്ഷം / മുക്തി", "or": "ମୋକ୍ଷ / ମୁକ୍ତି"
            },
        ),
        GlossaryTerm(
            term_id="TERM-PHI-002",
            sanskrit_term="धर्मः",
            iast="Dharmaḥ",
            category=TerminologyCategory.PHILOSOPHICAL_CONCEPTS,
            english_definition="Cosmic order, righteousness, moral duty, spiritual law.",
            translations={
                "hi": "धर्म", "te": "ధర్మము", "ta": "தர்மம் / அறம்", "kn": "ಧರ್ಮ",
                "mr": "धर्म", "bn": "ধর্ম", "gu": "ધર્મ", "ml": "ധർമ്മം", "or": "ଧର୍ମ"
            },
            regional_variants={"ta": ["அறம்"]},
        ),
        # 5. Grammatical Terms
        GlossaryTerm(
            term_id="TERM-GRA-001",
            sanskrit_term="पदच्छेदः",
            iast="Padacchēdaḥ",
            category=TerminologyCategory.GRAMMATICAL_TERMS,
            english_definition="Word-by-word separation resolving sandhi phonetic junctions in a verse.",
            translations={
                "hi": "पदच्छेद", "te": "పదచ్ఛేదము", "ta": "பதச்சேதம்", "kn": "ಪದಚ್ಛೇದ",
                "mr": "पदच्छेद", "bn": "পদচ্ছেদ", "gu": "પદચ્છેદ", "ml": "പദച്ഛേദം", "or": "ପଦଚ୍ଛେଦ"
            },
        ),
        GlossaryTerm(
            term_id="TERM-GRA-002",
            sanskrit_term="अन्वयः",
            iast="Anvayaḥ",
            category=TerminologyCategory.GRAMMATICAL_TERMS,
            english_definition="Syntactical reordering of words in poetic verse into natural prose order.",
            translations={
                "hi": "अन्वय", "te": "అన్వయము", "ta": "அன்வயம்", "kn": "ಅನ್ವಯ",
                "mr": "अन्वय", "bn": "অন্বয়", "gu": "અન્વય", "ml": "അന്വയം", "or": "ଅନ୍ୱୟ"
            },
        ),
        # 6. Mantra Terms
        GlossaryTerm(
            term_id="TERM-MAN-001",
            sanskrit_term="बीजम्",
            iast="Bījam",
            category=TerminologyCategory.MANTRA_TERMS,
            english_definition="Seed syllable embodying the concentrated potency of a mantra.",
            translations={
                "hi": "बीज मंत्र", "te": "బీజాక్షరము", "ta": "பீஜாட்சரம்", "kn": "ಬೀಜಾಕ್ಷರ",
                "mr": "बीज / बीजाक्षर", "bn": "বীজ / বীজাক্ষর", "gu": "બીજ / બીજાક્ષર", "ml": "ബീജാക്ഷരം", "or": "ବୀଜ / ବୀଜାକ୍ଷର"
            },
        ),
        GlossaryTerm(
            term_id="TERM-MAN-002",
            sanskrit_term="विनियोगः",
            iast="Viniyōgaḥ",
            category=TerminologyCategory.MANTRA_TERMS,
            english_definition="Preliminary liturgical statement specifying the Rishi, Chandas, Devata, and purpose of a mantra.",
            translations={
                "hi": "विनियोग", "te": "వినియోగము", "ta": "வினியோகம்", "kn": "ವಿನಿಯೋಗ",
                "mr": "विनियोग", "bn": "বিনিয়োগ", "gu": "વિનિયોગ", "ml": "വിനിയോഗം", "or": "ବିନିଯୋଗ"
            },
        ),
        # 7. Puja Terms
        GlossaryTerm(
            term_id="TERM-PUJ-001",
            sanskrit_term="षोडशोपचारः",
            iast="Ṣōḍaśōpacāraḥ",
            category=TerminologyCategory.PUJA_TERMS,
            english_definition="The sixteen traditional reverential offerings presented to the deity.",
            translations={
                "hi": "षोडशोपचार पूजा", "te": "షోడశోపచార పూజ", "ta": "ஷோடசோபசார பூஜை", "kn": "ಷೋಡಶೋಪಚಾರ ಪೂಜೆ",
                "mr": "षोडशोपचार पूजा", "bn": "ষোড়শোপচার পূজা", "gu": "ષોડશોપચાર પૂજા", "ml": "ഷോഡശോപചാര പൂജ", "or": "ଷୋଡ଼ଶୋପଚାର ପୂଜା"
            },
        ),
        GlossaryTerm(
            term_id="TERM-PUJ-002",
            sanskrit_term="अभिषेकः",
            iast="Abhiṣēkaḥ",
            category=TerminologyCategory.PUJA_TERMS,
            english_definition="Sacred ceremonial bathing of the deity accompanied by Vedic chanting.",
            translations={
                "hi": "अभिषेक", "te": "అభిషేకము", "ta": "அபிஷேகம் / திருமுழுக்கு", "kn": "ಅಭಿಷೇಕ",
                "mr": "अभिषेक", "bn": "অভিষেক", "gu": "અભિષેક", "ml": "അഭിഷേകം", "or": "ଅଭିଷେକ"
            },
        ),
        # 8. Calendar Terms
        GlossaryTerm(
            term_id="TERM-CAL-001",
            sanskrit_term="तिथिः",
            iast="Tithiḥ",
            category=TerminologyCategory.CALENDAR_TERMS,
            english_definition="Lunar day in the Vedic Panchanga, defined as a 12-degree elongation of the Moon from the Sun.",
            translations={
                "hi": "तिथि", "te": "తిథి", "ta": "திதி", "kn": "ತಿಥಿ",
                "mr": "तिथी", "bn": "তিথি", "gu": "તિથિ", "ml": "തിഥി", "or": "ତିଥି"
            },
        ),
        GlossaryTerm(
            term_id="TERM-CAL-002",
            sanskrit_term="नक्षत्रम्",
            iast="Nakṣatram",
            category=TerminologyCategory.CALENDAR_TERMS,
            english_definition="One of the 27 lunar mansions traversing the ecliptic.",
            translations={
                "hi": "नक्षत्र", "te": "నక్షత్రము", "ta": "நட்சத்திரம்", "kn": "ನಕ್ಷತ್ರ",
                "mr": "नक्षत्र", "bn": "নক্ষত্র", "gu": "નક્ષત્ર", "ml": "നക്ഷത്രം", "or": "ନକ୍ଷତ୍ର"
            },
        ),
        # 9. Additional Canonical Spiritual Terms (Phase 6C Expansion)
        GlossaryTerm(
            term_id="TERM-DEI-005",
            sanskrit_term="श्रीकृष्णः",
            iast="Śrīkṛṣṇaḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="Supreme Lord of divine love, joy, and beauty; focal deity of Madhurashtakam.",
            translations={
                "hi": "श्रीकृष्ण / श्यामसुंदर", "te": "శ్రీకృష్ణుడు / వేణుగోపాలుడు", "ta": "ஸ்ரீகிருஷ்ணர் / கண்ணன்", "kn": "ಶ್ರೀಕೃಷ್ಣ / ಗೋಪಾಲ",
                "mr": "श्रीकृष्ण / कान्हा", "bn": "শ্রীকৃষ্ণ / কানহাইয়া", "gu": "શ્રીકૃષ્ણ / ઠાકોરજી", "ml": "ശ്രീകൃഷ്ണൻ / ഗുരുവായൂരപ്പൻ", "or": "ଶ୍ରୀକୃଷ୍ଣ / ଜଗନ୍ନାଥ"
            },
            regional_variants={"ta": ["கண்ணன்", "வேணுகோபாலன்"], "gu": ["શ્રીનાથજી", "રણછોડરાય"], "mr": ["विठ्ठल", "पंढरीनाथ"]},
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-VED-005",
            sanskrit_term="संहिता",
            iast="Saṁhitā",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Continuous metrical collection of sacred Vedic hymns and mantras.",
            translations={
                "hi": "संहिता", "te": "సంహిత", "ta": "சம்ஹிதை", "kn": "ಸಂಹಿತೆ",
                "mr": "संहिता", "bn": "সংহিতা", "gu": "સંહિતા", "ml": "സംഹിത", "or": "ସଂହିତା"
            },
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-RIT-003",
            sanskrit_term="आचमनम्",
            iast="Ācamanam",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Ritual sipping of sanctified water purifying internal body and mind before worship.",
            translations={
                "hi": "आचमन", "te": "ఆచమనము", "ta": "ஆசமனம்", "kn": "ಆಚಮನ",
                "mr": "आचमन", "bn": "আচমন", "gu": "આચમન", "ml": "ആചമനം", "or": "ଆଚମନ"
            },
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-PHI-003",
            sanskrit_term="भक्तिः",
            iast="Bhaktiḥ",
            category=TerminologyCategory.PHILOSOPHICAL_CONCEPTS,
            english_definition="Unconditional, loving devotional surrender to the Divine.",
            translations={
                "hi": "भक्ति", "te": "భక్తి", "ta": "பக்தி", "kn": "ಭಕ್ತಿ",
                "mr": "भक्ती", "bn": "ভক্তি", "gu": "ભક્તિ", "ml": "ഭക്തി", "or": "ଭକ୍ତି"
            },
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-GRA-003",
            sanskrit_term="समासः",
            iast="Samāsaḥ",
            category=TerminologyCategory.GRAMMATICAL_TERMS,
            english_definition="Sanskrit grammatical compound structure combining multiple stems.",
            translations={
                "hi": "समास", "te": "సమాసము", "ta": "சமாசம்", "kn": "ಸಮಾಸ",
                "mr": "समास", "bn": "সমাস", "gu": "સમાસ", "ml": "സമാസം", "or": "ସମାସ"
            },
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-MAN-003",
            sanskrit_term="गायत्री",
            iast="Gāyatrī",
            category=TerminologyCategory.MANTRA_TERMS,
            english_definition="The 24-syllable Vedic solar metre and supreme mantra revealed to Vishvamitra.",
            translations={
                "hi": "गायत्री", "te": "గాయత్రి", "ta": "காயத்ரி", "kn": "ಗಾಯತ್ರಿ",
                "mr": "गायत्री", "bn": "গায়ত্রী", "gu": "ગાયત્રી", "ml": "ഗായത്രി", "or": "ଗାୟତ୍ରୀ"
            },
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-PUJ-003",
            sanskrit_term="नीराजनम् / आरती",
            iast="Nīrājanam / Āratī",
            category=TerminologyCategory.PUJA_TERMS,
            english_definition="Ceremonial waving of lighted camphor lamp accompanied by devotional hymns.",
            translations={
                "hi": "आरती", "te": "హారతి / నీరాజనము", "ta": "தீபாராதனை / ஆரத்தி", "kn": "ಆರತಿ / ಮಂಗಳಾರತಿ",
                "mr": "आरती", "bn": "আরতি", "gu": "આરતી", "ml": "ദീപારાധന / ആരതി", "or": "ଆଳତି"
            },
            is_human_reviewed=True,
        ),
        GlossaryTerm(
            term_id="TERM-CAL-003",
            sanskrit_term="पक्षः",
            iast="Pakṣaḥ",
            category=TerminologyCategory.CALENDAR_TERMS,
            english_definition="Lunar fortnight in the Hindu calendar (Shukla Paksha or Krishna Paksha).",
            translations={
                "hi": "पक्ष (शुक्ल / कृष्ण)", "te": "పక్షము (శుక్ల / కృష్ణ)", "ta": "பட்சம் (சுக்ல / கிருஷ்ண)", "kn": "ಪಕ್ಷ (ಶುಕ್ಲ / ಕೃಷ್ಣ)",
                "mr": "पक्ष (शुक्ल / कृष्ण)", "bn": "পক্ষ (শুক্ল / কৃষ্ণ)", "gu": "પક્ષ (શુક્લ / કૃષ્ણ)", "ml": "പക്ഷം (ശുക്ല / കൃഷ്ണ)", "or": "ପକ୍ଷ (ଶୁକ୍ଳ / କୃଷ୍ଣ)"
            },
            is_human_reviewed=True,
        ),
        # ---------------------------------------------------------------------
        # Phase 6C Batch 2: Vedic Suktam Terminology
        # ---------------------------------------------------------------------
        GlossaryTerm(
            term_id="TERM-VED-006",
            sanskrit_term="पुरुषः",
            iast="Puruṣaḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Supreme Cosmic Person, the transcendent and immanent consciousness of Rigveda 10.90.",
            translations={
                "hi": "पुरुष (परम पुरुष / विराट पुरुष)",
                "te": "పురుషుడు (పరమపురుషుడు / విశ్వపురుషుడు)",
                "ta": "புருஷன் (ஆதி பரம புருஷன்)",
                "kn": "ಪುರುಷ (ಪರಮಪುರುಷ / ವಿರಾಟ್ ಪುರುಷ)",
                "mr": "पुरुष (परमपुरुष / विराट पुरुष)",
                "bn": "পুরুষ (পরমপুরুষ / বিরাট পুরুষ)",
                "gu": "પુરુષ (પરમપુરુષ / વિરાટ પુરુષ)",
                "ml": "പുരുഷൻ (പരമപുരുഷൻ / വിരാട് പുരുഷൻ)",
                "or": "ପୁରୁଷ (ପରମପୁରୁଷ / ବିରାଟ ପୁରୁଷ)",
            },
            notes="In Rigvedic cosmogony, Purusha transcends the manifest cosmos by ten fingers (atyatiṣṭhad daśāṅgulam).",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-007",
            sanskrit_term="नारायणः",
            iast="Nārāyaṇaḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="The Supreme Cosmic Refuge of all beings, identical with Parabrahman in Taittiriya Aranyaka.",
            translations={
                "hi": "नारायण (परब्रह्म स्वरूप)",
                "te": "నారాయణుడు (పరబ్రహ్మ స్వరూపుడు)",
                "ta": "நாராயணன் (பரப்பிரம்ம வடிவம்)",
                "kn": "ನಾರಾಯಣ (ಪರಬ್ರಹ್ಮ ಸ್ವರೂಪ)",
                "mr": "नारायण (परब्रह्म स्वरूप)",
                "bn": "নারায়ণ (পরব্রহ্ম স্বরূপ)",
                "gu": "નારાયણ (પરબ્રહ્મ સ્વરૂપ)",
                "ml": "നാരായണൻ (പരബ്രഹ്മ സ്വരൂപം)",
                "or": "ନାରାୟଣ (ପରବ୍ରହ୍ମ ସ୍ୱରୂପ)",
            },
            notes="Derived in Mahanarayana Upanishad: the eternal truth dwelling in the heart lotus (hṛdaya-kamala).",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-008",
            sanskrit_term="श्रीः",
            iast="Śrīḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="Divine Mother Lakshmi, personification of supreme spiritual splendour, sovereignty, prosperity, and divine grace.",
            translations={
                "hi": "श्री / महालक्ष्मी",
                "te": "శ్రీ / మహాలక్ష్మి",
                "ta": "ஸ்ரீ / திருமகள் (மகாலட்சுமி)",
                "kn": "ಶ್ರೀ / ಮಹಾಲಕ್ಷ್ಮಿ",
                "mr": "श्री / महालक्ष्मी",
                "bn": "শ্রী / মহালক্ষ্মী",
                "gu": "શ્રી / મહાલક્ષ્મી",
                "ml": "ശ്രീ / മഹാലക്ഷ്മി",
                "or": "ଶ୍ରୀ / ମହାଲକ୍ଷ୍ମୀ",
            },
            notes="In Sri Suktam, invoked as the golden-hued daughter of the ocean and consort of Vishnu.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-009",
            sanskrit_term="अग्निः",
            iast="Agniḥ",
            category=TerminologyCategory.DEITY_NAMES,
            english_definition="The primordial Vedic deity of sacred fire, priest of the sacrifice (Purohita), and mediator between mortals and devas.",
            translations={
                "hi": "अग्नि देव",
                "te": "అగ్ని దేవుడు",
                "ta": "அக்னி தேவன்",
                "kn": "ಅಗ್ನಿ ದೇವ",
                "mr": "अग्निदेव",
                "bn": "অগ্নিদেব",
                "gu": "અગ્નિદેવ",
                "ml": "അഗ്നിദേവൻ",
                "or": "ଅଗ୍ନିଦେବ",
            },
            notes="First word of Rigveda Samhita (Agnim īḷe purohitam); invoked in both Sri Suktam and Durga Suktam.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-010",
            sanskrit_term="जातवेदाः",
            iast="Jātavēdāḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Epithet of Agni signifying 'Knower of all created beings' (jātāni veda iti) or 'Possessor of all knowledge'.",
            translations={
                "hi": "जातवेदा (सर्वज्ञ अग्नि)",
                "te": "జాతవేదుడు (సర్వజ్ఞుడైన అగ్ని)",
                "ta": "ஜாதவேதாஸ் (சகலமும் அறிந்த அக்னி)",
                "kn": "ಜಾತವೇದ (ಸರ್ವಜ್ಞ ಅಗ್ನಿ)",
                "mr": "जातवेदा (सर्वज्ञ अग्नि)",
                "bn": "জাতবেদা (সর্বজ্ঞ অগ্নি)",
                "gu": "જાતવેદા (સર્વજ્ઞ અગ્નિ)",
                "ml": "ജാതവേദസ്സ് (സർവ്വജ്ഞനായ അഗ്നി)",
                "or": "ଜାତବେଦା (ସର୍ବଜ୍ଞ ଅଗ୍ନି)",
            },
            notes="Central address in Sri Suktam verse 1 and Durga Suktam verse 1.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-011",
            sanskrit_term="हिरण्यवर्णा",
            iast="Hiraṇyavarṇā",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Radiating golden or lustrous brilliance; the radiant divine effulgence of Goddess Sri.",
            translations={
                "hi": "हिरण्यवर्णा (स्वर्ण जैसी कान्ति वाली)",
                "te": "హిరణ్యవర్ణ (బంగారు వర్ణము గలది)",
                "ta": "ஹிரண்யவர்ணா (பொன்னிற மேனியள்)",
                "kn": "ಹಿರಣ್ಯವರ್ಣಾ (ಚಿನ್ನದ ಬಣ್ಣದವಳು)",
                "mr": "हिरण्यवर्णा (सुवर्णकांती असणारी)",
                "bn": "হিরণ্যবর্ণা (স্বর্ণের ন্যায় উজ্জ্বল কান্তিময়ী)",
                "gu": "હિરણ્યવર્ણા (સુવર્ણ જેવી તેજસ્વી કાંતિવાળી)",
                "ml": "ഹിരണ്യവർണ്ണ (സ്വർണ്ണവർണ്ണമുള്ളവൾ)",
                "or": "ହିରଣ୍ୟବର୍ଣ୍ଣା (ସୁବର୍ଣ୍ଣ ଭଳି ତେଜୋମୟୀ କାନ୍ତି ବିଶିଷ୍ଟ)",
            },
            notes="Opening word of Sri Suktam (hiraṇyavarṇāṁ hariṇīm).",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-012",
            sanskrit_term="भूमिः",
            iast="Bhūmiḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Mother Earth, the divine cosmic foundation, celebrated in the Atharvaveda Prithvi Sukta and Purusha Suktam.",
            translations={
                "hi": "भूमि (पृथ्वी माता)",
                "te": "భూమి (భూమాత)",
                "ta": "பூமி (பூமாதேவி)",
                "kn": "ಭೂಮಿ (ಭೂದೇವಿ)",
                "mr": "भूमी (धरती माता)",
                "bn": "ভূমি (ধরিত্রী মাতা)",
                "gu": "ભૂમિ (ધરતી માતા)",
                "ml": "ഭൂമി (ഭൂമീദേവി)",
                "or": "ଭୂମି (ଧରିତ୍ରୀ ମାତା)",
            },
            notes="Purusha Suktam verse 14: padbhyāṁ bhūmir diśaḥ śrotrāt.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-RIT-004",
            sanskrit_term="यज्ञः",
            iast="Yajñaḥ",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Sacred Vedic cosmic ritual, act of worship, and universal principle of selfless offering and cosmic reciprocity.",
            translations={
                "hi": "यज्ञ (हवन / अनुष्ठान)",
                "te": "యజ్ఞము (క్రతువు / హోమము)",
                "ta": "யாகம் / வேள்வி",
                "kn": "ಯಜ್ಞ (ಹೋಮ / ಕ್ರತು)",
                "mr": "यज्ञ (हवन / होम)",
                "bn": "যজ্ঞ (হোম / যাগ)",
                "gu": "યજ્ઞ (હવન / હોમ)",
                "ml": "യജ്ഞം (ഹോമം / യാഗം)",
                "or": "ଯଜ୍ଞ (ହୋମ / କ୍ରତୁ)",
            },
            notes="Purusha Suktam verse 16: yajñena yajñamayajanta devāḥ.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-013",
            sanskrit_term="ऋषिः",
            iast="Ṛṣiḥ",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="Vedic seer, sage of intuitive vision who 'saw' (drashtā) the eternal mantras rather than composing them.",
            translations={
                "hi": "ऋषि (मंत्रद्रष्टा)",
                "te": "ఋషి (మంత్రద్రష్ట)",
                "ta": "ரிஷி (மந்திரங்களை உணர்ந்த ஞானி)",
                "kn": "ಋಷಿ (ಮಂತ್ರದ್ರಷ್ಟಾರ)",
                "mr": "ऋषी (मंत्रद्रष्टा)",
                "bn": "ঋষি (মন্ত্রদ্রষ্টা)",
                "gu": "ઋષિ (મંત્રદ્રષ્ટા)",
                "ml": "ഋഷി (മന്ത്രദ്രഷ്ടാവ്)",
                "or": "ଋଷି (ମନ୍ତ୍ରଦ୍ରଷ୍ଟା)",
            },
            notes="Every Vedic Suktam has a presiding Rishi (e.g., Narayana for Purusha Suktam; Ananda-Kardama for Sri Suktam).",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-GRA-004",
            sanskrit_term="छन्दः",
            iast="Chandaḥ",
            category=TerminologyCategory.GRAMMATICAL_TERMS,
            english_definition="Vedic poetic metre governing the cadence of sacred recitation.",
            translations={
                "hi": "छन्द (वैदिक वृत्त)",
                "te": "ఛందస్సు (వైదిక వృత్తము)",
                "ta": "சந்தஸ் (வேத யாப்பு)",
                "kn": "ಛಂದಸ್ಸು (ವೈದಿಕ ಛಂದಸ್ಸು)",
                "mr": "छंद (वैदिक वृत्त)",
                "bn": "ছন্দ (বৈদিক ছন্দ)",
                "gu": "છંદ (વૈદિક છંદ)",
                "ml": "ഛന്ദസ്സ് (വൈദിക വൃത്തം)",
                "or": "ଛନ୍ଦ (ବୈଦିକ ବୃତ୍ତ)",
            },
            notes="From chad ('to cover, protect'); the protective matrix of the Vedic sound.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-VED-014",
            sanskrit_term="देवता",
            iast="Dēvatā",
            category=TerminologyCategory.VEDIC_TERMS,
            english_definition="The divine celestial aspect or conscious cosmic principle revealed and addressed in a Vedic hymn.",
            translations={
                "hi": "देवता (उपास्य देव)",
                "te": "దేవత (ఆరాధ్య దైవము)",
                "ta": "தேவதை / இறைவன்",
                "kn": "ದೇವತೆ (ಆರಾಧ್ಯ ದೈವ)",
                "mr": "देवता (आराध्य देव)",
                "bn": "দেবতা (উপাস্য দেব)",
                "gu": "દેવતા (ઉપાસ્ય દેવ)",
                "ml": "ദേവത (ആരാധ്യനായ ദൈവം)",
                "or": "ଦେବତା (ଉପାସ୍ୟ ଦେବ)",
            },
            notes="Essential triad of Vedic recitation: Rishi, Chhandas, and Devata.",
            is_human_reviewed=False,
        ),
        GlossaryTerm(
            term_id="TERM-RIT-005",
            sanskrit_term="हविः / आहुतिः",
            iast="Haviḥ / Āhutiḥ",
            category=TerminologyCategory.RITUAL_TERMS,
            english_definition="Sacred consecrated offering cast into the sacrificial fire for the satisfaction of the devas.",
            translations={
                "hi": "हविष्य / आहुति",
                "te": "హవిస్సు / ఆహుతి",
                "ta": "ஹவிஸ் / ஆகுதி",
                "kn": "ಹವಿಸ್ಸು / ಆಹುತಿ",
                "mr": "हविष्य / आहुती",
                "bn": "হব্য / আহুতি",
                "gu": "હવિષ્ય / આહુતિ",
                "ml": "ഹവിസ്സ് / ആഹൂതി",
                "or": "ହବିଷ୍ୟ / ଆହୁତି",
            },
            notes="Purusha Suktam verse 6: grīṣma idhmaḥ śaraddhaviḥ.",
            is_human_reviewed=False,
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
