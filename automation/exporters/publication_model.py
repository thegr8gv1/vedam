"""
Vedic Heritage Platform — Format-Independent Publication Representation
Part D.1: Canonical publication document model decoupling presentation formats
from domain entities, preserving script fidelity, translation views, and governance state.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
import hashlib
import json
import logging
from typing import Any, Dict, List, Optional, Tuple

from automation.localization.registry import MultilingualRegistry
from automation.localization.script_registry import MultilingualScriptRegistry, ScriptDirection
from database.models import ReleaseStatus, ReviewStatus, Text, Translation, TranslationView, Verse

logger = logging.getLogger("vedam.automation.exporters.publication_model")


@dataclass(frozen=True)
class PublicationMetadata:
    content_id: str
    canonical_title: str
    devanagari_title: str
    deity: Optional[str] = None
    rishi: Optional[str] = None
    chandas: Optional[str] = None
    primary_category: str = "Stotra"
    source_scripture: Optional[str] = None
    traditional_usage: Optional[str] = None
    composer: Optional[str] = None


@dataclass(frozen=True)
class LanguageScriptTarget:
    language_code: str          # ISO 639-1 / 639-3 (e.g. hi, te, ta, ur, sa, en)
    language_name: str          # English name (e.g. Hindi, Telugu, Urdu)
    script_code: str            # ISO 15924 (e.g. Deva, Telu, Arab, Latn)
    script_name: str            # English script name (e.g. Devanagari, Perso-Arabic)
    bcp47: str                  # e.g. hi-Deva, ur-Arab
    direction: str              # "ltr" or "rtl"
    is_rtl: bool                # True if RTL
    shaping_required: bool      # OpenType complex shaping requirement


@dataclass(frozen=True)
class VerseEntry:
    verse_number: int
    verse_id: str
    canonical_order: int
    raw_source: str
    devanagari_source: str
    iast_transliteration: str
    target_script_transliteration: Optional[str] = None
    has_vedic_swaras: bool = False
    # Granular Translation Views
    literal_translation: Optional[str] = None
    literal_status: str = "MISSING"     # "MISSING", "DRAFT", "APPROVED"
    literal_version: Optional[int] = None
    tatparya_translation: Optional[str] = None
    tatparya_status: str = "MISSING"    # "MISSING", "DRAFT", "APPROVED"
    tatparya_version: Optional[int] = None
    bhavartha_translation: Optional[str] = None
    bhavartha_status: str = "MISSING"   # "MISSING", "DRAFT", "APPROVED"
    bhavartha_version: Optional[int] = None
    word_by_word_json: Optional[List[Dict[str, Any]]] = None
    notes: Optional[str] = None


@dataclass(frozen=True)
class MissingContentLedger:
    total_verses: int
    missing_literal_count: int
    missing_tatparya_count: int
    missing_bhavartha_count: int
    is_legacy_gap_affected: bool

    @property
    def has_missing_views(self) -> bool:
        return (
            self.missing_literal_count > 0 or
            self.missing_tatparya_count > 0 or
            self.missing_bhavartha_count > 0
        )


@dataclass(frozen=True)
class PublicationGovernance:
    publication_channel: str            # "internal_preview", "draft_export", "scholarly_review", "approved_publication"
    overall_review_status: str          # "DRAFT", "SUBMITTED_FOR_REVIEW", "APPROVED", "REJECTED"
    is_approved_for_public_release: bool
    watermark_text: Optional[str]
    approving_reviewer_name: Optional[str] = None
    approving_reviewer_accreditation: Optional[str] = None
    approval_timestamp: Optional[datetime] = None
    accreditation_verified: bool = False
    disclaimer: str = (
        "Internal scholarly preview or draft export. Raw ancient source texts are preserved intact. "
        "Unapproved translations must never be presented as scholar-certified canonical editions."
    )


@dataclass(frozen=True)
class PublicationDocument:
    """
    Format-independent representation of a multilingual publication package.
    Consumable by HTML, PDF, DOCX, and EPUB exporters.
    """
    metadata: PublicationMetadata
    target: LanguageScriptTarget
    governance: PublicationGovernance
    missing_content: MissingContentLedger
    verses: Tuple[VerseEntry, ...]
    generated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))
    document_hash: str = ""

    def __post_init__(self):
        if not self.document_hash:
            # Deterministic SHA-256 fingerprint
            content_repr = f"{self.metadata.content_id}:{self.target.bcp47}:{len(self.verses)}:{self.governance.publication_channel}"
            calculated_hash = hashlib.sha256(content_repr.encode("utf-8")).hexdigest()
            object.__setattr__(self, "document_hash", calculated_hash)

    @classmethod
    def from_text_and_views(
        cls,
        text: Text,
        target_language: str,
        target_script: Optional[str] = None,
        publication_channel: str = "draft_export",
        governance_override: Optional[PublicationGovernance] = None,
        include_target_transliteration: bool = True,
    ) -> "PublicationDocument":
        """
        Builds a PublicationDocument from a SQLAlchemy Text instance and its related verses/views.
        Preserves all canonical verse orderings, identifies missing views, and calculates governance.
        """
        lang_def = MultilingualRegistry.get_language(target_language)
        if not lang_def:
            raise ValueError(f"Unrecognized target language: '{target_language}'.")

        selected_script = target_script or lang_def.primary_script
        script_profile = MultilingualScriptRegistry.get_script(selected_script)
        if not script_profile:
            raise ValueError(f"Unrecognized target script: '{selected_script}'.")

        # Validate language/script compatibility
        is_valid, reason = MultilingualScriptRegistry.validate_script_for_language(target_language, selected_script)
        if not is_valid:
            raise ValueError(f"Incompatible language and script: {reason}")

        is_rtl = (script_profile.direction == ScriptDirection.RTL)

        target_obj = LanguageScriptTarget(
            language_code=lang_def.iso_639_1,
            language_name=lang_def.name,
            script_code=script_profile.iso_15924,
            script_name=script_profile.name,
            bcp47=f"{lang_def.iso_639_1}-{script_profile.iso_15924}",
            direction=script_profile.direction.value,
            is_rtl=is_rtl,
            shaping_required=script_profile.requires_opentype_shaping,
        )

        deity_name = None
        if getattr(text, "deity", None) and hasattr(text.deity, "name"):
            deity_name = text.deity.name
        elif getattr(text, "deity_id", None):
            deity_name = str(text.deity_id)

        category_name = "Stotra"
        if getattr(text, "primary_category", None) and hasattr(text.primary_category, "name"):
            category_name = text.primary_category.name
        elif getattr(text, "primary_category_id", None):
            category_name = str(text.primary_category_id)

        meta = PublicationMetadata(
            content_id=text.content_id,
            canonical_title=text.canonical_title,
            devanagari_title=text.devanagari_title,
            deity=deity_name,
            rishi=text.rishi,
            chandas=text.chandas,
            primary_category=category_name,
            source_scripture=text.source_scripture,
            traditional_usage=text.traditional_usage,
            composer=text.composer,
        )

        # Transliteration Engine
        from automation.localization.transliteration_engine import MultilingualTransliterationEngine

        verse_entries: List[VerseEntry] = []
        missing_lit = 0
        missing_tat = 0
        missing_bhav = 0

        # Sort verses canonically
        sorted_verses = sorted(text.verses, key=lambda v: v.verse_number)

        for v in sorted_verses:
            # Query translations for target language
            trans_rec = next((t for t in v.translations if t.target_language == target_language), None)

            # Query granular views
            lit_text = None
            lit_status = "MISSING"
            lit_ver = None
            tat_text = None
            tat_status = "MISSING"
            tat_ver = None
            bhav_text = None
            bhav_status = "MISSING"
            bhav_ver = None
            w_by_w = None

            if trans_rec:
                w_by_w = trans_rec.word_by_word_json
                for view in getattr(trans_rec, "translation_views", []):
                    v_type = view.view_type.upper() if isinstance(view.view_type, str) else view.view_type.value.upper()
                    st = view.review_status.value if hasattr(view.review_status, "value") else str(view.review_status)
                    if v_type == "LITERAL":
                        lit_text = view.view_text
                        lit_status = st
                        lit_ver = view.version
                    elif v_type == "TATPARYA":
                        tat_text = view.view_text
                        tat_status = st
                        tat_ver = view.version
                    elif v_type == "BHAVARTHA":
                        bhav_text = view.view_text
                        bhav_status = st
                        bhav_ver = view.version

                # Fallback: if bhavartha not in views, use translated_text
                if not bhav_text and trans_rec.translated_text:
                    bhav_text = trans_rec.translated_text
                    bhav_status = trans_rec.review_status.value if hasattr(trans_rec.review_status, "value") else str(trans_rec.review_status)
                    bhav_ver = 1

            if not lit_text:
                missing_lit += 1
            if not tat_text:
                missing_tat += 1
            if not bhav_text:
                missing_bhav += 1

            # Target script transliteration
            tgt_translit = None
            if include_target_transliteration and selected_script != "Deva":
                # Transliterate Sanskrit source to target script
                if MultilingualTransliterationEngine.is_conversion_supported("Deva", selected_script):
                    t_res = MultilingualTransliterationEngine.transliterate(v.devanagari_text, "Deva", selected_script)
                    tgt_translit = t_res.text

            v_entry = VerseEntry(
                verse_number=v.verse_number,
                verse_id=v.verse_id,
                canonical_order=v.verse_number,
                raw_source=v.raw_source_text or v.devanagari_text,
                devanagari_source=v.devanagari_text,
                iast_transliteration=v.iast_text or "",
                target_script_transliteration=tgt_translit,
                has_vedic_swaras=bool(v.vedic_accents_present),
                literal_translation=lit_text,
                literal_status=lit_status,
                literal_version=lit_ver,
                tatparya_translation=tat_text,
                tatparya_status=tat_status,
                tatparya_version=tat_ver,
                bhavartha_translation=bhav_text,
                bhavartha_status=bhav_status,
                bhavartha_version=bhav_ver,
                word_by_word_json=w_by_w,
                notes=v.notes,
            )
            verse_entries.append(v_entry)

        total_v = len(verse_entries)
        missing_ledger = MissingContentLedger(
            total_verses=total_v,
            missing_literal_count=missing_lit,
            missing_tatparya_count=missing_tat,
            missing_bhavartha_count=missing_bhav,
            is_legacy_gap_affected=(missing_lit > 0 or missing_tat > 0),
        )

        # Default governance if not overridden
        if not governance_override:
            # Check if any translation is APPROVED
            all_bhav_approved = (total_v > 0 and all(ve.bhavartha_status == "APPROVED" for ve in verse_entries))
            all_views_approved = all_bhav_approved and (missing_lit == 0 and all(ve.literal_status == "APPROVED" for ve in verse_entries))

            if publication_channel == "approved_publication":
                # Can only be approved if all views are verified approved
                if not all_views_approved:
                    raise PermissionError(
                        "Cannot generate 'approved_publication': Translations are currently in DRAFT status. "
                        "Public release requires accredited human scholarly certification."
                    )
                gov = PublicationGovernance(
                    publication_channel="approved_publication",
                    overall_review_status="APPROVED",
                    is_approved_for_public_release=True,
                    watermark_text=None,
                    accreditation_verified=True,
                )
            elif publication_channel == "scholarly_review":
                gov = PublicationGovernance(
                    publication_channel="scholarly_review",
                    overall_review_status="SUBMITTED_FOR_REVIEW",
                    is_approved_for_public_release=False,
                    watermark_text="CONFIDENTIAL SCHOLARLY REVIEW COPY — NOT FOR DISTRIBUTION",
                    accreditation_verified=False,
                )
            elif publication_channel == "internal_preview":
                gov = PublicationGovernance(
                    publication_channel="internal_preview",
                    overall_review_status="DRAFT",
                    is_approved_for_public_release=False,
                    watermark_text="INTERNAL PREVIEW ONLY — UNVERIFIED DRAFT",
                    accreditation_verified=False,
                )
            else:  # draft_export
                gov = PublicationGovernance(
                    publication_channel="draft_export",
                    overall_review_status="DRAFT",
                    is_approved_for_public_release=False,
                    watermark_text="UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE",
                    accreditation_verified=False,
                )
        else:
            gov = governance_override

        return cls(
            metadata=meta,
            target=target_obj,
            governance=gov,
            missing_content=missing_ledger,
            verses=tuple(verse_entries),
        )
