"""
Vedic Heritage Platform — Phase 8 Automated Test Suite
Validates Scholarly Review Workbench production readiness, authentication security,
RBAC permissions, real reviewer onboarding & credential governance, demonstration account barriers,
three-composition pilot execution, Sanskrit AI intelligence validation, source citations,
TranslationView gap audit (752 records), and security protections.
"""

from datetime import datetime, timedelta, timezone
import pytest
from sqlalchemy.orm import Session

from automation.ai_sanskrit_engine.anvaya import AnvayaEngine
from automation.ai_sanskrit_engine.chandas import ChandasEngine
from automation.ai_sanskrit_engine.evaluator import AIModelEvaluator
from automation.ai_sanskrit_engine.grammar import GrammarEngine
from automation.ai_sanskrit_engine.padachheda import PadachhedaEngine
from automation.ai_sanskrit_engine.pronunciation import PronunciationEngine
from automation.ai_sanskrit_engine.provider import AIAnnotationResult, MockAIProvider
from automation.ai_sanskrit_engine.source_research import SourceResearchEngine
from automation.ai_sanskrit_engine.word_meaning import WordMeaningEngine
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from automation.workbench.api import WorkbenchComparisonEngine
from automation.workbench.assignment_engine import AssignmentEngine, AssignmentGovernanceError
from automation.workbench.auth import (
    AccountLockedError,
    AuthError,
    AuthService,
    AuthenticationRequiredError,
    PermissionDeniedError,
    PermissionGuard,
    RateLimitExceededError,
    RateLimiter,
    generate_csrf_token,
    hash_password,
    validate_csrf_token,
    verify_password,
)
from automation.workbench.backfill_queue import BackfillQueueEngine
from automation.workbench.conflict_engine import ConflictResolutionEngine
from automation.workbench.onboarding import OnboardingGovernanceError, ReviewerOnboardingService
from automation.workbench.review_action_engine import ReviewActionEngine, ReviewActionError
from automation.workbench.review_pilot import ScholarlyReviewPilot
from database.connection import get_db_session
from database.models import (
    AIAnnotationType,
    AssignmentPriority,
    AssignmentStatus,
    AuthAuditLog,
    DisputeStatus,
    ReviewActionLog,
    ReviewActionType,
    ReviewAssignment,
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
from database.schemas import (
    ReviewActionLogCreate,
    ReviewAssignmentCreate,
    ReviewerProfileCreate,
    TextualDisputeCreate,
)


@pytest.fixture(autouse=True)
def cleanup_test_reviewers():
    """Teardown fixture clearing test reviewers and assignments."""
    yield
    with get_db_session() as db:
        # Delete test assignments
        test_rev_ids = [
            r.id for r in db.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-P8TEST-%")).all()
        ]
        if test_rev_ids:
            db.query(ReviewAssignment).filter(ReviewAssignment.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
            db.query(ReviewActionLog).filter(ReviewActionLog.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
            db.query(ReviewerSession).filter(ReviewerSession.reviewer_id.in_(test_rev_ids)).delete(synchronize_session=False)
            db.query(ReviewerProfile).filter(ReviewerProfile.id.in_(test_rev_ids)).delete(synchronize_session=False)
        db.commit()


# ===========================================================================
# 1. AUTHENTICATION & SECURITY TESTS (Part 2A)
# ===========================================================================

def test_password_hashing_and_verification():
    raw_pwd = "VedicScholar#Secure2026"
    hashed = hash_password(raw_pwd)
    assert hashed.startswith("pbkdf2_sha256$100000$")
    assert verify_password(raw_pwd, hashed) is True
    assert verify_password("WrongPassword!", hashed) is False
    assert verify_password("", hashed) is False


def test_authentication_success_and_session_lifecycle():
    with get_db_session() as db:
        applicant = ReviewerOnboardingService.register_applicant(
            db,
            ReviewerProfileCreate(
                reviewer_id="REV-P8TEST-AUTH01",
                full_name="Dr. Test Authenticated Scholar",
                primary_role=ReviewerRole.SANSKRIT_TEXTUAL,
                email="auth01@test.org",
            ),
            raw_password="TestPassword123#",
        )
        db.commit()

        # Login
        reviewer, session_obj = AuthService.authenticate(
            db,
            reviewer_id="REV-P8TEST-AUTH01",
            raw_password="TestPassword123#",
            client_ip="127.0.0.1",
        )
        assert reviewer.id == applicant.id
        assert len(session_obj.session_token) > 20
        assert session_obj.is_revoked is False

        # Validate Session
        validated_reviewer = AuthService.validate_session(db, session_obj.session_token)
        assert validated_reviewer.reviewer_id == "REV-P8TEST-AUTH01"

        # Logout / Revocation
        AuthService.revoke_session(db, session_obj.session_token)
        with pytest.raises(AuthenticationRequiredError, match="Session has been revoked"):
            AuthService.validate_session(db, session_obj.session_token)


def test_account_lockout_after_consecutive_failures():
    with get_db_session() as db:
        applicant = ReviewerOnboardingService.register_applicant(
            db,
            ReviewerProfileCreate(
                reviewer_id="REV-P8TEST-LOCKOUT",
                full_name="Sri Test Lockout Scholar",
                primary_role=ReviewerRole.HINDI_TRANSLATOR,
            ),
            raw_password="CorrectPassword123#",
        )
        db.commit()

        # Attempt 4 failed logins
        for i in range(4):
            with pytest.raises(AuthenticationRequiredError):
                AuthService.authenticate(db, "REV-P8TEST-LOCKOUT", "BadPassword")
        
        applicant_profile = db.query(ReviewerProfile).filter_by(reviewer_id="REV-P8TEST-LOCKOUT").first()
        assert applicant_profile.failed_login_attempts == 4
        assert applicant_profile.is_locked is False

        # 5th failed login triggers lock
        with pytest.raises(AuthenticationRequiredError):
            AuthService.authenticate(db, "REV-P8TEST-LOCKOUT", "BadPassword")

        db.refresh(applicant_profile)
        assert applicant_profile.is_locked is True

        # Subsequent login raises AccountLockedError
        with pytest.raises(AccountLockedError, match="Account is locked"):
            AuthService.authenticate(db, "REV-P8TEST-LOCKOUT", "CorrectPassword123#")

        # Admin unlocks account
        AuthService.unlock_account(db, "REV-P8TEST-LOCKOUT", admin_name="Admin Sharma")
        db.refresh(applicant_profile)
        assert applicant_profile.is_locked is False
        assert applicant_profile.failed_login_attempts == 0


def test_sliding_window_rate_limiting():
    limiter = RateLimiter()
    key = "test_rate_ip_192.168.1.100"
    for _ in range(5):
        assert limiter.check_rate_limit(key, max_requests=5, window_seconds=10) is True

    # 6th request violates limit
    with pytest.raises(RateLimitExceededError, match="Rate limit exceeded"):
        limiter.check_rate_limit(key, max_requests=5, window_seconds=10)


def test_csrf_token_generation_and_validation():
    session_token = "cryptographic_random_session_token_xyz123"
    csrf = generate_csrf_token(session_token)
    assert len(csrf) == 64
    assert validate_csrf_token(csrf, session_token) is True
    assert validate_csrf_token("invalid_csrf_token", session_token) is False
    assert validate_csrf_token(csrf, "different_session_token") is False


# ===========================================================================
# 2. REVIEWER ONBOARDING & CREDENTIAL GOVERNANCE (Part 3)
# ===========================================================================

def test_reviewer_applicant_starts_as_pending_verification():
    with get_db_session() as db:
        applicant = ReviewerOnboardingService.register_applicant(
            db,
            ReviewerProfileCreate(
                reviewer_id="REV-P8TEST-PENDING",
                full_name="Dr. Candidate Scholar",
                primary_role=ReviewerRole.AWADHI_SPECIALIST,
                academic_qualifications="MA in Hindi",
            ),
            raw_password="CandidatePass123#",
        )
        db.commit()

        assert applicant.is_credentials_verified is False
        assert applicant.verification_status == "PENDING_VERIFICATION"
        assert applicant.is_demonstration is False
        assert "APPROVE_TRANSLATION" not in (applicant.permissions or [])


def test_demonstration_account_cannot_issue_production_approval():
    with get_db_session() as db:
        demo = ReviewerOnboardingService.create_demonstration_profile(
            db,
            reviewer_id="REV-P8TEST-DEMO",
            full_name="Demo Test User",
            role=ReviewerRole.SANSKRIT_TEXTUAL,
            raw_password="DemoPassword123#",
        )
        db.commit()

        assert demo.is_demonstration is True
        assert demo.verification_status == "DEMO"

        # PermissionGuard blocks demonstration endorsement
        with pytest.raises(PermissionDeniedError, match="is a demonstration profile"):
            PermissionGuard.require_production_endorsement_capability(demo)

        # ReviewActionEngine blocks approval by demonstration profile
        t = db.query(Translation).first()
        v = db.query(Verse).filter_by(id=t.verse_id).first()
        with pytest.raises(ReviewActionError, match="is a demonstration account"):
            ReviewActionEngine.execute_action(
                db,
                ReviewActionLogCreate(
                    translation_id=t.id,
                    verse_id=v.id,
                    reviewer_id=demo.id,
                    action_type=ReviewActionType.APPROVE,
                    previous_status="DRAFT",
                    new_status="APPROVED",
                    scholarly_commentary="Attempted demo approval",
                ),
            )


def test_admin_credential_verification_workflow():
    with get_db_session() as db:
        # Create admin
        admin = ReviewerProfile(
            reviewer_id="REV-P8TEST-ADMIN",
            full_name="Admin Council",
            primary_role=ReviewerRole.EDITORIAL_BOARD,
            is_credentials_verified=True,
            verification_status="VERIFIED",
            permissions=["ADMIN_ALL", "CAN_VERIFY_CREDENTIALS"],
        )
        db.add(admin)
        db.flush()

        # Register applicant
        applicant = ReviewerOnboardingService.register_applicant(
            db,
            ReviewerProfileCreate(
                reviewer_id="REV-P8TEST-APPLICANT",
                full_name="Prof. Verified Scholar",
                primary_role=ReviewerRole.VEDIC_RECENSION,
            ),
            raw_password="VerifiedPass123#",
        )

        # Verify applicant credentials
        verified = ReviewerOnboardingService.verify_credentials(
            db,
            admin_reviewer=admin,
            applicant_reviewer_id="REV-P8TEST-APPLICANT",
            verification_method="MATHA_PATTAM_VERIFIED",
            verification_notes="Verified oral recitation and Samhita pedigree.",
            approve=True,
        )
        assert verified.is_credentials_verified is True
        assert verified.verification_status == "VERIFIED"
        assert verified.verified_by_admin == "REV-P8TEST-ADMIN"
        assert "APPROVE_TRANSLATION" in verified.permissions


# ===========================================================================
# 3. THREE-COMPOSITION REVIEW PILOT & 11 FEEDBACK CATEGORIES (Part 4)
# ===========================================================================

def test_scholarly_review_pilot_execution_and_categories():
    with get_db_session() as db:
        pilot_results = ScholarlyReviewPilot.execute_pilot(db)

        # Verify 3 Compositions Evaluated
        assert len(pilot_results["compositions_evaluated"]) == 3
        c_map = {c["content_id"]: c for c in pilot_results["compositions_evaluated"]}
        assert "VEDA-TXT-00006" in c_map  # Gayatri
        assert "VEDA-TXT-00002" in c_map  # Shiva Tandava
        assert "VEDA-TXT-00008" in c_map  # Hanuman Chalisa

        # Verify Independent Verse-Level Completion & Composition Status
        # Gayatri (1/1 verses reviewed -> APPROVED)
        assert c_map["VEDA-TXT-00006"]["verse_completion_percentage"] == 100.0
        assert c_map["VEDA-TXT-00006"]["composition_status"] == "APPROVED"

        # Shiva Tandava (3/16 verses reviewed -> strictly IN_PROGRESS)
        assert c_map["VEDA-TXT-00002"]["reviewed_verses"] == 3
        assert c_map["VEDA-TXT-00002"]["composition_status"] == "IN_PROGRESS"

        # Hanuman Chalisa (3/43 verses reviewed -> strictly IN_PROGRESS)
        assert c_map["VEDA-TXT-00008"]["reviewed_verses"] == 3
        assert c_map["VEDA-TXT-00008"]["composition_status"] == "IN_PROGRESS"

        # Verify all 11 required feedback categories were exercised
        exercised = pilot_results["categories_exercised"]
        assert len(exercised) == 11
        for cat in ReviewerFeedbackCategory:
            assert cat.value in exercised

        # Verify Textual Dispute preserved competing traditional readings
        assert len(pilot_results["disputes_registered"]) >= 1
        dispute = db.query(TextualDispute).first()
        assert dispute is not None
        assert "Advaita Vedanta" in dispute.opinion_a_json["school"]
        assert "Vishishtadvaita Vedanta" in dispute.opinion_b_json["school"]
        assert dispute.status == DisputeStatus.OPEN


# ===========================================================================
# 4. SANSKRIT AI INTELLIGENCE ENGINE VALIDATION (Part 5)
# ===========================================================================

def test_padachheda_engine_paninian_and_awadhi_compounds():
    # 1. Classical compound with Savarnadirgha and Purvarupa
    shiva_verse = "जटाटवीगलज्जलप्रवाहपावितस्थले गलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम्"
    res = PadachhedaEngine.analyze_padachheda(shiva_verse, language="sa")
    assert len(res["primary_padas"]) >= 4
    assert res["language"] == "Classical Sanskrit"
    # Verify compound_token preserved
    assert len(res["sandhi_junctions"]) > 0
    assert any("ऽ" in j["compound_token"] for j in res["sandhi_junctions"])

    # 2. Awadhi separation without enforcing Sanskrit Sandhi
    awadhi_verse = "श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि"
    awa_res = PadachhedaEngine.analyze_padachheda(awadhi_verse, language="awa")
    assert awa_res["language"] == "Awadhi"
    assert "चरन" in awa_res["primary_padas"]
    assert "सरोज" in awa_res["primary_padas"]


def test_anvaya_engine_dandanvaya_khandanvaya_and_uncertainty():
    padas = ["तत्", "सवितुः", "वरेण्यम्", "भर्गः", "देवस्य", "धीमहि"]
    res = AnvayaEngine.reconstruct_anvaya(padas, "तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि", language="sa", is_vedic=True)
    assert res["is_suggestion_only"] is True
    assert "dandanvaya" in res
    assert "khandanvaya_inquiry" in res
    assert "topicalized_variant" in res
    assert len(res["alternative_anvayas"]) >= 1
    # Check uncertainty flag on ambiguous neuter noun
    assert any("भर्गः" in f or "ambiguous" in f.lower() for f in res["uncertainty_flags"])


def test_grammar_engine_paninian_sutras_and_awadhi_affixes():
    # Sanskrit Accusative Karma
    g1 = GrammarEngine.analyze_pada_grammar("वरेण्यम्", language="sa")
    assert "कर्मणि द्वितीया" in g1["paninian_sutra_citation"]
    assert g1["is_human_confirmed"] is False

    # Awadhi Verbal Past
    g2 = GrammarEngine.analyze_pada_grammar("दीन्ह", language="awa")
    assert "अवधी" in g2["part_of_speech"]
    assert "भूतकाल" in g2["awadhi_grammatical_feature"]


def test_chandas_prosody_scansion_vedic_classical_and_awadhi():
    # 1. Vedic Gayatri (24 syllables)
    gayatri_verse = "तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्"
    c_gayatri = ChandasEngine.analyze_meter(gayatri_verse, language="sa", is_vedic=True, declared_meter="Gayatri")
    assert "Gayatri" in c_gayatri["meter_name"]
    assert c_gayatri["expected_syllables"] == 24

    # 2. Classical Panchachamara (16 aksharas per quarter)
    shiva_line = "जटाटवीगलज्जलप्रवाहपावितस्थले गलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम्"
    c_shiva = ChandasEngine.analyze_meter(shiva_line, language="sa", is_vedic=False)
    assert "Panchachamara" in c_shiva["meter_name"]

    # 3. Awadhi Chaupai (16 matras)
    chaupai_line = "जय हनुमान ज्ञान गुन सागर । जय कपीस तिहुँ लोक उजागर ॥"
    c_awa = ChandasEngine.analyze_meter(chaupai_line, language="awa", declared_meter="Chaupai")
    assert "Chaupai" in c_awa["meter_name"]
    assert c_awa["meter_family"] == "Matrika Chhandas (मात्रिक छन्दः)"


def test_word_meaning_engine_and_lexical_citations():
    entry = WordMeaningEngine.get_word_analysis("वरेण्यम्", language="sa")
    assert entry["iast"] == "vareṇyam"
    assert "वृञ्" in entry["dhatu_etymology"]
    assert "Apte" in entry["lexicographical_citation"]
    assert "Sayana" in entry["traditional_interpretation"]


def test_source_research_engine_historical_citations():
    citation = SourceResearchEngine.get_verified_citation("SAYANA_RIGVEDA", "Mandala 3, Sukta 62, Rk 10")
    assert citation["is_verified_authorized_source"] is True
    assert "Sayana" in citation["author_commentator"]
    assert "VSM" in citation["edition"] or "Vaidika Samsodhana Mandala" in citation["edition"]
    assert citation["publication_year"] == 1933


def test_ai_model_comparative_evaluator_and_reports():
    eval_res = AIModelEvaluator.run_full_comparative_evaluation()
    assert len(eval_res["models_compared"]) == 3
    for model in eval_res["models_compared"]:
        assert model["is_suggestion_only"] is True
        assert model["samples_evaluated"] == 6
        assert "ACCEPTED_SUGGESTION" in model["review_outcomes"]


# ===========================================================================
# 5. BACKFILL GAP AUDIT & DASHBOARD METRICS (Part 6 & 7)
# ===========================================================================

def test_translation_view_gap_audit_752_records():
    with get_db_session() as db:
        res = BackfillQueueEngine.audit_legacy_gaps(db)
        # Verify exactly 752 legacy records lacking separate Literal and Tatparya views
        assert res["total_legacy_gap_records"] == 752
        assert "Tier 1: Canonical Vedic Mantras & Suktams" in res["tier_distribution"]
        assert "Tier 2: Major Devotional & Philosophical Stotras" in res["tier_distribution"]
        assert "Tier 3: Classical Devotional Ashtakams" in res["tier_distribution"]
        assert "Tier 4: Vernacular Bhakti Literature (Awadhi)" in res["tier_distribution"]

        # Assert no auto-modifications made to DB
        unmodified_views = db.query(TranslationView).count()
        assert unmodified_views == 7706


def test_expanded_library_analytics_dashboard_metrics():
    with get_db_session() as db:
        metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db)
        d = metrics.to_dict()

        # Phase 8 Reviewer Census Metrics
        assert d["total_reviewers"] >= 4
        assert d["demonstration_accounts"] >= 1
        assert d["verified_production_reviewers"] >= 3
        assert d["missing_translation_views"] == 752
        assert d["unresolved_conflicts"] >= 1
        assert "composition_review_completion" in d
        assert "language_review_completion" in d
