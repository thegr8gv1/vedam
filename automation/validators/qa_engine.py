"""
Vedic Heritage Platform — Content Quality Assurance Engine
Implements the 12-stage lifecycle quality gates, completeness classification,
and 14 automated textual, liturgical, and linguistic validation checks.
"""

from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
import enum
import json
import re
from typing import Any, Dict, List, Optional, Set, Tuple

from automation.cleaners.unicode_preserver import VedicSwara, UnicodePreserver
from database.models import (
    IPLayerType,
    Jurisdiction,
    ReleaseStatus,
    ReviewStatus,
    RightsReleaseStatus,
    Text,
    Verse,
    VerseType,
)


class QualityLifecycleStatus(str, enum.Enum):
    """The 12 formal stages of content qualification."""
    DISCOVERED = "DISCOVERED"
    SOURCE_IDENTIFIED = "SOURCE_IDENTIFIED"
    RIGHTS_PENDING = "RIGHTS_PENDING"
    AUTHORIZED_FOR_COLLECTION = "AUTHORIZED_FOR_COLLECTION"
    COLLECTED = "COLLECTED"
    PARSED = "PARSED"
    REQUIRES_VERIFICATION = "REQUIRES_VERIFICATION"
    UNDER_SCHOLARLY_REVIEW = "UNDER_SCHOLARLY_REVIEW"
    TEXT_VERIFIED = "TEXT_VERIFIED"
    RIGHTS_APPROVED = "RIGHTS_APPROVED"
    APPROVED_FOR_TRANSLATION = "APPROVED_FOR_TRANSLATION"
    APPROVED_FOR_PUBLICATION = "APPROVED_FOR_PUBLICATION"


class TextCompletenessStatus(str, enum.Enum):
    """Categorization of textual payload completeness."""
    METADATA_ONLY = "METADATA_ONLY"
    SAMPLE_RECORD = "SAMPLE_RECORD"
    INCOMPLETE_TEXT = "INCOMPLETE_TEXT"
    FULL_UNVERIFIED_TEXT = "FULL_UNVERIFIED_TEXT"
    VERIFIED_FULL_TEXT = "VERIFIED_FULL_TEXT"


@dataclass
class QualityCheckIssue:
    check_name: str
    severity: str  # "ERROR", "WARNING", "INFO"
    message: str
    context: Optional[Dict[str, Any]] = None


@dataclass
class QualityAuditReport:
    content_id: str
    canonical_title: str
    audit_timestamp: str
    completeness_status: TextCompletenessStatus
    quality_lifecycle_status: QualityLifecycleStatus
    total_verses_expected: int
    total_verses_found: int
    passed_all_mandatory_checks: bool
    issues: List[QualityCheckIssue] = field(default_factory=list)
    accent_analysis: Dict[str, Any] = field(default_factory=dict)
    metadata_completeness_score: float = 0.0


class ContentQualityAssuranceEngine:
    """Automated inspector enforcing strict scholarly and textual standards."""

    # Danda regex patterns
    DANDA_PATTERN = re.compile(r"[।॥]")
    CORRUPT_CHAR_PATTERN = re.compile(r"[\uFFFD\u0000-\u0008\u000B\u000C\u000E-\u001F]")

    @classmethod
    def audit_text(
        cls,
        text: Text,
        reference_edition_verses: Optional[List[str]] = None,
    ) -> QualityAuditReport:
        """Runs all 14 comprehensive quality checks on a Text model entity."""
        issues: List[QualityCheckIssue] = []
        now_str = datetime.now(timezone.utc).isoformat()

        # 1. Missing verses and completeness check
        verses = text.verses or []
        found_count = len(verses)
        expected_count = text.verse_count or 0

        completeness_status = cls._determine_completeness(found_count, expected_count)

        if found_count == 0:
            issues.append(QualityCheckIssue(
                check_name="VERSIFICATION_CHECK",
                severity="ERROR",
                message="No verses found in database. Record is metadata-only.",
            ))
        elif expected_count > 0 and found_count < expected_count:
            issues.append(QualityCheckIssue(
                check_name="COMPLETENESS_CHECK",
                severity="WARNING" if found_count == 1 else "ERROR",
                message=f"Text payload incomplete: found {found_count} verses, expected {expected_count}.",
                context={"found": found_count, "expected": expected_count},
            ))

        # 2. Duplicate verses check
        seen_texts: Set[str] = set()
        seen_numbers: Set[int] = set()
        for v in verses:
            if v.verse_number in seen_numbers:
                issues.append(QualityCheckIssue(
                    check_name="DUPLICATE_NUMBER_CHECK",
                    severity="ERROR",
                    message=f"Duplicate verse number {v.verse_number} encountered.",
                    context={"verse_id": v.verse_id},
                ))
            seen_numbers.add(v.verse_number)

            norm = (v.devanagari_text or "").strip()
            if norm and norm in seen_texts:
                issues.append(QualityCheckIssue(
                    check_name="DUPLICATE_CONTENT_CHECK",
                    severity="ERROR",
                    message=f"Duplicate verse text detected in verse number {v.verse_number}.",
                ))
            if norm:
                seen_texts.add(norm)

        # 3. Sequence continuity check
        sorted_numbers = sorted(seen_numbers)
        if sorted_numbers and sorted_numbers != list(range(1, len(sorted_numbers) + 1)):
            if completeness_status not in [TextCompletenessStatus.SAMPLE_RECORD, TextCompletenessStatus.METADATA_ONLY]:
                issues.append(QualityCheckIssue(
                    check_name="SEQUENCE_CHECK",
                    severity="ERROR",
                    message=f"Verse sequence is non-contiguous: {sorted_numbers}",
                ))

        # 4. Opening and concluding (Phalasruti) check
        has_phalasruti = any(v.verse_type == VerseType.PHALASRUTI for v in verses)
        if text.primary_category and text.primary_category.slug in ["stotra", "ashtakam", "sahasranama"]:
            if not has_phalasruti and expected_count > 1 and completeness_status == TextCompletenessStatus.VERIFIED_FULL_TEXT:
                issues.append(QualityCheckIssue(
                    check_name="PHALASRUTI_CHECK",
                    severity="INFO",
                    message="No explicit Phalasruti tagged verse found in stotra collection.",
                ))

        # 5. Stanza separation and Danda syntax check
        for v in verses:
            d_text = v.devanagari_text or ""
            if not cls.DANDA_PATTERN.search(d_text):
                issues.append(QualityCheckIssue(
                    check_name="STANZA_PUNCTUATION_CHECK",
                    severity="WARNING",
                    message=f"Verse {v.verse_number} lacks traditional danda (। or ॥) delimiters.",
                ))

        # 6. Character corruption / Unicode replacement glyph check
        for v in verses:
            d_text = v.devanagari_text or ""
            if cls.CORRUPT_CHAR_PATTERN.search(d_text):
                issues.append(QualityCheckIssue(
                    check_name="CHARACTER_CORRUPTION_CHECK",
                    severity="ERROR",
                    message=f"Character corruption / illegal control character found in verse {v.verse_number}.",
                ))

        # 7. Unicode normalization verification
        for v in verses:
            d_text = v.devanagari_text or ""
            # Verify NFC normalization
            import unicodedata
            if unicodedata.normalize("NFC", d_text) != d_text:
                issues.append(QualityCheckIssue(
                    check_name="UNICODE_NORMALIZATION_CHECK",
                    severity="WARNING",
                    message=f"Verse {v.verse_number} requires Unicode NFC normalization.",
                ))

        # 8. Vedic accents check
        accent_summary = {}
        is_vedic = (text.primary_category and text.primary_category.slug in ["mantra", "suktam"]) or (text.canonical_title and "vedic" in text.canonical_title.lower())
        if is_vedic:
            for v in verses:
                analysis = UnicodePreserver.analyze_vedic_swaras(v.devanagari_text or "")
                accent_summary[f"verse_{v.verse_number}"] = analysis
                if not analysis["has_vedic_accents"]:
                    issues.append(QualityCheckIssue(
                        check_name="VEDIC_ACCENT_CHECK",
                        severity="WARNING",
                        message=f"Vedic composition verse {v.verse_number} lacks Vedic swara accents.",
                    ))

        # 9. Broken ligatures / invalid Halanta sequences
        for v in verses:
            d_text = v.devanagari_text or ""
            if "््" in d_text or "  " in d_text:
                issues.append(QualityCheckIssue(
                    check_name="LIGATURE_INTEGRITY_CHECK",
                    severity="WARNING",
                    message=f"Potential broken ligature or double-halanta in verse {v.verse_number}.",
                ))

        # 10. Multi-script transliteration coverage
        for v in verses:
            trans_count = len(v.transliterations or [])
            if trans_count < 4 and len(v.devanagari_text or "") > 0:
                issues.append(QualityCheckIssue(
                    check_name="TRANSLITERATION_COVERAGE_CHECK",
                    severity="INFO",
                    message=f"Verse {v.verse_number} has {trans_count} transliterations; recommend Devanagari, Telugu, Tamil, Kannada, Malayalam, IAST.",
                ))

        # 11. Language identification verification
        if text.original_language == "awa":
            # Must have Dohas or Chaupais
            has_awadhi_meters = any(v.verse_type in [VerseType.DOHA, VerseType.CHAUPAI] for v in verses)
            if not has_awadhi_meters and len(verses) > 0:
                issues.append(QualityCheckIssue(
                    check_name="LANGUAGE_METER_CHECK",
                    severity="INFO",
                    message="Awadhi text tagged without explicit DOHA or CHAUPAI verse types.",
                ))

        # 12. Metadata completeness calculation
        metadata_score, missing_meta = cls._calculate_metadata_score(text)
        if missing_meta:
            issues.append(QualityCheckIssue(
                check_name="METADATA_COMPLETENESS_CHECK",
                severity="WARNING" if metadata_score < 0.75 else "INFO",
                message=f"Missing metadata fields: {', '.join(missing_meta)}",
                context={"score": metadata_score, "missing": missing_meta},
            ))

        # 13. Traditional attribution and source scripture verification
        if not text.composer and not text.rishi:
            issues.append(QualityCheckIssue(
                check_name="ATTRIBUTION_CHECK",
                severity="WARNING",
                message="No traditional composer or Vedic rishi attributed to text.",
            ))
        if not text.source_scripture:
            issues.append(QualityCheckIssue(
                check_name="SCRIPTURE_REFERENCE_CHECK",
                severity="WARNING",
                message="No primary scripture reference recorded.",
            ))

        # 14. Rights clearance audit
        is_green = text.rights and text.rights.release_status == ReleaseStatus.GREEN
        if not is_green:
            issues.append(QualityCheckIssue(
                check_name="RIGHTS_CLEARANCE_CHECK",
                severity="ERROR",
                message=f"Text lacks confirmed GREEN rights release status (current: {text.rights.release_status.value if text.rights else 'NONE'}).",
            ))

        # Determine overall lifecycle quality status
        error_count = sum(1 for iss in issues if iss.severity == "ERROR")
        passed = (error_count == 0)

        quality_status = cls._determine_quality_lifecycle(text, completeness_status, passed, is_green)

        return QualityAuditReport(
            content_id=text.content_id,
            canonical_title=text.canonical_title,
            audit_timestamp=now_str,
            completeness_status=completeness_status,
            quality_lifecycle_status=quality_status,
            total_verses_expected=expected_count,
            total_verses_found=found_count,
            passed_all_mandatory_checks=passed,
            issues=issues,
            accent_analysis=accent_summary,
            metadata_completeness_score=metadata_score,
        )

    @staticmethod
    def _determine_completeness(found: int, expected: int) -> TextCompletenessStatus:
        if found == 0:
            return TextCompletenessStatus.METADATA_ONLY
        if expected > 0 and found == expected:
            return TextCompletenessStatus.VERIFIED_FULL_TEXT
        if found < expected and found <= 2:
            return TextCompletenessStatus.SAMPLE_RECORD
        if found < expected:
            return TextCompletenessStatus.INCOMPLETE_TEXT
        return TextCompletenessStatus.FULL_UNVERIFIED_TEXT

    @staticmethod
    def _determine_quality_lifecycle(
        text: Text,
        completeness: TextCompletenessStatus,
        passed_checks: bool,
        is_green: bool,
    ) -> QualityLifecycleStatus:
        if not is_green:
            return QualityLifecycleStatus.RIGHTS_PENDING
        if completeness in [TextCompletenessStatus.METADATA_ONLY, TextCompletenessStatus.SAMPLE_RECORD]:
            return QualityLifecycleStatus.PARSED
        if not passed_checks:
            return QualityLifecycleStatus.REQUIRES_VERIFICATION
        if completeness == TextCompletenessStatus.VERIFIED_FULL_TEXT and passed_checks and is_green:
            return QualityLifecycleStatus.APPROVED_FOR_PUBLICATION
        return QualityLifecycleStatus.UNDER_SCHOLARLY_REVIEW

    @staticmethod
    def _calculate_metadata_score(text: Text) -> Tuple[float, List[str]]:
        fields_to_check = {
            "canonical_title": bool(text.canonical_title),
            "devanagari_title": bool(text.devanagari_title),
            "primary_category": bool(text.primary_category_id),
            "deity": bool(text.deity_id),
            "attribution": bool(text.composer or text.rishi),
            "scripture": bool(text.source_scripture),
            "content_hash": bool(text.content_hash),
            "rights_record": bool(text.rights),
        }
        present = sum(1 for v in fields_to_check.values() if v)
        total = len(fields_to_check)
        missing = [k for k, v in fields_to_check.items() if not v]
        return round(present / total, 2), missing
