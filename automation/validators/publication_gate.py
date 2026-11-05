"""
Vedic Heritage Platform — Pre-Flight Publication Quality Gate
Enforces 15 rigorous multidimensional publication checks before authorizing
export to Excel, Word, PDF, or mobile client distribution.
"""

from dataclasses import dataclass, field
from datetime import datetime, timezone
from enum import Enum
import hashlib
import logging
from typing import Any, Dict, List, Optional

from automation.cleaners.unicode_preserver import UnicodePreserver
from automation.rights.approval_workflow import (
    AcquisitionStatus,
    ApprovalWorkflowEngine,
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from automation.rights.jurisdiction import RightsReleaseStatus
from database.models import ReleaseStatus, ReviewStatus, Text, Verse, VerseType

logger = logging.getLogger("vedam.automation.publication_gate")


class GateSeverity(str, Enum):
    BLOCKER = "BLOCKER"
    WARNING = "WARNING"
    INFO = "INFO"


@dataclass
class GateCheckResult:
    rule_id: str
    rule_name: str
    passed: bool
    severity: GateSeverity
    message: str
    details: Optional[Dict[str, Any]] = None


@dataclass
class PreflightReport:
    content_id: str
    canonical_title: str
    passed_all_gates: bool
    can_publish: bool
    total_checks: int
    passed_checks: int
    failed_blockers: int
    warnings: int
    checks: List[GateCheckResult] = field(default_factory=list)
    evaluated_at: datetime = field(default_factory=lambda: datetime.now(timezone.utc))

    def summary(self) -> Dict[str, Any]:
        return {
            "content_id": self.content_id,
            "title": self.canonical_title,
            "can_publish": self.can_publish,
            "passed_all_gates": self.passed_all_gates,
            "passed_checks": f"{self.passed_checks}/{self.total_checks}",
            "blockers": self.failed_blockers,
            "warnings": self.warnings,
            "failed_rules": [c.rule_name for c in self.checks if not c.passed and c.severity == GateSeverity.BLOCKER],
        }


class PublicationPreflightGate:
    """Pre-flight publication gate checking 15 comprehensive publication readiness criteria."""

    @classmethod
    def evaluate(cls, text: Text, target_channel: str = "scholarly_review") -> PreflightReport:
        checks: List[GateCheckResult] = []

        # 1. Rule: Title Presence Check
        has_titles = bool(text.canonical_title and text.devanagari_title)
        checks.append(
            GateCheckResult(
                rule_id="PUB-001",
                rule_name="TITLE_CHECK",
                passed=has_titles,
                severity=GateSeverity.BLOCKER,
                message="Canonical and Devanagari titles are present." if has_titles else "Missing canonical or Devanagari title.",
            )
        )

        # 2. Rule: Classification / Deity Check
        has_class = bool(text.primary_category and text.deity)
        checks.append(
            GateCheckResult(
                rule_id="PUB-002",
                rule_name="CLASSIFICATION_CHECK",
                passed=has_class,
                severity=GateSeverity.BLOCKER,
                message="Category and Deity are properly classified." if has_class else "Missing Category or Deity classification.",
            )
        )

        # 3. Rule: Language & Script Specification
        has_lang = bool(text.original_language and text.original_script)
        checks.append(
            GateCheckResult(
                rule_id="PUB-003",
                rule_name="LANGUAGE_SCRIPT_CHECK",
                passed=has_lang,
                severity=GateSeverity.BLOCKER,
                message=f"Language ({text.original_language}) and Script ({text.original_script}) are defined." if has_lang else "Missing language or script specification.",
            )
        )

        # 4. Rule: Provenance & Attribution Check
        has_provenance = bool(text.source_scripture and text.composer)
        checks.append(
            GateCheckResult(
                rule_id="PUB-004",
                rule_name="PROVENANCE_ATTRIBUTION_CHECK",
                passed=has_provenance,
                severity=GateSeverity.BLOCKER,
                message="Source scripture and attribution/composer are documented." if has_provenance else "Incomplete scripture or composer attribution.",
            )
        )

        # 5. Rule: Source Critical Edition Check
        has_editions = bool(text.source_editions and len(text.source_editions) > 0)
        primary_ed = text.source_editions[0] if has_editions else None
        ed_valid = bool(primary_ed and primary_ed.edition_title and primary_ed.publication_year)
        checks.append(
            GateCheckResult(
                rule_id="PUB-005",
                rule_name="CRITICAL_EDITION_CHECK",
                passed=ed_valid,
                severity=GateSeverity.BLOCKER,
                message=f"Primary critical edition verified: '{primary_ed.edition_title}' ({primary_ed.publication_year})." if ed_valid else "Missing or incomplete primary critical edition reference.",
            )
        )

        # 6. Rule: Rights Clearance Status Check
        rights_cleared = (text.rights_clearance_status == RightsClearanceStatus.GREEN_CLEARED)
        checks.append(
            GateCheckResult(
                rule_id="PUB-006",
                rule_name="RIGHTS_CLEARANCE_STATUS_CHECK",
                passed=rights_cleared,
                severity=GateSeverity.BLOCKER,
                message=f"Rights clearance status is {text.rights_clearance_status.value}." if rights_cleared else f"Rights clearance status is {text.rights_clearance_status.value} (must be GREEN_CLEARED).",
            )
        )

        # 7. Rule: Legal Counsel Sign-off Check
        has_legal_signoff = False
        if text.rights_grants:
            has_legal_signoff = any(g.is_legally_approved and g.legal_reviewer for g in text.rights_grants)
        elif text.rights:
            has_legal_signoff = (text.rights.release_status == ReleaseStatus.GREEN and bool(text.rights.reviewed_by))
        checks.append(
            GateCheckResult(
                rule_id="PUB-007",
                rule_name="LEGAL_COUNSEL_SIGNOFF_CHECK",
                passed=has_legal_signoff,
                severity=GateSeverity.BLOCKER,
                message="Signed off by legal reviewer for publication." if has_legal_signoff else "No affirmative legal counsel approval found in rights grants.",
            )
        )

        # 8. Rule: Acquisition Status Check
        acq_valid = (text.acquisition_status == AcquisitionStatus.VERIFIED_SOURCE)
        checks.append(
            GateCheckResult(
                rule_id="PUB-008",
                rule_name="ACQUISITION_STATUS_CHECK",
                passed=acq_valid,
                severity=GateSeverity.BLOCKER,
                message=f"Source acquisition status is {text.acquisition_status.value}." if acq_valid else f"Source acquisition is {text.acquisition_status.value} (unauthorized).",
            )
        )

        # 9. Rule: Textual Verification Status Check
        text_verified = (text.textual_verification_status == TextualVerificationStatus.SCHOLAR_VERIFIED)
        checks.append(
            GateCheckResult(
                rule_id="PUB-009",
                rule_name="TEXTUAL_VERIFICATION_CHECK",
                passed=text_verified,
                severity=GateSeverity.BLOCKER,
                message=f"Textual verification status is {text.textual_verification_status.value}." if text_verified else f"Textual verification status is {text.textual_verification_status.value} (must be SCHOLAR_VERIFIED).",
            )
        )

        # 10. Rule: Translation Approval Status Check
        if target_channel == "commercial_release":
            has_drafts = any(
                t.review_status == ReviewStatus.DRAFT
                for v in text.verses for t in v.translations
            )
            has_uncredited_approvals = any(
                t.review_status in (ReviewStatus.APPROVED, ReviewStatus.SCHOLAR_REVIEWED) and not t.reviewer
                for v in text.verses for t in v.translations
            )
            trans_status_ok = (text.translation_status in [TranslationStatus.APPROVED, TranslationStatus.SCHOLAR_REVIEWED])
            
            if trans_status_ok and not has_drafts and not has_uncredited_approvals:
                trans_approved = True
                msg = f"Translation status is '{text.translation_status.value}' with accredited scholarly panel sign-off."
            else:
                trans_approved = False
                msg = (
                    f"Commercial release requires independent accredited scholar panel approval; "
                    f"current translation status is '{text.translation_status.value}'. "
                    f"Internal editorial synthesis without accredited human reviewer sign-off cannot bypass "
                    f"the scholarly approval requirement for commercial distribution."
                )

            checks.append(
                GateCheckResult(
                    rule_id="PUB-010",
                    rule_name="TRANSLATION_APPROVAL_CHECK",
                    passed=trans_approved,
                    severity=GateSeverity.BLOCKER,
                    message=msg,
                )
            )
        else:
            is_draft = (text.translation_status == TranslationStatus.DRAFT)
            trans_approved = (text.translation_status in [TranslationStatus.APPROVED, TranslationStatus.SCHOLAR_REVIEWED, TranslationStatus.DRAFT])
            checks.append(
                GateCheckResult(
                    rule_id="PUB-010",
                    rule_name="TRANSLATION_APPROVAL_CHECK",
                    passed=trans_approved,
                    severity=GateSeverity.WARNING if is_draft else GateSeverity.BLOCKER,
                    message="Translation is in DRAFT status (Awaiting Scholarly Panel Review); permitted for review." if is_draft else f"Translation status is {text.translation_status.value}.",
                )
            )

        # 11. Rule: Editorial Approval Status Check
        editorial_approved = (text.editorial_approval_status == EditorialApprovalStatus.APPROVED)
        checks.append(
            GateCheckResult(
                rule_id="PUB-011",
                rule_name="EDITORIAL_APPROVAL_CHECK",
                passed=editorial_approved,
                severity=GateSeverity.BLOCKER,
                message=f"Editorial approval status is {text.editorial_approval_status.value}." if editorial_approved else f"Editorial status is {text.editorial_approval_status.value} (must be APPROVED).",
            )
        )

        # 12. Rule: Verse Count & Non-Empty Payload Check
        verses = text.verses
        has_verses = bool(verses and len(verses) > 0 and len(verses) == text.verse_count)
        checks.append(
            GateCheckResult(
                rule_id="PUB-012",
                rule_name="VERSE_COUNT_MATCH_CHECK",
                passed=has_verses,
                severity=GateSeverity.BLOCKER,
                message=f"Text contains {len(verses)} verses matching declared count {text.verse_count}." if has_verses else f"Verse count mismatch: {len(verses)} actual vs {text.verse_count} declared.",
            )
        )

        # 13. Rule: Verse Sequence Continuity & No Duplicates
        seq_valid = True
        seq_msg = "Verse sequence is continuous from 1 to N without gaps or duplicates."
        if verses:
            sorted_v = sorted(verses, key=lambda v: v.verse_number)
            expected = 1
            seen_texts = set()
            for v in sorted_v:
                if v.verse_number != expected:
                    seq_valid = False
                    seq_msg = f"Verse numbering broken: expected {expected}, found {v.verse_number}."
                    break
                # Check for duplicate text
                clean_t = UnicodePreserver.extract_canonical_text(v.devanagari_text or "")[0]
                if clean_t in seen_texts:
                    seq_valid = False
                    seq_msg = f"Duplicate verse text detected at verse {v.verse_number}."
                    break
                seen_texts.add(clean_t)
                expected += 1
        else:
            seq_valid = False
            seq_msg = "No verses available to verify sequence."

        checks.append(
            GateCheckResult(
                rule_id="PUB-013",
                rule_name="VERSE_SEQUENCE_CONTINUITY_CHECK",
                passed=seq_valid,
                severity=GateSeverity.BLOCKER,
                message=seq_msg,
            )
        )

        # 14. Rule: Vedic Swara Accent Preservation Check
        # If any verse contains accents or category is 'vedic_suktam' / 'suktam' / 'mantra' with accents
        accent_valid = True
        accent_msg = "Vedic swara accent check passed."
        has_any_accents = any(v.vedic_accents_present for v in verses) if verses else False
        if text.primary_category and text.primary_category.slug in ["suktam", "vedic-suktam", "mantra"]:
            if not has_any_accents:
                accent_valid = False
                accent_msg = f"Text is classified as {text.primary_category.slug} but has no Vedic swara annotations preserved."
            else:
                accent_msg = "Vedic swara accents preserved and verified."
        checks.append(
            GateCheckResult(
                rule_id="PUB-014",
                rule_name="VEDIC_SWARA_ACCENT_CHECK",
                passed=accent_valid,
                severity=GateSeverity.BLOCKER if (text.primary_category and text.primary_category.slug in ["suktam"]) else GateSeverity.WARNING,
                message=accent_msg,
            )
        )

        # 15. Rule: Content SHA-256 Hash Integrity Check
        hash_valid = False
        hash_msg = "Content hash integrity verified."
        if text.content_hash and text.raw_source_text:
            expected_hash = hashlib.sha256(text.raw_source_text.encode("utf-8")).hexdigest()
            if text.content_hash == expected_hash:
                hash_valid = True
            else:
                hash_valid = False
                hash_msg = f"Content hash mismatch: stored {text.content_hash[:12]}... != computed {expected_hash[:12]}..."
        elif text.content_hash:
            hash_valid = True
            hash_msg = "Content hash is present."
        else:
            hash_valid = False
            hash_msg = "Missing content SHA-256 hash."

        checks.append(
            GateCheckResult(
                rule_id="PUB-015",
                rule_name="CONTENT_HASH_INTEGRITY_CHECK",
                passed=hash_valid,
                severity=GateSeverity.BLOCKER,
                message=hash_msg,
            )
        )

        total = len(checks)
        passed_count = sum(1 for c in checks if c.passed)
        blockers = sum(1 for c in checks if not c.passed and c.severity == GateSeverity.BLOCKER)
        warnings = sum(1 for c in checks if not c.passed and c.severity == GateSeverity.WARNING)
        can_publish = (blockers == 0)

        return PreflightReport(
            content_id=text.content_id,
            canonical_title=text.canonical_title,
            passed_all_gates=(blockers == 0 and warnings == 0),
            can_publish=can_publish,
            total_checks=total,
            passed_checks=passed_count,
            failed_blockers=blockers,
            warnings=warnings,
            checks=checks,
        )

    @classmethod
    def assert_can_publish(cls, text: Text, target_channel: str = "scholarly_review") -> None:
        """Raises PermissionError if text fails any blocker gate checks."""
        report = cls.evaluate(text, target_channel=target_channel)
        if not report.can_publish:
            failed_rules = [f"[{c.rule_id} {c.rule_name}] {c.message}" for c in report.checks if not c.passed and c.severity == GateSeverity.BLOCKER]
            raise PermissionError(
                f"Publication Gatekeeper Blocked '{text.canonical_title}' ({text.content_id}) for channel '{target_channel}':\n" +
                "\n".join(failed_rules)
            )
