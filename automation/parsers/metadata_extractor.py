"""
Vedic Heritage Platform — Liturgical Metadata Extractor
Parses traditional Sankalpam and Dhyana prefaces to extract Rishi, Chandas,
Devata, Bija, Shakti, Kilaka, Viniyoga, and traditional composer attributions.
"""

import re
from typing import Any, Dict, Optional


class LiturgicalMetadataExtractor:
    """
    Extracts classical liturgical apparatus from Sanskrit introductory stanzas.
    
    Standard Sanskrit Nyasa formula:
    'अस्य श्री[स्तोत्र/मन्त्र]स्य [ऋषि] ऋषिः [छन्दस्] छन्दः [देवता] देवता [बीज] बीजम् [शक्ति] शक्तिः [कीलक] कीलकम् [विनियोग] विनियोगः'
    """

    RISHI_PATTERN = re.compile(r"([^\s,।॥]+)\s+ऋषिः")
    CHANDAS_PATTERN = re.compile(r"([^\s,।॥]+)\s+छन्दः")
    DEVATA_PATTERN = re.compile(r"([^\s,।॥]+)\s+देवता")
    BIJA_PATTERN = re.compile(r"([^\s,।॥]+)\s+बीजम्")
    SHAKTI_PATTERN = re.compile(r"([^\s,।॥]+)\s+शक्तिः")
    KILAKA_PATTERN = re.compile(r"([^\s,।॥]+)\s+कीलकम्")
    VINIYOGA_PATTERN = re.compile(r"जपे\s+विनियोगः|विनियोगः")

    COMPOSER_PATTERNS = [
        (re.compile(r"शङ्कराचार्य|शंकराचार्य"), "Adi Shankaracharya"),
        (re.compile(r"तुलसीदास|गोस्वामी"), "Goswami Tulsidas"),
        (re.compile(r"वल्लभाचार्य"), "Vallabhacharya"),
        (re.compile(r"रावण|दशानन"), "Ravana"),
        (re.compile(r"वाल्मीकि"), "Valmiki"),
        (re.compile(r"व्यास|वेदव्यास"), "Veda Vyasa"),
        (re.compile(r"कालिदास"), "Kalidasa"),
    ]

    CHANDAS_LIST = [
        "अनुष्टुप्", "गायत्री", "त्रिष्टुप्", "जगती", "वसन्त्तलका", "शार्दूलविक्रीडितम्",
        "मालिनी", "मन्दाक्रान्ता", "स्रग्धरा", "भुजङ्गप्रयातम्", "दोहा", "चौपाई"
    ]

    @classmethod
    def extract_metadata(cls, text: str) -> Dict[str, Any]:
        """Extract all identifiable liturgical attributes from text."""
        result: Dict[str, Any] = {
            "rishi": None,
            "chandas": None,
            "devata": None,
            "bija": None,
            "shakti": None,
            "kilaka": None,
            "composer": None,
            "has_formal_viniyoga": False,
        }

        if not text:
            return result

        # Check Rishi
        r_match = cls.RISHI_PATTERN.search(text)
        if r_match:
            result["rishi"] = r_match.group(1).strip()

        # Check Chandas
        c_match = cls.CHANDAS_PATTERN.search(text)
        if c_match:
            result["chandas"] = c_match.group(1).strip()
        else:
            # Fallback scan for known meter names
            for meter in cls.CHANDAS_LIST:
                if meter in text:
                    result["chandas"] = meter
                    break

        # Check Devata
        d_match = cls.DEVATA_PATTERN.search(text)
        if d_match:
            result["devata"] = d_match.group(1).strip()

        # Check Bija / Shakti / Kilaka
        b_match = cls.BIJA_PATTERN.search(text)
        if b_match:
            result["bija"] = b_match.group(1).strip()

        s_match = cls.SHAKTI_PATTERN.search(text)
        if s_match:
            result["shakti"] = s_match.group(1).strip()

        k_match = cls.KILAKA_PATTERN.search(text)
        if k_match:
            result["kilaka"] = k_match.group(1).strip()

        # Check Viniyoga
        if cls.VINIYOGA_PATTERN.search(text):
            result["has_formal_viniyoga"] = True

        # Check Composer
        for pat, composer_name in cls.COMPOSER_PATTERNS:
            if pat.search(text):
                result["composer"] = composer_name
                break

        return result
