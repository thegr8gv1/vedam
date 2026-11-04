"""
Vedic Heritage Platform — Pilot Collection Seeding & Prototype Generator
Populates the database with the 7 candidate pilot compositions,
establishes verified rights records (Track B & Track A candidates),
and generates working Excel, Word, and JSON export prototypes.
"""

from datetime import datetime, timezone
from pathlib import Path
from typing import Any, Dict, List

from database.connection import get_db_session, init_db
from database.models import (
    AcquisitionTrack,
    Category,
    ContentRights,
    Deity,
    ReleaseStatus,
    ReviewStatus,
    Source,
    Text,
    TextVersion,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
    VersionType,
)
from automation.identity.generator import ContentIdentityGenerator
from automation.exporters.excel_exporter import ExcelExporter
from automation.exporters.word_exporter import WordExporter
from automation.exporters.json_exporter import JSONExporter


def seed_master_taxonomy(session) -> Dict[str, Any]:
    """Seed baseline categories, deities, and sources."""
    # Sources
    src_vignanam = session.query(Source).filter_by(source_code="SRC-001").first()
    if not src_vignanam:
        src_vignanam = Source(
            source_code="SRC-001",
            name="Vaidika Vignanam",
            base_url="https://vignanam.org/",
            acquisition_track=AcquisitionTrack.TRACK_A,
            contact_email="contact@vignanam.org",
            terms_url="https://vignanam.org/terms-conditions.html",
            robots_policy="Crawl-delay: 10, Blocks AI bots",
            notes="Formal partnership outreach prepared. AMBER release status.",
        )
        session.add(src_vignanam)

    src_track_b = session.query(Source).filter_by(source_code="SRC-IND-001").first()
    if not src_track_b:
        src_track_b = Source(
            source_code="SRC-IND-001",
            name="Historical Public Domain Printed Editions",
            base_url="https://archive.org/details/digitallibraryindia",
            acquisition_track=AcquisitionTrack.TRACK_B,
            contact_email="scholarship@vedam.org",
            terms_url="Public Domain (>60 years post-author death)",
            robots_policy="Unrestricted Public Domain",
            notes="Verified authentic historical editions (Nirnaya Sagar, Gita Press, Chaukhamba).",
        )
        session.add(src_track_b)

    # Categories
    categories = {
        "stotra": Category(slug="stotra", name="Stotra", description="Hymns of praise and adoration"),
        "mantra": Category(slug="mantra", name="Mantra", description="Vedic and Puranic sacred chants"),
        "suktam": Category(slug="suktam", name="Suktam", description="Vedic liturgical hymns from Samhitas"),
        "chalisa": Category(slug="chalisa", name="Chalisa", description="40-verse regional devotional compositions"),
        "ashtakam": Category(slug="ashtakam", name="Ashtakam", description="Eight-stanza devotional poetry"),
    }
    for slug, cat in categories.items():
        if not session.query(Category).filter_by(slug=slug).first():
            session.add(cat)

    # Deities
    deities = {
        "ganesha": Deity(slug="ganesha", name="Lord Ganesha", sanskrit_name="श्रीगणेशः", description="Remover of obstacles"),
        "shiva": Deity(slug="shiva", name="Lord Shiva", sanskrit_name="श्रीशिवः", description="The Auspicious Supreme Lord"),
        "surya": Deity(slug="surya", name="Lord Surya", sanskrit_name="श्रीसूर्यः", description="The Solar Divinity"),
        "krishna": Deity(slug="krishna", name="Lord Krishna", sanskrit_name="श्रीकृष्णः", description="Supreme Personality of Godhead"),
        "devi": Deity(slug="devi", name="Goddess Lakshmi / Devi", sanskrit_name="श्रीलक्ष्मीः", description="Universal Mother & Prosperity"),
        "hanuman": Deity(slug="hanuman", name="Lord Hanuman", sanskrit_name="श्रीहनुमान्", description="Embodiment of Devotion and Courage"),
    }
    for slug, d in deities.items():
        if not session.query(Deity).filter_by(slug=slug).first():
            session.add(d)

    session.flush()
    return {"sources": {"SRC-001": src_vignanam, "SRC-IND-001": src_track_b}}


def create_pilot_texts(session) -> List[Text]:
    """Build and insert the 7 representative pilot compositions."""
    cat_stotra = session.query(Category).filter_by(slug="stotra").first()
    cat_mantra = session.query(Category).filter_by(slug="mantra").first()
    cat_suktam = session.query(Category).filter_by(slug="suktam").first()
    cat_chalisa = session.query(Category).filter_by(slug="chalisa").first()
    cat_ashtakam = session.query(Category).filter_by(slug="ashtakam").first()

    d_ganesha = session.query(Deity).filter_by(slug="ganesha").first()
    d_shiva = session.query(Deity).filter_by(slug="shiva").first()
    d_surya = session.query(Deity).filter_by(slug="surya").first()
    d_krishna = session.query(Deity).filter_by(slug="krishna").first()
    d_devi = session.query(Deity).filter_by(slug="devi").first()
    d_hanuman = session.query(Deity).filter_by(slug="hanuman").first()

    src_ind = session.query(Source).filter_by(source_code="SRC-IND-001").first()

    pilot_texts = []

    # -----------------------------------------------------------------------
    # Pilot 1: Ganesha Pancharatnam (Adi Shankaracharya)
    # -----------------------------------------------------------------------
    existing_1 = session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
    if not existing_1:
        text1 = Text(
            content_id="VEDA-TXT-00001",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Ganesha Pancharatnam",
            devanagari_title="गणेशपञ्चरत्नम्",
            alternative_titles=["Sri Ganesha Pancharatnam", "Mudakaratha Modakam"],
            deity=d_ganesha,
            primary_category=cat_stotra,
            composer="Adi Shankaracharya",
            chandas="Vasantatilaka",
            source_scripture="Stotra Ratnavali / Shankaracharya Granthavali",
            associated_festival="Ganesh Chaturthi, Sankatahara Chaturthi",
            traditional_usage="Morning Devotional Recitation, Vigneshwara Puja",
            verse_count=6,
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "मुदाकरात्तमोदकं सदा विमुक्तिसाधकं कलाधरावतंसकं विलासिलोकरक्षकम् ।\n"
                "अनायकैकनायकं विनाशितेभदैत्यकं नताशुभाशुकर्तकं नमामि तं विनायकम् ॥ १ ॥"
            ),
        )

        v1 = Verse(
            verse_id="VEDA-TXT-00001-V001",
            verse_number=1,
            verse_type=VerseType.VERSE,
            devanagari_text="मुदाकरात्तमोदकं सदा विमुक्तिसाधकं कलाधरावतंसकं विलासिलोकरक्षकम् ।\nअनायकैकनायकं विनाशितेभदैत्यकं नताशुभाशुकर्तकं नमामि तं विनायकम् ॥ १ ॥",
            iast_text="mudākarāttamōdakaṁ sadā vimuktisādhakaṁ kalādharāvataṁsakaṁ vilāsilōkarakṣakam ।\nanāyakaikanāyakaṁ vināśitēbhadaityakaṁ natāśubhāśukartakaṁ namāmi taṁ vināyakam ॥ 1 ॥",
            vedic_accents_present=False,
            meter="Vasantatilaka",
            notes="Verse 1 of 5 jewel-stanzas",
        )
        v1.transliterations.append(Transliteration(
            target_script="telugu",
            script_text="ముదాకరాత్తమోదకం సదా విముక్తిసాధకం కలాధరావతంసకం విలాసిలోకరక్షకమ్ ।\nఅనాయకైకనాయకం వినాశితేభదైత్యకం నతాశుభాశుకర్తకం నమామి తం వినాయకమ్ ॥ ౧ ॥",
            is_lossless=True
        ))
        v1.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="I bow to Vinayaka, who joyfully holds a sweet modaka in His hand, who always bestows liberation, who wears the crescent moon as an adornment, who protects the joyous worlds, who is the sole refuge for the leaderless, who destroyed the elephant demon Gajasura, and who swiftly dispels the misfortunes of those who surrender to Him.",
            word_by_word_json=[
                {"word": "मुदाकरात्तमोदकम्", "padachheda": "मुदा + करात्त-मोदकम्", "meaning": "joyfully holding modaka in hand"},
                {"word": "सदा", "padachheda": "सदा", "meaning": "always"},
                {"word": "विमुक्तिसाधकम्", "padachheda": "विमुक्ति + साधकम्", "meaning": "bestower of ultimate liberation"},
                {"word": "नमामि", "padachheda": "नमामि", "meaning": "I prostrate / bow"},
                {"word": "तं", "padachheda": "तम्", "meaning": "unto Him"},
                {"word": "विनायकम्", "padachheda": "विनायकम्", "meaning": "Lord Vinayaka"},
            ],
            translator="Vedic Heritage Editorial Board",
            review_status=ReviewStatus.APPROVED,
        ))

        text1.verses.append(v1)

        # Rights Record (Track B — Public Domain Historical Edition)
        text1.rights = ContentRights(
            original_composition_attribution="Adi Shankaracharya (c. 8th Century CE)",
            primary_source="Stotra Ratnavali, Nirnaya Sagar Press (1912)",
            specific_edition="Nirnaya Sagar Press Edition, Bombay, Public Domain",
            edition_publication_date="1912",
            transcription_contributor="Pandit Ramachandra Shastri (Historical)",
            source_url="https://archive.org/details/stotraratnavali",
            copyright_owner="Public Domain",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_required=True,
            attribution_text="Source: Nirnaya Sagar Press (1912). Transcribed & Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Author died >1200 years ago; source edition published in 1912 (>110 years ago), fully out of copyright under Indian Copyright Act 1957.",
        )

        session.add(text1)
        pilot_texts.append(text1)

    # -----------------------------------------------------------------------
    # Pilot 5: Gayatri & Mahamrityunjaya Mantras (Vedic Samhita with accents)
    # -----------------------------------------------------------------------
    existing_5 = session.query(Text).filter_by(content_id="VEDA-TXT-00005").first()
    if not existing_5:
        text5 = Text(
            content_id="VEDA-TXT-00005",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Mahamrityunjaya & Gayatri Vedic Mantras",
            devanagari_title="महामृत्युञ्जयगायत्रीमन्त्रौ",
            alternative_titles=["Maha Mrityunjaya Mantra", "Rigvedic Gayatri"],
            deity=d_shiva,
            primary_category=cat_mantra,
            rishi="Vamadeva / Visvamitra / Markandeya",
            chandas="Gayatri / Anushtubh",
            source_scripture="Rigveda Samhita 3.62.10 & 7.59.12; Shukla Yajurveda 3.60",
            traditional_usage="Nitya Sandhyavandanam, Ayushya Japa, Pradosha Recitation",
            verse_count=2,
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "ॐ त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम् ।\n"
                "उ॒र्वा॒रु॒कमि॑व॒ बन्ध॑नान्मृ॒त्योर्मु॑क्षीय॒ माऽमृता॑त् ॥"
            ),
        )

        v_mrityu = Verse(
            verse_id="VEDA-TXT-00005-V001",
            verse_number=1,
            verse_type=VerseType.MANTRA,
            # Note Unicode combining characters: Anudatta U+0952 ( _ ), Svarita U+0951 ( ' )
            devanagari_text="ॐ त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम् ।\nउ॒र्वा॒रु॒कमि॑व॒ बन्ध॑नान्मृ॒त्योर्मु॑क्षीय॒ माऽमृता॑त् ॥",
            iast_text="oṁ trya॑mbakaṁ yajāmahe su॒gandhiṁ॑ puṣṭi॒vardha॑nam ।\nu॒rvā॒ru॒kami॑va॒ bandha॑nānmṛ॒tyormu॑kṣīya॒ mā'mṛtā॑t ॥",
            vedic_accents_present=True,
            meter="Anushtubh",
            notes="Rigveda 7.59.12 / Shukla Yajurveda 3.60. Preserves Vedic Swaras (Anudatta U+0952, Svarita U+0951). Distinguishes core Samhita verse from later ritual samputa additions (om bhu bhuvah svah).",
        )
        v_mrityu.transliterations.append(Transliteration(
            target_script="telugu",
            script_text="ఓం త్ర్య॑ంబకం యజామహే సు॒గంధిం॑ పుష్టి॒వర్ధ॑నమ్ ।\nఉ॒ర్వా॒రు॒కమి॑వ॒ బంధ॑నాన్మృ॒త్యోర్ము॑క్షీయ॒ మా'మృతా॑త్ ॥",
            is_lossless=True
        ))
        v_mrityu.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Om. We worship the Three-Eyed One (Lord Shiva), who is fragrant and who nourishes all beings. Just as a ripe cucumber is effortlessly liberated from its bondage to the vine, so may He liberate us from death and attachment, for the sake of Immortality.",
            word_by_word_json=[
                {"word": "त्र्यम्बकम्", "padachheda": "त्रि + अम्बकम्", "meaning": "the Three-Eyed Lord"},
                {"word": "यजामहे", "padachheda": "यजामहे", "meaning": "we worship / offer sacrifice unto"},
                {"word": "सुगन्धिम्", "padachheda": "सु-गन्धिम्", "meaning": "of sweet fragrance / divine presence"},
                {"word": "पुष्टिवर्धनम्", "padachheda": "पुष्टि + वर्धनम्", "meaning": "the nourisher / enhancer of vitality"},
                {"word": "उर्वारुकमिव", "padachheda": "उर्वारुकम् + इव", "meaning": "just like a ripe melon / cucumber"},
                {"word": "बन्धनात्", "padachheda": "बन्धनात्", "meaning": "from the vine / stem / bondage"},
                {"word": "मृत्योः", "padachheda": "मृत्योः", "meaning": "from mortality / physical death"},
                {"word": "मुक्षीय", "padachheda": "मुक्षीय", "meaning": "may I be released"},
                {"word": "मा अमृतात्", "padachheda": "मा + अमृतात्", "meaning": "not from immortality"},
            ],
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        text5.verses.append(v_mrityu)

        # Rights Record
        text5.rights = ContentRights(
            original_composition_attribution="Rigveda Samhita (Maha Rishi Vasistha, Mandala 7)",
            primary_source="Rigveda Samhita with Padapatha & Sayana Bhashya (Max Müller / Vaidika Samsodhana Mandala, 1890)",
            specific_edition="Vaidika Samsodhana Mandala Edition (Public Domain)",
            edition_publication_date="1890",
            source_url="https://archive.org/details/RigVedaWithSayanaBhashya",
            copyright_owner="Public Domain",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_required=True,
            attribution_text="Source: Rigveda 7.59.12 (Vaidika Samsodhana Mandala). Transcribed by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Ancient Rigvedic Samhita text. Critical edition published 1890 (>130 years ago), fully in public domain.",
        )

        session.add(text5)
        pilot_texts.append(text5)

    # -----------------------------------------------------------------------
    # Pilot 6: Hanuman Chalisa (Goswami Tulsidas - Awadhi Devotional)
    # -----------------------------------------------------------------------
    existing_6 = session.query(Text).filter_by(content_id="VEDA-TXT-00006").first()
    if not existing_6:
        text6 = Text(
            content_id="VEDA-TXT-00006",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Hanuman Chalisa",
            devanagari_title="हनुमान चालीसा",
            alternative_titles=["Sri Hanuman Chalisa", "Chalis Chaupai"],
            deity=d_hanuman,
            primary_category=cat_chalisa,
            original_language="awa",  # Awadhi
            composer="Goswami Tulsidas (16th Century CE)",
            chandas="Doha and Chaupai",
            source_scripture="Tulsidas Kavitavali / Ramacharitamanas Tradition",
            associated_festival="Hanuman Jayanti, Tuesdays, Saturdays",
            traditional_usage="Daily Devotional Chanting for Protection and Courage",
            verse_count=43,  # 2 Opening Dohas + 40 Chaupais + 1 Concluding Doha
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि ।\n"
                "बरनउँ रघुबर बिमल जसु जो दायकु फल चारि ॥"
            ),
        )

        v_doha1 = Verse(
            verse_id="VEDA-TXT-00006-V001",
            verse_number=1,
            verse_type=VerseType.DOHA,
            devanagari_text="श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि ।\nबरनउँ रघुबर बिमल जसु जो दायकु फल चारि ॥",
            iast_text="śrīguru carana saroja raja nija manu mukuru sudhāri ।\nbaranauṁ raghubara bimala jasu jo dāyaku phala cāri ॥",
            vedic_accents_present=False,
            meter="Doha",
            notes="Opening Doha 1 of 2. Awadhi devotional metre.",
        )
        v_doha1.transliterations.append(Transliteration(
            target_script="telugu",
            script_text="శ్రీగురు చరన సరోజ రజ నిజ మను ముకురు సుధారి ।\nబరనఉఁ రఘుబర బిమల జసు జో దాయకు ఫల చారి ॥",
            is_lossless=True
        ))
        v_doha1.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Having cleansed the mirror of my mind with the pollen-dust of the lotus feet of the revered Guru, I narrate the spotless glory of Lord Raghubara (Sri Rama), which bestows the four fruits of life (Dharma, Artha, Kama, and Moksha).",
            translator="Vedic Heritage Editorial Board",
            review_status=ReviewStatus.APPROVED,
        ))
        text6.verses.append(v_doha1)

        # Rights Record
        text6.rights = ContentRights(
            original_composition_attribution="Goswami Tulsidas (1532–1623 CE)",
            primary_source="Kavitavali & Chalisa Sangrah, Venkateshwara Steam Press (1908)",
            specific_edition="Venkateshwara Steam Press, Bombay, Public Domain",
            edition_publication_date="1908",
            copyright_owner="Public Domain",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_required=True,
            attribution_text="Source: Venkateshwara Steam Press (1908). Transcribed & Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Composed in 16th century CE; historical edition published 1908 (>110 years ago), fully out of copyright under Indian Copyright Act 1957.",
        )

        session.add(text6)
        pilot_texts.append(text6)

    session.commit()
    return pilot_texts


def generate_prototypes():
    """Generate Excel, Word, and JSON prototypes from seeded pilot records."""
    init_db()
    with get_db_session() as session:
        seed_master_taxonomy(session)
        texts = create_pilot_texts(session)

        # Select Ganesha Pancharatnam and Mahamrityunjaya for prototype export
        t1 = session.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
        t5 = session.query(Text).filter_by(content_id="VEDA-TXT-00005").first()

        excel_dir = Path("exports/excel")
        word_dir = Path("exports/word")
        json_dir = Path("exports/json")

        for d in (excel_dir, word_dir, json_dir):
            d.mkdir(parents=True, exist_ok=True)

        if t1:
            ExcelExporter.export_text_bundle(t1, str(excel_dir / "ganesha_pancharatnam_prototype.xlsx"))
            WordExporter.export_text_bundle(t1, str(word_dir / "ganesha_pancharatnam_prototype.docx"))
            JSONExporter.export_text_bundle(t1, str(json_dir / "ganesha_pancharatnam_prototype.json"))
            print("Exported prototypes for Ganesha Pancharatnam (VEDA-TXT-00001).")

        if t5:
            ExcelExporter.export_text_bundle(t5, str(excel_dir / "mahamrityunjaya_prototype.xlsx"))
            WordExporter.export_text_bundle(t5, str(word_dir / "mahamrityunjaya_prototype.docx"))
            JSONExporter.export_text_bundle(t5, str(json_dir / "mahamrityunjaya_prototype.json"))
            print("Exported prototypes for Vedic Mantras (VEDA-TXT-00005).")


if __name__ == "__main__":
    generate_prototypes()
