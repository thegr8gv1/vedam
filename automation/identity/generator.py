"""
Vedic Heritage Platform — Identity & Content ID Generator
Standardized, collision-free identification for texts, verses, and digital assets.
"""

import hashlib
import unicodedata
import uuid
import re
from typing import Optional


class ContentIdentityGenerator:
    """
    Generates immutable identifiers conforming to platform architecture.
    Formats:
    - Master Text: VEDA-TXT-XXXXX (e.g., VEDA-TXT-00001)
    - Verse:       VEDA-TXT-XXXXX-VXXX (e.g., VEDA-TXT-00001-V001)
    - Universal:   UUIDv4
    - Hash:        SHA-256 of NFC-normalized text
    """

    PREFIX_TEXT = "VEDA-TXT"
    CONTENT_ID_PATTERN = re.compile(r"^VEDA-TXT-(\d{5})$")
    VERSE_ID_PATTERN = re.compile(r"^VEDA-TXT-(\d{5})-V(\d{3,4})$")

    @classmethod
    def generate_text_id(cls, sequence_number: int) -> str:
        """Format sequential integer into standard Content ID."""
        if sequence_number < 1 or sequence_number > 99999:
            raise ValueError("Sequence number must be between 1 and 99999.")
        return f"{cls.PREFIX_TEXT}-{sequence_number:05d}"

    @classmethod
    def generate_verse_id(cls, text_id: str, verse_number: int) -> str:
        """Derive canonical verse identifier from text ID and verse sequence."""
        if not cls.CONTENT_ID_PATTERN.match(text_id):
            raise ValueError(f"Invalid text_id '{text_id}'. Must match 'VEDA-TXT-XXXXX'")
        if verse_number < 1:
            raise ValueError("verse_number must be >= 1")
        return f"{text_id}-V{verse_number:03d}"

    @classmethod
    def generate_uuid(cls) -> str:
        """Generate standard UUID v4 string."""
        return str(uuid.uuid4())

    @classmethod
    def compute_content_hash(cls, raw_text: str) -> str:
        """
        Compute deterministic SHA-256 hash of text.
        Applies Unicode NFC normalization and strips non-semantic whitespace.
        """
        if not raw_text:
            return hashlib.sha256(b"").hexdigest()
        
        # Normalize Unicode to NFC
        normalized = unicodedata.normalize("NFC", raw_text)
        # Collapse multi-whitespace but retain verse newlines
        lines = [re.sub(r"[ \t]+", " ", line).strip() for line in normalized.splitlines()]
        clean_body = "\n".join(lines).strip()
        
        return hashlib.sha256(clean_body.encode("utf-8")).hexdigest()

    @classmethod
    def validate_content_id(cls, content_id: str) -> bool:
        """Validate if a string is a valid platform content ID."""
        return bool(cls.CONTENT_ID_PATTERN.match(content_id))
