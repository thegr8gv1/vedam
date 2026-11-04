"""
Unit Tests for Excel, Word, and JSON Exporters
"""

import json
from pathlib import Path
import pytest
import openpyxl
from docx import Document

from automation.exporters.excel_exporter import ExcelExporter
from automation.exporters.json_exporter import JSONExporter
from automation.exporters.word_exporter import WordExporter
from automation.rights.engine import RightsComplianceError
from database.models import (
    Category,
    ContentRights,
    Deity,
    ReleaseStatus,
    Text,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
)


@pytest.fixture
def sample_text():
    cat = Category(slug="stotra", name="Stotra")
    deity = Deity(slug="ganesha", name="Lord Ganesha")
    text = Text(
        content_id="VEDA-TXT-00001",
        uuid="uuid-ganesha-001",
        canonical_title="Ganesha Pancharatnam",
        devanagari_title="गणेशपञ्चरत्नम्",
        deity=deity,
        primary_category=cat,
        composer="Adi Shankaracharya",
        chandas="Vasantatilaka",
        content_hash="hash-123456",
        verse_count=1,
    )
    v1 = Verse(
        verse_id="VEDA-TXT-00001-V001",
        verse_number=1,
        verse_type=VerseType.VERSE,
        devanagari_text="मुदाकरात्तमोदकं सदा विमुक्तिसाधकम्",
        iast_text="mudākarāttamōdakaṁ sadā vimuktisādhakam",
    )
    v1.transliterations.append(Transliteration(
        verse=v1,
        target_script="telugu",
        script_text="ముదాకరాత్తమోదకం సదా విముక్తిసాధకమ్",
    ))
    v1.translations.append(Translation(
        verse=v1,
        target_language="en",
        translation_type=TranslationType.BHAVARTHA,
        translated_text="I bow to Lord Ganesha who joyfully holds a sweet modaka...",
    ))
    text.verses.append(v1)

    text.rights = ContentRights(
        text=text,
        original_composition_attribution="Adi Shankaracharya",
        primary_source="Nirnaya Sagar Press (1912)",
        license_type="PUBLIC_DOMAIN",
        commercial_reuse_permitted=True,
        release_status=ReleaseStatus.GREEN,
    )
    return text


def test_excel_exporter(sample_text, tmp_path):
    out_path = str(tmp_path / "test_export.xlsx")
    saved = ExcelExporter.export_text_bundle(sample_text, out_path)
    assert Path(saved).exists()

    # Inspect openpyxl workbook
    wb = openpyxl.load_workbook(saved)
    assert "Overview & Metadata" in wb.sheetnames
    assert "Verses & Translations" in wb.sheetnames
    assert "Rights & Provenance" in wb.sheetnames

    ws_verses = wb["Verses & Translations"]
    assert ws_verses["A2"].value == "VEDA-TXT-00001-V001"
    assert ws_verses["D2"].value == "मुदाकरात्तमोदकं सदा विमुक्तिसाधकम्"


def test_word_exporter(sample_text, tmp_path):
    out_path = str(tmp_path / "test_export.docx")
    saved = WordExporter.export_text_bundle(sample_text, out_path)
    assert Path(saved).exists()

    # Inspect docx document
    doc = Document(saved)
    full_text = " ".join([p.text for p in doc.paragraphs])
    assert "गणेशपञ्चरत्नम्" in full_text
    assert "Ganesha Pancharatnam" in full_text
    assert "Verse 1" in full_text


def test_json_exporter(sample_text, tmp_path):
    out_path = str(tmp_path / "test_export.json")
    saved = JSONExporter.export_text_bundle(sample_text, out_path)
    assert Path(saved).exists()

    with open(saved, "r", encoding="utf-8") as f:
        data = json.load(f)

    assert data["content_id"] == "VEDA-TXT-00001"
    assert data["title"]["canonical"] == "Ganesha Pancharatnam"
    assert data["rights_and_provenance"]["release_status"] == "GREEN"
    assert len(data["verses"]) == 1
    assert data["verses"][0]["transliterations"]["telugu"] == "ముదాకరాత్తమోదకం సదా విముక్తిసాధకమ్"


def test_exporter_blocks_red_status(sample_text, tmp_path):
    sample_text.rights.release_status = ReleaseStatus.RED
    sample_text.rights.commercial_reuse_permitted = False
    out_path = str(tmp_path / "blocked.xlsx")

    with pytest.raises(RightsComplianceError):
        ExcelExporter.export_text_bundle(sample_text, out_path, target_channel="commercial_release")
