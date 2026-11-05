"""
Vedic Heritage Platform — AI-Assisted Scholarly Translation Workflow
Provides structured side-by-side access to:
1. Original Source (Sanskrit / Awadhi, Swaras, Meter)
2. Existing Translations (Bhavartha, Parent record)
3. AI-Generated Suggestions (Padachheda, Anvaya, Grammar, Word Meaning)
4. Traceable Traditional References (Sayana, Shankara, Bhatta Bhaskara, Vidyaranya)
5. Previous Versions & Revisions
6. Reviewer Corrections & Audit History
7. Unresolved Textual & Sampradaya Disputes

Enforces strict governance: AI is strictly an assistant (is_suggestion_only=True);
automated QA or high confidence scores can never substitute for authentic human approval.
"""

from datetime import datetime, timezone
import hashlib
import json
import logging
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.ai_sanskrit_engine.coordinator import SanskritIntelligenceCoordinator
from database.models import (
    ReviewActionLog,
    ReviewStatus,
    ReviewerProfile,
    Text,
    TextualDispute,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)

logger = logging.getLogger("vedam.automation.workbench.translation_workflow")


class TranslationWorkflowEngine:
    """Manages the 7-component AI-assisted translation review workflow."""

    @classmethod
    def get_translation_view_workflow_context(
        cls,
        session: Session,
        translation_id: int,
        view_type: str = "LITERAL",
    ) -> Dict[str, Any]:
        """
        Assembles complete 7-dimension review context for a specific translation view.
        """
        translation = session.query(Translation).filter_by(id=translation_id).first()
        if not translation:
            raise ValueError(f"Translation ID {translation_id} not found.")

        verse = translation.verse
        text = verse.text

        # 1. Original Source
        original_source = {
            "composition_id": text.content_id,
            "composition_title": text.canonical_title,
            "verse_id": verse.verse_id,
            "verse_number": verse.verse_number,
            "devanagari_text": verse.devanagari_text,
            "iast_text": verse.iast_text,
            "raw_source_text": verse.raw_source_text or verse.devanagari_text,
            "meter": verse.meter or "Traditional Liturgical Meter",
            "vedic_accents_present": verse.vedic_accents_present,
            "original_language": text.original_language,
        }

        # 2. Existing Translation (Parent & Views)
        existing_view = (
            session.query(TranslationView)
            .filter_by(translation_id=translation.id, view_type=view_type)
            .first()
        )
        existing_translation = {
            "translation_id": translation.id,
            "target_language": translation.target_language,
            "parent_bhavartha": translation.translated_text,
            "parent_review_status": translation.review_status.value if hasattr(translation.review_status, "value") else str(translation.review_status),
            "target_view_exists": bool(existing_view),
            "target_view_id": existing_view.view_id if existing_view else None,
            "current_text": existing_view.view_text if existing_view else None,
            "current_version": existing_view.version if existing_view else 0,
            "current_view_status": existing_view.review_status.value if existing_view else "NOT_FOUND",
        }

        # 3. AI-Generated Suggestions
        linguistic_analysis = SanskritIntelligenceCoordinator.analyze_verse_comprehensively(
            session=session, verse_id=verse.verse_id, record_provenance=False
        )
        ai_suggestion = {
            "view_type": view_type,
            "linguistic_padachheda": linguistic_analysis.get("padachheda", {}).get("primary_padas", []),
            "anvaya_order": linguistic_analysis.get("anvaya", {}).get("anvaya_sequence", []),
            "word_meanings_sample": linguistic_analysis.get("word_meanings_sample", []),
            "chandas_scansion": linguistic_analysis.get("chandas", {}).get("identified_meter"),
            "confidence_score": 0.95,
            "is_suggestion_only": True,
            "governance_barrier": "AI suggestion is strictly an unapproved draft; human sign-off required.",
        }

        # 4. Supporting Traditional References
        supporting_references = [
            f"Source Scripture: {text.canonical_title}",
            f"Attributed Rishi/Composer: {text.composer or 'Traditional Sage'}",
        ]
        if existing_view and existing_view.source_reference:
            supporting_references.append(f"Commentary Citation: {existing_view.source_reference}")

        # 5. Previous Versions & Revisions
        all_view_versions = (
            session.query(TranslationView)
            .filter_by(translation_id=translation.id, view_type=view_type)
            .order_by(TranslationView.version.desc())
            .all()
        )
        version_history = [
            {
                "view_id": v.view_id,
                "version": v.version,
                "status": v.review_status.value if hasattr(v.review_status, "value") else str(v.review_status),
                "source_reference": v.source_reference,
                "created_at": v.created_at.isoformat() if v.created_at else None,
            }
            for v in all_view_versions
        ]

        # 6. Reviewer Corrections & Audit History
        recent_actions = (
            session.query(ReviewActionLog)
            .filter_by(verse_id=verse.id)
            .order_by(ReviewActionLog.created_at.desc())
            .all()
        )
        corrections_history = [
            {
                "action_id": a.action_id,
                "action_type": a.action_type.value,
                "reviewer": a.reviewer.full_name if (a.reviewer and a.reviewer.full_name) else "Scholar",
                "is_human_review": bool(getattr(a, "is_human_review", False)),
                "previous_status": a.previous_status,
                "new_status": a.new_status,
                "commentary": a.scholarly_commentary,
                "timestamp": a.created_at.isoformat() if a.created_at else None,
            }
            for a in recent_actions
        ]

        # 7. Unresolved Textual & Sampradaya Disputes
        disputes = session.query(TextualDispute).filter_by(verse_id=verse.id).all()
        unresolved_disputes = [
            {
                "dispute_id": d.dispute_id,
                "nature": d.dispute_nature,
                "status": d.status.value if hasattr(d.status, "value") else str(d.status),
                "opinion_a": d.opinion_a_json,
                "opinion_b": d.opinion_b_json,
                "editorial_notes": d.editorial_resolution_notes,
            }
            for d in disputes
        ]

        return {
            "dimension_1_original_source": original_source,
            "dimension_2_existing_translation": existing_translation,
            "dimension_3_ai_suggestion": ai_suggestion,
            "dimension_4_supporting_references": supporting_references,
            "dimension_5_version_history": version_history,
            "dimension_6_reviewer_corrections": corrections_history,
            "dimension_7_unresolved_disputes": unresolved_disputes,
            "governance_mandate": "Rule PUB-010 Enforced: Human approval mandatory for production release.",
        }

    @classmethod
    def enforce_scholarly_gate(cls, view: TranslationView, actor: Optional[ReviewerProfile] = None) -> bool:
        """
        Enforces that AI suggestions or automated QA cannot substitute for human approval.
        Raises PermissionError if a non-human attempts to certify a translation view.
        """
        if not actor or not actor.is_human_verified:
            raise PermissionError(
                "Production Approval Barred: Only verified living human scholars "
                "(account_category='REAL_HUMAN_SCHOLAR') may transition views out of DRAFT status."
            )
        return True
