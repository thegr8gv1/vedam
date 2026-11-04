"""
Unit Tests for Database Models and Pydantic Schemas
"""

import pytest
from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker

from database.models import (
    Base,
    Category,
    ContentRights,
    Deity,
    ReleaseStatus,
    ReviewStatus,
    Text,
    Translation,
    TranslationType,
    Transliteration,
    Verse,
    VerseType,
)
from database.schemas import TextCreate, ContentRightsCreate


@pytest.fixture
def in_memory_db():
    engine = create_engine("sqlite:///:memory:", echo=False)
    Base.metadata.create_all(engine)
    Session = sessionmaker(bind=engine)
    session = Session()
    yield session
    session.close()


def test_insert_text_with_relationships(in_memory_db):
    cat = Category(slug="stotra", name="Stotra")
    deity = Deity(slug="shiva", name="Lord Shiva")
    in_memory_db.add_all([cat, deity])
    in_memory_db.flush()

    text = Text(
        content_id="VEDA-TXT-00001",
        uuid="test-uuid-1234",
        canonical_title="Shiva Tandava Stotram",
        devanagari_title="शिवताण्डवस्तोत्रम्",
        deity=deity,
        primary_category=cat,
        composer="Ravana",
        content_hash="test-hash-123",
        verse_count=1,
    )
    in_memory_db.add(text)
    in_memory_db.flush()

    verse = Verse(
        verse_id="VEDA-TXT-00001-V001",
        verse_number=1,
        verse_type=VerseType.VERSE,
        devanagari_text="जटाटवीगलज्जलप्रवाहपावितस्थले",
        iast_text="jaṭāṭavīgalajjala...",
        text=text,
    )
    in_memory_db.add(verse)
    in_memory_db.flush()

    translit = Transliteration(
        verse=verse,
        target_script="telugu",
        script_text="జటాటవీగలజ్జలప్రవాహపావితస్థలే",
    )
    in_memory_db.add(translit)

    trans = Translation(
        verse=verse,
        target_language="en",
        translation_type=TranslationType.BHAVARTHA,
        translated_text="From the forest of His matted locks...",
    )
    in_memory_db.add(trans)

    rights = ContentRights(
        text=text,
        original_composition_attribution="Ravana",
        primary_source="Historical Manuscript Archive",
        license_type="PUBLIC_DOMAIN",
        commercial_reuse_permitted=True,
        release_status=ReleaseStatus.GREEN,
    )
    in_memory_db.add(rights)
    in_memory_db.commit()

    # Query back and verify
    queried = in_memory_db.query(Text).filter_by(content_id="VEDA-TXT-00001").first()
    assert queried is not None
    assert queried.canonical_title == "Shiva Tandava Stotram"
    assert len(queried.verses) == 1
    assert len(queried.verses[0].transliterations) == 1
    assert queried.verses[0].transliterations[0].target_script == "telugu"
    assert queried.rights.release_status == ReleaseStatus.GREEN


def test_pydantic_schema_validation():
    valid_data = {
        "content_id": "VEDA-TXT-00001",
        "canonical_title": "Ganesha Pancharatnam",
        "devanagari_title": "गणेशपञ्चरत्नम्",
        "primary_category_slug": "stotra",
        "rights": {
            "original_composition_attribution": "Adi Shankaracharya",
            "primary_source": "Nirnaya Sagar Press",
            "license_type": "PUBLIC_DOMAIN",
            "commercial_reuse_permitted": True,
        }
    }
    schema = TextCreate(**valid_data)
    assert schema.content_id == "VEDA-TXT-00001"
    assert schema.canonical_title == "Ganesha Pancharatnam"

    # Test invalid content_id format
    invalid_data = valid_data.copy()
    invalid_data["content_id"] = "INVALID-TXT"
    with pytest.raises(ValueError):
        TextCreate(**invalid_data)
