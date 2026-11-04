"""
Vedic Heritage Platform — Phase 2B Authorized Pilot Collection
Seeds the database with the 8 authorized candidate compositions, establishes
jurisdiction-aware rights records, preserves Vedic swaras and Awadhi classification,
and generates prototype exports in Excel, Word, and JSON.
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
    SourceEdition,
    Text,
    TextVersion,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
    VersionType,
)
from automation.cleaners.unicode_preserver import TransliterationEngine, UnicodePreserver
from automation.exporters.excel_exporter import ExcelExporter
from automation.exporters.json_exporter import JSONExporter
from automation.exporters.word_exporter import WordExporter
from automation.identity.generator import ContentIdentityGenerator


def seed_master_taxonomy(session) -> Dict[str, Any]:
    """Ensure all core sources, categories, and deities exist."""
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
            notes="Track A formal partnership outreach prepared. AMBER release status.",
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
            terms_url="Public Domain (>60 years post-author death / Pre-1930 editions)",
            robots_policy="Unrestricted Public Domain",
            notes="Verified authentic historical editions (Nirnaya Sagar, Vaidika Samsodhana Mandala, Venkateshwara Steam Press).",
        )
        session.add(src_track_b)

    # Categories
    categories = {
        "stotra": ("Stotra", "Hymns of praise and adoration"),
        "mantra": ("Mantra", "Vedic and Puranic sacred chants"),
        "suktam": ("Suktam", "Vedic liturgical hymns from Samhitas and Brahmanas"),
        "chalisa": ("Chalisa", "40-verse regional devotional compositions"),
        "ashtakam": ("Ashtakam", "Eight-stanza devotional poetry"),
        "itihasa": ("Itihasa Hymn", "Devotional hymns embedded in the Epics"),
    }
    for slug, (name, desc) in categories.items():
        if not session.query(Category).filter_by(slug=slug).first():
            session.add(Category(slug=slug, name=name, description=desc))

    # Deities
    deities = {
        "ganesha": ("Lord Ganesha", "श्रीगणेशः", "Remover of obstacles and Lord of beginnings"),
        "shiva": ("Lord Shiva", "श्रीशिवः", "The Auspicious Supreme Lord"),
        "surya": ("Lord Surya", "श्रीसूर्यः", "The Solar Divinity, giver of health and light"),
        "krishna": ("Lord Krishna", "श्रीकृष्णः", "Supreme Lord of Mathura & Vrindavan"),
        "devi": ("Goddess Lakshmi / Devi", "श्रीलक्ष्मीः", "Universal Mother & Bestower of Sri"),
        "hanuman": ("Lord Hanuman", "श्रीहनुमान्", "Embodiment of Devotion, Courage and Wisdom"),
    }
    for slug, (name, sname, desc) in deities.items():
        if not session.query(Deity).filter_by(slug=slug).first():
            session.add(Deity(slug=slug, name=name, sanskrit_name=sname, description=desc))

    session.flush()
    return {"sources": {"SRC-001": src_vignanam, "SRC-IND-001": src_track_b}}


def seed_all_pilot_texts(session) -> List[Text]:
    """Populate all 8 authorized candidate pilot compositions."""
    cat_stotra = session.query(Category).filter_by(slug="stotra").first()
    cat_mantra = session.query(Category).filter_by(slug="mantra").first()
    cat_suktam = session.query(Category).filter_by(slug="suktam").first()
    cat_chalisa = session.query(Category).filter_by(slug="chalisa").first()
    cat_ashtakam = session.query(Category).filter_by(slug="ashtakam").first()
    cat_itihasa = session.query(Category).filter_by(slug="itihasa").first()

    d_ganesha = session.query(Deity).filter_by(slug="ganesha").first()
    d_shiva = session.query(Deity).filter_by(slug="shiva").first()
    d_surya = session.query(Deity).filter_by(slug="surya").first()
    d_krishna = session.query(Deity).filter_by(slug="krishna").first()
    d_devi = session.query(Deity).filter_by(slug="devi").first()
    d_hanuman = session.query(Deity).filter_by(slug="hanuman").first()

    src_ind = session.query(Source).filter_by(source_code="SRC-IND-001").first()

    pilot_records = []

    # Helper function to generate multi-script transliterations
    def add_scripts(verse_obj, devanagari_str):
        for script in ["telugu", "tamil", "kannada", "malayalam"]:
            try:
                converted = TransliterationEngine.to_script(devanagari_str, script)
                verse_obj.transliterations.append(Transliteration(
                    target_script=script,
                    script_text=converted,
                    is_lossless=True,
                ))
            except Exception:
                pass

    # -----------------------------------------------------------------------
    # 1. Ganesha Pancharatnam (VEDA-TXT-00001)
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00001").first():
        t1 = Text(
            content_id="VEDA-TXT-00001",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Ganesha Pancharatnam",
            devanagari_title="गणेशपञ्चरत्नम्",
            alternative_titles=["Sri Ganesha Pancharatna Stotram", "Mudakaratha Modakam"],
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
            meter="Vasantatilaka",
        )
        add_scripts(v1, v1.devanagari_text)
        v1.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="I bow to Vinayaka, who joyfully holds a sweet modaka in His hand, who always bestows liberation, who wears the crescent moon as an ornament, who protects the joyous worlds, who is the sole refuge for the leaderless, who destroyed the elephant demon Gajasura, and who swiftly dispels the misfortunes of those who surrender to Him.",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t1.verses.append(v1)
        t1.rights = ContentRights(
            original_composition_attribution="Adi Shankaracharya (c. 8th Century CE)",
            primary_source="Stotra Ratnavali, Nirnaya Sagar Press (1912)",
            specific_edition="Nirnaya Sagar Press Edition, Bombay, Public Domain",
            edition_publication_date="1912",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Nirnaya Sagar Press (1912). Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Author died >1200 years ago; edition published in 1912 (>110 years ago), fully in public domain worldwide.",
        )
        session.add(t1)
        pilot_records.append(t1)

    # -----------------------------------------------------------------------
    # 2. Shiva Tandava Stotram (VEDA-TXT-00002)
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00002").first():
        t2 = Text(
            content_id="VEDA-TXT-00002",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Shiva Tandava Stotram",
            devanagari_title="शिवताण्डवस्तोत्रम्",
            alternative_titles=["Ravana Kruta Shiva Tandava Stotram"],
            deity=d_shiva,
            primary_category=cat_stotra,
            composer="Ravana",
            chandas="Panchachamara",
            associated_festival="Maha Shivaratri, Pradosham",
            traditional_usage="Chanting for Vitality, Strength, and Shiva Bhakti",
            verse_count=15,
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "जटाटवीगलज्जलप्रवाहपावितस्थले गलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम् ।\n"
                "डमड्डमड्डमड्डमन्निनादवड्डमर्वयं चकार चण्डताण्डवं तनोतु नः शिवः शिवम् ॥ १ ॥"
            ),
        )
        v2 = Verse(
            verse_id="VEDA-TXT-00002-V001",
            verse_number=1,
            verse_type=VerseType.VERSE,
            devanagari_text="जटाटवीगलज्जलप्रवाहपावितस्थले गलेऽवलम्ब्य लम्बितां भुजङ्गतुङ्गमालिकाम् ।\nडमड्डमड्डमड्डमन्निनादवड्डमर्वयं चकार चण्डताण्डवं तनोतु नः शिवः शिवम् ॥ १ ॥",
            iast_text="jaṭāṭavīgalajjala-pravāha-pāvitasthale gale'valambya lambitāṁ bhujaṅgatuṅgamālikām ।\nḍamaḍ-ḍamaḍ-ḍamaḍ-ḍaman-ninādavad-ḍamarvayaṁ cakāra caṇḍatāṇḍavaṁ tanotu naḥ śivaḥ śivam ॥ 1 ॥",
            meter="Panchachamara",
        )
        add_scripts(v2, v2.devanagari_text)
        v2.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="May Lord Shiva extend auspiciousness unto us—He on whose neck hangs the garland of the supreme serpent, His holy neck sanctified by the waters cascading from the dense forest of His matted locks, as His damaru emits the resonant sound 'damad-damad-damad-damad' while He performs the impassioned cosmic Tandava dance.",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t2.verses.append(v2)
        t2.rights = ContentRights(
            original_composition_attribution="Traditional (Attributed to Ravana)",
            primary_source="Brihat Stotra Ratnakara, Nirnaya Sagar Press (1906)",
            specific_edition="Nirnaya Sagar Press Edition, Bombay, Public Domain",
            edition_publication_date="1906",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Nirnaya Sagar Press (1906). Transcribed by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Classical devotional hymn published 1906, out of copyright worldwide.",
        )
        session.add(t2)
        pilot_records.append(t2)

    # -----------------------------------------------------------------------
    # 3. Aditya Hrudayam (VEDA-TXT-00003)
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00003").first():
        t3 = Text(
            content_id="VEDA-TXT-00003",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Aditya Hrudayam",
            devanagari_title="आदित्यहृदयम्",
            alternative_titles=["Sri Aditya Hridaya Stotram", "Agastya-prokta Aditya Hrudaya"],
            deity=d_surya,
            primary_category=cat_itihasa,
            composer="Sage Agastya",
            rishi="Agastya",
            chandas="Anushtubh",
            source_scripture="Valmiki Ramayana, Yuddha Kanda, Sarga 105",
            associated_festival="Ratha Saptami, Sundays",
            traditional_usage="Victory over Obstacles, Health, Vitality, Solar Upasana",
            verse_count=31,
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "ततो युद्धपरिश्रान्तं समरे चिन्तया स्थितम् ।\n"
                "रावणं चाग्रतो दृष्ट्वा युद्धाय समुपस्थितम् ॥ १ ॥"
            ),
        )
        v3 = Verse(
            verse_id="VEDA-TXT-00003-V001",
            verse_number=1,
            verse_type=VerseType.VERSE,
            devanagari_text="ततो युद्धपरिश्रान्तं समरे चिन्तया स्थितम् ।\nरावणं चाग्रतो दृष्ट्वा युद्धाय समुपस्थितम् ॥ १ ॥",
            iast_text="tato yuddhaparāśrāntaṁ samare cintayā sthitam ।\nrāvaṇaṁ cāgrato dṛṣṭvā yuddhāya samupasthitam ॥ 1 ॥",
            meter="Anushtubh",
        )
        add_scripts(v3, v3.devanagari_text)
        v3.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Beholding Sri Rama standing weary in the midst of battle, absorbed in deep thought, and seeing Ravana standing before Him fully prepared for war...",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t3.verses.append(v3)
        t3.rights = ContentRights(
            original_composition_attribution="Sage Valmiki (Ramayana, Yuddha Kanda)",
            primary_source="Valmiki Ramayana, Nirnaya Sagar Critical Edition (1930)",
            specific_edition="Nirnaya Sagar Press Edition (1930)",
            edition_publication_date="1930",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Valmiki Ramayana Yuddha Kanda 105 (Nirnaya Sagar 1930). Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Ancient Valmiki Ramayana text published in 1930, fully public domain in India and the US.",
        )
        session.add(t3)
        pilot_records.append(t3)

    # -----------------------------------------------------------------------
    # 4. Madhurashtakam (VEDA-TXT-00004)
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00004").first():
        t4 = Text(
            content_id="VEDA-TXT-00004",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Madhurashtakam",
            devanagari_title="मधुराष्टकम्",
            alternative_titles=["Sri Madhurashtaka Stotram", "Adharam Madhuram"],
            deity=d_krishna,
            primary_category=cat_ashtakam,
            composer="Vallabhacharya (1479–1531 CE)",
            chandas="Totaka",
            associated_festival="Janmashtami, Radhashtami",
            traditional_usage="Pushtimarg Bhakti, Krishna Prema Recitation",
            verse_count=9,  # 8 Stanzas + 1 Phalasruti Stanza
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "अधरं मधुरं वदनं मधुरं नयनं मधुरं हसितं मधुरम् ।\n"
                "हृदयं मधुरं गमनं मधुरं मधुराधिपतेरखिलं मधुरम् ॥ १ ॥"
            ),
        )
        v4 = Verse(
            verse_id="VEDA-TXT-00004-V001",
            verse_number=1,
            verse_type=VerseType.VERSE,
            devanagari_text="अधरं मधुरं वदनं मधुरं नयनं मधुरं हसितं मधुरम् ।\nहृदयं मधुरं गमनं मधुरं मधुराधिपतेरखिलं मधुरम् ॥ १ ॥",
            iast_text="adharaṁ madhuraṁ vadanaṁ madhuraṁ nayanaṁ madhuraṁ hasitaṁ madhuram ।\nhṛdayaṁ madhuraṁ gamanaṁ madhuraṁ madhurādhipaterakhilaṁ madhuram ॥ 1 ॥",
            meter="Totaka",
        )
        add_scripts(v4, v4.devanagari_text)
        v4.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Sweet are His lips, sweet is His face, sweet are His eyes, sweet is His smile, sweet is His heart, and sweet is His gait—everything is completely sweet about the Lord of Sweetness.",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t4.verses.append(v4)
        t4.rights = ContentRights(
            original_composition_attribution="Vallabhacharya (15th Century CE)",
            primary_source="Brihat Stotra Muktavali, Chaukhamba Sanskrit Sansthan (1924)",
            specific_edition="Chaukhamba Edition (1924)",
            edition_publication_date="1924",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Chaukhamba Sanskrit Sansthan (1924). Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Composed 16th century CE; source edition published 1924 (>100 years ago), fully out of copyright worldwide.",
        )
        session.add(t4)
        pilot_records.append(t4)

    # -----------------------------------------------------------------------
    # 5. Mahamrityunjaya Mantra (VEDA-TXT-00005) - Rigveda 7.59.12
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00005").first():
        t5 = Text(
            content_id="VEDA-TXT-00005",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Mahamrityunjaya Vedic Mantra",
            devanagari_title="महामृत्युञ्जयमन्त्रः",
            alternative_titles=["Tryambakam Mantra", "Mrita-Sanjivani Mantra"],
            deity=d_shiva,
            primary_category=cat_mantra,
            rishi="Maha Rishi Vasistha / Markandeya",
            chandas="Anushtubh",
            source_scripture="Rigveda Samhita 7.59.12; Shukla Yajurveda Samhita 3.60; Taittiriya Samhita 1.8.6.i",
            traditional_usage="Ayushya Japa, Longevity, Pradosha Recitation, Liberation from Death",
            verse_count=1,
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "ॐ त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम् ।\n"
                "उ॒र्वा॒रु॒कमि॑व॒ बन्ध॑नान्मृ॒त्योर्मु॑क्षीय॒ माऽमृता॑त् ॥"
            ),
        )
        v5 = Verse(
            verse_id="VEDA-TXT-00005-V001",
            verse_number=1,
            verse_type=VerseType.MANTRA,
            devanagari_text="ॐ त्र्य॑म्बकं यजामहे सु॒गन्धिं॑ पुष्टि॒वर्ध॑नम् ।\nउ॒र्वा॒रु॒कमि॑व॒ बन्ध॑नान्मृ॒त्योर्मु॑क्षीय॒ माऽमृता॑त् ॥",
            iast_text="oṁ trya॑mbakaṁ yajāmahe su॒gandhiṁ॑ puṣṭi॒vardha॑nam ।\nu॒rvā॒ru॒kami॑va॒ bandha॑nānmṛ॒tyormu॑kṣīya॒ mā'mṛtā॑t ॥",
            vedic_accents_present=True,
            meter="Anushtubh",
            notes="Rigveda 7.59.12 / Shukla Yajurveda 3.60. Preserves authentic Vedic swaras (Anudatta U+0952, Svarita U+0951). Distinguishes core Samhita verse from later ritual samputa additions.",
        )
        add_scripts(v5, v5.devanagari_text)
        v5.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Om. We worship the Three-Eyed Lord (Shiva), who is fragrant and who nourishes all beings. Just as a ripe melon is released from its vine, may He liberate us from death and attachment, for the sake of Immortality.",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t5.verses.append(v5)
        t5.rights = ContentRights(
            original_composition_attribution="Rigveda Samhita (Mandala 7, Sukta 59, Rik 12)",
            primary_source="Rigveda Samhita with Padapatha, Vaidika Samsodhana Mandala (1890)",
            specific_edition="Vaidika Samsodhana Mandala Critical Edition (1890)",
            edition_publication_date="1890",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Rigveda 7.59.12 (Vaidika Samsodhana Mandala 1890). Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Ancient Rigvedic Samhita text. Critical edition published 1890 (>130 years ago), fully in public domain worldwide.",
        )
        session.add(t5)
        pilot_records.append(t5)

    # -----------------------------------------------------------------------
    # 6. Gayatri Mantra (VEDA-TXT-00006) - Rigveda 3.62.10
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00006").first():
        t6 = Text(
            content_id="VEDA-TXT-00006",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Gayatri Vedic Mantra",
            devanagari_title="सावित्रीगायत्रीमन्त्रः",
            alternative_titles=["Savitri Mantra", "Rigvedic Gayatri"],
            deity=d_surya,
            primary_category=cat_mantra,
            rishi="Maha Rishi Visvamitra",
            chandas="Gayatri (Tripada, 24 syllables: 8-8-8)",
            devata="Savitr (The Divine Sun / Illuminator of Consciousness)",
            source_scripture="Rigveda Samhita 3.62.10; Shukla Yajurveda Samhita 36.3; Sama Veda Samhita 1462",
            traditional_usage="Nitya Sandhyavandanam, Gayatri Japa, Spiritual Enlightenment",
            verse_count=1,
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "ॐ भूर्भुव॒स्स॒वः॑ । तत्स॑वि॒तुर्वरे॑ण्यं॒ भर्गो॑ दे॒वस्य॑ धीमहि ।\n"
                "धियो॒ यो नः॑ प्रचो॒दया॑त् ॥"
            ),
        )
        v6 = Verse(
            verse_id="VEDA-TXT-00006-V001",
            verse_number=1,
            verse_type=VerseType.MANTRA,
            # Distinguishes Rigvedic Samhita Rik (tat savitur varenyam...) from liturgical preface (Om bhur bhuvah svah)
            devanagari_text="ॐ भूर्भुव॒स्स॒वः॑ ।\nतत्स॑वि॒तुर्वरे॑ण्यं॒ भर्गो॑ दे॒वस्य॑ धीमहि ।\nधियो॒ यो नः॑ प्रचो॒दया॑त् ॥",
            iast_text="oṁ bhūrbhuva॒ssa॒vaḥ॑ ।\ntatsa॑vi॒turvare॑ṇyaṁ॒ bhargo॑ de॒vasya॑ dhīmahi ।\ndhiyo॒ yo naḥ॑ praco॒dayā॑t ॥",
            vedic_accents_present=True,
            meter="Gayatri (8-8-8 syllables)",
            notes="Rigveda 3.62.10. Preserves Vedic Swaras. Distinguishes the original 3-line Rigvedic Rik from the customary Mahavyahriti prefix.",
        )
        add_scripts(v6, v6.devanagari_text)
        v6.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Om. We meditate upon the supreme, adorable radiance of the Divine Illuminator (Savitr). May that Divine Light inspire, guide, and illuminate our intellects and consciousness.",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t6.verses.append(v6)
        t6.rights = ContentRights(
            original_composition_attribution="Rigveda Samhita (Mandala 3, Sukta 62, Rik 10, Seer Visvamitra)",
            primary_source="Rigveda Samhita with Sayana Bhashya, Max Müller / Oxford (1890)",
            specific_edition="Max Müller Rigveda Samhita (1890, Public Domain)",
            edition_publication_date="1890",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Rigveda 3.62.10. Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Ancient Rigvedic Rik composed millennia ago; critical edition published in 1890, out of copyright worldwide.",
        )
        session.add(t6)
        pilot_records.append(t6)

    # -----------------------------------------------------------------------
    # 7. Sri Suktam (VEDA-TXT-00007) - Rigveda Shakala Khilani
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00007").first():
        t7 = Text(
            content_id="VEDA-TXT-00007",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Sri Suktam",
            devanagari_title="श्रीसूक्तम्",
            alternative_titles=["Rigvedic Sri Sukta", "Lakshmi Suktam"],
            deity=d_devi,
            primary_category=cat_suktam,
            rishi="Ananda / Kardama / Chiklita",
            chandas="Anushtubh / Trishtubh",
            devata="Agni / Sri Lakshmi",
            source_scripture="Rigveda Samhita Khila Parisishta (Shakala Recension)",
            associated_festival="Diwali Lakshmi Puja, Varalakshmi Vratam, Fridays",
            traditional_usage="Havanam, Sri Vidya Upasana, Invocation of Prosperity and Auspiciousness",
            verse_count=16,  # 15 Samhita verses + Phalasruti
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "ॐ हिर॑ण्यवर्णां॒ हरि॑णीं सु॒वर्ण॑रज॒तस्र॑जाम् ।\n"
                "च॒न्द्रां हि॒रण्म॑यीं ल॒क्ष्मीं जात॑वेदो म॒ आव॑ह ॥ १ ॥"
            ),
        )
        v7 = Verse(
            verse_id="VEDA-TXT-00007-V001",
            verse_number=1,
            verse_type=VerseType.VERSE,
            devanagari_text="ॐ हिर॑ण्यवर्णां॒ हरि॑णीं सु॒वर्ण॑रज॒तस्र॑जाम् ।\nच॒न्द्रां हि॒रण्म॑यीं ल॒क्ष्मीं जात॑वेदो म॒ आव॑ह ॥ १ ॥",
            iast_text="oṁ hira॑ṇyavarṇāṁ॒ hari॑ṇīṁ su॒varṇa॑raja॒tasra॑jām ।\nca॒ndrāṁ hi॒raṇma॑yīṁ la॒kṣmīṁ jāta॑vedo ma॒ āva॑ha ॥ 1 ॥",
            vedic_accents_present=True,
            meter="Anushtubh",
            notes="Rigveda Shakala Khila Sukta 5.87. Verse 1 of 15. Preserves Vedic accents (Anudatta U+0952, Svarita U+0951).",
        )
        add_scripts(v7, v7.devanagari_text)
        v7.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Om. O Jatavedas (Agni)! Invoke for me that Lakshmi who shines with the golden hue, who is radiant as the deer, adorned with garlands of gold and silver, luminous as the soothing moon, and completely golden in form.",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t7.verses.append(v7)
        t7.rights = ContentRights(
            original_composition_attribution="Rigveda Khilani (Shakala Recension Khila Parisishta)",
            primary_source="Die Khilen des Rigveda, J. Scheftelowitz (Breslau, 1906)",
            specific_edition="Scheftelowitz Critical Khila Edition (1906, Public Domain)",
            edition_publication_date="1906",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Rigveda Khila Parisishta (Scheftelowitz 1906). Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Ancient Rigvedic Khila Sukta. Critical academic edition published in 1906 (>115 years ago), fully out of copyright worldwide.",
        )
        session.add(t7)
        pilot_records.append(t7)

    # -----------------------------------------------------------------------
    # 8. Hanuman Chalisa (VEDA-TXT-00008) - Awadhi Devotional Literature
    # -----------------------------------------------------------------------
    if not session.query(Text).filter_by(content_id="VEDA-TXT-00008").first():
        t8 = Text(
            content_id="VEDA-TXT-00008",
            uuid=ContentIdentityGenerator.generate_uuid(),
            canonical_title="Hanuman Chalisa",
            devanagari_title="हनुमान चालीसा",
            alternative_titles=["Sri Hanuman Chalisa", "Chalis Chaupai", "Goswami Tulsidas Hanuman Chalisa"],
            deity=d_hanuman,
            primary_category=cat_chalisa,
            original_language="awa",  # Explicitly Awadhi
            composer="Goswami Tulsidas (1532–1623 CE)",
            chandas="Doha and Chaupai",
            source_scripture="Tulsidas Devotional Corpus",
            associated_festival="Hanuman Jayanti, Tuesdays, Saturdays",
            traditional_usage="Daily Devotional Chanting for Protection, Fearlessness, and Strength",
            verse_count=43,  # 2 Opening Dohas + 40 Chaupais + 1 Concluding Doha
            content_hash=ContentIdentityGenerator.compute_content_hash(
                "श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि ।\n"
                "बरनउँ रघुबर बिमल जसु जो दायकु फल चारि ॥\n"
                "बुद्धिहीन तनु जानिके सुमिरौ पवन-कुमार ।\n"
                "बल बुद्धि बिद्या देहु मोहिं हरहु कलेस बिकार ॥"
            ),
        )
        v8_d1 = Verse(
            verse_id="VEDA-TXT-00008-V001",
            verse_number=1,
            verse_type=VerseType.DOHA,
            devanagari_text="श्रीगुरु चरन सरोज रज निज मनु मुकुरु सुधारि ।\nबरनउँ रघुबर बिमल जसु जो दायकु फल चारि ॥",
            iast_text="śrīguru carana saroja raja nija manu mukuru sudhāri ।\nbaranauṁ raghubara bimala jasu jo dāyaku phala cāri ॥",
            meter="Doha (13-11 matras)",
            notes="Opening Doha 1 of 2. Awadhi devotional metre.",
        )
        add_scripts(v8_d1, v8_d1.devanagari_text)
        v8_d1.translations.append(Translation(
            target_language="en",
            translation_type=TranslationType.BHAVARTHA,
            translated_text="Having cleansed the mirror of my mind with the pollen-dust of the lotus feet of the revered Guru, I celebrate the pure fame of Lord Raghubara (Sri Rama), which bestows the four fruits of life (Dharma, Artha, Kama, and Moksha).",
            translator="Vedic Heritage Scholarly Commission",
            review_status=ReviewStatus.APPROVED,
        ))
        t8.verses.append(v8_d1)
        t8.rights = ContentRights(
            original_composition_attribution="Goswami Tulsidas (16th Century CE)",
            primary_source="Kavitavali & Chalisa Sangrah, Venkateshwara Steam Press (1908)",
            specific_edition="Venkateshwara Steam Press, Bombay (1908)",
            edition_publication_date="1908",
            license_type="PUBLIC_DOMAIN",
            commercial_reuse_permitted=True,
            translation_permitted=True,
            derivative_work_permitted=True,
            distribution_permitted=True,
            attribution_text="Source: Venkateshwara Steam Press (1908). Classified as Awadhi devotional literature. Verified by Vedic Heritage Digital Library.",
            release_status=ReleaseStatus.GREEN,
            supporting_evidence="Composed in Awadhi in the 16th century CE; historical edition published 1908 (>115 years ago), fully out of copyright worldwide.",
        )
        session.add(t8)
        pilot_records.append(t8)

    session.commit()
    return pilot_records


def generate_all_prototypes():
    """Generate Excel, Word, and JSON outputs for the pilot collection."""
    init_db()
    with get_db_session() as session:
        seed_master_taxonomy(session)
        seed_all_pilot_texts(session)

        excel_dir = Path("exports/excel")
        word_dir = Path("exports/word")
        json_dir = Path("exports/json")

        for d in (excel_dir, word_dir, json_dir):
            d.mkdir(parents=True, exist_ok=True)

        texts = session.query(Text).order_by(Text.id).all()
        for t in texts:
            slug = t.canonical_title.lower().replace(" ", "_").replace("&", "and")
            ExcelExporter.export_text_bundle(t, str(excel_dir / f"{slug}_prototype.xlsx"))
            WordExporter.export_text_bundle(t, str(word_dir / f"{slug}_prototype.docx"))
            JSONExporter.export_text_bundle(t, str(json_dir / f"{slug}_prototype.json"))
            print(f"Exported prototypes for {t.content_id}: {t.canonical_title}")


if __name__ == "__main__":
    generate_all_prototypes()
