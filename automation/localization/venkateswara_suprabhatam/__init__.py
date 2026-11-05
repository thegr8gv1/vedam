"""
Sri Venkateswara Suprabhatam Complete Four-Section Collection Package
Provides structured section metadata, original texts, and 9-language localization data for:
- Section 1: Suprabhatam (Verses 1 to 29)
- Section 2: Stotram (Verses 30 to 40)
- Section 3: Prapatti (Verses 41 to 56)
- Section 4: Mangalasasanam (Verses 57 to 70)
Total: 70 verse units.
"""

from typing import Any, Dict

from automation.localization.venkateswara_suprabhatam.sections_metadata import (
    SUPRABHATAM_SECTIONS,
    SuprabhatamSectionMeta,
)
from automation.localization.venkateswara_suprabhatam.suprabhatam_data import (
    get_suprabhatam_section_payload,
)
from automation.localization.venkateswara_suprabhatam.stotram_data import (
    get_stotram_section_payload,
)
from automation.localization.venkateswara_suprabhatam.prapatti_data import (
    get_prapatti_section_payload,
)
from automation.localization.venkateswara_suprabhatam.mangalasasanam_data import (
    get_mangalasasanam_section_payload,
)


def get_full_suprabhatam_collection_payload() -> Dict[int, Dict[str, Any]]:
    """
    Combines all four canonical sections into a unified 70-verse collection payload.
    Global verse numbering:
      1..29: Suprabhatam (SEC-SV-01)
      30..40: Stotram (SEC-SV-02)
      41..56: Prapatti (SEC-SV-03)
      57..70: Mangalasasanam (SEC-SV-04)
    """
    combined: Dict[int, Dict[str, Any]] = {}
    combined.update(get_suprabhatam_section_payload())
    combined.update(get_stotram_section_payload())
    combined.update(get_prapatti_section_payload())
    combined.update(get_mangalasasanam_section_payload())

    assert len(combined) == 70, f"Expected 70 verses in collection, found {len(combined)}"
    assert sorted(combined.keys()) == list(range(1, 71)), "Verse keys must be contiguous 1..70"
    return combined


__all__ = [
    "SUPRABHATAM_SECTIONS",
    "SuprabhatamSectionMeta",
    "get_suprabhatam_section_payload",
    "get_stotram_section_payload",
    "get_prapatti_section_payload",
    "get_mangalasasanam_section_payload",
    "get_full_suprabhatam_collection_payload",
]
