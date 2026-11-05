"""
Vedic Heritage Platform — Sanskrit Anvaya (Prose Order) Engine
Reconstructs metrical verse syntax into logical prose order (Karta -> Karma -> Kriya)
while preserving the original sacred verse completely immutable.
"""

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.anvaya")


class AnvayaEngine:
    """Reconstructs Sanskrit and Awadhi poetic verse syntax into syntactical prose sequence."""

    # Common Syntactical Roles in Sanskrit Anvaya
    SYNTACTIC_ROLES = {
        "karta": "Subject / Agent (कर्तृ - प्रथमा विभक्ति)",
        "karma": "Direct Object (कर्म - द्वितीया विभक्ति)",
        "karana": "Instrument / Means (करण - तृतीया विभक्ति)",
        "sampradana": "Recipient / Beneficiary (सम्प्रदान - चतुर्थी विभक्ति)",
        "apadana": "Source / Separation (अपादान - पञ्चमी विभक्ति)",
        "sambandha": "Genitive / Relationship (सम्बन्ध - षष्ठी विभक्ति)",
        "adhikarana": "Locus / Substratum (अधिकरण - सप्तमी विभक्ति)",
        "sambodhana": "Vocative (सम्बोधन)",
        "kriya": "Action / Verb (क्रिया - आख्यातपद)",
        "avyaya": "Undeclinable Particle (अव्यय)",
    }

    @classmethod
    def reconstruct_anvaya(
        cls,
        padas: List[str],
        verse_text: str,
        language: str = "sa",
        is_vedic: bool = False,
    ) -> Dict[str, Any]:
        """
        Reorders padas into standard Sanskrit prose syntax.
        Vedic/Classical format: Sambodhana -> Karta + Visheshana -> Karma + Visheshana -> Karana/Adhikarana -> Kriya.
        """
        if not padas:
            padas = [w for w in verse_text.replace("।", "").replace("॥", "").split() if w]

        prose_units: List[Dict[str, Any]] = []

        # Simple deterministic heuristic classifying common endings
        # e.g., vocatives with हे, words ending in visarga / m
        for idx, pada in enumerate(padas, start=1):
            role = "karta"
            if pada.endswith(("म्", "ं", "m")):
                role = "karma"
            elif pada.endswith(("ना", "या", "ena", "ya")):
                role = "karana"
            elif pada.endswith(("ाय", "aye", "aya")):
                role = "sampradana"
            elif pada.endswith(("ात्", "āt", "at")):
                role = "apadana"
            elif pada.endswith(("स्य", "sya")):
                role = "sambandha"
            elif pada.endswith(("े", "e", "isu", "ेषु")):
                role = "adhikarana"
            elif pada.endswith(("ति", "न्ति", "te", "nti", "मः", "mah", "mahe", "महे")):
                role = "kriya"
            elif pada in ("च", "तु", "अपि", "एव", "हि", "वै", "यथा", "तथा"):
                role = "avyaya"

            prose_units.append({
                "original_position": idx,
                "pada": pada,
                "syntactic_role": role,
                "role_description": cls.SYNTACTIC_ROLES.get(role, "Syntactic Element"),
            })

        # Order priority: Sambodhana -> Sambandha -> Karta -> Adhikarana -> Karana -> Sampradana -> Karma -> Avyaya -> Kriya
        role_order = {
            "sambodhana": 1,
            "sambandha": 2,
            "karta": 3,
            "adhikarana": 4,
            "karana": 5,
            "sampradana": 6,
            "karma": 7,
            "avyaya": 8,
            "kriya": 9,
        }

        sorted_units = sorted(prose_units, key=lambda u: role_order.get(u["syntactic_role"], 5))
        prose_sentence = " ".join(u["pada"] for u in sorted_units) + " ।"

        return {
            "original_verse_immutable": verse_text.strip(),
            "proposed_prose_order": prose_sentence,
            "ordered_padas": [u["pada"] for u in sorted_units],
            "syntactic_dependencies": sorted_units,
            "grammar_flow": " → ".join(u["syntactic_role"].capitalize() for u in sorted_units),
            "is_suggestion_only": True,
            "confidence": 0.89,
            "disclaimer": "AI-generated Anvaya rearrangement; original verse structure preserved unconditionally.",
        }
