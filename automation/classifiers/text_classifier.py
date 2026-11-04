"""
Vedic Heritage Platform — Text Classification Engine
Classifies devotional and liturgical texts into primary and secondary categories,
detects sacred languages (Sanskrit vs. Awadhi vs. regional), and identifies deities.
"""

import re
from typing import Dict, List, Optional, Tuple


class TextClassifier:
    """
    Automated classification engine identifying category, linguistic stratum, and devata.
    """

    # Deity keywords
    DEITY_PATTERNS = {
        "shiva": [r"शिव", r"शम्भु", r"शङ्कर", r"रुद्र", r"महेश", r"नीलकण्ठ", r"कैलास"],
        "ganesha": [r"गणेश", r"विनायक", r"गजानन", r"लम्बोदर", r"हेरम्ब", r"वक्रतुण्ड", r"एकदन्त"],
        "vishnu": [r"विष्णु", r"नारायण", r"हरि", r"माधव", r"गोविन्द", r"वैकुण्ठ", r"जनार्दन"],
        "krishna": [r"कृष्ण", r"गोविन्द", r"गोपाल", r"वासुदेव", r"मुरली", r"मधुर"],
        "rama": [r"राम", r"रघुनाथ", r"राघव", r"सीतापते", r"रघुवर", r"जानकी"],
        "devi": [r"देवी", r"दुर्गा", r"लक्ष्मी", r"पार्वती", r"भवानी", r"ललिता", r"अम्बा", r"काली"],
        "hanuman": [r"हनुमान", r"मारुति", r"अञ्जनी", r"पवनसुत", r"कपीश", r"बजरङ्ग"],
        "surya": [r"सूर्य", r"आदित्य", r"भास्कर", r"दिनकर", r"रवि", r"सविता"],
    }

    # Awadhi linguistic markers (Hanuman Chalisa, Tulsidas)
    AWADHI_MARKERS = [r"सिय", r"रघुबर", r"चरन", r"निज", r"बिहंग", r"कीजै", r"होहू", r"सुमिरी", r"दीजै", r"जोई"]

    @classmethod
    def detect_language(cls, text: str) -> str:
        """Distinguish Sanskrit (sa) from Awadhi (awa) or Hindi (hi)."""
        awadhi_hits = sum(1 for m in cls.AWADHI_MARKERS if re.search(m, text))
        if awadhi_hits >= 2:
            return "awa"
        return "sa"

    @classmethod
    def classify_category(cls, title: str, text: str, verse_count: int = 0) -> str:
        """Determine primary taxonomy category slug."""
        lower_title = title.lower()

        # Check explicit title indicators
        if "चालीसा" in title or "chalisa" in lower_title:
            return "chalisa"
        if "सूक्त" in title or "suktam" in lower_title or "sukta" in lower_title:
            return "suktam"
        if "अष्टक" in title or "ashtakam" in lower_title or (verse_count in {8, 9} and "स्तोत्र" in title):
            return "ashtakam"
        if "सहस्रनाम" in title or "sahasranama" in lower_title:
            return "sahasranama"
        if "अष्टोत्तर" in title or "shatanama" in lower_title or "108" in title:
            return "ashtottara"
        if "कवच" in title or "kavacham" in lower_title:
            return "kavacham"
        if "मन्त्र" in title or "mantra" in lower_title or "गायत्री" in title:
            return "mantra"

        # Check textual characteristics
        if "शिरो मे पातु" in text or "रक्षेत्" in text:
            return "kavacham"

        return "stotra"

    @classmethod
    def detect_deity(cls, title: str, text: str) -> Optional[str]:
        """Detect principal addressed divinity."""
        combined = f"{title} {text[:500]}"
        for deity_slug, patterns in cls.DEITY_PATTERNS.items():
            for pat in patterns:
                if re.search(pat, combined):
                    return deity_slug
        return None
