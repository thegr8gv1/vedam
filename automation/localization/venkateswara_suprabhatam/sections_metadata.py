"""
Sri Venkateswara Suprabhatam Four-Section Collection Metadata
Official Tirumala Tirupati Devasthanams (TTD) Liturgical Canon:
1. Sri Venkateswara Suprabhatam — 29 slokas
2. Sri Venkateswara Stotram — 11 slokas
3. Sri Venkateswara Prapatti — 16 stanzas
4. Sri Venkateswara Mangalasasanam — 14 stanzas
Total Collection: 70 verse units.

Attribution: Sri Prativadi Bhayankaram Annan (c. 1400 CE; disciple of Swami Manavala Mamunigal).
Source Edition: Sri Venkateswara Suprabhata Stotram (Vavilla Ramaswamy Sastrulu & Sons, Madras, 1918 / TTD Archival 1928).
Rights Clearance: GREEN_CLEARED (historical out-of-copyright edition).
Verification Status: SCHOLAR_VERIFIED.
"""

from dataclasses import dataclass, field
from typing import Any, Dict, List, Tuple


@dataclass
class SuprabhatamSectionMeta:
    section_id: str
    original_section_name: str
    english_section_name: str
    traditional_order: int
    verse_count: int
    start_verse: int
    end_verse: int
    liturgical_role: str
    theological_focus: str
    source_edition: str
    composer: str
    rights_status: str
    verification_status: str


SUPRABHATAM_SECTIONS: Dict[str, SuprabhatamSectionMeta] = {
    "SEC-SV-01": SuprabhatamSectionMeta(
        section_id="SEC-SV-01",
        original_section_name="श्रीवेङ्कटेशसुप्रभातम्",
        english_section_name="Suprabhatam (Awakening of the Lord)",
        traditional_order=1,
        verse_count=29,
        start_verse=1,
        end_verse=29,
        liturgical_role="Ritual morning awakening of Lord Srinivasa and Sri Alarmelmanga (Padmavathi)",
        theological_focus="Brahma Muhurta awakening; nature, celestials, sages and devotees arriving for Vishvarupa Darshana",
        source_edition="Sri Venkateswara Suprabhata Stotram (Vavilla Ramaswamy Sastrulu & Sons, Madras, 1918 / TTD Archival 1928)",
        composer="Prativadi Bhayankaram Annan (c. 1400 CE)",
        rights_status="GREEN_CLEARED",
        verification_status="SCHOLAR_VERIFIED",
    ),
    "SEC-SV-02": SuprabhatamSectionMeta(
        section_id="SEC-SV-02",
        original_section_name="श्रीवेङ्कटेशस्तोत्रम्",
        english_section_name="Stotram (Praise of Divine Glories and Form)",
        traditional_order=2,
        verse_count=11,
        start_verse=30,
        end_verse=40,
        liturgical_role="Eulogy contemplating the Lord's transcendent beauty, Kaustubha jewel, and lotus eyes",
        theological_focus="Para-vasudeva theology; Krishna and Rama identity; refuge for distressed souls",
        source_edition="Sri Venkateswara Suprabhata Stotram (Vavilla Ramaswamy Sastrulu & Sons, Madras, 1918 / TTD Archival 1928)",
        composer="Prativadi Bhayankaram Annan (c. 1400 CE)",
        rights_status="GREEN_CLEARED",
        verification_status="SCHOLAR_VERIFIED",
    ),
    "SEC-SV-03": SuprabhatamSectionMeta(
        section_id="SEC-SV-03",
        original_section_name="श्रीवेङ्कटेशप्रपत्तिः",
        english_section_name="Prapatti (Solemn Surrender and Sharanagati)",
        traditional_order=3,
        verse_count=16,
        start_verse=41,
        end_verse=56,
        liturgical_role="Solemn surrender (Nyasa / Sharanagati) at the lotus feet of the Lord",
        theological_focus="Sri Vaishnava Purushakara doctrine: invoking Sri Mahalakshmi first (verses 1-7) to intercede before surrendering to Venkateswara",
        source_edition="Sri Venkateswara Suprabhata Stotram (Vavilla Ramaswamy Sastrulu & Sons, Madras, 1918 / TTD Archival 1928)",
        composer="Prativadi Bhayankaram Annan (c. 1400 CE)",
        rights_status="GREEN_CLEARED",
        verification_status="SCHOLAR_VERIFIED",
    ),
    "SEC-SV-04": SuprabhatamSectionMeta(
        section_id="SEC-SV-04",
        original_section_name="श्रीवेङ्कटेशमङ्गलाशासनम्",
        english_section_name="Mangalasasanam (Auspicious Benediction)",
        traditional_order=4,
        verse_count=14,
        start_verse=57,
        end_verse=70,
        liturgical_role="Auspicious concluding benediction wishing eternal glory to the Divine Couple",
        theological_focus="Periyazhwar and Ramanuja tradition of wishing auspiciousness to God Himself (Mangalam) across all His manifestations",
        source_edition="Sri Venkateswara Suprabhata Stotram (Vavilla Ramaswamy Sastrulu & Sons, Madras, 1918 / TTD Archival 1928)",
        composer="Prativadi Bhayankaram Annan (c. 1400 CE)",
        rights_status="GREEN_CLEARED",
        verification_status="SCHOLAR_VERIFIED",
    ),
}
