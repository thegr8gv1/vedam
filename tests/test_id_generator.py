"""
Unit Tests for Content Identity and Identifier Generator
"""

import pytest

from automation.identity.generator import ContentIdentityGenerator


def test_generate_text_id():
    assert ContentIdentityGenerator.generate_text_id(1) == "VEDA-TXT-00001"
    assert ContentIdentityGenerator.generate_text_id(42) == "VEDA-TXT-00042"
    assert ContentIdentityGenerator.generate_text_id(99999) == "VEDA-TXT-99999"

    with pytest.raises(ValueError):
        ContentIdentityGenerator.generate_text_id(0)

    with pytest.raises(ValueError):
        ContentIdentityGenerator.generate_text_id(100000)


def test_generate_verse_id():
    assert ContentIdentityGenerator.generate_verse_id("VEDA-TXT-00001", 1) == "VEDA-TXT-00001-V001"
    assert ContentIdentityGenerator.generate_verse_id("VEDA-TXT-00001", 108) == "VEDA-TXT-00001-V108"

    with pytest.raises(ValueError):
        ContentIdentityGenerator.generate_verse_id("INVALID-ID", 1)

    with pytest.raises(ValueError):
        ContentIdentityGenerator.generate_verse_id("VEDA-TXT-00001", 0)


def test_validate_content_id():
    assert ContentIdentityGenerator.validate_content_id("VEDA-TXT-00001") is True
    assert ContentIdentityGenerator.validate_content_id("VEDA-TXT-99999") is True
    assert ContentIdentityGenerator.validate_content_id("VEDA-TXT-1") is False
    assert ContentIdentityGenerator.validate_content_id("VEDA-00001") is False
    assert ContentIdentityGenerator.validate_content_id("random_string") is False


def test_compute_content_hash():
    text1 = "ॐ नमः शिवाय"
    text2 = "ॐ  नमः   शिवाय\n"  # Whitespace variations
    text3 = "हरे कृष्ण"

    hash1 = ContentIdentityGenerator.compute_content_hash(text1)
    hash2 = ContentIdentityGenerator.compute_content_hash(text2)
    hash3 = ContentIdentityGenerator.compute_content_hash(text3)

    assert len(hash1) == 64
    assert hash1 == hash2  # Whitespace normalized
    assert hash1 != hash3
