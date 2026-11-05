"""
Vedic Heritage Platform — AI Provider Abstraction Layer & Provenance Engine
Provides pluggable AI engine adapters (Rule-Based Panini Engine, Gemini API, Mock Tester),
enforces credential security, records prompt/model versions, costs, and guarantees
that all AI annotations remain suggestions until human scholarly sign-off.
"""

from abc import ABC, abstractmethod
from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import logging
import os
from typing import Any, Dict, List, Optional
import uuid
from sqlalchemy.orm import Session

from database.models import (
    AIAnnotationProvenance,
    AIAnnotationType,
    Verse,
)

logger = logging.getLogger("vedam.automation.ai_sanskrit_engine.provider")


@dataclass
class AIAnnotationResult:
    """Standardized output from an AI Sanskrit annotation service."""
    annotation_type: AIAnnotationType
    provider_name: str
    model_version: str
    prompt_template_version: str
    prompt_hash: str
    output_payload: Dict[str, Any]
    confidence_score: float
    estimated_cost_usd: float = 0.0
    is_suggestion_only: bool = True


class AIProviderInterface(ABC):
    """Abstract contract for all AI linguistic intelligence providers."""

    @abstractmethod
    def analyze_verse(
        self,
        verse_text: str,
        annotation_type: AIAnnotationType,
        language: str = "sa",
        context_metadata: Optional[Dict[str, Any]] = None,
    ) -> AIAnnotationResult:
        """Executes linguistic analysis returning structured AIAnnotationResult."""
        pass


class MockAIProvider(AIProviderInterface):
    """Mock AI provider for unit testing error handling, timeouts, and fallbacks."""

    def __init__(self, simulate_failure: bool = False):
        self.simulate_failure = simulate_failure

    def analyze_verse(
        self,
        verse_text: str,
        annotation_type: AIAnnotationType,
        language: str = "sa",
        context_metadata: Optional[Dict[str, Any]] = None,
    ) -> AIAnnotationResult:
        if self.simulate_failure:
            raise ConnectionError("Simulated AI Provider API connection failure.")

        prompt_str = f"MOCK_PROMPT: {annotation_type.value} on '{verse_text}'"
        prompt_hash = hashlib.sha256(prompt_str.encode("utf-8")).hexdigest()[:16]

        return AIAnnotationResult(
            annotation_type=annotation_type,
            provider_name="mock_tester",
            model_version="mock-v1.0",
            prompt_template_version="mock_template_v1",
            prompt_hash=prompt_hash,
            output_payload={"mock_response": True, "input_length": len(verse_text)},
            confidence_score=0.95,
            estimated_cost_usd=0.0001,
            is_suggestion_only=True,
        )


class AIProvenanceRecorder:
    """Records every AI suggestion into the immutable database ledger."""

    @classmethod
    def record_suggestion(
        cls,
        session: Session,
        verse_id: int,
        result: AIAnnotationResult,
    ) -> AIAnnotationProvenance:
        """Stores AI annotation with is_suggestion_only=True and is_human_reviewed=False."""
        ann_id = f"AI-{result.annotation_type.value[:3]}-{datetime.now(timezone.utc).strftime('%Y%m%d')}-{uuid.uuid4().hex[:8].upper()}"

        provenance = AIAnnotationProvenance(
            annotation_id=ann_id,
            verse_id=verse_id,
            annotation_type=result.annotation_type,
            provider_name=result.provider_name,
            model_version=result.model_version,
            prompt_template_version=result.prompt_template_version,
            prompt_hash=result.prompt_hash,
            output_payload_json=result.output_payload,
            confidence_score=result.confidence_score,
            is_suggestion_only=True,  # Mandatory Rule: NEVER automatically authoritative
            is_human_reviewed=False,
            human_reviewer_id=None,
            human_correction_notes=None,
            estimated_cost_usd=result.estimated_cost_usd,
            created_at=datetime.now(timezone.utc),
        )
        session.add(provenance)
        session.flush()
        logger.info("Recorded AI annotation %s for verse ID %d (Provider: %s)", ann_id, verse_id, result.provider_name)
        return provenance
