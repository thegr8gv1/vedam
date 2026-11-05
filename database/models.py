"""
Vedic Heritage Platform — SQLAlchemy 2.0 Relational Data Models (Enhanced)
Canonical representation of sacred texts, verses, translations, multi-script
transliterations, source editions, media assets, and the jurisdiction-aware
Content Rights & Provenance Engine.
"""

from datetime import datetime, timezone
import enum
from typing import List, Optional

from sqlalchemy import (
    Boolean,
    Column,
    DateTime,
    Enum,
    Float,
    ForeignKey,
    Integer,
    JSON,
    String,
    Table,
    Text as SA_Text,
    UniqueConstraint,
)
from sqlalchemy.orm import DeclarativeBase, Mapped, mapped_column, relationship

from automation.rights.approval_workflow import (
    AcquisitionStatus,
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from automation.rights.jurisdiction import IPLayerType, Jurisdiction, RightsReleaseStatus


class Base(DeclarativeBase):
    """Base class for all SQLAlchemy declarative models."""
    pass


# ---------------------------------------------------------------------------
# Enums
# ---------------------------------------------------------------------------

class AcquisitionTrack(str, enum.Enum):
    TRACK_A = "TRACK_A"  # Formal partnership & permission
    TRACK_B = "TRACK_B"  # Independently sourced public-domain edition


class ReleaseStatus(str, enum.Enum):
    GREEN = "GREEN"  # Approved for commercial publishing and platform release
    AMBER = "AMBER"  # Under review; additional permission/verification needed
    RED = "RED"      # Prohibited for commercial reuse; restricted or unverified


class VersionType(str, enum.Enum):
    RAW_EXTRACTED = "RAW_EXTRACTED"
    CLEANED = "CLEANED"
    VERIFIED_ORIGINAL = "VERIFIED_ORIGINAL"
    CHANTING_READY = "CHANTING_READY"
    SCHOLAR_CORRECTED = "SCHOLAR_CORRECTED"


class VerseType(str, enum.Enum):
    INVOCATION = "INVOCATION"
    VERSE = "VERSE"
    DOHA = "DOHA"
    CHAUPAI = "CHAUPAI"
    MANTRA = "MANTRA"
    PHALASRUTI = "PHALASRUTI"
    COLOPHON = "COLOPHON"


class TranslationType(str, enum.Enum):
    LITERAL = "LITERAL"
    BHAVARTHA = "BHAVARTHA"      # Devotional / interpretive meaning
    PADACHHEDA = "PADACHHEDA"    # Word-by-word grammatical dissection
    TATPARYA = "TATPARYA"        # Extended philosophical commentary
    CULTURAL_NOTES = "CULTURAL_NOTES"  # Traditional liturgical / cultural context notes


class ReviewStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    SCHOLAR_REVIEWED = "SCHOLAR_REVIEWED"
    APPROVED = "APPROVED"


class DuplicateStatus(str, enum.Enum):
    DETECTED = "DETECTED"
    RESOLVED_IDENTICAL = "RESOLVED_IDENTICAL"
    RESOLVED_VARIANT = "RESOLVED_VARIANT"
    RESOLVED_DISTINCT = "RESOLVED_DISTINCT"


class MediaType(str, enum.Enum):
    AUDIO_CHANT = "AUDIO_CHANT"          # Studio chanting recording
    AUDIO_JAPA_LOOP = "AUDIO_JAPA_LOOP"  # Repetition loop (108 counts)
    AUDIO_NARRATION = "AUDIO_NARRATION"  # Puja instruction narration
    VIDEO_LONG = "VIDEO_LONG"            # YouTube landscape video
    VIDEO_SHORT = "VIDEO_SHORT"          # YouTube Shorts / Reels (9:16)
    IMAGE_THUMBNAIL = "IMAGE_THUMBNAIL"  # Social thumbnail


class ReviewerRole(str, enum.Enum):
    SANSKRIT_TEXTUAL = "SANSKRIT_TEXTUAL"
    VEDIC_RECENSION = "VEDIC_RECENSION"
    HINDI_TRANSLATOR = "HINDI_TRANSLATOR"
    TELUGU_TRANSLATOR = "TELUGU_TRANSLATOR"
    TAMIL_TRANSLATOR = "TAMIL_TRANSLATOR"
    KANNADA_TRANSLATOR = "KANNADA_TRANSLATOR"
    MARATHI_TRANSLATOR = "MARATHI_TRANSLATOR"
    BENGALI_TRANSLATOR = "BENGALI_TRANSLATOR"
    GUJARATI_TRANSLATOR = "GUJARATI_TRANSLATOR"
    MALAYALAM_TRANSLATOR = "MALAYALAM_TRANSLATOR"
    ODIA_TRANSLATOR = "ODIA_TRANSLATOR"
    AWADHI_SPECIALIST = "AWADHI_SPECIALIST"
    SANSKRIT_GRAMMAR = "SANSKRIT_GRAMMAR"
    TRADITIONAL_COMMENTARY = "TRADITIONAL_COMMENTARY"
    LEGAL_COPYRIGHT = "LEGAL_COPYRIGHT"
    EDITORIAL_BOARD = "EDITORIAL_BOARD"


class AssignmentPriority(str, enum.Enum):
    LOW = "LOW"
    NORMAL = "NORMAL"
    HIGH = "HIGH"
    URGENT = "URGENT"


class AssignmentStatus(str, enum.Enum):
    PENDING = "PENDING"
    IN_PROGRESS = "IN_PROGRESS"
    COMPLETED = "COMPLETED"
    REASSIGNED = "REASSIGNED"
    DISPUTED = "DISPUTED"


class ReviewActionType(str, enum.Enum):
    APPROVE = "APPROVE"
    APPROVE_WITH_CORRECTIONS = "APPROVE_WITH_CORRECTIONS"
    REQUEST_REVISION = "REQUEST_REVISION"
    REJECT = "REJECT"
    FLAG_UNCERTAINTY = "FLAG_UNCERTAINTY"
    FLAG_TERMINOLOGY = "FLAG_TERMINOLOGY"
    FLAG_MISSING_SOURCE = "FLAG_MISSING_SOURCE"
    ESCALATE = "ESCALATE"


class DisputeStatus(str, enum.Enum):
    OPEN = "OPEN"
    UNDER_SECONDARY_REVIEW = "UNDER_SECONDARY_REVIEW"
    REFERRED_TO_EDITORIAL_BOARD = "REFERRED_TO_EDITORIAL_BOARD"
    RESOLVED_PRESERVED_BOTH = "RESOLVED_PRESERVED_BOTH"
    RESOLVED_CONSENSUS = "RESOLVED_CONSENSUS"


class AIAnnotationType(str, enum.Enum):
    PADACHHEDA = "PADACHHEDA"
    ANVAYA = "ANVAYA"
    GRAMMAR = "GRAMMAR"
    WORD_MEANING = "WORD_MEANING"
    CHANDAS = "CHANDAS"
    PRONUNCIATION = "PRONUNCIATION"
    SOURCE_CITATION = "SOURCE_CITATION"


class ReviewerVerificationStatus(str, enum.Enum):
    DEMO = "DEMO"
    PENDING_VERIFICATION = "PENDING_VERIFICATION"
    VERIFIED = "VERIFIED"
    REJECTED = "REJECTED"
    DEACTIVATED = "DEACTIVATED"


class ReviewerFeedbackCategory(str, enum.Enum):
    ORIGINAL_TEXT_CONCERN = "ORIGINAL_TEXT_CONCERN"
    SANSKRIT_GRAMMAR_ISSUE = "SANSKRIT_GRAMMAR_ISSUE"
    TRANSLITERATION_ISSUE = "TRANSLITERATION_ISSUE"
    INCORRECT_WORD_MEANING = "INCORRECT_WORD_MEANING"
    TRANSLATION_ISSUE = "TRANSLATION_ISSUE"
    TRADITIONAL_INTERPRETATION_ISSUE = "TRADITIONAL_INTERPRETATION_ISSUE"
    METER_ISSUE = "METER_ISSUE"
    PRONUNCIATION_ISSUE = "PRONUNCIATION_ISSUE"
    SOURCE_REFERENCE_CONCERN = "SOURCE_REFERENCE_CONCERN"
    ALTERNATIVE_RECENSION = "ALTERNATIVE_RECENSION"
    CULTURAL_DEVOTIONAL_NUANCE = "CULTURAL_DEVOTIONAL_NUANCE"


# ---------------------------------------------------------------------------
# Models
# ---------------------------------------------------------------------------

class Source(Base):
    """Catalog of platforms, libraries, publishers, and manuscript archives."""
    __tablename__ = "sources"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    source_code: Mapped[str] = mapped_column(String(32), unique=True, index=True)  # e.g., 'SRC-001'
    name: Mapped[str] = mapped_column(String(255))
    base_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    acquisition_track: Mapped[AcquisitionTrack] = mapped_column(Enum(AcquisitionTrack), default=AcquisitionTrack.TRACK_B)
    contact_email: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    terms_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    robots_policy: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    rights_records: Mapped[List["ContentRights"]] = relationship("ContentRights", back_populates="source")
    editions: Mapped[List["SourceEdition"]] = relationship("SourceEdition", back_populates="source")


class Contributor(Base):
    """Scholars, transcribers, reviewers, translators, and legal approvers."""
    __tablename__ = "contributors"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    name: Mapped[str] = mapped_column(String(128))
    role: Mapped[str] = mapped_column(String(64))  # 'SCHOLAR', 'TRANSCRIBER', 'LEGAL_REVIEWER', 'TRANSLATOR'
    affiliation: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    email: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


class SourceEdition(Base):
    """Specific historical or modern printed edition of a text."""
    __tablename__ = "source_editions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    source_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sources.id"), nullable=True)
    edition_title: Mapped[str] = mapped_column(String(255))
    publisher: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    editor_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    publication_year: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    publication_city: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    isbn_or_call_number: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    archive_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    is_primary_critical_edition: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="source_editions")
    source: Mapped[Optional["Source"]] = relationship("Source", back_populates="editions")


class Category(Base):
    """Hierarchical taxonomy for devotional text classification."""
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(128))
    description: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    parent_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("categories.id"), nullable=True)

    # Relationships
    parent: Mapped[Optional["Category"]] = relationship("Category", remote_side=[id], backref="subcategories")


class Deity(Base):
    """Deities, Avatars, Rishis, and traditional subjects of adoration."""
    __tablename__ = "deities"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    name: Mapped[str] = mapped_column(String(128))
    sanskrit_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    description: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)

    # Relationships
    texts: Mapped[List["Text"]] = relationship("Text", back_populates="deity")


class Text(Base):
    """
    Canonical Master Record for an individual sacred composition.
    Preserves raw source text, canonical scholarly text, titles, liturgical metadata, and relationships.
    """
    __tablename__ = "texts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    content_id: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    uuid: Mapped[str] = mapped_column(String(36), unique=True, index=True)
    canonical_title: Mapped[str] = mapped_column(String(255), index=True)
    devanagari_title: Mapped[str] = mapped_column(String(255))
    alternative_titles: Mapped[Optional[list]] = mapped_column(JSON, default=list)

    # Immutable Raw Ingestion Data
    raw_source_script: Mapped[Optional[str]] = mapped_column(String(32), default="Devanagari")
    raw_source_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    canonical_scholarly_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)

    # Taxonomy Links
    deity_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("deities.id"), nullable=True)
    primary_category_id: Mapped[int] = mapped_column(Integer, ForeignKey("categories.id"))
    secondary_category_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("categories.id"), nullable=True)

    # Traditional Attribution & Liturgical Context
    original_language: Mapped[str] = mapped_column(String(16), default="sa")
    original_script: Mapped[str] = mapped_column(String(32), default="Devanagari")
    composer: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    rishi: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    chandas: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    devata: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    source_scripture: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    associated_festival: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    traditional_usage: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Integrity & Counts
    verse_count: Mapped[int] = mapped_column(Integer, default=0)
    content_hash: Mapped[str] = mapped_column(String(64), index=True)

    # Multidimensional Approval Workflow (Independent Governance Dimensions)
    acquisition_status: Mapped[AcquisitionStatus] = mapped_column(
        Enum(AcquisitionStatus), default=AcquisitionStatus.VERIFIED_SOURCE
    )
    textual_verification_status: Mapped[TextualVerificationStatus] = mapped_column(
        Enum(TextualVerificationStatus), default=TextualVerificationStatus.UNVERIFIED
    )
    rights_clearance_status: Mapped[RightsClearanceStatus] = mapped_column(
        Enum(RightsClearanceStatus), default=RightsClearanceStatus.PENDING
    )
    translation_status: Mapped[TranslationStatus] = mapped_column(
        Enum(TranslationStatus), default=TranslationStatus.NOT_STARTED
    )
    editorial_approval_status: Mapped[EditorialApprovalStatus] = mapped_column(
        Enum(EditorialApprovalStatus), default=EditorialApprovalStatus.DRAFT
    )
    publication_status: Mapped[PublicationStatus] = mapped_column(
        Enum(PublicationStatus), default=PublicationStatus.DRAFT
    )

    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    deity: Mapped[Optional["Deity"]] = relationship("Deity", back_populates="texts")
    primary_category: Mapped["Category"] = relationship("Category", foreign_keys=[primary_category_id])
    secondary_category: Mapped[Optional["Category"]] = relationship("Category", foreign_keys=[secondary_category_id])
    source_editions: Mapped[List["SourceEdition"]] = relationship("SourceEdition", back_populates="text", cascade="all, delete-orphan")
    versions: Mapped[List["TextVersion"]] = relationship("TextVersion", back_populates="text", cascade="all, delete-orphan")
    verses: Mapped[List["Verse"]] = relationship("Verse", back_populates="text", cascade="all, delete-orphan", order_by="Verse.verse_number")
    rights: Mapped[Optional["ContentRights"]] = relationship("ContentRights", back_populates="text", uselist=False, cascade="all, delete-orphan")
    rights_grants: Mapped[List["RightsGrant"]] = relationship("RightsGrant", back_populates="text", cascade="all, delete-orphan")
    media_assets: Mapped[List["MediaAsset"]] = relationship("MediaAsset", back_populates="text", cascade="all, delete-orphan")
    audit_logs: Mapped[List["VerificationAuditLog"]] = relationship("VerificationAuditLog", back_populates="text", cascade="all, delete-orphan")


class TextVersion(Base):
    """Preserves raw, cleaned, verified original, and chanting versions."""
    __tablename__ = "text_versions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    version_type: Mapped[VersionType] = mapped_column(Enum(VersionType))
    version_number: Mapped[int] = mapped_column(Integer, default=1)
    full_text: Mapped[str] = mapped_column(SA_Text)
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    created_by: Mapped[Optional[str]] = mapped_column(String(128), default="system")
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="versions")


class Verse(Base):
    """Granular verse-level entity with swara markup and multi-script links."""
    __tablename__ = "verses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    verse_id: Mapped[str] = mapped_column(String(48), unique=True, index=True)
    verse_number: Mapped[int] = mapped_column(Integer, index=True)
    verse_type: Mapped[VerseType] = mapped_column(Enum(VerseType), default=VerseType.VERSE)
    
    # Textual Renderings
    raw_source_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    devanagari_text: Mapped[str] = mapped_column(SA_Text)
    iast_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    vedic_accents_present: Mapped[bool] = mapped_column(Boolean, default=False)
    vedic_accent_annotations: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    meter: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="verses")
    transliterations: Mapped[List["Transliteration"]] = relationship("Transliteration", back_populates="verse", cascade="all, delete-orphan")
    translations: Mapped[List["Translation"]] = relationship("Translation", back_populates="verse", cascade="all, delete-orphan")
    translation_views: Mapped[List["TranslationView"]] = relationship("TranslationView", back_populates="verse", cascade="all, delete-orphan")


class Transliteration(Base):
    """Lossless phonetic script projections across Indian scripts."""
    __tablename__ = "transliterations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id"), index=True)
    target_script: Mapped[str] = mapped_column(String(32), index=True)
    script_text: Mapped[str] = mapped_column(SA_Text)
    is_lossless: Mapped[bool] = mapped_column(Boolean, default=True)
    engine_name: Mapped[str] = mapped_column(String(64), default="indic-transliteration")

    # Relationships
    verse: Mapped["Verse"] = relationship("Verse", back_populates="transliterations")

    __table_args__ = (UniqueConstraint("verse_id", "target_script", name="uq_verse_script"),)


class Translation(Base):
    """Multilingual translations, word-by-word padachhedas, and commentaries."""
    __tablename__ = "translations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id"), index=True)
    target_language: Mapped[str] = mapped_column(String(16), index=True)
    translation_type: Mapped[TranslationType] = mapped_column(Enum(TranslationType), default=TranslationType.BHAVARTHA)
    translated_text: Mapped[str] = mapped_column(SA_Text)
    word_by_word_json: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    translator_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("contributors.id"), nullable=True)
    translator: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    reviewer_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("contributors.id"), nullable=True)
    reviewer: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    review_status: Mapped[ReviewStatus] = mapped_column(Enum(ReviewStatus), default=ReviewStatus.DRAFT)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    verse: Mapped["Verse"] = relationship("Verse", back_populates="translations")
    review_feedbacks: Mapped[List["TranslationReviewFeedback"]] = relationship("TranslationReviewFeedback", back_populates="translation", cascade="all, delete-orphan")
    views: Mapped[List["TranslationView"]] = relationship("TranslationView", back_populates="translation", cascade="all, delete-orphan")

    __table_args__ = (UniqueConstraint("verse_id", "target_language", "translation_type", name="uq_verse_lang_type"),)


class TranslationView(Base):
    """
    Granular, independently reviewable view of a verse translation.
    Supports distinct views: Literal (Word-by-word / Padachheda), Traditional Meaning (Tatparya),
    and Devotional Expression (Bhavartha), each with its own review lifecycle, translator provenance,
    and approval history.
    """
    __tablename__ = "translation_views"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    view_id: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    translation_id: Mapped[int] = mapped_column(Integer, ForeignKey("translations.id", ondelete="CASCADE"), index=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id", ondelete="CASCADE"), index=True)
    target_language: Mapped[str] = mapped_column(String(16), index=True)
    view_type: Mapped[TranslationType] = mapped_column(Enum(TranslationType), index=True)
    view_text: Mapped[str] = mapped_column(SA_Text)
    version: Mapped[int] = mapped_column(Integer, default=1)
    source_reference: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    translator_provenance: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    review_status: Mapped[ReviewStatus] = mapped_column(Enum(ReviewStatus), default=ReviewStatus.DRAFT, index=True)
    reviewer: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    reviewer_affiliation: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    reviewed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    approval_notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    approval_history_json: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    translation: Mapped["Translation"] = relationship("Translation", back_populates="views")
    verse: Mapped["Verse"] = relationship("Verse", back_populates="translation_views")

    __table_args__ = (
        UniqueConstraint("translation_id", "view_type", "version", name="uq_translation_view_type_version"),
    )


class TranslationReviewFeedback(Base):
    """Verse-level human scholarly and native-speaker review audit trails."""
    __tablename__ = "translation_review_feedbacks"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    translation_id: Mapped[int] = mapped_column(Integer, ForeignKey("translations.id", ondelete="CASCADE"), index=True)
    reviewer_name: Mapped[str] = mapped_column(String(128))
    reviewer_qualification: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    native_language: Mapped[str] = mapped_column(String(16))
    linguistic_expertise: Mapped[str] = mapped_column(String(64))  # e.g., "Sanskrit", "Awadhi", "Telugu"
    review_status: Mapped[ReviewStatus] = mapped_column(Enum(ReviewStatus), default=ReviewStatus.DRAFT)
    suggested_correction: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    scholarly_comment: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    terminology_adherence_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    reviewed_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    translation: Mapped["Translation"] = relationship("Translation", back_populates="review_feedbacks")


class ArchivedTranslation(Base):
    """Preserves historical or disconnected translation iterations with full forensic audit trail."""
    __tablename__ = "archived_translations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    original_translation_id: Mapped[int] = mapped_column(Integer)
    original_verse_id: Mapped[int] = mapped_column(Integer)
    target_language: Mapped[str] = mapped_column(String(16))
    translation_type: Mapped[str] = mapped_column(String(32))
    translated_text: Mapped[str] = mapped_column(SA_Text)
    translator: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    review_status: Mapped[str] = mapped_column(String(32))
    archived_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    archival_reason: Mapped[str] = mapped_column(String(255))



class ContentRights(Base):
    """
    Master Content Rights Record. Maintained for primary text-level clearance.
    Works in synergy with RightsGrant for layer-specific and jurisdiction-specific audits.
    """
    __tablename__ = "content_rights"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), unique=True, index=True)
    source_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sources.id"), nullable=True)

    # Attribution & Provenance
    original_composition_attribution: Mapped[str] = mapped_column(String(255))
    primary_source: Mapped[str] = mapped_column(String(255))
    specific_edition: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    edition_publication_date: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    transcription_contributor: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    source_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    copyright_owner: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # License & Permission Flags
    license_type: Mapped[str] = mapped_column(String(64))
    license_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    commercial_reuse_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    translation_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    derivative_work_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    distribution_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    attribution_required: Mapped[bool] = mapped_column(Boolean, default=True)
    attribution_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    written_permission_reference: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    permission_expiry: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    territory_restriction: Mapped[str] = mapped_column(String(64), default="GLOBAL")
    
    # Audit & Status
    review_date: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    legal_reviewer: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    is_legally_approved: Mapped[bool] = mapped_column(Boolean, default=False)
    supporting_evidence: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    release_status: Mapped[ReleaseStatus] = mapped_column(Enum(ReleaseStatus), default=ReleaseStatus.AMBER)

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="rights")
    source: Mapped[Optional["Source"]] = relationship("Source", back_populates="rights_records")


class RightsGrant(Base):
    """
    Granular, jurisdiction-specific and layer-specific rights grant.
    Enforces independent clearance for translations, editions, audio, and commentary.
    """
    __tablename__ = "rights_grants"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    ip_layer: Mapped[IPLayerType] = mapped_column(Enum(IPLayerType))
    jurisdiction: Mapped[Jurisdiction] = mapped_column(Enum(Jurisdiction), default=Jurisdiction.GLOBAL)
    license_type: Mapped[str] = mapped_column(String(64))
    commercial_reuse_authorized: Mapped[bool] = mapped_column(Boolean, default=False)
    contract_reference: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    contract_expiry: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    is_legally_approved: Mapped[bool] = mapped_column(Boolean, default=False)
    legal_reviewer: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    status: Mapped[RightsReleaseStatus] = mapped_column(Enum(RightsReleaseStatus), default=RightsReleaseStatus.AMBER)
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="rights_grants")


class MediaAsset(Base):
    """Audio recordings, Japa counting audio, videos, and visual graphics."""
    __tablename__ = "media_assets"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    media_type: Mapped[MediaType] = mapped_column(Enum(MediaType))
    title: Mapped[str] = mapped_column(String(255))
    file_path: Mapped[str] = mapped_column(String(512))
    duration_seconds: Mapped[Optional[float]] = mapped_column(Float, nullable=True)
    repetition_count: Mapped[Optional[int]] = mapped_column(Integer, default=1)
    license_type: Mapped[str] = mapped_column(String(64), default="ORIGINAL_PLATFORM_PRODUCTION")
    performer_artist: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    commercial_release_cleared: Mapped[bool] = mapped_column(Boolean, default=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="media_assets")


class VerificationAuditLog(Base):
    """Auditing trail for text modifications, rights reviews, and scholar approvals."""
    __tablename__ = "verification_audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    action: Mapped[str] = mapped_column(String(64))
    previous_value: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    new_value: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    performed_by: Mapped[str] = mapped_column(String(128))
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    timestamp: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="audit_logs")


class DuplicateCandidate(Base):
    """Candidate duplicate records identified by hash or fuzzy phonetic matching."""
    __tablename__ = "duplicate_candidates"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id_a: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"))
    text_id_b: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"))
    similarity_score: Mapped[float] = mapped_column(Float)
    comparison_method: Mapped[str] = mapped_column(String(64))
    status: Mapped[DuplicateStatus] = mapped_column(Enum(DuplicateStatus), default=DuplicateStatus.DETECTED)
    resolved_by: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))


# ---------------------------------------------------------------------------
# Phase 7: Scholarly Review Workbench & AI Intelligence Models
# ---------------------------------------------------------------------------

class ReviewerProfile(Base):
    """
    Verified scholar and translator profiles with role definitions,
    language proficiencies, and verification credentials.
    """
    __tablename__ = "reviewer_profiles"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    reviewer_id: Mapped[str] = mapped_column(String(32), unique=True, index=True)
    full_name: Mapped[str] = mapped_column(String(128))
    email: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    primary_role: Mapped[ReviewerRole] = mapped_column(Enum(ReviewerRole), index=True)
    secondary_roles: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    areas_of_expertise: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    language_proficiency: Mapped[Optional[dict]] = mapped_column(JSON, nullable=True)
    sanskrit_proficiency: Mapped[str] = mapped_column(String(64), default="Vidwan")
    vedic_specialization: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    academic_qualifications: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    institutional_affiliation: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_credentials_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verification_method: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    verification_date: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    permissions: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    is_active: Mapped[bool] = mapped_column(Boolean, default=True)

    # Phase 8: Authentication, Security & Onboarding Status
    password_hash: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    is_demonstration: Mapped[bool] = mapped_column(Boolean, default=False)
    verification_status: Mapped[str] = mapped_column(String(32), default="PENDING_VERIFICATION")
    verified_by_admin: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    verification_notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    last_login_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    failed_login_attempts: Mapped[int] = mapped_column(Integer, default=0)
    is_locked: Mapped[bool] = mapped_column(Boolean, default=False)

    # Phase 9: Authentic Human Scholar Verification
    account_category: Mapped[str] = mapped_column(String(50), default="SYNTHETIC_TEST_PERSONA")
    is_human_verified: Mapped[bool] = mapped_column(Boolean, default=False)
    verification_doc_hash: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    verification_authority: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    assignments: Mapped[List["ReviewAssignment"]] = relationship("ReviewAssignment", foreign_keys="ReviewAssignment.reviewer_id", back_populates="reviewer")
    actions: Mapped[List["ReviewActionLog"]] = relationship("ReviewActionLog", back_populates="reviewer")
    reviewed_annotations: Mapped[List["AIAnnotationProvenance"]] = relationship("AIAnnotationProvenance", back_populates="human_reviewer")
    sessions: Mapped[List["ReviewerSession"]] = relationship("ReviewerSession", back_populates="reviewer")


class ReviewAssignment(Base):
    """
    Granular task assignment dispatching compositions, verses, and views
    to qualified scholars with priority and deadline tracking.
    """
    __tablename__ = "review_assignments"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    assignment_id: Mapped[str] = mapped_column(String(48), unique=True, index=True)
    reviewer_id: Mapped[int] = mapped_column(Integer, ForeignKey("reviewer_profiles.id"), index=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    verse_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("verses.id"), nullable=True, index=True)
    target_language: Mapped[str] = mapped_column(String(16), index=True)
    view_type: Mapped[Optional[TranslationType]] = mapped_column(Enum(TranslationType), nullable=True)
    priority: Mapped[AssignmentPriority] = mapped_column(Enum(AssignmentPriority), default=AssignmentPriority.NORMAL)
    status: Mapped[AssignmentStatus] = mapped_column(Enum(AssignmentStatus), default=AssignmentStatus.PENDING, index=True)
    deadline: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    assigned_by: Mapped[str] = mapped_column(String(128), default="system_admin")
    assigned_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    completed_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    reassigned_to_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("reviewer_profiles.id"), nullable=True)

    # Relationships
    reviewer: Mapped["ReviewerProfile"] = relationship("ReviewerProfile", foreign_keys=[reviewer_id], back_populates="assignments")
    reassigned_to: Mapped[Optional["ReviewerProfile"]] = relationship("ReviewerProfile", foreign_keys=[reassigned_to_id])
    text: Mapped["Text"] = relationship("Text")
    verse: Mapped[Optional["Verse"]] = relationship("Verse")


class ReviewActionLog(Base):
    """
    Immutable ledger of every scholarly review action, correction proposal,
    and status transition with complete rationale and citations.
    """
    __tablename__ = "review_action_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    action_id: Mapped[str] = mapped_column(String(48), unique=True, index=True)
    assignment_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("review_assignments.id"), nullable=True, index=True)
    translation_id: Mapped[int] = mapped_column(Integer, ForeignKey("translations.id"), index=True)
    translation_view_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("translation_views.id"), nullable=True, index=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id"), index=True)
    reviewer_id: Mapped[int] = mapped_column(Integer, ForeignKey("reviewer_profiles.id"), index=True)
    action_type: Mapped[ReviewActionType] = mapped_column(Enum(ReviewActionType), index=True)
    previous_status: Mapped[str] = mapped_column(String(32))
    new_status: Mapped[str] = mapped_column(String(32))
    previous_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    proposed_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    scholarly_commentary: Mapped[str] = mapped_column(SA_Text)
    feedback_category: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    traditional_references: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    alternative_readings: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)
    original_text_immutable_verified: Mapped[bool] = mapped_column(Boolean, default=True)
    is_human_review: Mapped[bool] = mapped_column(Boolean, default=False)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    reviewer: Mapped["ReviewerProfile"] = relationship("ReviewerProfile", back_populates="actions")
    assignment: Mapped[Optional["ReviewAssignment"]] = relationship("ReviewAssignment")
    translation: Mapped["Translation"] = relationship("Translation")
    translation_view: Mapped[Optional["TranslationView"]] = relationship("TranslationView")
    verse: Mapped["Verse"] = relationship("Verse")


class TextualDispute(Base):
    """
    Tracks scholarly disagreements, preserving both traditional interpretations
    with citations until consensus or editorial board adjudication.
    """
    __tablename__ = "textual_disputes"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    dispute_id: Mapped[str] = mapped_column(String(48), unique=True, index=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id"), index=True)
    translation_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("translations.id"), nullable=True, index=True)
    translation_view_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("translation_views.id"), nullable=True, index=True)
    dispute_nature: Mapped[str] = mapped_column(String(128))
    opinion_a_json: Mapped[dict] = mapped_column(JSON)
    opinion_b_json: Mapped[dict] = mapped_column(JSON)
    status: Mapped[DisputeStatus] = mapped_column(Enum(DisputeStatus), default=DisputeStatus.OPEN, index=True)
    editorial_resolution_notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    resolved_by: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    resolved_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    verse: Mapped["Verse"] = relationship("Verse")
    translation: Mapped[Optional["Translation"]] = relationship("Translation")
    translation_view: Mapped[Optional["TranslationView"]] = relationship("TranslationView")


class AIAnnotationProvenance(Base):
    """
    Tracks provenance of AI-generated Sanskrit linguistic suggestions
    (Padachheda, Anvaya, Grammar, Chandas, Pronunciation, Citations).
    Enforces that AI annotations remain suggestions until human review.
    """
    __tablename__ = "ai_annotation_provenances"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    annotation_id: Mapped[str] = mapped_column(String(48), unique=True, index=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id"), index=True)
    annotation_type: Mapped[AIAnnotationType] = mapped_column(Enum(AIAnnotationType), index=True)
    provider_name: Mapped[str] = mapped_column(String(64))
    model_version: Mapped[str] = mapped_column(String(64))
    prompt_template_version: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    prompt_hash: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    output_payload_json: Mapped[dict] = mapped_column(JSON)
    confidence_score: Mapped[float] = mapped_column(Float, default=0.0)
    is_suggestion_only: Mapped[bool] = mapped_column(Boolean, default=True)
    is_human_reviewed: Mapped[bool] = mapped_column(Boolean, default=False)
    human_reviewer_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("reviewer_profiles.id"), nullable=True)
    human_correction_notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    estimated_cost_usd: Mapped[float] = mapped_column(Float, default=0.0)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    verse: Mapped["Verse"] = relationship("Verse")
    human_reviewer: Mapped[Optional["ReviewerProfile"]] = relationship("ReviewerProfile", back_populates="reviewed_annotations")


class ReviewerSession(Base):
    """
    Active cryptographic session tokens for authenticated scholars,
    supporting expiry, IP tracking, and instant revocation.
    """
    __tablename__ = "reviewer_sessions"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    session_token: Mapped[str] = mapped_column(String(64), unique=True, index=True)
    reviewer_id: Mapped[int] = mapped_column(Integer, ForeignKey("reviewer_profiles.id"), index=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    expires_at: Mapped[datetime] = mapped_column(DateTime)
    last_activity_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    absolute_expires_at: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    is_revoked: Mapped[bool] = mapped_column(Boolean, default=False)
    client_ip: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    user_agent: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # Relationships
    reviewer: Mapped["ReviewerProfile"] = relationship("ReviewerProfile", back_populates="sessions")


class AuthAuditLog(Base):
    """
    Immutable audit trail of authentication events, credential modifications,
    login attempts, lockout enforcements, and unauthorized requests.
    """
    __tablename__ = "auth_audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    reviewer_id: Mapped[Optional[int]] = mapped_column(Integer, nullable=True)
    event_type: Mapped[str] = mapped_column(String(64), index=True)
    ip_address: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    details: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

