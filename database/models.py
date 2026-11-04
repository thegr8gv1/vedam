"""
Vedic Heritage Platform — SQLAlchemy 2.0 Relational Data Models
Canonical representation of sacred texts, verses, translations, multi-script
transliterations, and the mandatory Content Rights & Provenance Engine.
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


class ReviewStatus(str, enum.Enum):
    DRAFT = "DRAFT"
    SCHOLAR_REVIEWED = "SCHOLAR_REVIEWED"
    APPROVED = "APPROVED"


class DuplicateStatus(str, enum.Enum):
    DETECTED = "DETECTED"
    RESOLVED_IDENTICAL = "RESOLVED_IDENTICAL"
    RESOLVED_VARIANT = "RESOLVED_VARIANT"
    RESOLVED_DISTINCT = "RESOLVED_DISTINCT"


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


class Category(Base):
    """Hierarchical taxonomy for devotional text classification."""
    __tablename__ = "categories"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)  # e.g., 'stotra', 'mantra'
    name: Mapped[str] = mapped_column(String(128))
    description: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    parent_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("categories.id"), nullable=True)

    # Relationships
    parent: Mapped[Optional["Category"]] = relationship("Category", remote_side=[id], backref="subcategories")


class Deity(Base):
    """Deities, Avatars, Rishis, and traditional subjects of adoration."""
    __tablename__ = "deities"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    slug: Mapped[str] = mapped_column(String(64), unique=True, index=True)  # e.g., 'shiva', 'ganesha'
    name: Mapped[str] = mapped_column(String(128))
    sanskrit_name: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)  # e.g., 'शिवः'
    description: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)

    # Relationships
    texts: Mapped[List["Text"]] = relationship("Text", back_populates="deity")


class Text(Base):
    """
    Canonical Master Record for an individual sacred composition.
    Preserves universal unique identifier, titles, liturgical metadata, and relationships.
    """
    __tablename__ = "texts"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    content_id: Mapped[str] = mapped_column(String(32), unique=True, index=True)  # e.g., 'VEDA-TXT-00001'
    uuid: Mapped[str] = mapped_column(String(36), unique=True, index=True)         # UUID v4
    canonical_title: Mapped[str] = mapped_column(String(255), index=True)         # English title
    devanagari_title: Mapped[str] = mapped_column(String(255))                     # Original Devanagari
    alternative_titles: Mapped[Optional[list]] = mapped_column(JSON, default=list) # Alternate aliases

    # Taxonomy Links
    deity_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("deities.id"), nullable=True)
    primary_category_id: Mapped[int] = mapped_column(Integer, ForeignKey("categories.id"))
    secondary_category_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("categories.id"), nullable=True)

    # Traditional Attribution & Liturgical Context
    original_language: Mapped[str] = mapped_column(String(16), default="sa")       # ISO 639-1 (sa, awa, etc.)
    original_script: Mapped[str] = mapped_column(String(32), default="Devanagari")
    composer: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)   # e.g., 'Adi Shankaracharya'
    rishi: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)      # Vedic Seer
    chandas: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)     # Metre: Anushtubh, etc.
    devata: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)     # Addressed Devata
    source_scripture: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)  # e.g., 'Rigveda 10.90'
    associated_festival: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    traditional_usage: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)  # e.g., 'Nitya Japa'

    # Integrity & Counts
    verse_count: Mapped[int] = mapped_column(Integer, default=0)
    content_hash: Mapped[str] = mapped_column(String(64), index=True)             # SHA-256 of canonical text
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    updated_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc), onupdate=lambda: datetime.now(timezone.utc))

    # Relationships
    deity: Mapped[Optional["Deity"]] = relationship("Deity", back_populates="texts")
    primary_category: Mapped["Category"] = relationship("Category", foreign_keys=[primary_category_id])
    secondary_category: Mapped[Optional["Category"]] = relationship("Category", foreign_keys=[secondary_category_id])
    versions: Mapped[List["TextVersion"]] = relationship("TextVersion", back_populates="text", cascade="all, delete-orphan")
    verses: Mapped[List["Verse"]] = relationship("Verse", back_populates="text", cascade="all, delete-orphan", order_by="Verse.verse_number")
    rights: Mapped[Optional["ContentRights"]] = relationship("ContentRights", back_populates="text", uselist=False, cascade="all, delete-orphan")
    audit_logs: Mapped[List["VerificationAuditLog"]] = relationship("VerificationAuditLog", back_populates="text", cascade="all, delete-orphan")


class TextVersion(Base):
    """
    Tiered version preservation:
    Raw Extracted -> Cleaned -> Verified Original -> Chanting Ready.
    Never silently overwrites earlier versions.
    """
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
    """
    Granular verse-level entity.
    Maintains verse numbering, meter, Vedic swaras, and links to translations/transliterations.
    """
    __tablename__ = "verses"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    verse_id: Mapped[str] = mapped_column(String(48), unique=True, index=True)  # e.g., 'VEDA-TXT-00001-V001'
    verse_number: Mapped[int] = mapped_column(Integer, index=True)
    verse_type: Mapped[VerseType] = mapped_column(Enum(VerseType), default=VerseType.VERSE)
    
    # Original Canonical Rendering
    devanagari_text: Mapped[str] = mapped_column(SA_Text)
    iast_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    vedic_accents_present: Mapped[bool] = mapped_column(Boolean, default=False)
    meter: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    notes: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="verses")
    transliterations: Mapped[List["Transliteration"]] = relationship("Transliteration", back_populates="verse", cascade="all, delete-orphan")
    translations: Mapped[List["Translation"]] = relationship("Translation", back_populates="verse", cascade="all, delete-orphan")


class Transliteration(Base):
    """Lossless phonetic script projections across Indian scripts."""
    __tablename__ = "transliterations"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    verse_id: Mapped[int] = mapped_column(Integer, ForeignKey("verses.id"), index=True)
    target_script: Mapped[str] = mapped_column(String(32), index=True)  # telugu, tamil, kannada, etc.
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
    target_language: Mapped[str] = mapped_column(String(16), index=True)  # en, hi, te, ta, kn, etc.
    translation_type: Mapped[TranslationType] = mapped_column(Enum(TranslationType), default=TranslationType.BHAVARTHA)
    translated_text: Mapped[str] = mapped_column(SA_Text)
    word_by_word_json: Mapped[Optional[list]] = mapped_column(JSON, nullable=True)  # List of {word, padachheda, meaning}
    translator: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    reviewer: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    review_status: Mapped[ReviewStatus] = mapped_column(Enum(ReviewStatus), default=ReviewStatus.DRAFT)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))

    # Relationships
    verse: Mapped["Verse"] = relationship("Verse", back_populates="translations")

    __table_args__ = (UniqueConstraint("verse_id", "target_language", "translation_type", name="uq_verse_lang_type"),)


class ContentRights(Base):
    """
    Mandatory Content Rights and Provenance Engine Record.
    Every text MUST have an associated rights record.
    Texts CANNOT enter commercial publication or export pipelines without release_status == GREEN.
    """
    __tablename__ = "content_rights"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), unique=True, index=True)
    source_id: Mapped[Optional[int]] = mapped_column(Integer, ForeignKey("sources.id"), nullable=True)

    # Attribution & Provenance
    original_composition_attribution: Mapped[str] = mapped_column(String(255))
    primary_source: Mapped[str] = mapped_column(String(255))               # e.g., 'Gita Press Edition No. 1234'
    specific_edition: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)
    edition_publication_date: Mapped[Optional[str]] = mapped_column(String(64), nullable=True)
    transcription_contributor: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    source_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    copyright_owner: Mapped[Optional[str]] = mapped_column(String(255), nullable=True)

    # License & Permission Flags
    license_type: Mapped[str] = mapped_column(String(64))                  # e.g., 'PUBLIC_DOMAIN', 'CC_BY_4_0'
    license_url: Mapped[Optional[str]] = mapped_column(String(512), nullable=True)
    commercial_reuse_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    translation_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    derivative_work_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    distribution_permitted: Mapped[bool] = mapped_column(Boolean, default=False)
    attribution_required: Mapped[bool] = mapped_column(Boolean, default=True)
    attribution_text: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    written_permission_reference: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    permission_expiry: Mapped[Optional[datetime]] = mapped_column(DateTime, nullable=True)
    
    # Audit & Status
    review_date: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
    supporting_evidence: Mapped[Optional[str]] = mapped_column(SA_Text, nullable=True)
    release_status: Mapped[ReleaseStatus] = mapped_column(Enum(ReleaseStatus), default=ReleaseStatus.AMBER)

    # Relationships
    text: Mapped["Text"] = relationship("Text", back_populates="rights")
    source: Mapped[Optional["Source"]] = relationship("Source", back_populates="rights_records")


class VerificationAuditLog(Base):
    """Auditing trail for text modifications, rights reviews, and scholar approvals."""
    __tablename__ = "verification_audit_logs"

    id: Mapped[int] = mapped_column(Integer, primary_key=True, autoincrement=True)
    text_id: Mapped[int] = mapped_column(Integer, ForeignKey("texts.id"), index=True)
    action: Mapped[str] = mapped_column(String(64))  # 'RIGHTS_REVIEW', 'VERSE_CORRECTION', etc.
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
    comparison_method: Mapped[str] = mapped_column(String(64))  # 'EXACT_HASH', 'TOKEN_SORT_RATIO'
    status: Mapped[DuplicateStatus] = mapped_column(Enum(DuplicateStatus), default=DuplicateStatus.DETECTED)
    resolved_by: Mapped[Optional[str]] = mapped_column(String(128), nullable=True)
    created_at: Mapped[datetime] = mapped_column(DateTime, default=lambda: datetime.now(timezone.utc))
