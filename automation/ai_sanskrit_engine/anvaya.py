"""
Vedic Heritage Platform — Sanskrit Anvaya (Prose Order) Engine
Reconstructs metrical verse syntax into logical prose order using both Dandanvaya
and Khandanvaya methodologies, supporting alternative valid word orders, contextual
syntactic dependencies, and uncertainty flags.
Original sacred verses are preserved unconditionally.
"""

import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.anvaya")


class AnvayaEngine:
    """Reconstructs Sanskrit and Awadhi poetic verse syntax into syntactical prose sequence."""

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
        "adhyahara": "Supplied / Implicit Word (अध्याहार)",
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
        Supports both Dandanvaya (syntactic prose flow) and Khandanvaya (interrogative inquiry).
        Does NOT force an artificial single universal word order; provides alternative valid constructions
        and explicitly signals grammatical ambiguities.
        """
        if not padas:
            padas = [w for w in verse_text.replace("।", "").replace("॥", "").split() if w]

        prose_units: List[Dict[str, Any]] = []
        uncertainty_flags: List[str] = []

        has_explicit_verb = False

        for idx, pada in enumerate(padas, start=1):
            role = "karta"
            confidence = 0.90
            ambiguity = None

            # Awadhi vernacular handling
            if language == "awa":
                if pada in ("राम", "हनुमान", "अंजनीपुत्र", "कपि", "नाथ", "प्रभु"):
                    role = "karta"
                elif pada in ("कीजै", "करहु", "पावै", "गावै", "होई", "सुनावै", "बन्दउँ"):
                    role = "kriya"
                    has_explicit_verb = True
                elif pada in ("चरण", "कमल", "कृपा", "बल", "बुद्धि", "विद्या", "सुजसु"):
                    role = "karma"
                elif pada in ("ते", "सें", "करि", "सों"):
                    role = "karana"
                elif pada in ("कूँ", "कहँ", "काज"):
                    role = "sampradana"
                elif pada in ("हि", "में", "माँह", "पर"):
                    role = "adhikarana"
                elif pada in ("के", "की", "का", "केर"):
                    role = "sambandha"
                else:
                    role = "karma"
            else:
                # Sanskrit classical & Vedic morphological heuristics
                if pada in ("भर्गः", "भर्गो", "मधुरम्", "मङ्गलम्", "सत्यम्"):
                    role = "karma"
                    ambiguity = "Neuter singular can syntactically serve as either Karta (Subject) or Karma (Object)."
                    uncertainty_flags.append(f"Pada '{pada}': ambiguous Karta/Karma in neuter gender.")
                elif pada.startswith(("हे", "भोः", "अये")):
                    role = "sambodhana"
                elif pada.endswith(("म्", "ं", "m")):
                        role = "karma"
                elif pada.endswith(("ना", "या", "ena", "ya", "भिः", "bhiḥ", "bhih")):
                    role = "karana"
                elif pada.endswith(("ाय", "aye", "aya", "भ्यः", "bhyaḥ", "bhya")):
                    role = "sampradana"
                elif pada.endswith(("ात्", "āt", "at", "भ्यः", "bhyaḥ")):
                    role = "apadana"
                elif pada.endswith(("स्य", "sya", "नाम्", "nām", "nam")):
                    role = "sambandha"
                elif pada.endswith(("े", "e", "isu", "ेषु", "eṣu", "au", "ौ")):
                    role = "adhikarana"
                elif pada.endswith(("ति", "न्ति", "te", "nti", "मः", "mah", "mahe", "महे", "धीमहि", "प्रचोदयात्", "तनोतु")):
                    role = "kriya"
                    has_explicit_verb = True
                elif pada in ("च", "तु", "अपि", "एव", "हि", "वै", "यथा", "तथा", "इति"):
                    role = "avyaya"

            prose_units.append({
                "original_position": idx,
                "pada": pada,
                "syntactic_role": role,
                "role_description": cls.SYNTACTIC_ROLES.get(role, "Syntactic Element"),
                "ambiguity_notes": ambiguity,
            })

        if not has_explicit_verb and language != "awa":
            uncertainty_flags.append("No overt conjugated finite verb detected; implicit copula (अध्याहार: 'अस्ति' / 'भवति' / 'वर्तते') supplied contextually.")

        # Primary Dandanvaya Ordering:
        # Sambodhana (1) -> Sambandha (2) -> Karta (3) -> Adhikarana (4) -> Karana (5) -> Sampradana (6) -> Karma (7) -> Avyaya (8) -> Kriya (9)
        role_order_dandanvaya = {
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
        primary_units = sorted(prose_units, key=lambda u: role_order_dandanvaya.get(u["syntactic_role"], 5))
        dandanvaya_prose = " ".join(u["pada"] for u in primary_units) + " ।"

        # Alternative Valid Construction (Topicalized Karma / Focus Construction):
        # Karma topicalization: Sambodhana -> Karma -> Karta -> Karana/Adhikarana -> Kriya
        role_order_topicalized = {
            "sambodhana": 1,
            "karma": 2,
            "sambandha": 3,
            "karta": 4,
            "adhikarana": 5,
            "karana": 6,
            "sampradana": 7,
            "avyaya": 8,
            "kriya": 9,
        }
        topicalized_units = sorted(prose_units, key=lambda u: role_order_topicalized.get(u["syntactic_role"], 5))
        topicalized_prose = " ".join(u["pada"] for u in topicalized_units) + " ।"

        # Khandanvaya (Interrogative Inquiry Framework)
        khandanvaya_steps = []
        verbs = [u for u in prose_units if u["syntactic_role"] == "kriya"]
        subjects = [u for u in prose_units if u["syntactic_role"] == "karta"]
        objects = [u for u in prose_units if u["syntactic_role"] == "karma"]
        instruments = [u for u in prose_units if u["syntactic_role"] == "karana"]

        if verbs:
            khandanvaya_steps.append(f"क्रियापदम् (What is the action?): '{verbs[0]['pada']}'")
        if subjects:
            khandanvaya_steps.append(f"कः/का/किम् (Who performs the action?): '{subjects[0]['pada']}'")
        if objects:
            khandanvaya_steps.append(f"कम/काम्/किम् (What is affected/sought?): '{objects[0]['pada']}'")
        if instruments:
            khandanvaya_steps.append(f"केन (By what means/instrument?): '{instruments[0]['pada']}'")

        return {
            "original_verse_immutable": verse_text.strip(),
            "proposed_prose_order": dandanvaya_prose,
            "dandanvaya": dandanvaya_prose,
            "topicalized_variant": topicalized_prose,
            "khandanvaya_inquiry": khandanvaya_steps,
            "alternative_anvayas": [
                {
                    "style": "Topicalized Focus (Karma-First Construction)",
                    "prose_text": topicalized_prose,
                    "grammatical_rationale": "In devotional stotras and Vedic mantras, the object of contemplation often precedes the agent.",
                }
            ],
            "ordered_padas": [u["pada"] for u in primary_units],
            "syntactic_dependencies": primary_units,
            "grammar_flow": " → ".join(u["syntactic_role"].capitalize() for u in primary_units),
            "uncertainty_flags": uncertainty_flags,
            "is_suggestion_only": True,
            "confidence": 0.92 if not uncertainty_flags else 0.82,
            "disclaimer": "AI-generated Anvaya rearrangement; multiple valid syntactic orders exist; original verse structure preserved unconditionally.",
        }
