"""
Integration and Pipeline Tests for Phase 2A Processing Engine
"""

from pathlib import Path
import pytest

from automation.classifiers.text_classifier import TextClassifier
from automation.connectors.base import BaseSourceConnector, ConnectorPermissionError
from automation.parsers.metadata_extractor import LiturgicalMetadataExtractor
from automation.parsers.verse_splitter import VerseSplitter
from automation.pipeline.checkpoint import JobCheckpoint
from automation.pipeline.queue import ProcessingQueue
from automation.validators.completeness_checker import CompletenessChecker
from database.connection import get_db_session, init_db
from database.models import ReleaseStatus, Text, VerseType


def test_job_checkpoint_resumability(tmp_path):
    checkpoint_dir = str(tmp_path / "checkpoints")
    cp = JobCheckpoint(job_id="test_job_1", source_code="SRC-TEST", checkpoint_dir=checkpoint_dir)

    cp.mark_completed("https://example.com/stotra/1")
    cp.mark_completed("https://example.com/stotra/2")
    cp.mark_failed("https://example.com/stotra/3", "HTTP 500 error")

    assert cp.is_processed("https://example.com/stotra/1") is True
    assert cp.is_processed("https://example.com/stotra/3") is False

    # Simulate process crash and resume by loading new instance from disk
    cp_resumed = JobCheckpoint(job_id="test_job_1", source_code="SRC-TEST", checkpoint_dir=checkpoint_dir)
    assert cp_resumed.is_processed("https://example.com/stotra/1") is True
    assert cp_resumed.is_processed("https://example.com/stotra/2") is True
    assert "https://example.com/stotra/3" in cp_resumed.failed_items


def test_verse_splitter_sanskrit():
    sample_stotra = (
        "मुदाकरात्तमोदकं सदा विमुक्तिसाधकम् ॥ १ ॥\n\n"
        "नताशुभाशुकर्तकं नमामि तं विनायकम् ॥ २ ॥"
    )
    verses = VerseSplitter.split_into_verses(sample_stotra)
    assert len(verses) == 2
    assert verses[0]["verse_number"] == 1
    assert verses[1]["verse_number"] == 2
    assert "विनायकम्" in verses[1]["devanagari_text"]


def test_verse_splitter_phalasruti_detection():
    sample_with_phala = (
        "मुदाकरात्तमोदकं सदा विमुक्तिसाधकम् ॥ १ ॥\n\n"
        "फलश्रुतिः\n"
        "प्रातर्भजति यो नित्यं स लभेत वाञ्छितं फलम् ॥ २ ॥"
    )
    verses = VerseSplitter.split_into_verses(sample_with_phala)
    assert len(verses) == 2
    assert verses[1]["verse_type"] == VerseType.PHALASRUTI


def test_liturgical_metadata_extractor():
    prefix_text = (
        "अस्य श्रीमहामृत्युञ्जयमन्त्रस्य वसिष्ठ ऋषिः अनुष्टुप् छन्दः "
        "श्रीमृत्युञ्जयो देवता ह्रीं बीजं स्वाहा शक्तिः जपे विनियोगः"
    )
    meta = LiturgicalMetadataExtractor.extract_metadata(prefix_text)
    assert "वसिष्ठ" in meta["rishi"]
    assert meta["chandas"] == "अनुष्टुप्"
    assert "मृत्युञ्जय" in meta["devata"]
    assert meta["has_formal_viniyoga"] is True


def test_text_classifier():
    # Awadhi Chalisa detection
    awadhi_chalisa = "श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि । जय हनुमान ज्ञान गुन सागर"
    lang = TextClassifier.detect_language(awadhi_chalisa)
    cat = TextClassifier.classify_category("हनुमान चालीसा", awadhi_chalisa)
    deity = TextClassifier.detect_deity("हनुमान चालीसा", awadhi_chalisa)

    assert lang == "awa"
    assert cat == "chalisa"
    assert deity == "hanuman"

    # Sanskrit Stotra detection
    sanskrit_stotra = "मुदाकरात्तमोदकं सदा विमुक्तिसाधकं नमामि तं विनायकम्"
    assert TextClassifier.detect_language(sanskrit_stotra) == "sa"
    assert TextClassifier.detect_deity("गणेशपञ्चरत्नम्", sanskrit_stotra) == "ganesha"


def test_completeness_checker():
    # Valid continuous sequence
    valid_verses = [
        {"verse_number": 1, "devanagari_text": "verse 1 text ॥"},
        {"verse_number": 2, "devanagari_text": "verse 2 text ॥"},
        {"verse_number": 3, "devanagari_text": "verse 3 text ॥"},
    ]
    is_complete, issues = CompletenessChecker.validate_verse_sequence(valid_verses)
    assert is_complete is True
    assert len(issues) == 0

    # Sequence with missing verse 2
    broken_verses = [
        {"verse_number": 1, "devanagari_text": "verse 1 text ॥"},
        {"verse_number": 3, "devanagari_text": "verse 3 text ॥"},
    ]
    is_complete, issues = CompletenessChecker.validate_verse_sequence(broken_verses)
    assert is_complete is False
    assert any("Missing verses" in issue for issue in issues)


def test_connector_permission_enforcement():
    class TestRestrictedConnector(BaseSourceConnector):
        def verify_source_authorization(self) -> bool:
            return False  # Permission denied

        def discover_items(self):
            return [{"slug": "item-1"}]

        def fetch_item(self, item):
            return {"content": "text"}

    conn = TestRestrictedConnector("SRC-RESTRICTED", "https://restricted.org")
    with pytest.raises(ConnectorPermissionError):
        conn.run_collection()


def test_processing_queue_end_to_end():
    init_db()
    queue = ProcessingQueue()
    payload = {
        "title": "Aditya Hrudayam Sample",
        "canonical_title": "Aditya Hrudayam Sample",
        "devanagari_title": "आदित्यहृदयम्",
        "raw_text": "ततो युद्धपरिश्रान्तं समरे चिन्तया स्थितम् ॥ १ ॥\n\nआदित्यं सर्वभूतानां नमस्कुरु दिवाकरम् ॥ २ ॥",
        "raw_script": "Devanagari",
        "deity_slug": "surya",
        "rights": {
            "attribution": "Sage Agastya",
            "primary_source": "Valmiki Ramayana (1930)",
            "license_type": "PUBLIC_DOMAIN",
            "commercial_reuse": True,
            "release_status": "GREEN",
        }
    }

    result = queue.process_raw_item(payload, sequence_num=99)
    assert result["status"] == "STORED"
    assert result["content_id"] == "VEDA-TXT-00099"
    assert result["verse_count"] == 2

    # Query back from DB
    with get_db_session() as session:
        queried = session.query(Text).filter_by(content_id="VEDA-TXT-00099").first()
        assert queried is not None
        assert queried.canonical_title == "Aditya Hrudayam Sample"
        assert queried.rights.release_status == ReleaseStatus.GREEN
        assert len(queried.verses) == 2
        # Verify regional transliterations were generated automatically
        assert len(queried.verses[0].transliterations) >= 4
