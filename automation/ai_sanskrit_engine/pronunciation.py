"""
Vedic Heritage Platform — Pronunciation & Vedic Recension Chanting Engine
Generates recension-specific pronunciation guidance for Vedic Sanskrit, Classical Sanskrit,
and Awadhi without flattening sacred accents or conflating transliteration with audio instructions.
"""

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.pronunciation")


class PronunciationEngine:
    """Provides phonetic articulation guidance separated from script transliteration."""

    # Articulation Places (Uchharana Sthana) according to Paniniya Shiksha
    UCHHARANA_STHANA = {
        "कण्ठ्य (Velar / Guttural)": {"letters": "अ, आ, क, ख, ग, घ, ङ, ह, ः", "organ": "Throat / Soft palate"},
        "तालव्य (Palatal)": {"letters": "इ, ई, च, छ, ज, झ, ञ, य, श", "organ": "Hard palate"},
        "मूर्धन्य (Retroflex)": {"letters": "ऋ, ॠ, ट, ठ, ड, ढ, ण, र, ष", "organ": "Roof of mouth with tongue curled back"},
        "दन्त्य (Dental)": {"letters": "लृ, त, थ, द, ध, न, ल, स", "organ": "Upper teeth with tongue tip"},
        "ओष्ठ्य (Labial)": {"letters": "उ, ऊ, प, फ, ब, भ, म", "organ": "Lips"},
        "नासिक्य (Nasal)": {"letters": "ङ, ञ, ण, न, म, ं", "organ": "Nasal cavity"},
    }

    # Vedic Swara Tonal Markers
    VEDIC_SWARA_GUIDE = {
        "Udatta (उदात्तः)": {
            "sign": "Unmarked or high pitch",
            "technique": "Higher pitch / acute musical tone (उच्चैरुदात्तः - पाणिनी १.२.२९)",
            "chanting_instruction": "Raise the voice to the natural modal register without straining.",
        },
        "Anudatta (अनुदात्तः)": {
            "sign": "Horizontal underscore bar below (e.g., क॒, त॒)",
            "technique": "Lower pitch / grave musical tone (नीचैरनुदात्तः - पाणिनी १.२.३०)",
            "chanting_instruction": "Drop voice pitch precisely half a step below the base recitative tone.",
        },
        "Svarita (स्वरितः)": {
            "sign": "Vertical stroke above (e.g., क॑, त॑)",
            "technique": "Circumflex combination tone rising then falling (समाहारः स्वरितः - पाणिनी १.२.३१)",
            "chanting_instruction": "Initiate higher than base tone and glide gracefully to modal level.",
        },
    }

    @classmethod
    def generate_pronunciation_guide(
        cls,
        verse_text: str,
        iast_text: Optional[str] = None,
        language: str = "sa",
        is_vedic: bool = False,
        has_accents: bool = False,
        target_regional_script: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Generates comprehensive phonetic guidance for chanters and audio narrators."""

        if language == "awa":
            return cls._generate_awadhi_pronunciation(verse_text, iast_text)

        phonetic_cues: List[str] = []
        recension_notes = "Classical Paninian Sanskrit Pronunciation."

        if is_vedic:
            recension_notes = (
                "Vedic Chanting Pronunciation (Taittiriya / Rigvedic Shakha). "
                "Preserves exact Svarita (vertical stroke) and Anudatta (horizontal subscript) pitch modulations."
            )
            phonetic_cues.append("Pronounce Visarga followed by voiceless plosive as Jihvamuliya (before k/kh) or Upadhmaniya (before p/ph).")
            if has_accents:
                phonetic_cues.append("Strict tonal swara discipline: Anudatta (drop pitch), Udatta (base tone), Svarita (elevated gliding tone).")

        # Regional Script Guidance
        script_guidance = None
        if target_regional_script == "tamil":
            script_guidance = (
                "Tamil Reciters: Plosive distinctions (k1, k2, g3, gh4) are denoted using Grantha subscripts. "
                "Ensure aspirated and voiced consonants are articulated distinctly rather than assimilated into unvoiced base Tamil."
            )
        elif target_regional_script == "telugu":
            script_guidance = (
                "Telugu Reciters: Preserve full vowel elongation on final vowels and avoid adding implicit auxiliary epenthetic vowels to halant consonants."
            )

        return {
            "language": "Vedic Sanskrit" if is_vedic else "Classical Sanskrit",
            "recension_notes": recension_notes,
            "has_vedic_swara_accents": has_accents,
            "swara_rules": cls.VEDIC_SWARA_GUIDE if has_accents else None,
            "articulation_places": cls.UCHHARANA_STHANA,
            "phonetic_chanting_cues": phonetic_cues,
            "regional_script_guidance": script_guidance,
            "separation_guarantee": "Text transliteration, phonetic pronunciation, and audio manifests remain decoupled.",
        }

    @classmethod
    def _generate_awadhi_pronunciation(cls, verse_text: str, iast_text: Optional[str]) -> Dict[str, Any]:
        """Awadhi pronunciation rules for Hanuman Chalisa and Ramcharitmanas reciters."""
        return {
            "language": "Awadhi (Bhakti Vernacular)",
            "recension_notes": "Goswami Tulsidas Awadhi Chanting Tradition (Kashi / Ayodhya Sampradaya).",
            "has_vedic_swara_accents": False,
            "phonetic_chanting_cues": [
                "Awadhi 'v' is typically pronounced as soft bilabial 'b' in traditional folk recitation (e.g. vidya -> bidya).",
                "Dental 's' (स) is universal; retroflex 'sh' (ष) is often chanted gently as dental sibilant or kh in eastern tradition.",
                "Maintain rapid, energetic Chaupai rhythm with clean rhyming pauses at each 16-matra caesura (yati).",
                "Final vowels in Chaupais are held for exactly two counts (Guru) to preserve the melodic cadence."
            ],
            "regional_script_guidance": "Transliterated faithfully into regional scripts preserving Awadhi lexical integrity.",
            "separation_guarantee": "Decoupled from Sanskrit Paninian rules.",
        }
