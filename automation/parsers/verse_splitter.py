"""
Vedic Heritage Platform — Verse and Stanza Separation Engine
Parses continuous sacred texts into structured, numbered verses, dohas,
chaupais, mantras, and phalasruti colophons using traditional danda orthography.
"""

import re
from typing import Any, Dict, List, Optional, Tuple

from database.models import VerseType


class VerseSplitter:
    """
    Intelligent stanza demarcation engine.
    
    Orthographic cues:
    - Double Danda (॥) with Devanagari or Arabic numerals: e.g., '॥ १ ॥', '॥ 1 ॥'
    - Awadhi meters: 2-line rhyming Dohas vs 4-line Chaupais
    - Vedic Mantras: Samhita delimiters
    - Colophons: 'इति ... समाप्तम्', 'फलश्रुतिः'
    """

    # Matches verse end with numeral: e.g. '॥ १ ॥', '॥ १२ ॥', '॥ 1 ॥', '|| 1 ||'
    VERSE_NUMBER_PATTERN = re.compile(r"(?:॥|\|\|)\s*([०-९\d]+)\s*(?:॥|\|\|)")
    DEVANAGARI_DIGITS = "०१२३४५६७८९"

    @classmethod
    def devanagari_to_int(cls, num_str: str) -> int:
        """Convert Devanagari numerals (१, २, ३) or Arabic digits (1, 2, 3) to int."""
        cleaned = ""
        for char in num_str.strip():
            if char in cls.DEVANAGARI_DIGITS:
                cleaned += str(cls.DEVANAGARI_DIGITS.index(char))
            elif char.isdigit():
                cleaned += char
        return int(cleaned) if cleaned else 1

    @classmethod
    def split_into_verses(
        cls,
        text: str,
        expected_verse_type: VerseType = VerseType.VERSE,
    ) -> List[Dict[str, Any]]:
        """
        Split a continuous multi-stanza composition into ordered verse dictionaries.
        Handles both numbered double-dandas (॥ १ ॥) and unnumbered paragraph stanzas.
        """
        if not text:
            return []

        # 1. Check for numbered verse delimiters
        matches = list(cls.VERSE_NUMBER_PATTERN.finditer(text))
        if matches:
            verses = []
            last_end = 0
            current_type = expected_verse_type

            for m in matches:
                verse_end = m.end()
                num_str = m.group(1)
                num = cls.devanagari_to_int(num_str)
                chunk = text[last_end:verse_end].strip()
                last_end = verse_end

                if "फलश्रुति" in chunk or "फल श्रुति" in chunk:
                    current_type = VerseType.PHALASRUTI

                verses.append(cls._package_verse(chunk, num, current_type))

            # Check if there is a trailing colophon after the final numbered verse
            trailing = text[last_end:].strip()
            if trailing:
                col_type = VerseType.COLOPHON if "समाप्त" in trailing or "इति" in trailing else current_type
                verses.append(cls._package_verse(trailing, len(verses) + 1, col_type))

            return verses

        # 2. Fallback for unnumbered paragraph stanzas
        verses = []
        raw_paragraphs = [p.strip() for p in text.split("\n\n") if p.strip()]
        for idx, p in enumerate(raw_paragraphs, start=1):
            p_type = VerseType.PHALASRUTI if "फलश्रुति" in p else expected_verse_type
            verses.append(cls._package_verse(p, idx, p_type))

        return verses

    @classmethod
    def _package_verse(cls, text: str, verse_number: int, verse_type: VerseType) -> Dict[str, Any]:
        """Normalize whitespace and construct structured verse object."""
        clean_text = "\n".join([line.strip() for line in text.splitlines() if line.strip()])
        return {
            "verse_number": verse_number,
            "verse_type": verse_type,
            "devanagari_text": clean_text,
            "line_count": len(clean_text.splitlines()),
        }
