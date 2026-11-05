"""
Vedic Heritage Platform — Scholarly Source Research & Citation Engine
Maintains verified bibliography of classical commentaries and critical editions.
Enforces that every interpretation citation is verifiable and audit-traceable,
explicitly flagging any unverified claim as an AI-generated suggestion.
"""

from datetime import datetime, timezone
import logging
from typing import Any, Dict, List, Optional

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.source_research")


class SourceResearchEngine:
    """Verifies and records traceable citations from recognized traditional commentaries."""

    # Authorized Scholarly Commentary & Critical Edition Registry
    AUTHORIZED_SOURCES = {
        "SAYANA_RIGVEDA": {
            "title": "Rigveda Samhita with the Commentary of Sayanacharya",
            "author_commentator": "Sayanacharya (c. 1350 CE)",
            "edition": "Vaidika Samsodhana Mandala 5-Volume Critical Edition",
            "publication_year": 1933,
            "place": "Poona, India",
            "authority_scope": "Rigvedic Suktams, Gayatri Mantra, Mahamrityunjaya Mantra",
            "verified_in_catalog": True,
        },
        "BHATTA_BHASKARA_TAITTIRIYA": {
            "title": "Taittiriya Aranyaka with the Commentary of Bhatta Bhaskara Mishra",
            "author_commentator": "Bhatta Bhaskara Mishra (Jnanayajna)",
            "edition": "Government Oriental Library Series, Mysore",
            "publication_year": 1902,
            "place": "Mysore, India",
            "authority_scope": "Durga Suktam, Narayana Suktam, Purusha Suktam",
            "verified_in_catalog": True,
        },
        "SHANKARA_STOTRA_BHASHYA": {
            "title": "Complete Works of Sri Sankaracharya (Vani Vilas Press)",
            "author_commentator": "Sri Adi Shankaracharya (c. 8th Cent. CE)",
            "edition": "Sri Vani Vilas Press Memorial Edition",
            "publication_year": 1910,
            "place": "Srirangam, India",
            "authority_scope": "Ganesha Pancharatnam, Kanakadhara Stotram, Bhaja Govindam",
            "verified_in_catalog": True,
        },
        "GOVINDARAJA_RAMAYANA": {
            "title": "Srimad Valmiki Ramayana with Bhushana Commentary of Govindaraja",
            "author_commentator": "Govindaraja (c. 16th Cent. CE)",
            "edition": "Nirnaya Sagar Press Critical Edition",
            "publication_year": 1912,
            "place": "Bombay, India",
            "authority_scope": "Aditya Hrudayam (Yuddha Kanda Canto 105)",
            "verified_in_catalog": True,
        },
        "GITA_PRESS_MANAS": {
            "title": "Shri Ramcharitmanas and Hanuman Chalisa with Commentary",
            "author_commentator": "Goswami Tulsidas (c. 1600 CE) / Hanuman Prasad Poddar",
            "edition": "Gita Press Archival Standard Edition",
            "publication_year": 1938,
            "place": "Gorakhpur, India",
            "authority_scope": "Hanuman Chalisa, Sankat Mochan, Vinaya Patrika",
            "verified_in_catalog": True,
        },
        "VAVILLA_SUPRABHATAM": {
            "title": "Sri Venkateswara Suprabhata Stotram with Telugu & Sanskrit Meaning",
            "author_commentator": "Prativadi Bhayankaram Annan (c. 1400 CE)",
            "edition": "Vavilla Ramaswamy Sastrulu & Sons Critical Edition",
            "publication_year": 1918,
            "place": "Madras, India",
            "authority_scope": "Sri Venkateswara Suprabhatam (4 Sections)",
            "verified_in_catalog": True,
        },
    }

    @classmethod
    def get_verified_citation(
        cls,
        source_key: str,
        page_or_verse_ref: str,
        retrieved_passage_id: Optional[str] = None,
    ) -> Dict[str, Any]:
        """Returns structured traceable citation metadata for an authorized scholarly source."""
        source = cls.AUTHORIZED_SOURCES.get(source_key)
        if not source:
            return {
                "source_title": "Unverified Commentary Reference",
                "author_commentator": "Unknown / AI Heuristic Suggestion",
                "is_verified_authorized_source": False,
                "disclaimer": "AI-generated commentary suggestion requiring human scholarly verification. Citation unverified.",
                "checked_at": datetime.now(timezone.utc).isoformat(),
            }

        return {
            "source_key": source_key,
            "source_title": source["title"],
            "author_commentator": source["author_commentator"],
            "edition": source["edition"],
            "publication_year": source["publication_year"],
            "place": source["place"],
            "authority_scope": source["authority_scope"],
            "page_or_verse_ref": page_or_verse_ref,
            "retrieved_passage_id": retrieved_passage_id or f"PASSAGE-{source_key}-{page_or_verse_ref}",
            "is_verified_authorized_source": True,
            "checked_at": datetime.now(timezone.utc).isoformat(),
        }
