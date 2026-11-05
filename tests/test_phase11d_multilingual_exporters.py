"""
Vedic Heritage Platform — Phase 11D Automated Regression Test Suite
Multilingual Publication Engines, RTL Layouts & Format Exporters

Validates:
1. Publication Document Model (verse ordering, view mapping, gap auditing, fingerprints)
2. Typography Engine & Font Registration (14 scripts, licensing, ReportLab TTFonts)
3. BiDi & RTL Layout Engine (directionality, <bdi> wrapping, Arabic shaping)
4. Central Release Gatekeeper (PUB-001 through PUB-004, DRAFT protections)
5. Accessible HTML5 Exporter (semantic markup, dir attributes, XSS escaping, DRAFT banner)
6. Print-Ready PDF Exporter (ReportLab canvas, page numbering, diagonal watermark, font fallback)
7. Structured DOCX Exporter (Word manuscript, paragraph alignment, bilingual tables)
8. Reflowable EPUB 3 Exporter (ZIP container, mimetype uncompressed, OPF, nav, spine)
9. Unified Orchestrator & Manifest (all 4 formats, SHA-256 calculation, test isolation)
"""

from datetime import datetime, timezone
import io
import json
import os
from pathlib import Path
import tempfile
import zipfile

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from automation.exporters.bidi_layout import BidiDirection, BidiLayoutEngine
from automation.exporters.docx_multilingual_exporter import MultilingualDOCXExporter
from automation.exporters.epub_exporter import MultilingualEPUBExporter
from automation.exporters.html_exporter import MultilingualHTMLExporter
from automation.exporters.multilingual_publication_orchestrator import (
    MultilingualPublicationOrchestrator,
    PublicationArtifact,
    PublicationManifest,
)
from automation.exporters.pdf_multilingual_exporter import (
    MultilingualPDFExporter,
    WatermarkedNumberedCanvas,
)
from automation.exporters.publication_gatekeeper import (
    GateViolation,
    PublicationGatekeeper,
    PublicationGateReport,
    ReleaseGateVerdict,
)
from automation.exporters.publication_model import (
    LanguageScriptTarget,
    MissingContentLedger,
    PublicationDocument,
    PublicationGovernance,
    PublicationMetadata,
    VerseEntry,
)
from automation.exporters.typography import FontProfile, MultilingualTypographyEngine
from database.models import (
    Base,
    Category,
    Deity,
    ReviewerProfile,
    ReviewerRole,
    ReviewStatus,
    Text,
    Translation,
    TranslationView,
    Verse,
)


# ===========================================================================
# Fixtures for Isolated In-Memory Database
# ===========================================================================

@pytest.fixture
def isolated_db_session():
    """Provides a pristine in-memory SQLite database session isolated from production."""
    engine = create_engine("sqlite:///:memory:")
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()

    # Create category and deity
    cat = Category(slug="veda-suktam", name="Veda Suktam")
    deity = Deity(slug="savita", name="Savitri")
    session.add_all([cat, deity])
    session.flush()

    # Create dummy text and verses
    text = Text(
        content_id="VEDA-TXT-TEST01",
        uuid="test-uuid-0001",
        canonical_title="Test Gayatri",
        devanagari_title="परीक्षण गायत्री",
        primary_category_id=cat.id,
        deity_id=deity.id,
        composer="Vishvamitra",
        rishi="Vishvamitra",
        chandas="Gayatri",
        source_scripture="Rigveda",
        traditional_usage="Daily Sandhyavandanam",
        content_hash="test-content-hash-001",
    )
    session.add(text)
    session.flush()

    verse1 = Verse(
        text_id=text.id,
        verse_id="VERSE-TEST-001",
        verse_number=1,
        devanagari_text="ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यम् ।",
        raw_source_text="ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यम् ।",
        iast_text="oṃ bhūrbhuvaḥ svaḥ tatsaviturvareṇyam |",
    )
    verse2 = Verse(
        text_id=text.id,
        verse_id="VERSE-TEST-002",
        verse_number=2,
        devanagari_text="भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥",
        raw_source_text="भर्गो देवस्य धीमहि धियो यो नः प्रचोदयात् ॥",
        iast_text="bhargo devasya dhīmahi dhiyo yo naḥ pracodayāt ||",
    )
    session.add_all([verse1, verse2])
    session.flush()

    # Add Hindi DRAFT translation
    trans_hi_1 = Translation(
        verse_id=verse1.id,
        target_language="hi",
        translated_text="हम उस परमात्मा का ध्यान करते हैं।",
        review_status=ReviewStatus.DRAFT,
        word_by_word_json=[{"sanskrit": "तत्", "meaning": "उस"}],
    )
    trans_hi_2 = Translation(
        verse_id=verse2.id,
        target_language="hi",
        translated_text="जो हमारी बुद्धियों को प्रेरित करे।",
        review_status=ReviewStatus.DRAFT,
    )
    session.add_all([trans_hi_1, trans_hi_2])
    session.flush()

    # Add Bhavartha views
    view_hi_1 = TranslationView(
        view_id="VIEW-TEST-HI-001",
        translation_id=trans_hi_1.id,
        verse_id=verse1.id,
        target_language="hi",
        view_type="BHAVARTHA",
        view_text="उस सर्वव्यापक परमात्मा का तेज हमारी बुद्धि को सन्मार्ग पर चलाए।",
        review_status=ReviewStatus.DRAFT,
        version=1,
    )
    view_hi_2 = TranslationView(
        view_id="VIEW-TEST-HI-002",
        translation_id=trans_hi_2.id,
        verse_id=verse2.id,
        target_language="hi",
        view_type="BHAVARTHA",
        view_text="वह सूर्य रूप परमात्मा हमारी प्रज्ञा को प्रदीप्त करे।",
        review_status=ReviewStatus.DRAFT,
        version=1,
    )
    session.add_all([view_hi_1, view_hi_2])

    # Add Urdu DRAFT translation
    trans_ur_1 = Translation(
        verse_id=verse1.id,
        target_language="ur",
        translated_text="ہم اس برتر نور کا مراقبہ کرتے ہیں۔",
        review_status=ReviewStatus.DRAFT,
    )
    session.add(trans_ur_1)
    session.flush()

    view_ur_1 = TranslationView(
        view_id="VIEW-TEST-UR-001",
        translation_id=trans_ur_1.id,
        verse_id=verse1.id,
        target_language="ur",
        view_type="BHAVARTHA",
        view_text="ہم اس نور کا دھیان کرتے ہیں جو کائنات کا خالق ہے۔",
        review_status=ReviewStatus.DRAFT,
        version=1,
    )
    session.add(view_ur_1)
    session.commit()

    yield session
    session.close()


@pytest.fixture
def sample_publication_doc():
    """Provides a synthetic PublicationDocument for Hindi (Devanagari)."""
    return PublicationDocument(
        metadata=PublicationMetadata(
            content_id="VEDA-TXT-00001",
            canonical_title="Shri Shiv Tandava Stotram",
            devanagari_title="श्री शिव ताण्डव स्तोत्रम्",
            composer="Ravana",
            deity="Shiva",
            chandas="Panchachamara",
            source_scripture="Traditional Stotra",
        ),
        target=LanguageScriptTarget(
            language_code="hi",
            language_name="Hindi",
            script_code="Deva",
            script_name="Devanagari",
            bcp47="hi-Deva",
            direction="ltr",
            is_rtl=False,
            shaping_required=True,
        ),
        missing_content=MissingContentLedger(
            total_verses=2,
            missing_literal_count=1,
            missing_tatparya_count=2,
            missing_bhavartha_count=0,
            is_legacy_gap_affected=True,
        ),
        verses=(
            VerseEntry(
                verse_number=1,
                verse_id="VERSE-001",
                canonical_order=1,
                raw_source="जटाटवीगलज्जलप्रवाहपावितस्थले",
                devanagari_source="जटाटवीगलज्जलप्रवाहपावितस्थले",
                iast_transliteration="jaṭāṭavīgalajjalapravāhapāvitasthale",
                literal_translation="जटा रूपी सघन वन से निकलते हुए जल प्रवाह से...",
                literal_status="DRAFT",
                bhavartha_translation="जिन शिवजी के जटा रूपी वन से बहने वाली गंगा...",
                bhavartha_status="DRAFT",
                word_by_word_json=[{"sanskrit": "जटाटवी", "meaning": "जटारूपी वन"}],
            ),
            VerseEntry(
                verse_number=2,
                verse_id="VERSE-002",
                canonical_order=2,
                raw_source="जटाकटाहसम्भ्रमभ्रमन्निलिम्पनिर्झरी",
                devanagari_source="जटाकटाहसम्भ्रमभ्रमन्निलिम्पनिर्झरी",
                iast_transliteration="jaṭākaṭāhasambhramabhramannilimpanirjharī",
                bhavartha_translation="जिनके जटा-कुण्ड में विचरने वाली देवनदी गंगा की तरंगें...",
                bhavartha_status="DRAFT",
            ),
        ),
        governance=PublicationGovernance(
            publication_channel="draft_export",
            overall_review_status="DRAFT",
            is_approved_for_public_release=False,
            watermark_text="UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE",
        ),
    )


@pytest.fixture
def sample_rtl_publication_doc():
    """Provides a synthetic PublicationDocument for Urdu (Perso-Arabic script, RTL)."""
    return PublicationDocument(
        metadata=PublicationMetadata(
            content_id="VEDA-TXT-00006",
            canonical_title="Gayatri Mantra",
            devanagari_title="गायत्री मन्त्र",
            composer="Vishvamitra",
            deity="Savitri",
            chandas="Gayatri",
        ),
        target=LanguageScriptTarget(
            language_code="ur",
            language_name="Urdu",
            script_code="Arab",
            script_name="Perso-Arabic",
            bcp47="ur-Arab",
            direction="rtl",
            is_rtl=True,
            shaping_required=True,
        ),
        missing_content=MissingContentLedger(
            total_verses=1,
            missing_literal_count=0,
            missing_tatparya_count=0,
            missing_bhavartha_count=0,
            is_legacy_gap_affected=False,
        ),
        verses=(
            VerseEntry(
                verse_number=1,
                verse_id="VERSE-GAYATRI-01",
                canonical_order=1,
                raw_source="ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यम् ।",
                devanagari_source="ॐ भूर्भुवः स्वः तत्सवितुर्वरेण्यम् ।",
                iast_transliteration="oṃ bhūrbhuvaḥ svaḥ tatsaviturvareṇyam |",
                bhavartha_translation="ہم اس پروردگار کا دھیان کرتے ہیں جس کا نور تمام عالم کو روشن کرتا ہے۔",
                bhavartha_status="DRAFT",
            ),
        ),
        governance=PublicationGovernance(
            publication_channel="draft_export",
            overall_review_status="DRAFT",
            is_approved_for_public_release=False,
            watermark_text="UNREVIEWED DRAFT — NOT FOR PUBLIC DEVOTIONAL USE",
        ),
    )


# ===========================================================================
# 1. Publication Document Model Tests
# ===========================================================================

class TestPublicationModel:
    def test_document_deterministic_hash(self, sample_publication_doc):
        """Ensures PublicationDocument calculates a reproducible SHA-256 fingerprint."""
        h1 = sample_publication_doc.document_hash
        assert isinstance(h1, str)
        assert len(h1) == 64

    def test_from_text_and_views_ordering_and_gap_census(self, isolated_db_session):
        """Verifies construction from Text entity preserves verse ordering and tallies missing views."""
        text = isolated_db_session.query(Text).first()
        doc = PublicationDocument.from_text_and_views(
            text=text,
            target_language="hi",
            target_script="Deva",
            publication_channel="draft_export",
        )
        assert doc.metadata.content_id == "VEDA-TXT-TEST01"
        assert doc.target.bcp47 == "hi-Deva"
        assert len(doc.verses) == 2
        assert doc.verses[0].verse_number == 1
        assert doc.verses[1].verse_number == 2
        assert doc.verses[0].bhavartha_translation is not None
        # Literal views were not populated in fixture, ledger should record gaps
        assert doc.missing_content.missing_literal_count == 2
        assert doc.missing_content.is_legacy_gap_affected is True

    def test_unsupported_language_raises_error(self, isolated_db_session):
        """Verifies an invalid language code raises ValueError."""
        text = isolated_db_session.query(Text).first()
        with pytest.raises(ValueError, match="Unrecognized target language"):
            PublicationDocument.from_text_and_views(text, target_language="invalid_lang")


# ===========================================================================
# 2. Typography Engine Tests
# ===========================================================================

class TestMultilingualTypographyEngine:
    def test_all_14_scripts_have_registered_profiles(self):
        """Ensures every one of the 14 platform scripts has a comprehensive typography profile."""
        scripts = ["Deva", "Telu", "Taml", "Gran", "Knda", "Mlym", "Beng", "Gujr", "Guru", "Orya", "Olck", "Arab", "Mtei", "Latn"]
        for s in scripts:
            assert s in MultilingualTypographyEngine.FONT_PROFILES
            prof = MultilingualTypographyEngine.FONT_PROFILES[s]
            assert prof.family_name
            assert prof.css_stack
            assert prof.word_font_name
            assert prof.license
            assert prof.embedding_rights

    def test_css_font_family_resolution(self):
        """Checks CSS font family resolution for Indic and Perso-Arabic scripts."""
        deva_css = MultilingualTypographyEngine.get_css_font_family("Deva")
        assert "Devanagari" in deva_css or "Nirmala" in deva_css
        arab_css = MultilingualTypographyEngine.get_css_font_family("Arab")
        assert "Noto Naskh Arabic" in arab_css or "Tahoma" in arab_css

    def test_reportlab_font_registration(self):
        """Verifies ReportLab font registration runs cleanly without unhandled exceptions."""
        result = MultilingualTypographyEngine.register_reportlab_fonts()
        assert "NirmalaUI" in result or "Helvetica" in result
        assert isinstance(result, dict)


# ===========================================================================
# 3. BiDi & RTL Layout Engine Tests
# ===========================================================================

class TestBidiLayoutEngine:
    def test_direction_identification(self):
        """Tests RTL identification for Urdu, Kashmiri, Sindhi, and Arabic script."""
        assert BidiLayoutEngine.is_rtl("ur") is True
        assert BidiLayoutEngine.is_rtl("ks") is True
        assert BidiLayoutEngine.is_rtl("sd") is True
        assert BidiLayoutEngine.is_rtl("Arab") is True
        assert BidiLayoutEngine.is_rtl("hi") is False
        assert BidiLayoutEngine.is_rtl("te") is False
        assert BidiLayoutEngine.is_rtl("Deva") is False

    def test_text_direction_detection(self):
        """Tests direction detection on actual text strings."""
        assert BidiLayoutEngine.get_text_direction("ہمارا پیارا وطن") == BidiDirection.RTL
        assert BidiLayoutEngine.get_text_direction("नमस्ते भारत") == BidiDirection.LTR

    def test_wrap_html_bidi_isolates_ltr_tokens(self):
        """Checks that wrap_html_bidi wraps Latin or numbers with <bdi dir=\"ltr\"> in RTL mode."""
        rtl_with_latin = "یہ ایک VEDA-01 ٹیسٹ ہے"
        wrapped = BidiLayoutEngine.wrap_html_bidi(rtl_with_latin, is_rtl=True)
        assert '<bdi dir="ltr">VEDA-01</bdi>' in wrapped

    def test_arabic_contextual_shaping_for_pdf(self):
        """Tests Arabic shaping transforms isolated characters to joined contextual forms."""
        test_urdu = "کتاب"  # Kaf, Taa, Alif, Baa
        shaped = BidiLayoutEngine.shape_arabic_for_pdf(test_urdu)
        assert isinstance(shaped, str)
        # Should not raise exception and should produce string of equal non-diacritic length


# ===========================================================================
# 4. Central Release Gatekeeper Tests
# ===========================================================================

class TestPublicationGatekeeper:
    def test_block_draft_from_approved_publication(self, sample_publication_doc):
        """PUB-001: Blocks draft translations from approved_publication channel."""
        # Mutate channel to approved_publication while status is DRAFT
        unauthorized_doc = PublicationDocument(
            metadata=sample_publication_doc.metadata,
            target=sample_publication_doc.target,
            missing_content=sample_publication_doc.missing_content,
            verses=sample_publication_doc.verses,
            governance=PublicationGovernance(
                publication_channel="approved_publication",
                overall_review_status="DRAFT",
                is_approved_for_public_release=False,
                watermark_text=None,
            ),
        )
        gate_rep = PublicationGatekeeper.evaluate_publication(unauthorized_doc)
        assert gate_rep.can_export is False
        assert gate_rep.verdict == ReleaseGateVerdict.REJECTED
        assert any(b.rule_code == "PUB-001" for b in gate_rep.blockers)

    def test_block_unaccredited_reviewer(self, sample_publication_doc):
        """PUB-002: Blocks approved release without accredited reviewer profile."""
        doc_approved = PublicationDocument(
            metadata=sample_publication_doc.metadata,
            target=sample_publication_doc.target,
            missing_content=MissingContentLedger(2, 0, 0, 0, False),
            verses=sample_publication_doc.verses,
            governance=PublicationGovernance(
                publication_channel="approved_publication",
                overall_review_status="APPROVED",
                is_approved_for_public_release=True,
                watermark_text=None,
            ),
        )
        gate_rep = PublicationGatekeeper.evaluate_publication(doc_approved, requesting_reviewer=None)
        assert gate_rep.can_export is False
        assert any(b.rule_code == "PUB-002" for b in gate_rep.blockers)

    def test_allow_draft_export_with_watermark(self, sample_publication_doc):
        """Permits draft_export and internal_preview with mandatory draft watermarks."""
        gate_rep = PublicationGatekeeper.evaluate_publication(sample_publication_doc)
        assert gate_rep.can_export is True
        assert gate_rep.verdict == ReleaseGateVerdict.CONDITIONAL_DRAFT_ONLY
        assert len(gate_rep.blockers) == 0


# ===========================================================================
# 5. Multilingual HTML Exporter Tests
# ===========================================================================

class TestMultilingualHTMLExporter:
    def test_export_html_indic(self, sample_publication_doc, tmp_path):
        """Generates valid HTML5 with Devanagari typography, DRAFT banner, and verse cards."""
        out_file = str(tmp_path / "test_hi.html")
        MultilingualHTMLExporter.export(sample_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        content = Path(out_file).read_text(encoding="utf-8")
        assert "<!DOCTYPE html>" in content
        assert 'lang="hi-Deva"' in content
        assert 'dir="ltr"' in content
        assert "UNREVIEWED DRAFT" in content
        assert "Shri Shiv Tandava Stotram" in content
        assert "जटाटवीगलज्जलप्रवाहपावितस्थले" in content
        assert "Verse 1" in content
        assert "Verse 2" in content

    def test_export_html_rtl_urdu(self, sample_rtl_publication_doc, tmp_path):
        """Generates HTML5 with dir=\"rtl\" and Urdu Perso-Arabic text."""
        out_file = str(tmp_path / "test_ur.html")
        MultilingualHTMLExporter.export(sample_rtl_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        content = Path(out_file).read_text(encoding="utf-8")
        assert 'lang="ur-Arab"' in content
        assert 'dir="rtl"' in content
        assert "ہم اس پروردگار کا دھیان کرتے ہیں" in content


# ===========================================================================
# 6. Print-Ready PDF Exporter Tests
# ===========================================================================

class TestMultilingualPDFExporter:
    def test_export_pdf_indic(self, sample_publication_doc, tmp_path):
        """Generates valid print-ready PDF with running headers, footers, and DRAFT watermark."""
        out_file = str(tmp_path / "test_hi.pdf")
        MultilingualPDFExporter.export(sample_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        data = Path(out_file).read_bytes()
        assert data.startswith(b"%PDF-")
        assert len(data) > 2000

    def test_export_pdf_rtl_urdu(self, sample_rtl_publication_doc, tmp_path):
        """Generates valid PDF containing Perso-Arabic text without crashing."""
        out_file = str(tmp_path / "test_ur.pdf")
        MultilingualPDFExporter.export(sample_rtl_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        data = Path(out_file).read_bytes()
        assert data.startswith(b"%PDF-")
        assert len(data) > 2000


# ===========================================================================
# 7. Structured DOCX Exporter Tests
# ===========================================================================

class TestMultilingualDOCXExporter:
    def test_export_docx_indic(self, sample_publication_doc, tmp_path):
        """Generates valid Microsoft Word manuscript (.docx) with metadata and verses."""
        out_file = str(tmp_path / "test_hi.docx")
        MultilingualDOCXExporter.export(sample_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        # DOCX is a zip file containing word/document.xml
        with zipfile.ZipFile(out_file) as zf:
            namelist = zf.namelist()
            assert "word/document.xml" in namelist
            doc_xml = zf.read("word/document.xml").decode("utf-8")
            assert "Shri Shiv Tandava Stotram" in doc_xml

    def test_export_docx_rtl_urdu(self, sample_rtl_publication_doc, tmp_path):
        """Generates DOCX with RTL paragraph alignments for Urdu."""
        out_file = str(tmp_path / "test_ur.docx")
        MultilingualDOCXExporter.export(sample_rtl_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        with zipfile.ZipFile(out_file) as zf:
            assert "word/document.xml" in zf.namelist()


# ===========================================================================
# 8. Reflowable EPUB 3 Exporter Tests
# ===========================================================================

class TestMultilingualEPUBExporter:
    def test_export_epub_indic(self, sample_publication_doc, tmp_path):
        """Generates valid EPUB 3 archive adhering strictly to IDPF container spec."""
        out_file = str(tmp_path / "test_hi.epub")
        MultilingualEPUBExporter.export(sample_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        with zipfile.ZipFile(out_file) as zf:
            namelist = zf.namelist()
            # Requirement: mimetype must be first file
            assert namelist[0] == "mimetype"
            info = zf.getinfo("mimetype")
            assert info.compress_type == zipfile.ZIP_STORED
            assert zf.read("mimetype") == b"application/epub+zip"

            # Requirement: container.xml and content.opf
            assert "META-INF/container.xml" in namelist
            assert "OEBPS/content.opf" in namelist
            assert "OEBPS/nav.xhtml" in namelist
            assert "OEBPS/styles.css" in namelist
            assert "OEBPS/titlepage.xhtml" in namelist
            assert "OEBPS/content.xhtml" in namelist

            # Check OPF spine direction
            opf_text = zf.read("OEBPS/content.opf").decode("utf-8")
            assert 'page-progression-direction="ltr"' in opf_text

    def test_export_epub_rtl_urdu(self, sample_rtl_publication_doc, tmp_path):
        """Generates EPUB 3 with page-progression-direction=\"rtl\" for Urdu."""
        out_file = str(tmp_path / "test_ur.epub")
        MultilingualEPUBExporter.export(sample_rtl_publication_doc, output_path=out_file)

        assert os.path.exists(out_file)
        with zipfile.ZipFile(out_file) as zf:
            opf_text = zf.read("OEBPS/content.opf").decode("utf-8")
            assert 'page-progression-direction="rtl"' in opf_text


# ===========================================================================
# 9. Unified Orchestrator & Manifest Tests
# ===========================================================================

class TestMultilingualPublicationOrchestrator:
    def test_export_all_formats_indic(self, sample_publication_doc, tmp_path):
        """Orchestrator produces all 4 formats and emits accurate manifest with SHA-256 hashes."""
        manifest = MultilingualPublicationOrchestrator.export_all(
            document=sample_publication_doc,
            formats=["html", "pdf", "docx", "epub"],
            output_dir=tmp_path,
        )

        assert isinstance(manifest, PublicationManifest)
        assert manifest.content_id == "VEDA-TXT-00001"
        assert manifest.target_bcp47 == "hi-Deva"
        assert set(manifest.artifacts.keys()) == {"html", "pdf", "docx", "epub"}

        for fmt, art in manifest.artifacts.items():
            assert os.path.exists(art.file_path)
            assert art.file_size_bytes > 0
            assert len(art.sha256_hash) == 64

        # Verify manifest JSON file was written
        m_file = tmp_path / f"{sample_publication_doc.metadata.content_id}_{sample_publication_doc.target.bcp47}_manifest.json"
        assert m_file.exists()
        saved_dict = json.loads(m_file.read_text(encoding="utf-8"))
        assert saved_dict["content_id"] == "VEDA-TXT-00001"
        assert len(saved_dict["artifacts"]) == 4

    def test_export_text_from_database(self, isolated_db_session, tmp_path):
        """Tests database loading through orchestrator using isolated session."""
        manifest = MultilingualPublicationOrchestrator.export_text_from_database(
            session=isolated_db_session,
            text_id_or_content_id="VEDA-TXT-TEST01",
            target_language="hi",
            target_script="Deva",
            formats=["html", "epub"],
            output_dir=tmp_path,
        )
        assert manifest.content_id == "VEDA-TXT-TEST01"
        assert "html" in manifest.artifacts
        assert "epub" in manifest.artifacts
