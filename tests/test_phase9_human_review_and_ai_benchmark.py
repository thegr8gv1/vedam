"""
Unit, Integration, and Security Tests for Phase 9:
Human Scholarly Review Architecture, Production Security Hardening,
and AI-Assisted Sanskrit Intelligence Benchmarking.
"""

from datetime import datetime, timedelta, timezone
import pytest
from sqlalchemy.orm import Session

from automation.ai_sanskrit_engine.evaluator import AIIntelligenceBenchmarkEngine
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from automation.rights.approval_workflow import (
    EditorialApprovalStatus,
    PublicationStatus,
    RightsClearanceStatus,
    TextualVerificationStatus,
    TranslationStatus,
)
from automation.validators.publication_gate import GateSeverity, PublicationPreflightGate
from automation.workbench.auth import (
    AccountLockedError,
    AuthenticationRequiredError,
    AuthService,
    DEFAULT_ABSOLUTE_SESSION_HOURS,
    DEFAULT_IDLE_TIMEOUT_MINUTES,
    generate_csrf_token,
    get_secure_cookie_config,
    hash_password,
    PermissionDeniedError,
    PermissionGuard,
    RateLimiter,
    validate_csrf_token,
    verify_and_upgrade_password,
    verify_password,
)
from automation.workbench.backfill_queue import BackfillQueueEngine
from automation.workbench.onboarding import OnboardingGovernanceError, ReviewerOnboardingService
from automation.workbench.review_action_engine import ReviewActionEngine, ReviewActionError
from automation.workbench.review_pilot import ScholarlyReviewPilot
from database.connection import get_db_session
from database.models import (
    ReviewActionLog,
    ReviewActionType,
    ReviewStatus,
    ReviewerFeedbackCategory,
    ReviewerProfile,
    ReviewerRole,
    ReviewerSession,
    Text,
    TextualDispute,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)
from database.schemas import ReviewActionLogCreate, ReviewerProfileCreate, TextualDisputeCreate


@pytest.fixture(scope="module")
def db_session():
    with get_db_session() as session:
        yield session


class TestPhase9ProductionSecurityHardening:
    """Validates Argon2id password hashing, session rotation, idle timeouts, and cookie security."""

    def test_argon2id_hashing_and_verification(self):
        pwd = "ScholarlySecurePassword#2026"
        hashed = hash_password(pwd)
        assert hashed.startswith("$argon2id$v=19$m=65536,t=3,p=4$")
        assert verify_password(pwd, hashed) is True
        assert verify_password("WrongPassword123!", hashed) is False

    def test_password_hash_lazy_upgrade_from_pbkdf2(self):
        # Create a legacy PBKDF2 hash
        import hashlib, secrets
        salt = secrets.token_bytes(16)
        pwd = "LegacyPasswordToUpgrade#2026"
        derived = hashlib.pbkdf2_hmac("sha256", pwd.encode("utf-8"), salt, 100000)
        legacy_hash = f"pbkdf2_sha256$100000${salt.hex()}${derived.hex()}"

        # Verify and upgrade
        is_valid, upgraded = verify_and_upgrade_password(pwd, legacy_hash)
        assert is_valid is True
        assert upgraded is not None
        assert upgraded.startswith("$argon2id$v=19$m=65536,t=3,p=4$")
        assert verify_password(pwd, upgraded) is True

    def test_secure_cookie_attributes_configuration(self):
        token = "test_token_abcdef123456"
        cookie = get_secure_cookie_config(token, secure=True)
        assert cookie["key"] == "vedam_session"
        assert cookie["value"] == token
        assert cookie["httponly"] is True
        assert cookie["samesite"] == "Strict"
        assert cookie["secure"] is True
        assert cookie["max_age"] == 12 * 3600
        assert cookie["path"] == "/"

    def test_session_idle_timeout_and_absolute_expiration(self, db_session: Session):
        admin = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-ADMIN-001").first()
        now_utc = datetime.now(timezone.utc)

        # Create active session
        sess = ReviewerSession(
            session_token="test_idle_timeout_token",
            reviewer_id=admin.id,
            created_at=now_utc,
            expires_at=now_utc + timedelta(hours=12),
            last_activity_at=now_utc,
            absolute_expires_at=now_utc + timedelta(hours=12),
            is_revoked=False,
        )
        db_session.add(sess)
        db_session.commit()

        # 1. Normal validation updates last_activity_at
        rev = AuthService.validate_session(db_session, "test_idle_timeout_token")
        assert rev.reviewer_id == "REV-ADMIN-001"

        # 2. Simulate 35 minutes idle inactivity
        sess.last_activity_at = now_utc - timedelta(minutes=35)
        db_session.commit()

        with pytest.raises(AuthenticationRequiredError, match="Session expired due to inactivity"):
            AuthService.validate_session(db_session, "test_idle_timeout_token")

        # 3. Simulate absolute expiration (12 hours reached)
        sess.is_revoked = False
        sess.last_activity_at = now_utc  # active
        sess.absolute_expires_at = now_utc - timedelta(minutes=5)
        db_session.commit()

        with pytest.raises(AuthenticationRequiredError, match="Session has expired"):
            AuthService.validate_session(db_session, "test_idle_timeout_token")

        db_session.delete(sess)
        db_session.commit()

    def test_session_rotation(self, db_session: Session):
        admin = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-ADMIN-001").first()
        now_utc = datetime.now(timezone.utc)

        old_sess = ReviewerSession(
            session_token="token_to_rotate_123",
            reviewer_id=admin.id,
            created_at=now_utc,
            expires_at=now_utc + timedelta(hours=12),
            last_activity_at=now_utc,
            absolute_expires_at=now_utc + timedelta(hours=12),
            is_revoked=False,
        )
        db_session.add(old_sess)
        db_session.commit()

        # Rotate session
        rev, new_sess = AuthService.rotate_session(db_session, "token_to_rotate_123")
        assert rev.id == admin.id
        assert new_sess.session_token != "token_to_rotate_123"
        assert old_sess.is_revoked is True
        assert new_sess.is_revoked is False

        db_session.delete(old_sess)
        db_session.delete(new_sess)
        db_session.commit()


class TestPhase9ReviewerAuthenticityAndCompetency:
    """Validates strict isolation of synthetic personas and fine-grained discipline competency."""

    def test_reviewer_census_authenticity_breakdown(self, db_session: Session):
        census = ReviewerOnboardingService.get_reviewer_census(db_session)
        assert census["total_profiles"] >= 6
        # Zero living human scholars have completed physical onboarding yet
        assert census["real_human_scholars"] == 0
        assert census["synthetic_test_personas"] >= 4
        assert census["demonstration_accounts"] >= 1
        assert census["verified_production_reviewers"] >= 4

    def test_permission_guard_blocks_synthetic_persona_from_human_approval(self, db_session: Session):
        vedic_persona = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-PROD-VEDIC").first()
        assert vedic_persona.account_category == "SYNTHETIC_TEST_PERSONA"
        assert vedic_persona.is_human_verified is False

        with pytest.raises(PermissionDeniedError, match="synthetic test persona"):
            PermissionGuard.require_human_scholar(vedic_persona)

    def test_competency_validation_enforces_disciplinary_boundaries(self, db_session: Session):
        vedic_rev = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-PROD-VEDIC").first()
        awadhi_rev = db_session.query(ReviewerProfile).filter_by(reviewer_id="REV-PROD-AWADHI").first()

        # Vedic reviewer is authorized for Vedic texts
        assert ReviewerOnboardingService.validate_reviewer_competency(vedic_rev, content_genre="Vedic Samhita") is True

        # Vedic reviewer is NOT authorized for Awadhi vernacular poetry
        with pytest.raises(OnboardingGovernanceError, match="lacks verified Awadhi specialization"):
            ReviewerOnboardingService.validate_reviewer_competency(vedic_rev, content_genre="Awadhi Devotional")

        # Awadhi reviewer is authorized for Awadhi
        assert ReviewerOnboardingService.validate_reviewer_competency(awadhi_rev, content_genre="Awadhi literature") is True

        # Awadhi reviewer is NOT authorized for Vedic Samhita
        with pytest.raises(OnboardingGovernanceError, match="lacks verified Vedic Recension credentials"):
            ReviewerOnboardingService.validate_reviewer_competency(awadhi_rev, content_genre="Vedic Samhita")


class TestPhase9ExpandedHumanReviewPilot:
    """Validates the 3-composition review pilot, version increments, and textual disputes."""

    def test_original_sacred_text_immutability(self, db_session: Session):
        # Fetch Gayatri verse
        t = db_session.query(Text).filter_by(content_id="VEDA-TXT-00006").first()
        v = db_session.query(Verse).filter_by(text_id=t.id, verse_number=1).first()
        original_devanagari = v.devanagari_text

        # Execute pilot review action
        res = ScholarlyReviewPilot.execute_pilot(db_session)
        assert len(res["review_actions_logged"]) >= 7

        # Confirm original Devanagari is 100% unchanged
        db_session.refresh(v)
        assert v.devanagari_text == original_devanagari

    def test_textual_dispute_preserves_competing_traditional_interpretations(self, db_session: Session):
        dispute = db_session.query(TextualDispute).filter_by(dispute_nature="Sampradaya Exegetical Dispute on 'Tat Savitur Vareṇyam'").first()
        assert dispute is not None
        assert "Advaita" in dispute.opinion_a_json["school"]
        assert "Vishishtadvaita" in dispute.opinion_b_json["school"]
        assert dispute.opinion_a_json["citation"] is not None
        assert dispute.opinion_b_json["citation"] is not None


class TestPhase9AILinguisticBenchmarking:
    """Validates 30-item reference benchmark dataset and comparative provider scansion."""

    def test_benchmark_reference_dataset_structure_and_export(self):
        engine = AIIntelligenceBenchmarkEngine
        assert len(engine.BENCHMARK_DATASET) == 30

        vedic_samples = [s for s in engine.BENCHMARK_DATASET if s.tradition == "Vedic Sanskrit"]
        classical_samples = [s for s in engine.BENCHMARK_DATASET if s.tradition == "Classical Sanskrit"]
        awadhi_samples = [s for s in engine.BENCHMARK_DATASET if s.tradition == "Awadhi"]

        assert len(vedic_samples) == 10
        assert len(classical_samples) == 10
        assert len(awadhi_samples) == 10

        out_path = engine.export_reference_dataset()
        assert out_path.endswith(".json")

    def test_panini_rule_engine_deterministic_metrics(self):
        res = AIIntelligenceBenchmarkEngine.evaluate_panini_rule_engine()
        assert res.total_samples == 30
        assert res.overall_accuracy >= 0.95
        assert res.human_correction_rate <= 0.05
        assert res.avg_latency_ms < 5.0  # Sub-5ms execution
        assert res.estimated_cost_usd == 0.0
        assert res.is_suggestion_only is True

    def test_gemini_sanskrit_metrics(self):
        res = AIIntelligenceBenchmarkEngine.evaluate_gemini_sanskrit()
        assert res.total_samples == 30
        assert res.overall_accuracy >= 0.85
        assert res.human_correction_rate <= 0.15
        assert res.is_suggestion_only is True

    def test_generic_baseline_llm_high_correction_rate(self):
        res = AIIntelligenceBenchmarkEngine.evaluate_generic_baseline_llm()
        assert res.total_samples == 30
        # Generic LLMs suffer from high correction rate due to hallucinated Sandhi
        assert res.human_correction_rate >= 0.40


class TestPhase9TranslationViewBackfillQueue:
    """Validates the 752 legacy translation record audit and 5-record pilot proposal."""

    def test_backfill_queue_audit_exact_752_records(self, db_session: Session):
        audit = BackfillQueueEngine.audit_legacy_gaps(db_session)
        assert audit["total_legacy_gap_records"] == 752
        assert "Tier 1: Canonical Vedic Mantras & Suktams" in audit["tier_distribution"]

    def test_controlled_backfill_pilot_proposal(self, db_session: Session):
        prop = BackfillQueueEngine.generate_controlled_backfill_pilot_proposal(db_session)
        assert len(prop["pilot_records"]) == 5
        for item in prop["pilot_records"]:
            assert item["proposed_literal_view"]["is_suggestion_only"] is True
            assert item["proposed_literal_view"]["status"] == "DRAFT"
            assert item["proposed_tatparya_view"]["is_suggestion_only"] is True


class TestPhase9PublicationGovernanceOrthogonality:
    """Validates orthogonal decoupling of legal rights, text verification, and translation approval."""

    def test_publication_gate_orthogonality_scholarly_vs_commercial(self, db_session: Session):
        text = db_session.query(Text).filter_by(content_id="VEDA-TXT-00006").first()

        # Scholarly review channel passes
        rep_scholarly = PublicationPreflightGate.evaluate(text, target_channel="scholarly_review")
        assert rep_scholarly.can_publish is True
        assert rep_scholarly.failed_blockers == 0

        # Commercial release channel is strictly blocked because translations are in DRAFT
        rep_comm = PublicationPreflightGate.evaluate(text, target_channel="commercial_release")
        assert rep_comm.can_publish is False
        assert rep_comm.failed_blockers >= 1
        assert "TRANSLATION_APPROVAL_CHECK" in [c.rule_name for c in rep_comm.checks if not c.passed]
