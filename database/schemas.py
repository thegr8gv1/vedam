"""
Vedic Heritage Platform — Pydantic Validation Schemas (V2)
Provides rigorous validation for data ingestion, text preservation,
multilingual translations, and rights enforcement.
"""

from datetime import datetime
from typing import Any, Dict, List, Optional
import re

from pydantic import BaseModel, ConfigDict, Field, field_validator

from database.models import (
    AcquisitionTrack,
    DuplicateStatus,
    ReleaseStatus,
    ReviewStatus,
    TranslationType,
    VerseType,
    VersionType,
)


# ---------------------------------------------------------------------------
# Base Schema Configuration
# ---------------------------------------------------------------------------

class SchemaBase(BaseModel):
    model_config = ConfigDict(from_attributes=True, populate_by_name=True)


# ---------------------------------------------------------------------------
# Content Rights & Provenance Schemas
# ---------------------------------------------------------------------------

class ContentRightsBase(SchemaBase):
    original_composition_attribution: str = Field(..., min_length=2, description="Traditional author/Rishi/scripture")
    primary_source: str = Field(..., min_length=2, description="Physical or digital primary source")
    specific_edition: Optional[str] = Field(None, description="Specific printed or digital edition details")
    edition_publication_date: Optional[str] = Field(None, description="Year or publication date")
    transcription_contributor: Optional[str] = Field(None, description="Scholar or contributor who transcribed")
    source_url: Optional[str] = Field(None, description="Direct URL of the source")
    copyright_owner: Optional[str] = Field(None, description="Identified copyright holder, if any")
    license_type: str = Field(..., description="e.g., PUBLIC_DOMAIN, CC_BY_4_0, PROPRIETARY_AGREEMENT")
    license_url: Optional[str] = None
    commercial_reuse_permitted: bool = Field(False, description="Whether commercial republication is authorized")
    translation_permitted: bool = Field(False, description="Whether translations are authorized")
    derivative_work_permitted: bool = Field(False, description="Whether audio/video derivatives are authorized")
    distribution_permitted: bool = Field(False, description="Whether mobile/digital distribution is authorized")
    attribution_required: bool = True
    attribution_text: Optional[str] = None
    written_permission_reference: Optional[str] = None
    permission_expiry: Optional[datetime] = None
    supporting_evidence: Optional[str] = None
    release_status: ReleaseStatus = ReleaseStatus.AMBER


class ContentRightsCreate(ContentRightsBase):
    pass


class ContentRightsRead(ContentRightsBase):
    id: int
    text_id: int
    source_id: Optional[int] = None
    review_date: datetime


# ---------------------------------------------------------------------------
# Transliteration & Translation Schemas
# ---------------------------------------------------------------------------

class TransliterationCreate(SchemaBase):
    target_script: str = Field(..., min_length=2, description="e.g., telugu, tamil, kannada, iast")
    script_text: str = Field(..., min_length=1)
    is_lossless: bool = True
    engine_name: str = "indic-transliteration"


class TransliterationRead(TransliterationCreate):
    id: int
    verse_id: int


class TranslationCreate(SchemaBase):
    target_language: str = Field(..., min_length=2, max_length=16, description="ISO 639-1: en, hi, te, ta, kn")
    translation_type: TranslationType = TranslationType.BHAVARTHA
    translated_text: str = Field(..., min_length=1)
    word_by_word_json: Optional[List[Dict[str, Any]]] = None
    translator: Optional[str] = None
    reviewer: Optional[str] = None
    review_status: ReviewStatus = ReviewStatus.DRAFT


class TranslationRead(TranslationCreate):
    id: int
    verse_id: int
    created_at: datetime


# ---------------------------------------------------------------------------
# Verse Schemas
# ---------------------------------------------------------------------------

class VerseCreate(SchemaBase):
    verse_id: Optional[str] = None
    verse_number: int = Field(..., ge=1, description="Sequential verse number")
    verse_type: VerseType = VerseType.VERSE
    devanagari_text: str = Field(..., min_length=1)
    iast_text: Optional[str] = None
    vedic_accents_present: bool = False
    meter: Optional[str] = None
    notes: Optional[str] = None
    transliterations: List[TransliterationCreate] = Field(default_factory=list)
    translations: List[TranslationCreate] = Field(default_factory=list)


class VerseRead(SchemaBase):
    id: int
    text_id: int
    verse_id: str
    verse_number: int
    verse_type: VerseType
    devanagari_text: str
    iast_text: Optional[str] = None
    vedic_accents_present: bool
    meter: Optional[str] = None
    notes: Optional[str] = None
    transliterations: List[TransliterationRead] = Field(default_factory=list)
    translations: List[TranslationRead] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Text Version Schemas
# ---------------------------------------------------------------------------

class TextVersionCreate(SchemaBase):
    version_type: VersionType
    version_number: int = 1
    full_text: str = Field(..., min_length=1)
    notes: Optional[str] = None
    created_by: str = "system"


class TextVersionRead(TextVersionCreate):
    id: int
    text_id: int
    created_at: datetime


# ---------------------------------------------------------------------------
# Master Text Schemas
# ---------------------------------------------------------------------------

class TextCreate(SchemaBase):
    content_id: Optional[str] = Field(None, description="Canonical Content ID: e.g. VEDA-TXT-00001")
    canonical_title: str = Field(..., min_length=2, max_length=255)
    devanagari_title: str = Field(..., min_length=2, max_length=255)
    alternative_titles: List[str] = Field(default_factory=list)
    deity_slug: Optional[str] = None
    primary_category_slug: str = Field(..., min_length=2)
    secondary_category_slug: Optional[str] = None
    original_language: str = "sa"
    original_script: str = "Devanagari"
    composer: Optional[str] = None
    rishi: Optional[str] = None
    chandas: Optional[str] = None
    devata: Optional[str] = None
    source_scripture: Optional[str] = None
    associated_festival: Optional[str] = None
    traditional_usage: Optional[str] = None
    verses: List[VerseCreate] = Field(default_factory=list)
    rights: ContentRightsCreate

    @field_validator("content_id")
    @classmethod
    def validate_content_id(cls, v: Optional[str]) -> Optional[str]:
        if v and not re.match(r"^VEDA-TXT-\d{5}$", v):
            raise ValueError("content_id must match format 'VEDA-TXT-XXXXX' where X is a digit")
        return v


class TextRead(SchemaBase):
    id: int
    content_id: str
    uuid: str
    canonical_title: str
    devanagari_title: str
    alternative_titles: List[str] = Field(default_factory=list)
    original_language: str
    original_script: str
    composer: Optional[str] = None
    rishi: Optional[str] = None
    chandas: Optional[str] = None
    devata: Optional[str] = None
    source_scripture: Optional[str] = None
    associated_festival: Optional[str] = None
    traditional_usage: Optional[str] = None
    verse_count: int
    content_hash: str
    created_at: datetime
    updated_at: datetime
    rights: Optional[ContentRightsRead] = None
    verses: List[VerseRead] = Field(default_factory=list)


# ---------------------------------------------------------------------------
# Export Bundle Schema (JSON handoff format for Mobile App)
# ---------------------------------------------------------------------------

class MobileAppTextBundle(SchemaBase):
    """
    Standardized JSON export contract for the global mobile application.
    Enforces that unreleased texts (AMBER / RED) carry strict non-production flags.
    """
    content_id: str
    uuid: str
    title: Dict[str, str]  # {"canonical": "...", "devanagari": "...", "iast": "..."}
    category: str
    deity: Optional[str] = None
    metadata: Dict[str, Any]
    rights: Dict[str, Any]
    is_released_for_production: bool
    verses: List[Dict[str, Any]]
    chanting_presets: List[int] = [1, 3, 11, 21, 27, 54, 108]
    generated_at: datetime
