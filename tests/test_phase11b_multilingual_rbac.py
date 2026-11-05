"""
Phase 11B: Multilingual Database and Reviewer RBAC Expansion Tests
Tests language-aware reviewer roles, bidirectional mappings, authorization rules,
anti-self-approval safeguards, translation-type permissions, migration lifecycle,
and publication gate enforcement under strict test database isolation.
"""

from datetime import datetime, timezone
import os
import shutil
import tempfile
from typing import Generator
import uuid
import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import Session, sessionmaker

from alembic.config import Config
from alembic import command

from database.models import (
    Base,
    Category,
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    Text,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)
from database.schemas import ReviewActionLogCreate, ReviewerProfileCreate
from automation.workbench.multilingual_rbac import (
    MultilingualRBACEngine,
    SelfApprovalViolationError,
    UnauthorizedLanguageReviewError,
)
from automation.workbench.reviewer_manager import ReviewerManager
from automation.workbench.review_action_engine import ReviewActionEngine, ReviewActionError
from automation.workbench.auth import PermissionGuard, PermissionDeniedError
from automation.validators.publication_gate import PublicationPreflightGate, GateSeverity
from automation.rights.approval_workflow import (
    AcquisitionStatus,
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)


# ---------------------------------------------------------------------------
# Isolated Test Database Fixture
# ---------------------------------------------------------------------------
@pytest.fixture
def isolated_db() -> Generator[Session, None, None]:
    """Provides a pristine, isolated in-memory SQLite database session."""
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    session_factory = sessionmaker(bind=engine)
    session = session_factory()
    try:
        yield session
    finally:
        session.close()
        Base.metadata.drop_all(engine)
        engine.dispose()


# ---------------------------------------------------------------------------
# 1. Role Definitions & Backward Compatibility Tests
# ---------------------------------------------------------------------------
class TestMultilingualRoleDefinitions:
    """Verifies that all 13 new roles and 16 existing roles exist with proper capabilities."""

    def test_total_role_count_and_completeness(self):
        """ReviewerRole enum must contain exactly 29 canonical roles."""
        assert len(ReviewerRole) == 29

    def test_existing_roles_preserved(self):
        """All 16 baseline roles must remain intact with identical string values."""
        expected_existing = [
            "SANSKRIT_TEXTUAL", "VEDIC_RECENSION", "SANSKRIT_GRAMMAR", "AWADHI_SPECIALIST",
            "HINDI_TRANSLATOR", "TELUGU_TRANSLATOR", "TAMIL_TRANSLATOR", "KANNADA_TRANSLATOR",
            "MARATHI_TRANSLATOR", "BENGALI_TRANSLATOR", "GUJARATI_TRANSLATOR", "MALAYALAM_TRANSLATOR",
            "ODIA_TRANSLATOR", "TRADITIONAL_COMMENTARY", "LEGAL_COPYRIGHT", "EDITORIAL_BOARD",
        ]
        for role_name in expected_existing:
            assert hasattr(ReviewerRole, role_name), f"Missing existing role: {role_name}"
            role = getattr(ReviewerRole, role_name)
            assert role.value == role_name

    def test_all_13_new_roles_defined(self):
        """All 13 new multilingual translator roles must be defined."""
        new_roles = [
            "ENGLISH_TRANSLATOR", "ASSAMESE_TRANSLATOR", "BODO_TRANSLATOR", "DOGRI_TRANSLATOR",
            "KASHMIRI_TRANSLATOR", "KONKANI_TRANSLATOR", "MAITHILI_TRANSLATOR", "MANIPURI_TRANSLATOR",
            "NEPALI_TRANSLATOR", "PUNJABI_TRANSLATOR", "SANTALI_TRANSLATOR", "SINDHI_TRANSLATOR",
            "URDU_TRANSLATOR",
        ]
        for role_name in new_roles:
            assert hasattr(ReviewerRole, role_name), f"Missing new role: {role_name}"
            role = getattr(ReviewerRole, role_name)
            assert role.value == role_name

    def test_role_capabilities_dictionary_covers_all_29_roles(self):
        """Every role in ReviewerRole must have documented capabilities in MultilingualRBACEngine."""
        for role in ReviewerRole:
            assert role in MultilingualRBACEngine.ROLE_CAPABILITIES, f"Role {role} missing capabilities definition"
            caps = MultilingualRBACEngine.ROLE_CAPABILITIES[role]
            assert isinstance(caps, set)
            assert len(caps) >= 1, f"Role {role} has empty capabilities"


# ---------------------------------------------------------------------------
# 2. Language-to-Role Mapping & Script Compatibility Tests
# ---------------------------------------------------------------------------
class TestLanguageRoleMapping:
    """Verifies bidirectional mapping for all 22 Eighth Schedule languages + English + Awadhi."""

    def test_all_22_scheduled_languages_mapped(self):
        """All 22 Eighth Schedule languages must resolve to a valid ReviewerRole."""
        scheduled_codes = [
            "sa", "hi", "te", "ta", "kn", "ml", "bn", "gu", "mr", "or",
            "as", "brx", "doi", "ks", "kok", "mai", "mni", "ne", "pa", "sat", "sd", "ur",
        ]
        for code in scheduled_codes:
            role = MultilingualRBACEngine.get_role_for_language(code)
            assert role is not None, f"Language '{code}' failed to resolve to a ReviewerRole"
            assert isinstance(role, ReviewerRole)

    def test_bridge_and_specialized_languages_mapped(self):
        """English and Awadhi must resolve correctly."""
        assert MultilingualRBACEngine.get_role_for_language("en") == ReviewerRole.ENGLISH_TRANSLATOR
        assert MultilingualRBACEngine.get_role_for_language("eng") == ReviewerRole.ENGLISH_TRANSLATOR
        assert MultilingualRBACEngine.get_role_for_language("awa") == ReviewerRole.AWADHI_SPECIALIST

    def test_reverse_role_to_language_mapping(self):
        """Reverse lookup must return the corresponding ISO codes."""
        assert "hi" in MultilingualRBACEngine.get_languages_for_role(ReviewerRole.HINDI_TRANSLATOR)
        assert "as" in MultilingualRBACEngine.get_languages_for_role(ReviewerRole.ASSAMESE_TRANSLATOR)
        assert "ks" in MultilingualRBACEngine.get_languages_for_role(ReviewerRole.KASHMIRI_TRANSLATOR)
        assert "ur" in MultilingualRBACEngine.get_languages_for_role(ReviewerRole.URDU_TRANSLATOR)
        assert "sat" in MultilingualRBACEngine.get_languages_for_role(ReviewerRole.SANTALI_TRANSLATOR)

    def test_rtl_and_indigenous_script_compatibility(self):
        """RTL scripts (Arab) and indigenous scripts (Olck, Mtei) must be registered for roles."""
        ks_scripts = MultilingualRBACEngine.get_supported_scripts_for_role(ReviewerRole.KASHMIRI_TRANSLATOR)
        assert "Arab" in ks_scripts

        ur_scripts = MultilingualRBACEngine.get_supported_scripts_for_role(ReviewerRole.URDU_TRANSLATOR)
        assert "Arab" in ur_scripts

        sd_scripts = MultilingualRBACEngine.get_supported_scripts_for_role(ReviewerRole.SINDHI_TRANSLATOR)
        assert "Arab" in sd_scripts

        sat_scripts = MultilingualRBACEngine.get_supported_scripts_for_role(ReviewerRole.SANTALI_TRANSLATOR)
        assert "Olck" in sat_scripts

        mni_scripts = MultilingualRBACEngine.get_supported_scripts_for_role(ReviewerRole.MANIPURI_TRANSLATOR)
        assert "Mtei" in mni_scripts or "Beng" in mni_scripts

    def test_invalid_language_code_resolution(self):
        """Invalid or unrecognized language codes return None."""
        assert MultilingualRBACEngine.get_role_for_language("invalid_xyz") is None
        assert MultilingualRBACEngine.get_role_for_language("fr") is None


# ---------------------------------------------------------------------------
# 3. Reviewer Authorization & Access Rejection Tests
# ---------------------------------------------------------------------------
class TestReviewerAuthorization:
    """Verifies authorized reviewer access and rejection of unauthorized actions."""

    def test_authorized_reviewer_via_primary_role(self, isolated_db: Session):
        """Reviewer with primary role ASSAMESE_TRANSLATOR is authorized for 'as'."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-AS-001",
            full_name="Assamese Scholar",
            primary_role=ReviewerRole.ASSAMESE_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
            account_category="SYNTHETIC_TEST_PERSONA",
        )
        isolated_db.add(reviewer)
        isolated_db.commit()

        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "as") is True
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "asm") is True
        # Unauthorized for other languages
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "hi") is False
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "te") is False

    def test_authorized_reviewer_via_secondary_role(self, isolated_db: Session):
        """Reviewer with secondary role PUNJABI_TRANSLATOR is authorized for 'pa'."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-MULTI-001",
            full_name="Bilingual Scholar",
            primary_role=ReviewerRole.HINDI_TRANSLATOR,
            secondary_roles=["PUNJABI_TRANSLATOR"],
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        isolated_db.add(reviewer)
        isolated_db.commit()

        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "hi") is True
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "pa") is True
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "ta") is False

    def test_authorized_reviewer_via_language_proficiency(self, isolated_db: Session):
        """Reviewer with qualified proficiency rating is authorized."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-PROF-001",
            full_name="Proficient Scholar",
            primary_role=ReviewerRole.SANSKRIT_TEXTUAL,
            language_proficiency={"mai": "SCHOLAR", "kok": "NATIVE", "fr": "BASIC"},
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        isolated_db.add(reviewer)
        isolated_db.commit()

        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "mai") is True
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "kok") is True
        # BASIC proficiency is not qualified for scholarly review
        assert MultilingualRBACEngine.is_reviewer_authorized_for_language(reviewer, "fr") is False

    def test_editorial_board_universal_authorization(self, isolated_db: Session):
        """Editorial board members have universal language oversight."""
        editor = ReviewerProfile(
            reviewer_id="REV-ED-001",
            full_name="Chief Editor",
            primary_role=ReviewerRole.EDITORIAL_BOARD,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        isolated_db.add(editor)
        isolated_db.commit()

        for lang in ["hi", "te", "as", "ks", "ur", "sat", "en", "sa"]:
            assert MultilingualRBACEngine.is_reviewer_authorized_for_language(editor, lang) is True

    def test_unverified_reviewer_approval_blocked(self, isolated_db: Session):
        """Unverified reviewers cannot approve even authorized languages."""
        unv = ReviewerProfile(
            reviewer_id="REV-UNV-001",
            full_name="Unverified Applicant",
            primary_role=ReviewerRole.KASHMIRI_TRANSLATOR,
            is_credentials_verified=False,
            verification_status="PENDING_VERIFICATION",
            is_active=True,
        )
        isolated_db.add(unv)
        isolated_db.commit()

        can_approve, reason = MultilingualRBACEngine.can_reviewer_approve_language(unv, "ks")
        assert can_approve is False
        assert "not in verified status" in reason

    def test_demonstration_reviewer_approval_blocked(self, isolated_db: Session):
        """Demonstration accounts cannot issue canonical approvals."""
        demo = ReviewerProfile(
            reviewer_id="REV-DEMO-001",
            full_name="Demo Harness",
            primary_role=ReviewerRole.URDU_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_demonstration=True,
            account_category="DEMONSTRATION_HARNESS",
            is_active=True,
        )
        isolated_db.add(demo)
        isolated_db.commit()

        can_approve, reason = MultilingualRBACEngine.can_reviewer_approve_language(demo, "ur")
        assert can_approve is False
        assert "demonstration harness" in reason

    def test_auth_service_require_language_permission(self, isolated_db: Session):
        """PermissionGuard.require_language_permission raises PermissionDeniedError on unauthorized language."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-HI-001",
            full_name="Hindi Scholar",
            primary_role=ReviewerRole.HINDI_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        # Should succeed for Hindi
        PermissionGuard.require_language_permission(reviewer, "hi", action="review")

        # Should raise for Telugu
        with pytest.raises(PermissionDeniedError):
            PermissionGuard.require_language_permission(reviewer, "te", action="review")


# ---------------------------------------------------------------------------
# 4. Anti-Self-Approval & Safeguard Enforcement Tests
# ---------------------------------------------------------------------------
class TestAntiSelfApprovalAndSafeguards:
    """Verifies that translators cannot approve their own translations."""

    def test_self_approval_by_name_rejected(self, isolated_db: Session):
        """Reviewer cannot approve translation where translator field matches reviewer name."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-TRANSLATOR-01",
            full_name="Pandit Govind Sharma",
            primary_role=ReviewerRole.HINDI_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        translation = Translation(
            id=101,
            verse_id=1,
            target_language="hi",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Sample text",
            translator="Pandit Govind Sharma",
            review_status=ReviewStatus.DRAFT,
        )

        with pytest.raises(SelfApprovalViolationError) as exc_info:
            MultilingualRBACEngine.check_self_approval_restriction(reviewer, translation)
        assert "Self-approval prohibited" in str(exc_info.value)

    def test_self_approval_by_id_rejected(self, isolated_db: Session):
        """Reviewer cannot approve translation where translator field matches reviewer_id."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-PUNJABI-77",
            full_name="Giani Singh",
            primary_role=ReviewerRole.PUNJABI_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        translation = Translation(
            id=102,
            verse_id=1,
            target_language="pa",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Sample Punjabi text",
            translator="REV-PUNJABI-77",
            review_status=ReviewStatus.DRAFT,
        )

        with pytest.raises(SelfApprovalViolationError):
            MultilingualRBACEngine.check_self_approval_restriction(reviewer, translation)

    def test_non_self_approval_allowed(self, isolated_db: Session):
        """Reviewer can approve translation authored by someone else or AI engine."""
        reviewer = ReviewerProfile(
            reviewer_id="REV-HINDI-02",
            full_name="Dr. Sunita Varma",
            primary_role=ReviewerRole.HINDI_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        translation = Translation(
            id=103,
            verse_id=1,
            target_language="hi",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Sample Hindi text",
            translator="AI Translation Engine v2.0",
            review_status=ReviewStatus.DRAFT,
        )

        # Should not raise
        MultilingualRBACEngine.check_self_approval_restriction(reviewer, translation)

    def test_review_action_engine_blocks_unauthorized_language(self, isolated_db: Session):
        """ReviewActionEngine.execute_action raises ReviewActionError on unauthorized language."""
        cat = Category(id=1, slug="stotra", name="Stotra")
        isolated_db.add(cat)
        isolated_db.flush()

        # Setup text, verse, translation, and reviewer
        text = Text(
            id=1,
            content_id="VEDA-TXT-TEST",
            uuid=str(uuid.uuid4()),
            canonical_title="Test Text",
            devanagari_title="परीक्षण पाठ",
            content_hash="mock_hash_1",
            primary_category_id=1,
            original_language="sa",
        )
        verse = Verse(id=1, text_id=1, verse_id="VEDA-VR-TEST-001", verse_number=1, devanagari_text="ॐ नमः शिवाय")
        translation = Translation(
            id=1,
            verse_id=1,
            target_language="te",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Telugu translation text",
            translator="AI Engine",
            review_status=ReviewStatus.DRAFT,
        )
        # Reviewer is only qualified for Hindi
        reviewer = ReviewerProfile(
            id=1,
            reviewer_id="REV-HI-ONLY",
            full_name="Hindi Only Scholar",
            primary_role=ReviewerRole.HINDI_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        isolated_db.add_all([text, verse, translation, reviewer])
        isolated_db.commit()

        action_data = ReviewActionLogCreate(
            translation_id=1,
            verse_id=1,
            reviewer_id=1,
            action_type=ReviewActionType.APPROVE,
            previous_status="DRAFT",
            new_status="APPROVED",
            scholarly_commentary="Unauthorized attempt to approve Telugu translation.",
        )

        with pytest.raises(ReviewActionError) as exc_info:
            ReviewActionEngine.execute_action(isolated_db, action_data)
        assert "Unauthorized language" in str(exc_info.value)
        assert "not authorized to review target language 'te'" in str(exc_info.value)

    def test_review_action_engine_blocks_self_approval(self, isolated_db: Session):
        """ReviewActionEngine.execute_action raises ReviewActionError on self-approval attempt."""
        cat = isolated_db.query(Category).filter_by(id=1).first()
        if not cat:
            cat = Category(id=1, slug="stotra", name="Stotra")
            isolated_db.add(cat)
            isolated_db.flush()

        text = Text(
            id=2,
            content_id="VEDA-TXT-TEST2",
            uuid=str(uuid.uuid4()),
            canonical_title="Test Text 2",
            devanagari_title="परीक्षण पाठ २",
            content_hash="mock_hash_2",
            primary_category_id=1,
            original_language="sa",
        )
        verse = Verse(id=2, text_id=2, verse_id="VEDA-VR-TEST-002", verse_number=1, devanagari_text="गायत्री मन्त्र")
        reviewer = ReviewerProfile(
            id=2,
            reviewer_id="REV-AS-02",
            full_name="Dr. Bhupen Barua",
            primary_role=ReviewerRole.ASSAMESE_TRANSLATOR,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            is_active=True,
        )
        translation = Translation(
            id=2,
            verse_id=2,
            target_language="as",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Assamese translation",
            translator="Dr. Bhupen Barua",
            review_status=ReviewStatus.DRAFT,
        )
        isolated_db.add_all([text, verse, translation, reviewer])
        isolated_db.commit()

        action_data = ReviewActionLogCreate(
            translation_id=2,
            verse_id=2,
            reviewer_id=2,
            action_type=ReviewActionType.APPROVE,
            previous_status="DRAFT",
            new_status="APPROVED",
            scholarly_commentary="Self-approval attempt.",
        )

        with pytest.raises(ReviewActionError) as exc_info:
            ReviewActionEngine.execute_action(isolated_db, action_data)
        assert "Self-approval prohibited" in str(exc_info.value)


# ---------------------------------------------------------------------------
# 5. Database Migration Lifecycle Tests (Disposable Database)
# ---------------------------------------------------------------------------
class TestDatabaseMigrationUpgradeDowngrade:
    """Tests Alembic upgrade to e3a7b1c9f2d5 and downgrade back to 9f3c8a1b2d4e on disposable DB."""

    def test_migration_upgrade_and_downgrade(self):
        """Tests that e3a7b1c9f2d5 upgrades cleanly and downgrades reliably."""
        with tempfile.NamedTemporaryFile(suffix=".db", delete=False) as tmp:
            tmp_path = tmp.name

        try:
            norm_path = tmp_path.replace("\\", "/")
            cfg = Config("alembic.ini")
            cfg.set_main_option("sqlalchemy.url", f"sqlite:///{norm_path}")

            # Upgrade to previous head first (9f3c8a1b2d4e)
            command.upgrade(cfg, "9f3c8a1b2d4e")

            # Upgrade to new head (e3a7b1c9f2d5)
            command.upgrade(cfg, "e3a7b1c9f2d5")

            # Verify version table in disposable database
            import sqlite3
            conn = sqlite3.connect(tmp_path)
            cur = conn.cursor()
            cur.execute("SELECT version_num FROM alembic_version")
            v_after_up = cur.fetchone()[0]
            assert v_after_up == "e3a7b1c9f2d5"

            # Downgrade back to 9f3c8a1b2d4e
            command.downgrade(cfg, "9f3c8a1b2d4e")
            cur.execute("SELECT version_num FROM alembic_version")
            v_after_down = cur.fetchone()[0]
            assert v_after_down == "9f3c8a1b2d4e"
            conn.close()

        finally:
            if os.path.exists(tmp_path):
                os.remove(tmp_path)


# ---------------------------------------------------------------------------
# 6. Publication Gate & Safeguards Tests
# ---------------------------------------------------------------------------
class TestPublicationGateSafeguards:
    """Verifies that publication rule PUB-010 remains an active blocker for unreviewed content."""

    def test_pub010_blocks_draft_translations_from_commercial_release(self, isolated_db: Session):
        """Rule PUB-010 must block publishing of DRAFT translations regardless of role addition."""
        # Unapproved translations cannot pass publication gate
        text = Text(
            id=99,
            content_id="VEDA-TXT-SAMPLE",
            uuid=str(uuid.uuid4()),
            canonical_title="Sample Text",
            devanagari_title="नमूना पाठ",
            content_hash="mock_hash_sample",
            original_language="sa",
            original_script="Devanagari",
            rights_clearance_status=RightsClearanceStatus.AMBER_RESTRICTED,
            acquisition_status=AcquisitionStatus.VERIFIED_SOURCE,
            editorial_approval_status=EditorialApprovalStatus.DRAFT,
            publication_status=PublicationStatus.DRAFT,
            textual_verification_status=TextualVerificationStatus.UNVERIFIED,
            translation_status=TranslationStatus.DRAFT,
        )
        report = PublicationPreflightGate.evaluate(text, target_channel="commercial_release")
        assert report.can_publish is False
        pub010_check = next((c for c in report.checks if c.rule_id == "PUB-010"), None)
        assert pub010_check is not None
        assert pub010_check.passed is False
        assert pub010_check.severity == GateSeverity.BLOCKER
