"""
Vedic Heritage Platform — AI Sanskrit Intelligence Coordinator
Consolidates Padachheda, Anvaya, Grammar, Word Meaning, Chandas, Pronunciation,
and Source Citation into a unified pipeline with provenance tracking.
"""

from datetime import datetime, timezone
import hashlib
import json
import logging
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.ai_sanskrit_engine.anvaya import AnvayaEngine
from automation.ai_sanskrit_engine.chandas import ChandasEngine
from automation.ai_sanskrit_engine.grammar import GrammarEngine
from automation.ai_sanskrit_engine.padachheda import PadachhedaEngine
from automation.ai_sanskrit_engine.pronunciation import PronunciationEngine
from automation.ai_sanskrit_engine.provider import AIAnnotationResult, AIProvenanceRecorder
from automation.ai_sanskrit_engine.source_research import SourceResearchEngine
from automation.ai_sanskrit_engine.word_meaning import WordMeaningEngine
from database.models import (
    AIAnnotationProvenance,
    AIAnnotationType,
    Text,
    Verse,
)

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.coordinator")


class SanskritIntelligenceCoordinator:
    """Orchestrates comprehensive Sanskrit and Awadhi computational analysis."""

    @classmethod
    def analyze_verse_comprehensively(
        cls,
        session: Session,
        verse_id: str,
        record_provenance: bool = True,
    ) -> Dict[str, Any]:
        """Runs the complete suite of AI-assisted linguistic modules on a verse."""
        verse = session.query(Verse).filter_by(verse_id=verse_id).first()
        if not verse:
            raise ValueError(f"Verse '{verse_id}' not found.")

        text = verse.text
        is_vedic = bool(
            verse.vedic_accents_present or
            (text.primary_category and "suktam" in text.primary_category.slug.lower()) or
            "mantra" in text.primary_category.slug.lower()
        )
        is_awadhi = bool(text.original_language == "awa" or "chalisa" in text.canonical_title.lower())
        lang = "awa" if is_awadhi else "sa"

        verse_text = verse.devanagari_text or verse.raw_source_text or ""

        # 1. Padachheda
        padachheda_res = PadachhedaEngine.analyze_padachheda(
            verse_text=verse_text, language=lang, is_vedic=is_vedic
        )

        # 2. Anvaya
        anvaya_res = AnvayaEngine.reconstruct_anvaya(
            padas=padachheda_res["primary_padas"],
            verse_text=verse_text,
            language=lang,
            is_vedic=is_vedic,
        )

        # 3. Grammar (analyze first 5 padas)
        grammar_padas = [
            GrammarEngine.analyze_pada_grammar(pada, language=lang)
            for pada in padachheda_res["primary_padas"][:5]
        ]

        # 4. Word-by-word Meanings
        word_meanings = [
            WordMeaningEngine.get_word_analysis(pada, language=lang)
            for pada in padachheda_res["primary_padas"][:5]
        ]

        # 5. Chandas
        chandas_res = ChandasEngine.analyze_meter(
            verse_text=verse_text,
            language=lang,
            is_vedic=is_vedic,
            declared_meter=verse.meter,
        )

        # 6. Pronunciation Guide
        pronunciation_res = PronunciationEngine.generate_pronunciation_guide(
            verse_text=verse_text,
            iast_text=verse.iast_text,
            language=lang,
            is_vedic=is_vedic,
            has_accents=verse.vedic_accents_present,
        )

        # 7. Source Citations
        citation_key = "SAYANA_RIGVEDA" if is_vedic else ("GITA_PRESS_MANAS" if is_awadhi else "SHANKARA_STOTRA_BHASHYA")
        citation_res = SourceResearchEngine.get_verified_citation(
            source_key=citation_key,
            page_or_verse_ref=f"Verse {verse.verse_number}",
        )

        full_output = {
            "verse_id": verse.verse_id,
            "canonical_title": text.canonical_title,
            "verse_number": verse.verse_number,
            "language_mode": "Awadhi" if is_awadhi else ("Vedic Sanskrit" if is_vedic else "Classical Sanskrit"),
            "padachheda": padachheda_res,
            "anvaya": anvaya_res,
            "grammar_padas_sample": grammar_padas,
            "word_meanings_sample": word_meanings,
            "chandas": chandas_res,
            "pronunciation": pronunciation_res,
            "citation": citation_res,
            "governance_rule": "AI suggestions are unapproved drafts; Human Scholarly Review Mandatory.",
        }

        # 8. Record Provenance in Database if requested
        if record_provenance:
            prompt_hash = hashlib.sha256(verse_text.encode("utf-8")).hexdigest()[:16]
            res = AIAnnotationResult(
                annotation_type=AIAnnotationType.PADACHHEDA,
                provider_name="rule_based_panini_v1",
                model_version="vedam-ai-sanskrit-1.0",
                prompt_template_version="template_sanskrit_unified_v1",
                prompt_hash=prompt_hash,
                output_payload=full_output,
                confidence_score=0.92,
                estimated_cost_usd=0.0,
                is_suggestion_only=True,
            )
            AIProvenanceRecorder.record_suggestion(session, verse.id, res)

        return full_output
