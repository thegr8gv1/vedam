"""
Vedic Heritage Platform — Accessible Multilingual HTML Publication Exporter
Part D.5: Generates responsive, semantic HTML5 publications supporting all 14 scripts,
RTL flows for Urdu/Kashmiri/Sindhi, DRAFT banners, and strict XSS protection.
"""

from datetime import datetime, timezone
import html
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from automation.exporters.bidi_layout import BidiLayoutEngine
from automation.exporters.publication_gatekeeper import PublicationGatekeeper, ReleaseGateVerdict
from automation.exporters.publication_model import PublicationDocument
from automation.exporters.typography import MultilingualTypographyEngine

logger = logging.getLogger("vedam.automation.exporters.html_exporter")


class MultilingualHTMLExporter:
    """
    Renders high-accessibility, responsive HTML5 publication manuscripts.
    """

    DEFAULT_OUTPUT_DIR = "exports/multilingual_publication/html"

    @classmethod
    def export(
        cls,
        document: PublicationDocument,
        output_path: Optional[str] = None,
        enforce_gate: bool = True,
    ) -> str:
        """
        Exports a PublicationDocument to an accessible HTML5 file.
        Returns the absolute path of the generated HTML artifact.
        """
        if enforce_gate:
            gate_rep = PublicationGatekeeper.evaluate_publication(document)
            if not gate_rep.can_export:
                blocker_msgs = "; ".join([b.message for b in gate_rep.blockers])
                raise PermissionError(f"Publication Gate Blocked Export: {blocker_msgs}")

        if not output_path:
            out_dir = Path(cls.DEFAULT_OUTPUT_DIR)
            out_dir.mkdir(parents=True, exist_ok=True)
            slug = document.metadata.canonical_title.lower().replace(" ", "_").replace("-", "_")
            fname = f"{document.metadata.content_id}_{slug}_{document.target.bcp47}_{document.governance.publication_channel}.html"
            output_path = str(out_dir / fname)
        else:
            Path(output_path).parent.mkdir(parents=True, exist_ok=True)

        rendered_html = cls.render_html_string(document)

        with open(output_path, "w", encoding="utf-8") as f:
            f.write(rendered_html)

        logger.info("HTML publication successfully generated at: %s", output_path)
        return output_path

    @classmethod
    def render_html_string(cls, document: PublicationDocument) -> str:
        """Generates self-contained, accessible HTML5 string."""
        target = document.target
        meta = document.metadata
        gov = document.governance
        missing = document.missing_content

        font_family = MultilingualTypographyEngine.get_css_font_family(target.script_code)
        doc_dir = target.direction
        is_rtl = target.is_rtl

        # Safe escaping
        safe_title = html.escape(meta.canonical_title)
        safe_dev_title = html.escape(meta.devanagari_title)
        safe_content_id = html.escape(meta.content_id)
        safe_lang_name = html.escape(target.language_name)
        safe_script_name = html.escape(target.script_name)
        safe_bcp47 = html.escape(target.bcp47)

        # Watermark Banner
        watermark_html = ""
        if gov.watermark_text:
            safe_watermark = html.escape(gov.watermark_text)
            watermark_html = f"""
            <aside class="draft-watermark-banner" role="alert" aria-label="Draft Notice">
                <div class="watermark-content">
                    <span class="watermark-badge">&#9888; NOTICE</span>
                    <span class="watermark-text">{safe_watermark}</span>
                </div>
            </aside>
            """

        # Metadata badges
        badges = [
            f'<span class="badge badge-primary">{safe_content_id}</span>',
            f'<span class="badge badge-secondary">{html.escape(str(meta.primary_category))}</span>',
            f'<span class="badge badge-info">{safe_lang_name} ({safe_script_name})</span>',
            f'<span class="badge badge-status status-{gov.overall_review_status.lower()}">{html.escape(str(gov.overall_review_status))}</span>',
        ]
        if meta.deity:
            badges.append(f'<span class="badge badge-outline">Deity: {html.escape(str(meta.deity))}</span>')
        if meta.chandas:
            badges.append(f'<span class="badge badge-outline">Meter: {html.escape(str(meta.chandas))}</span>')
        if meta.rishi:
            badges.append(f'<span class="badge badge-outline">Rishi: {html.escape(str(meta.rishi))}</span>')

        badge_bar = "\n                ".join(badges)

        # Verse Cards
        verse_cards = []
        for ve in document.verses:
            v_num = ve.verse_number
            v_id = html.escape(ve.verse_id)

            # Source Sanskrit text
            safe_dev = html.escape(ve.devanagari_source)
            safe_iast = html.escape(ve.iast_transliteration)

            # Target transliteration
            target_translit_html = ""
            if ve.target_script_transliteration and target.script_code != "Deva":
                safe_tgt_translit = html.escape(ve.target_script_transliteration)
                target_translit_html = f"""
                <div class="verse-script-translit" dir="{doc_dir}">
                    <span class="view-label">{safe_script_name} Recitation:</span>
                    <p class="script-recitation-text" style="font-family: {font_family};">{safe_tgt_translit}</p>
                </div>
                """

            # Views
            views_html_parts = []

            # 1. Literal View
            if ve.literal_translation:
                if target.is_rtl:
                    safe_lit = BidiLayoutEngine.wrap_html_bidi(ve.literal_translation, is_rtl=True)
                else:
                    safe_lit = html.escape(ve.literal_translation)
                lit_badge = f'<span class="badge-mini status-{ve.literal_status.lower()}">{ve.literal_status}</span>'
                views_html_parts.append(f"""
                <div class="translation-view literal-view" dir="{doc_dir}">
                    <div class="view-header">
                        <span class="view-title">Literal Translation (Grammatical)</span>
                        {lit_badge}
                    </div>
                    <div class="view-content" style="font-family: {font_family};">{safe_lit}</div>
                </div>
                """)
            else:
                views_html_parts.append("""
                <div class="translation-view missing-view">
                    <span class="missing-label">&#9888; Literal Translation:</span>
                    <span class="missing-text">Pending scholarly review & certification.</span>
                </div>
                """)

            # 2. Tatparya View
            if ve.tatparya_translation:
                if target.is_rtl:
                    safe_tat = BidiLayoutEngine.wrap_html_bidi(ve.tatparya_translation, is_rtl=True)
                else:
                    safe_tat = html.escape(ve.tatparya_translation)
                tat_badge = f'<span class="badge-mini status-{ve.tatparya_status.lower()}">{ve.tatparya_status}</span>'
                views_html_parts.append(f"""
                <div class="translation-view tatparya-view" dir="{doc_dir}">
                    <div class="view-header">
                        <span class="view-title">Traditional Meaning (Tātparya / Bhāṣya)</span>
                        {tat_badge}
                    </div>
                    <div class="view-content" style="font-family: {font_family};">{safe_tat}</div>
                </div>
                """)
            else:
                views_html_parts.append("""
                <div class="translation-view missing-view">
                    <span class="missing-label">&#9888; Traditional Tātparya:</span>
                    <span class="missing-text">Pending commentary reference collation.</span>
                </div>
                """)

            # 3. Bhavartha View
            if ve.bhavartha_translation:
                if target.is_rtl:
                    safe_bhav = BidiLayoutEngine.wrap_html_bidi(ve.bhavartha_translation, is_rtl=True)
                else:
                    safe_bhav = html.escape(ve.bhavartha_translation)
                bhav_badge = f'<span class="badge-mini status-{ve.bhavartha_status.lower()}">{ve.bhavartha_status}</span>'
                views_html_parts.append(f"""
                <div class="translation-view bhavartha-view" dir="{doc_dir}">
                    <div class="view-header">
                        <span class="view-title">Devotional Bhavartha</span>
                        {bhav_badge}
                    </div>
                    <div class="view-content" style="font-family: {font_family};">{safe_bhav}</div>
                </div>
                """)

            all_views = "\n".join(views_html_parts)

            card_html = f"""
            <article class="verse-card" id="verse-{v_num}" aria-labelledby="verse-heading-{v_num}">
                <header class="verse-header">
                    <span class="verse-number" id="verse-heading-{v_num}">Verse {v_num}</span>
                    <span class="verse-id"><bdi dir="ltr">{v_id}</bdi></span>
                </header>
                <div class="verse-source" dir="ltr">
                    <p class="source-devanagari">{safe_dev}</p>
                    <p class="source-iast">{safe_iast}</p>
                </div>
                {target_translit_html}
                <div class="verse-views">
                    {all_views}
                </div>
            </article>
            """
            verse_cards.append(card_html)

        verses_body = "\n".join(verse_cards)

        # Legacy gap notice if present
        legacy_gap_notice = ""
        if missing.is_legacy_gap_affected:
            legacy_gap_notice = f"""
            <section class="legacy-gap-banner" role="note">
                <p><strong>Editorial Notice:</strong> This publication edition reflects historical translation records. "
                "Independent Literal ({missing.missing_literal_count} missing) and Traditional Tatparya ({missing.missing_tatparya_count} missing) "
                "views are currently staged in the controlled scholarly review queue.</p>
            </section>
            """

        timestamp_str = document.generated_at.strftime("%B %d, %Y at %H:%M UTC")

        full_html = f"""<!DOCTYPE html>
<html lang="{safe_bcp47}" dir="{doc_dir}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>{safe_title} — {safe_lang_name} Edition</title>
    <meta name="description" content="Authentic publication preview of {safe_title} in {safe_lang_name} ({safe_script_name}).">
    <meta name="generator" content="Vedic Heritage Digital Library Multilingual Publication Engine">
    <style>
        :root {{
            --royal-maroon: #800020;
            --royal-gold: #D4AF37;
            --dark-charcoal: #1F2937;
            --subtle-gray: #F3F4F6;
            --border-color: #E5E7EB;
            --text-muted: #6B7280;
            --bg-card: #FFFFFF;
            --bg-body: #F9FAFB;
        }}
        * {{ box-sizing: border-box; margin: 0; padding: 0; }}
        body {{
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            background-color: var(--bg-body);
            color: var(--dark-charcoal);
            line-height: 1.6;
            padding-bottom: 3rem;
        }}
        .draft-watermark-banner {{
            background: linear-gradient(135deg, #FFFBEB 0%, #FEF3C7 100%);
            border-bottom: 2px solid #F59E0B;
            color: #92400E;
            padding: 0.75rem 1.5rem;
            text-align: center;
            font-weight: 600;
            font-size: 0.95rem;
            position: sticky;
            top: 0;
            z-index: 100;
            box-shadow: 0 2px 4px rgba(0,0,0,0.05);
        }}
        .watermark-badge {{
            background-color: #F59E0B;
            color: white;
            padding: 0.2rem 0.5rem;
            border-radius: 4px;
            font-size: 0.8rem;
            margin-right: 0.5rem;
        }}
        .container {{
            max-width: 900px;
            margin: 0 auto;
            padding: 1.5rem;
        }}
        .publication-header {{
            background-color: var(--bg-card);
            border-radius: 8px;
            border: 1px solid var(--border-color);
            padding: 2rem;
            margin-bottom: 2rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.05);
            text-align: center;
        }}
        .title-devanagari {{
            font-size: 2rem;
            color: var(--royal-maroon);
            margin-bottom: 0.5rem;
            font-family: 'Noto Sans Devanagari', 'Siddhanta', 'Nirmala UI', sans-serif;
        }}
        .title-canonical {{
            font-size: 1.5rem;
            color: #111827;
            font-weight: 700;
            margin-bottom: 1rem;
        }}
        .badge-bar {{
            display: flex;
            flex-wrap: wrap;
            justify-content: center;
            gap: 0.5rem;
            margin-top: 1rem;
        }}
        .badge {{
            font-size: 0.8rem;
            padding: 0.25rem 0.6rem;
            border-radius: 12px;
            font-weight: 500;
        }}
        .badge-primary {{ background-color: var(--royal-maroon); color: white; }}
        .badge-secondary {{ background-color: #4B5563; color: white; }}
        .badge-info {{ background-color: #1D4ED8; color: white; }}
        .badge-outline {{ border: 1px solid var(--border-color); color: var(--text-muted); }}
        .status-draft {{ background-color: #FEF3C7; color: #92400E; }}
        .status-approved {{ background-color: #D1FAE5; color: #065F46; }}
        .status-submitted_for_review {{ background-color: #DBEAFE; color: #1E40AF; }}
        .verse-card {{
            background-color: var(--bg-card);
            border: 1px solid var(--border-color);
            border-radius: 8px;
            padding: 1.5rem;
            margin-bottom: 1.5rem;
            box-shadow: 0 1px 3px rgba(0,0,0,0.04);
        }}
        .verse-header {{
            display: flex;
            justify-content: space-between;
            border-bottom: 1px solid var(--border-color);
            padding-bottom: 0.5rem;
            margin-bottom: 1rem;
        }}
        .verse-number {{
            font-weight: 700;
            color: var(--royal-maroon);
            font-size: 1.1rem;
        }}
        .verse-id {{
            color: var(--text-muted);
            font-size: 0.85rem;
            font-family: monospace;
        }}
        .verse-source {{
            background-color: #FAF5EF;
            border-left: 4px solid var(--royal-maroon);
            padding: 1rem;
            border-radius: 4px;
            margin-bottom: 1rem;
        }}
        .source-devanagari {{
            font-size: 1.25rem;
            color: #4A151B;
            margin-bottom: 0.35rem;
            font-family: 'Noto Sans Devanagari', 'Siddhanta', 'Nirmala UI', sans-serif;
            line-height: 1.5;
        }}
        .source-iast {{
            font-size: 0.95rem;
            color: #555555;
            font-style: italic;
            font-family: 'Charis SIL', 'Gentium Plus', 'Georgia', serif;
        }}
        .verse-script-translit {{
            background-color: #EFF6FF;
            border-left: 4px solid #2563EB;
            padding: 0.85rem 1rem;
            border-radius: 4px;
            margin-bottom: 1rem;
        }}
        .view-label {{
            font-size: 0.75rem;
            font-weight: 600;
            color: #1E40AF;
            text-transform: uppercase;
            display: block;
            margin-bottom: 0.25rem;
        }}
        .script-recitation-text {{
            font-size: 1.15rem;
            color: #1E3A8A;
            line-height: 1.5;
        }}
        .translation-view {{
            border-top: 1px dashed var(--border-color);
            padding: 0.85rem 0;
        }}
        .view-header {{
            display: flex;
            justify-content: space-between;
            margin-bottom: 0.4rem;
        }}
        .view-title {{
            font-weight: 600;
            font-size: 0.85rem;
            color: #374151;
            text-transform: uppercase;
            letter-spacing: 0.03em;
        }}
        .view-content {{
            font-size: 1.05rem;
            color: #111827;
            line-height: 1.6;
        }}
        .badge-mini {{
            font-size: 0.7rem;
            padding: 0.1rem 0.4rem;
            border-radius: 4px;
            font-weight: 600;
        }}
        .missing-view {{
            padding: 0.5rem 0;
            color: #9CA3AF;
            font-size: 0.85rem;
            font-style: italic;
        }}
        .legacy-gap-banner {{
            background-color: #FEF3C7;
            border: 1px solid #F59E0B;
            border-radius: 6px;
            padding: 1rem;
            margin-bottom: 1.5rem;
            font-size: 0.9rem;
            color: #78350F;
        }}
        .publication-footer {{
            text-align: center;
            color: var(--text-muted);
            font-size: 0.85rem;
            margin-top: 3rem;
            border-top: 1px solid var(--border-color);
            padding-top: 1.5rem;
        }}
        .footer-disclaimer {{
            max-width: 650px;
            margin: 0.5rem auto;
            font-size: 0.8rem;
            line-height: 1.4;
        }}
        /* RTL Layout Tweaks */
        html[dir="rtl"] .verse-source {{
            border-left: none;
            border-right: 4px solid var(--royal-maroon);
        }}
        html[dir="rtl"] .verse-script-translit {{
            border-left: none;
            border-right: 4px solid #2563EB;
        }}
    </style>
</head>
<body>
    {watermark_html}
    <div class="container">
        <header class="publication-header">
            <h1 class="title-devanagari">{safe_dev_title}</h1>
            <h2 class="title-canonical">{safe_title}</h2>
            <div class="badge-bar">
                {badge_bar}
            </div>
        </header>

        {legacy_gap_notice}

        <main class="publication-verses">
            {verses_body}
        </main>

        <footer class="publication-footer">
            <p><strong>Vedic Heritage Platform Digital Publication Edition</strong></p>
            <p>Generated: {timestamp_str} | Document Hash: <code>{document.document_hash[:16]}...</code></p>
            <p class="footer-disclaimer">{html.escape(gov.disclaimer)}</p>
        </footer>
    </div>
</body>
</html>
"""
        return full_html
