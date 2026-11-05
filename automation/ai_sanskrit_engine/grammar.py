"""
Vedic Heritage Platform — Sanskrit Grammar & Morphological Analysis Engine
Computes grammatical parsing: Vibhakti, Linga, Vacana, Purusha, Lakara, Dhatu,
Samasa classification, and links to classical Paninian Ashtadhyayi Sutras.
Also supports Awadhi non-Paninian grammatical parsing.
"""

import logging
import re
from typing import Any, Dict, List, Optional

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.grammar")


class GrammarEngine:
    """Provides morphological and syntactical analysis with classical grammatical references."""

    # Classical Paninian Sutra Reference Table
    PANINIAN_SUTRAS = {
        "prathama": ("प्रातिपदिकार्थ-लिङ्ग-परिमाण-वचनमात्रे प्रथमा (२.३.४६)", "Nominative case for basic stem meaning/gender/number"),
        "dvitiya": ("कर्मणि द्वितीया (२.३.२)", "Accusative case for direct object (Karma)"),
        "tritiya": ("कर्तृकरणयोस्तृतीया (२.३.१८)", "Instrumental case for agent or instrument"),
        "caturthi": ("चतुर्थी सम्प्रदाने (२.३.१३)", "Dative case for recipient/beneficiary"),
        "panchami": ("अपादाने पञ्चमी (२.३.२८)", "Ablative case for point of departure/separation"),
        "shashthi": ("षष्ठी शेषे (२.३.५०)", "Genitive case for relational connections"),
        "saptami": ("सप्तम्यधिकरणे च (२.३.३६)", "Locative case for spatial/temporal substratum"),
        "sambodhana": ("सम्बोधने च (२.३.४७)", "Vocative case for direct address"),
        "tatpurusha": ("तत्पुरुषः (२.१.२२)", "Determinative compound with dependent noun"),
        "bahuvrihi": ("शेषो बहुव्रीहिः (२.२.२३)", "Exocentric compound referring to external referent"),
        "dvandva": ("चार्थे द्वन्द्वः (२.२.२९)", "Copulative compound connected by 'and'"),
        "karmadharaya": ("तत्पुरुषः समानाधिकरणः कर्मधारयः (१.२.४२)", "Descriptive compound (noun + adjective)"),
    }

    # Awadhi Grammatical Affixes & Patterns
    AWADHI_GRAMMAR = {
        "verbal_past_yo": ("Past Tense (भूतकाल -यो प्रत्यय)", "e.g., भयो, कियो - indicative completed action"),
        "verbal_past_nh": ("Past Tense (भूतकाल -न्ह प्रत्यय)", "e.g., दीन्ह, लीन्ह - perfective action marker"),
        "case_ke": ("Genitive/Relation (सम्बन्ध कारक)", "e.g., राम के, कपीस के - equivalent to Sanskrit षष्ठी"),
        "case_te": ("Ablative/Instrumental (अपादान/करण)", "e.g., चरन ते, कृपा ते - origin or cause marker"),
    }

    @classmethod
    def analyze_pada_grammar(
        cls,
        pada: str,
        language: str = "sa",
        context: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Analyzes a single morphological pada and returns structured grammatical attributes."""
        clean_pada = pada.strip().replace("।", "").replace("॥", "")

        if language == "awa":
            return cls._analyze_awadhi_pada(clean_pada)

        # Sanskrit Grammatical Parsing Heuristic
        pos = "noun"
        vibhakti = "प्रथमा (Nominative)"
        linga = "पुंलिङ्ग (Masculine)"
        vacana = "एकवचन (Singular)"
        lakara = None
        dhatu = None
        samasa = None
        sutra_ref = cls.PANINIAN_SUTRAS["prathama"]

        # Verb Detection
        if clean_pada.endswith(("ति", "न्ति", "ते", "न्ते", "सि", "थ", "मि", "मः", "महे")):
            pos = "verb"
            vibhakti = None
            linga = None
            vacana = "एकवचन (Singular)" if clean_pada.endswith(("ति", "ते", "मि")) else "बहुवचन (Plural)"
            lakara = "लट् लकार (Present Indicative)"
            dhatu = "Identifiable verbal root"
            sutra_ref = ("वर्तमाने लट् (३.२.१२३)", "Present tense verbal affixation")

        # Noun Case Endings
        elif clean_pada.endswith(("म्", "ं")):
            vibhakti = "द्वितीया (Accusative)"
            vacana = "एकवचन (Singular)"
            sutra_ref = cls.PANINIAN_SUTRAS["dvitiya"]
        elif clean_pada.endswith(("ना", "या", "ेन", "ena")):
            vibhakti = "तृतीया (Instrumental)"
            sutra_ref = cls.PANINIAN_SUTRAS["tritiya"]
        elif clean_pada.endswith(("ाय", "ये", "aye")):
            vibhakti = "चतुर्थी (Dative)"
            sutra_ref = cls.PANINIAN_SUTRAS["caturthi"]
        elif clean_pada.endswith(("ात्", "āt")):
            vibhakti = "पञ्चमी (Ablative)"
            sutra_ref = cls.PANINIAN_SUTRAS["panchami"]
        elif clean_pada.endswith(("स्य", "योः", "sya")):
            vibhakti = "षष्ठी (Genitive)"
            sutra_ref = cls.PANINIAN_SUTRAS["shashthi"]
        elif clean_pada.endswith(("े", "षु", "isu")):
            vibhakti = "सप्तमी (Locative)"
            sutra_ref = cls.PANINIAN_SUTRAS["saptami"]
        elif clean_pada.startswith(("हे", "he")):
            vibhakti = "सम्बोधन (Vocative)"
            sutra_ref = cls.PANINIAN_SUTRAS["sambodhana"]

        # Samasa (Compound) Detection if contains hyphen or long compound length
        if "-" in clean_pada or len(clean_pada) > 12:
            samasa = {
                "type": "तत्पुरुष (Tatpurusha) or कर्मधारय (Karmadharaya)",
                "sutra": cls.PANINIAN_SUTRAS["tatpurusha"][0],
                "explanation": "Compound noun consisting of dependent qualifiers.",
            }

        return {
            "pada": clean_pada,
            "part_of_speech": pos,
            "vibhakti_case": vibhakti,
            "linga_gender": linga,
            "vacana_number": vacana,
            "lakara_tense": lakara,
            "dhatu_root": dhatu,
            "samasa_compound": samasa,
            "paninian_sutra_citation": sutra_ref[0],
            "grammatical_rule_meaning": sutra_ref[1],
            "is_human_confirmed": False,
            "disclaimer": "Computational grammatical suggestion; distinct from human-certified vyakarana analysis.",
        }

    @classmethod
    def _analyze_awadhi_pada(cls, pada: str) -> Dict[str, Any]:
        """Awadhi grammatical analysis for Hanuman Chalisa and Ramcharitmanas verses."""
        feature = "सामान्य संज्ञा या पद (General Noun/Word)"
        rule = "Eastern Hindi / Awadhi morphology"

        for suffix, (gram_type, desc) in cls.AWADHI_GRAMMAR.items():
            if pada.endswith(suffix.replace("verbal_past_", "").replace("case_", "")):
                feature = gram_type
                rule = desc
                break

        return {
            "pada": pada,
            "part_of_speech": "अवधी पद (Awadhi Morphological Unit)",
            "awadhi_grammatical_feature": feature,
            "rule_description": rule,
            "linguistic_recension": "Tulsidas Awadhi (c. 1600 CE)",
            "is_human_confirmed": False,
        }
