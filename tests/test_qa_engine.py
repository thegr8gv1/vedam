"""
Vedic Heritage Platform — Content Quality Assurance Engine Tests
Verifies 12-stage quality lifecycle, versification checks, Vedic accent detection,
and metadata completeness evaluation.
"""

import pytest
from automation.validators.qa_engine import (
    ContentQualityAssuranceEngine,
    QualityLifecycleStatus,
    TextCompletenessStatus,
)
from database.models import Category, ContentRights, Deity, ReleaseStatus, Text, Verse, VerseType


def test_qa_sample_record_identification():
    """Verifies that a text with 1 verse when 6 are expected is flagged as SAMPLE_RECORD."""
    cat = Category(id=1, slug="stotra", name="Stotra")
    deity = Deity(id=1, slug="ganesha", name="Lord Ganesha")
    text = Text(
        content_id="TX-QA-001",
        canonical_title="Ganesha Pancharatnam Test",
        devanagari_title="गणेशपञ्चरत्नम्",
        primary_category_id=cat.id,
        primary_category=cat,
        deity_id=deity.id,
        deity=deity,
        verse_count=6,
        content_hash="hash-qa-1",
        composer="Adi Shankaracharya",
        source_scripture="Traditional",
    )
    v1 = Verse(
        verse_id="TX-QA-001-001",
        verse_number=1,
        verse_type=VerseType.VERSE,
        devanagari_text="मुदाकरात्तमोदकं सदा विमुक्तिसाधकम् ॥ १ ॥",
    )
    text.verses.append(v1)
    text.rights = ContentRights(release_status=ReleaseStatus.GREEN)

    report = ContentQualityAssuranceEngine.audit_text(text)
    assert report.completeness_status == TextCompletenessStatus.SAMPLE_RECORD
    assert report.quality_lifecycle_status == QualityLifecycleStatus.PARSED
    assert report.total_verses_found == 1
    assert report.total_verses_expected == 6


def test_qa_vedic_swara_detection():
    """Verifies that Vedic hymns lacking swara marks are flagged with a warning."""
    cat = Category(id=2, slug="mantra", name="Mantra")
    text = Text(
        content_id="TX-QA-002",
        canonical_title="Gayatri Vedic Mantra Test",
        devanagari_title="गायत्री मन्त्रः",
        primary_category_id=cat.id,
        primary_category=cat,
        verse_count=1,
        content_hash="hash-qa-2",
        composer="Rishi Vishvamitra",
        source_scripture="Rigveda 3.62.10",
    )
    # Verse without Vedic accents
    v1 = Verse(
        verse_id="TX-QA-002-001",
        verse_number=1,
        verse_type=VerseType.VERSE,
        devanagari_text="तत्सवितुर्वरेण्यं भर्गो देवस्य धीमहि । धियो यो नः प्रचोदयात् ॥",
    )
    text.verses.append(v1)
    text.rights = ContentRights(release_status=ReleaseStatus.GREEN)

    report = ContentQualityAssuranceEngine.audit_text(text)
    swara_issues = [iss for iss in report.issues if iss.check_name == "VEDIC_ACCENT_CHECK"]
    assert len(swara_issues) == 1
    assert "lacks Vedic swara accents" in swara_issues[0].message


def test_qa_duplicate_verse_number_detection():
    """Verifies detection of duplicate verse numbering."""
    cat = Category(id=1, slug="stotra", name="Stotra")
    text = Text(
        content_id="TX-QA-003",
        canonical_title="Duplicate Number Test",
        devanagari_title="परीक्षार्थम्",
        primary_category_id=cat.id,
        primary_category=cat,
        verse_count=2,
        content_hash="hash-qa-3",
        composer="Traditional",
        source_scripture="Traditional",
    )
    v1 = Verse(verse_id="TX-QA-003-001", verse_number=1, devanagari_text="प्रथमः श्लोकः ॥ १ ॥")
    v2 = Verse(verse_id="TX-QA-003-002", verse_number=1, devanagari_text="द्वितीयः श्लोकः ॥ २ ॥")  # Duplicate number 1!
    text.verses.extend([v1, v2])
    text.rights = ContentRights(release_status=ReleaseStatus.GREEN)

    report = ContentQualityAssuranceEngine.audit_text(text)
    dup_issues = [iss for iss in report.issues if iss.check_name == "DUPLICATE_NUMBER_CHECK"]
    assert len(dup_issues) == 1
    assert report.passed_all_mandatory_checks is False
