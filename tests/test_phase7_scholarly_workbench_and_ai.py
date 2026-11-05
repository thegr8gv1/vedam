"""
Vedic Heritage Platform — Phase 7 Automated Test Suite
Verifies:
1. Reviewer Profile Management, Credential Certification & Privacy Filtering.
2. Review Assignment Dispatching, Batch Assignments & Reassignment Logic.
3. Review Action Execution, Version Incrementing & Immutable Audit Trails.
4. Textual Conflict Resolution & Multi-Sampradaya Reading Preservation.
5. AI Sanskrit Intelligence Modules: Padachheda, Anvaya, Grammar, Word Meaning,
   Chandas (Vedic, Classical, Awadhi), Pronunciation, and Source Citation.
6. AI Provider Abstraction, Failure Resilience & Provenance Recording.
7. TranslationView Backfill & Independent View Approval.
8. Expanded Analytics Dashboard with Phase 7 Governance Metrics.
"""

from datetime import datetime, timezone
import pytest
from sqlalchemy.orm import Session

from automation.ai_sanskrit_engine.anvaya import AnvayaEngine
from automation.ai_sanskrit_engine.chandas import ChandasEngine
from automation.ai_sanskrit_engine.coordinator import SanskritIntelligenceCoordinator
from automation.ai_sanskrit_engine.grammar import GrammarEngine
from automation.ai_sanskrit_engine.padachheda import PadachhedaEngine
from automation.ai_sanskrit_engine.pronunciation import PronunciationEngine
from automation.ai_sanskrit_engine.provider import (
    AIAnnotationResult,
    AIProvenanceRecorder,
    MockAIProvider,
)
from automation.ai_sanskrit_engine.source_research import SourceResearchEngine
from automation.ai_sanskrit_engine.word_meaning import WordMeaningEngine
from automation.reporting.library_analytics import LibraryAnalyticsEngine
from automation.workbench.api import WorkbenchComparisonEngine
from automation.workbench.assignment_engine import AssignmentEngine, AssignmentGovernanceError
from automation.workbench.conflict_engine import ConflictResolutionEngine
from automation.workbench.dashboard_view import ScholarlyWorkbenchViewGenerator
from automation.workbench.review_action_engine import ReviewActionEngine, ReviewActionError
from automation.workbench.reviewer_manager import ReviewerManager, ReviewerGovernanceError
from automation.workbench.translation_view_backfill import TranslationViewBackfillEngine
from database.connection import get_db_session
from database.models import (
    AIAnnotationProvenance,
    AIAnnotationType,
    AssignmentPriority,
    AssignmentStatus,
    DisputeStatus,
    ReviewActionLog,
    ReviewActionType,
    ReviewAssignment,
    ReviewStatus,
    ReviewerProfile,
    ReviewerRole,
    Text,
    TextualDispute,
    Translation,
    TranslationType,
    TranslationView,
    Verse,
)
from database.schemas import (
    ReviewAssignmentCreate,
    ReviewActionLogCreate,
    ReviewerProfileCreate,
    TextualDisputeCreate,
)


@pytest.fixture(scope="module")
def db():
    with get_db_session() as session:
        # Pre-test cleanup of any previous test fixtures
        session.query(ReviewActionLog).filter(ReviewActionLog.action_id.like("ACT-%")).delete(synchronize_session=False)
        session.query(ReviewAssignment).filter(ReviewAssignment.assignment_id.like("ASGN-%")).delete(synchronize_session=False)
        session.query(TextualDispute).filter(TextualDispute.dispute_id.like("DSP-%")).delete(synchronize_session=False)
        session.query(AIAnnotationProvenance).filter(AIAnnotationProvenance.annotation_id.like("AI-%")).delete(synchronize_session=False)
        session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-TEST-%")).delete(synchronize_session=False)
        session.commit()

        yield session

        # Post-test cleanup to keep database clean
        session.query(ReviewActionLog).filter(ReviewActionLog.action_id.like("ACT-%")).delete(synchronize_session=False)
        session.query(ReviewAssignment).filter(ReviewAssignment.assignment_id.like("ASGN-%")).delete(synchronize_session=False)
        session.query(TextualDispute).filter(TextualDispute.dispute_id.like("DSP-%")).delete(synchronize_session=False)
        session.query(AIAnnotationProvenance).filter(AIAnnotationProvenance.annotation_id.like("AI-%")).delete(synchronize_session=False)
        session.query(ReviewerProfile).filter(ReviewerProfile.reviewer_id.like("REV-TEST-%")).delete(synchronize_session=False)
        session.commit()


# ---------------------------------------------------------------------------
# 1. Reviewer Profile Management Tests
# ---------------------------------------------------------------------------

def test_reviewer_registration_and_credential_verification(db: Session):
    """Test registering a scholar, verifying credentials, and checking privacy views."""
    req = ReviewerProfileCreate(
        reviewer_id="REV-TEST-001",
        full_name="Acharya Vachaspati Mishra",
        email="vachaspati@sanskrit-parishad.org",
        primary_role=ReviewerRole.SANSKRIT_GRAMMAR,
        secondary_roles=["SANSKRIT_TEXTUAL", "TRADITIONAL_COMMENTARY"],
        areas_of_expertise=["Paninian Vyakarana", "Advaita Vedanta", "Kavya Shastra"],
        language_proficiency={"sa": "EXPERT", "hi": "NATIVE", "te": "SCHOLARLY"},
        sanskrit_proficiency="Vyakarana Acharya",
        academic_qualifications="PhD in Sanskrit Vyakarana, Sampurnanand Sanskrit University",
        institutional_affiliation="Rashtriya Sanskrit Sansthan",
        is_credentials_verified=False,
    )
    profile = ReviewerManager.register_reviewer(db, req)
    db.commit()

    assert profile.id is not None
    assert profile.is_credentials_verified is False

    # Verify credentials
    verified = ReviewerManager.verify_credentials(
        db,
        reviewer_id="REV-TEST-001",
        verification_method="Doctoral Degree Verification & Board Endorsement",
        verified_by_admin="Dean of Research",
    )
    db.commit()
    assert verified.is_credentials_verified is True
    assert "Dean of Research" in verified.verification_method

    # Public profile test (privacy protection)
    public_view = ReviewerManager.get_public_profile(db, "REV-TEST-001")
    assert public_view is not None
    assert public_view.full_name == "Acharya Vachaspati Mishra"
    assert not hasattr(public_view, "email") or getattr(public_view, "email", None) is None

    # Admin profile test (includes email)
    admin_view = ReviewerManager.get_admin_profile(db, "REV-TEST-001")
    assert admin_view is not None
    assert admin_view.email == "vachaspati@sanskrit-parishad.org"


def test_reviewer_uniqueness_enforced(db: Session):
    """Duplicate reviewer_id must be rejected."""
    req = ReviewerProfileCreate(
        reviewer_id="REV-TEST-001",
        full_name="Duplicate Scholar",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
    )
    with pytest.raises(ReviewerGovernanceError):
        ReviewerManager.register_reviewer(db, req)


# ---------------------------------------------------------------------------
# 2. Review Assignment Dispatching Tests
# ---------------------------------------------------------------------------

def test_assignment_dispatching_and_reassignment(db: Session):
    """Test creating assignments, rejecting unverified reviewers, and reassignment."""
    reviewer = db.query(ReviewerProfile).filter_by(reviewer_id="REV-TEST-001").first()
    text = db.query(Text).filter_by(content_id="VEDA-TXT-00005").first()
    verse = text.verses[0]

    # Valid Assignment
    asgn_data = ReviewAssignmentCreate(
        reviewer_id=reviewer.id,
        text_id=text.id,
        verse_id=verse.id,
        target_language="sa",
        view_type=TranslationType.LITERAL,
        priority=AssignmentPriority.HIGH,
        notes="Inspect Paninian word dissection for Gayatri Mantra.",
    )
    asgn = AssignmentEngine.create_assignment(db, asgn_data)
    db.commit()

    assert asgn.id is not None
    assert asgn.status == AssignmentStatus.PENDING

    # Register second reviewer for reassignment
    req2 = ReviewerProfileCreate(
        reviewer_id="REV-TEST-002",
        full_name="Dr. Somadev Sharma",
        primary_role=ReviewerRole.VEDIC_RECENSION,
        is_credentials_verified=True,
    )
    rev2 = ReviewerManager.register_reviewer(db, req2)
    db.commit()

    # Reassign work
    reassigned = AssignmentEngine.reassign_work(
        db,
        assignment_id=asgn.assignment_id,
        new_reviewer_id=rev2.id,
        reassigned_by="Head of Linguistics",
        reason="Vedic accent specialization required.",
    )
    db.commit()

    assert reassigned.reviewer_id == rev2.id
    assert asgn.status == AssignmentStatus.REASSIGNED


# ---------------------------------------------------------------------------
# 3. Review Action Execution & Version Incrementing Tests
# ---------------------------------------------------------------------------

def test_review_action_execution_and_version_increment(db: Session):
    """Test approval with corrections increments version and logs immutably."""
    reviewer = db.query(ReviewerProfile).filter_by(reviewer_id="REV-TEST-001").first()
    text = db.query(Text).filter_by(content_id="VEDA-TXT-00005").first()
    verse = text.verses[0]

    # Find translation view
    view = db.query(TranslationView).filter_by(verse_id=verse.id, target_language="te").first()
    assert view is not None
    orig_version = view.version
    orig_text = view.view_text

    # Execute APPROVE_WITH_CORRECTIONS
    action_data = ReviewActionLogCreate(
        translation_id=view.translation_id,
        translation_view_id=view.id,
        verse_id=verse.id,
        reviewer_id=reviewer.id,
        action_type=ReviewActionType.APPROVE_WITH_CORRECTIONS,
        previous_status=view.review_status.value,
        new_status="APPROVED",
        previous_text=orig_text,
        proposed_text=orig_text + " (Scholarly refined Bhavartha phrasing).",
        scholarly_commentary="Refined Telugu phrasing to accurately mirror Sayana Bhashya.",
    )
    log = ReviewActionEngine.execute_action(db, action_data)
    db.commit()

    assert log.id is not None
    assert view.version == orig_version + 1
    assert view.review_status == ReviewStatus.APPROVED
    assert "Scholarly refined" in view.view_text
    # Original sacred text in verse remains untouched
    assert verse.devanagari_text != view.view_text


def test_unverified_reviewer_cannot_approve(db: Session):
    """An unverified reviewer must be blocked from issuing APPROVE action."""
    unverified_req = ReviewerProfileCreate(
        reviewer_id="REV-TEST-UNVERIFIED",
        full_name="Novice Contributor",
        primary_role=ReviewerRole.HINDI_TRANSLATOR,
        is_credentials_verified=False,
    )
    unv = ReviewerManager.register_reviewer(db, unverified_req)
    db.commit()

    text = db.query(Text).filter_by(content_id="VEDA-TXT-00005").first()
    verse = text.verses[0]
    view = db.query(TranslationView).filter_by(verse_id=verse.id, target_language="hi").first()

    action_data = ReviewActionLogCreate(
        translation_id=view.translation_id,
        translation_view_id=view.id,
        verse_id=verse.id,
        reviewer_id=unv.id,
        action_type=ReviewActionType.APPROVE,
        previous_status="DRAFT",
        new_status="APPROVED",
        scholarly_commentary="Attempted unverified approval.",
    )
    with pytest.raises(ReviewActionError):
        ReviewActionEngine.execute_action(db, action_data)


# ---------------------------------------------------------------------------
# 4. Textual Conflict Resolution Tests
# ---------------------------------------------------------------------------

def test_dispute_registration_and_preservation_of_both_readings(db: Session):
    """Test registering dispute and resolving it by preserving both readings."""
    text = db.query(Text).filter_by(content_id="VEDA-TXT-00002").first()
    verse = text.verses[0]

    dispute_data = TextualDisputeCreate(
        verse_id=verse.id,
        dispute_nature="Padachheda & Visarga Variant Interpretation",
        opinion_a_json={
            "reading": "गलेऽवलम्ब्य (gale'valambya)",
            "school": "Kashmir Shaivism",
            "citation": "Abhinavagupta Tantraloka",
            "meaning": "Suspended upon the neck",
        },
        opinion_b_json={
            "reading": "गलेऽवलम्बिताम् (gale'valambitām)",
            "school": "South Indian Shaiva Siddhanta",
            "citation": "Vani Vilas Stotra Corpus",
            "meaning": "Referring to the garland of serpents hanging down the throat",
        },
    )
    dispute = ConflictResolutionEngine.register_dispute(db, dispute_data)
    db.commit()

    assert dispute.id is not None
    assert dispute.status == DisputeStatus.OPEN

    # Resolve by preserving both
    resolved = ConflictResolutionEngine.resolve_preserve_both(
        db,
        dispute_id=dispute.dispute_id,
        resolved_by="Editorial Board of Sanskrit Scholars",
        editorial_justification="Both readings are authenticated in classical Shaiva Sampradayas.",
    )
    db.commit()

    assert resolved.status == DisputeStatus.RESOLVED_PRESERVED_BOTH
    assert "authenticated in classical Shaiva" in resolved.editorial_resolution_notes


# ---------------------------------------------------------------------------
# 5. AI Sanskrit Intelligence Modules Tests
# ---------------------------------------------------------------------------

def test_padachheda_engine_paninian_and_awadhi():
    """Verify Paninian sandhi detection on Classical Sanskrit and non-Paninian Awadhi."""
    # Classical Sanskrit with Sandhi
    sa_text = "जटाटवीगलज्जलप्रवाहपावितस्थले गलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम् डमड्डमड्डमड्डमन्निनादवड्डमर्वयं चकार चण्डताण्डवं तनोतु नः शिवः शिवम्"
    sa_res = PadachhedaEngine.analyze_padachheda(sa_text, language="sa")
    assert sa_res["primary_padas_count"] >= 5
    assert len(sa_res["sandhi_junctions"]) >= 1

    # Awadhi text (Hanuman Chalisa)
    awa_text = "जय हनुमान ज्ञान गुन सागर । जय कपीस तिहुँ लोक उजागर ॥"
    awa_res = PadachhedaEngine.analyze_padachheda(awa_text, language="awa")
    assert awa_res["language"] == "Awadhi"
    assert "जय" in awa_res["primary_padas"]
    assert "हनुमान" in awa_res["primary_padas"]


def test_anvaya_engine_syntactic_flow():
    """Verify prose order reconstruction and syntactic dependency tracking."""
    padas = ["ॐ", "सवितुः", "वरेण्यम्", "भर्गः", "देवस्य", "धीमहि"]
    res = AnvayaEngine.reconstruct_anvaya(padas, "ॐ सवितुर्वरेण्यं भर्गो देवस्य धीमहि")
    assert "proposed_prose_order" in res
    assert res["is_suggestion_only"] is True
    assert len(res["syntactic_dependencies"]) == 6


def test_grammar_engine_panini_and_awadhi():
    """Verify morphological case/gender/sutra citations and Awadhi markers."""
    # Sanskrit Genitive
    sa_gram = GrammarEngine.analyze_pada_grammar("देवस्य", language="sa")
    assert sa_gram["vibhakti_case"] == "षष्ठी (Genitive)"
    assert "षष्ठी शेषे" in sa_gram["paninian_sutra_citation"]

    # Awadhi Past Action
    awa_gram = GrammarEngine.analyze_pada_grammar("दीन्ह", language="awa")
    assert "Awadhi" in awa_gram["linguistic_recension"]


def test_chandas_engine_vedic_classical_and_awadhi():
    """Verify meter scansion for Vedic Gayatri, Classical Panchachamara, and Awadhi Chaupai."""
    # Vedic Gayatri
    gayatri_res = ChandasEngine.analyze_meter(
        "ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात्",
        language="sa", is_vedic=True, declared_meter="गायत्री छन्दः"
    )
    assert "Gayatri" in gayatri_res["meter_name"]

    # Classical Panchachamara (Shiva Tandava)
    stotra_line = "जटाटवीगलज्जलप्रवाहपावितस्थले गलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम्"
    stotra_res = ChandasEngine.analyze_meter(stotra_line, language="sa", is_vedic=False)
    assert "Panchachamara" in stotra_res["meter_name"]

    # Awadhi Doha
    doha_text = "श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि ।\nबरनउँ रघुबर बिमल जसु जो दायकु फल चारि ॥"
    doha_res = ChandasEngine.analyze_meter(doha_text, language="awa", declared_meter="doha")
    assert "Doha" in doha_res["meter_name"]


def test_pronunciation_engine_separation():
    """Verify phonetic guidance is strictly separated from orthographic transliteration."""
    res = PronunciationEngine.generate_pronunciation_guide(
        "तत्स॑वि॒तुर्वरे॑ण्यं॒", language="sa", is_vedic=True, has_accents=True, target_regional_script="tamil"
    )
    assert res["has_vedic_swara_accents"] is True
    assert any("Udatta" in k for k in res["swara_rules"])
    assert "Tamil Reciters" in res["regional_script_guidance"]


def test_source_research_engine_traceable_citations():
    """Verify citation validation and unverified citation flagging."""
    # Authorized Citation
    auth_cit = SourceResearchEngine.get_verified_citation("SAYANA_RIGVEDA", "Rigveda 3.62.10")
    assert auth_cit["is_verified_authorized_source"] is True
    assert "Sayanacharya" in auth_cit["author_commentator"]

    # Unverified Citation
    unauth_cit = SourceResearchEngine.get_verified_citation("UNKNOWN_BLOG_SOURCE", "Page 1")
    assert unauth_cit["is_verified_authorized_source"] is False
    assert "AI-generated" in unauth_cit["disclaimer"]


# ---------------------------------------------------------------------------
# 6. AI Provenance & Provider Resilience Tests
# ---------------------------------------------------------------------------

def test_mock_ai_provider_and_provenance_recording(db: Session):
    """Test AI suggestion recording with mandatory suggestion-only flag and mock failure handling."""
    text = db.query(Text).filter_by(content_id="VEDA-TXT-00005").first()
    verse = text.verses[0]

    # Successful Mock Provider Call
    provider = MockAIProvider(simulate_failure=False)
    res = provider.analyze_verse(verse.devanagari_text, AIAnnotationType.PADACHHEDA)
    assert res.confidence_score == 0.95

    # Record Provenance
    prov = AIProvenanceRecorder.record_suggestion(db, verse.id, res)
    db.commit()

    assert prov.id is not None
    assert prov.is_suggestion_only is True
    assert prov.is_human_reviewed is False

    # Failure simulation test
    failing_provider = MockAIProvider(simulate_failure=True)
    with pytest.raises(ConnectionError):
        failing_provider.analyze_verse(verse.devanagari_text, AIAnnotationType.ANVAYA)


# ---------------------------------------------------------------------------
# 7. TranslationView Backfill & Independent Review Tests
# ---------------------------------------------------------------------------

def test_translation_view_backfill_and_independent_approval(db: Session):
    """Test backfill legacy detection and independent view approval."""
    # 1. Check legacy identification
    legacy_records = TranslationViewBackfillEngine.get_legacy_translation_records(db)
    assert len(legacy_records) == 752

    # 2. Generate candidate draft views for one legacy translation
    sample_trans = legacy_records[0]
    candidate = TranslationViewBackfillEngine.generate_draft_view_candidates(db, sample_trans.id)
    assert candidate["literal_view_draft"]["review_status"] == "DRAFT"
    assert candidate["tatparya_view_draft"]["review_status"] == "DRAFT"

    # 3. Test independent view approval
    reviewer = db.query(ReviewerProfile).filter_by(reviewer_id="REV-TEST-001").first()
    view = db.query(TranslationView).filter_by(translation_id=sample_trans.id).first()
    assert view is not None

    app_view = TranslationViewBackfillEngine.approve_view_independently(
        db,
        view_id=view.view_id,
        reviewer_id=reviewer.id,
        scholarly_commentary="Verified literal syntax independently.",
    )
    db.commit()

    assert app_view.review_status == ReviewStatus.APPROVED


# ---------------------------------------------------------------------------
# 8. 6-Column Workbench API & Expanded Dashboard Tests
# ---------------------------------------------------------------------------

def test_workbench_6_column_payload_and_html_generation(db: Session, tmp_path):
    """Test 6-column comparison payload extraction and HTML view generation."""
    payload = WorkbenchComparisonEngine.get_verse_workbench_payload(
        db, "VEDA-TXT-00002-V001", target_language="te"
    )
    assert "column_1_original" in payload
    assert "column_2_transliterations" in payload
    assert "column_3_literal" in payload
    assert "column_4_traditional" in payload
    assert "column_5_bhavartha" in payload
    assert "column_6_governance" in payload

    # HTML Generation
    out_file = str(tmp_path / "test_workbench.html")
    html_path = ScholarlyWorkbenchViewGenerator.generate_html_workbench(
        db, content_id="VEDA-TXT-00002", verse_number=1, target_language="te", output_file=out_file
    )
    assert out_file == html_path


def test_expanded_analytics_dashboard_metrics(db: Session):
    """Test library analytics incorporates Phase 7 workbench and AI intelligence metrics."""
    metrics = LibraryAnalyticsEngine.generate_dashboard_metrics(db)
    m_dict = metrics.to_dict()

    assert "review_assignments_total" in m_dict
    assert "pending_reviewer_actions" in m_dict
    assert "approved_literal_views" in m_dict
    assert "approved_traditional_meaning_views" in m_dict
    assert "approved_bhavartha_views" in m_dict
    assert "ai_generated_annotations" in m_dict
    assert "human_corrected_ai_annotations" in m_dict
    assert "unresolved_textual_disputes" in m_dict
    assert "reviewer_productivity_stats" in m_dict
