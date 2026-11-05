"""
Vedic Heritage Platform — Multilingual Scholarly Review Workbench HTML Dashboard Generator
Part E.2: Renders a production-grade, responsive, accessible, script-aware scholarly workbench interface
supporting all 22 Eighth Schedule Indian Languages + English bridge, 14 writing scripts,
granular TranslationViews, Unicode fidelity diagnostics, RBAC governance, and publication previews.
"""

from datetime import datetime, timezone
import html
import json
import logging
import os
from pathlib import Path
from typing import Any, Dict, List, Optional
from sqlalchemy.orm import Session

from automation.exporters.typography import MultilingualTypographyEngine
from automation.workbench.multilingual_workbench_service import MultilingualWorkbenchService
from database.connection import get_db_session
from database.models import ReviewerProfile, Text, Verse

logger = logging.getLogger("vedam.automation.workbench.multilingual_dashboard")


class MultilingualWorkbenchViewGenerator:
    """Generates the static/interactive Multilingual Scholarly Review Workbench."""

    @classmethod
    def generate_html_workbench(
        cls,
        session: Session,
        content_id: str = "VEDA-TXT-00001",
        verse_number: int = 1,
        target_language: str = "hi",
        target_script: Optional[str] = "Deva",
        reviewer_id: Optional[str] = "REV-ADMIN-001",
        output_file: str = "exports/reports/multilingual_scholarly_workbench.html",
    ) -> str:
        """
        Generates a self-contained, publication-grade interactive HTML dashboard for
        the Multilingual Scholarly Workbench.
        """
        # Fetch payload for requested text and verse
        payload = MultilingualWorkbenchService.get_verse_scholarly_payload(
            session=session,
            content_id=content_id,
            verse_number=verse_number,
            target_language=target_language,
            target_script=target_script,
            reviewer_id=reviewer_id,
        )

        # Catalog metadata for navigation
        all_canonical = (
            session.query(Text)
            .filter(
                Text.content_id.like("VEDA-TXT-%"),
                ~Text.content_id.in_(["VEDA-TXT-TEST01", "VEDA-TXT-00009", "VEDA-TXT-00099"])
            )
            .order_by(Text.id)
            .all()
        )

        current_text = session.query(Text).filter_by(content_id=content_id).first()
        available_verses = current_text.verses if current_text else []

        # Available Reviewers for Persona Switching
        reviewers = session.query(ReviewerProfile).order_by(ReviewerProfile.id).all()

        # Language and Script Registry Metadata
        reg_data = MultilingualWorkbenchService.get_supported_languages_and_scripts()

        # Build HTML Options
        text_options = "".join(
            f'<option value="{t.content_id}" {"selected" if t.content_id == content_id else ""}>'
            f'{t.content_id} — {html.escape(t.canonical_title)} ({t.verse_count} verses)</option>'
            for t in all_canonical
        )

        verse_options = "".join(
            f'<option value="{v.verse_number}" {"selected" if v.verse_number == verse_number else ""}>'
            f'Verse {v.verse_number} ({html.escape(v.verse_type.value)}) — {html.escape(v.verse_id)}</option>'
            for v in available_verses
        )

        lang_options = "".join(
            f'<option value="{l["iso_639_1"]}" {"selected" if l["iso_639_1"] == target_language else ""} '
            f'data-dir="{l["primary_direction"]}" data-primary-script="{l["primary_script"]}">'
            f'{l["name"]} ({l["native_name"]}) [{"RTL" if l["is_rtl"] else "LTR"}]</option>'
            for l in reg_data["languages"]
        )

        # Scripts for the selected language
        target_lang_info = next((l for l in reg_data["languages"] if l["iso_639_1"] == target_language), reg_data["languages"][0])
        script_options = "".join(
            f'<option value="{s["iso_15924"]}" {"selected" if s["iso_15924"] == payload["target_script"] else ""}>'
            f'{s["name"]} ({s["native_name"]}) [{"RTL" if s["is_rtl"] else "LTR"}]</option>'
            for s in target_lang_info["supported_scripts"]
        )

        # Mode Options (Tamil Sangam vs Modern, Manipuri Meitei Mayek vs Bengali)
        mode_options = '<option value="standard">Standard Orthography</option>'
        if target_lang_info.get("special_modes"):
            mode_options = "".join(
                f'<option value="{m["id"]}" {"selected" if m["is_default"] else ""}>{html.escape(m["name"])}</option>'
                for m in target_lang_info["special_modes"]
            )

        reviewer_options = "".join(
            f'<option value="{r.reviewer_id}" {"selected" if r.reviewer_id == reviewer_id else ""}>'
            f'{r.reviewer_id} — {html.escape(r.full_name)} ({getattr(r.primary_role, "value", str(r.primary_role))}) [{getattr(r.verification_status, "value", str(r.verification_status))}]</option>'
            for r in reviewers
        )
        reviewer_options += f'<option value="GUEST" {"selected" if reviewer_id == "GUEST" else ""}>Guest Scholar (Unauthenticated)</option>'

        # Col 1 Data
        col1 = payload["column_1_original"]
        # Col 2 Data
        col2 = payload["column_2_transliterations"]
        # Col 3 Data
        col3 = payload["column_3_literal"]
        # Col 4 Data
        col4 = payload["column_4_traditional"]
        # Col 5 Data
        col5 = payload["column_5_bhavartha"]
        # Col 6 Data
        col6 = payload["column_6_governance"]
        # Unicode Diagnostics
        diag = payload["unicode_diagnostics"]
        # Publication Preview
        pub = payload["publication_preview"]

        # Transliterations cards
        projections_html = []
        for p_item in col2["all_projections"]:
            rev_class = "badge-success" if p_item["is_lossless"] else ("badge-warning" if p_item["reversibility"] == "CONDITIONALLY_REVERSIBLE" else "badge-danger")
            p_dir = "rtl" if p_item["is_rtl"] else "ltr"
            warn_text = f'<div class="proj-warn">⚠ {html.escape("; ".join(p_item["warnings"]))}</div>' if p_item["warnings"] else ""
            projections_html.append(f"""
            <div class="proj-card" dir="{p_dir}">
              <div class="proj-head">
                <span class="proj-name"><bdi>{p_item["script_name"]}</bdi> ({p_item["script_code"]})</span>
                <span class="badge {rev_class}"><bdi>{p_item["reversibility"]}</bdi></span>
              </div>
              <div class="proj-text">{html.escape(p_item["text"])}</div>
              {warn_text}
            </div>
            """)
        projections_block = "".join(projections_html)

        # Audit History
        actions_html = "".join(
            f"""<div class="action-item">
                <span class="badge badge-info">{html.escape(a["action_type"])}</span>
                <span class="badge {'badge-success' if a.get('is_human_review') else 'badge-warning'}">{'HUMAN SCHOLAR' if a.get('is_human_review') else 'SYNTHETIC / TEST'}</span>
                <strong>{html.escape(a["reviewer_name"])}</strong>
                <small class="text-muted">({a["timestamp"][:10]})</small>
                <p class="action-comment">{html.escape(a["scholarly_commentary"])}</p>
            </div>"""
            for a in col6["recent_actions"]
        ) or "<p class='text-muted'>No previous review actions logged for this verse.</p>"

        # Disputes
        disputes_html = "".join(
            f"""<div class="dispute-box">
                <div class="dispute-title"><strong>Dispute: {html.escape(d["dispute_nature"])}</strong> <span class="badge badge-danger">{d["status"]}</span></div>
                <p class="dispute-desc">{html.escape(d.get("editorial_notes") or "Open for traditional sampradaya resolution.")}</p>
            </div>"""
            for d in col6["open_disputes"]
        ) or "<p class='text-muted'>No open disputes recorded on this verse.</p>"

        # Status styling
        gov_profile = col6["reviewer_profile"]
        can_approve = col6["can_approve_views"]
        auth_banner_class = "auth-granted" if col6["is_authorized_for_language"] and not col6["is_quarantined"] else ("auth-demo" if col6["is_quarantined"] else "auth-denied")

        doc_dir = payload["direction"]
        doc_lang = payload["target_language"]
        font_family = MultilingualTypographyEngine.get_profile(payload["target_script"]).css_stack if MultilingualTypographyEngine.get_profile(payload["target_script"]) else "sans-serif"

        html_content = f"""<!DOCTYPE html>
<html lang="{doc_lang}" dir="{doc_dir}">
<head>
<meta charset="utf-8"/>
<meta name="viewport" content="width=device-width, initial-scale=1.0"/>
<title>Vedic Scholarly Review Workbench — {html.escape(payload["canonical_title"])} [{html.escape(payload["target_bcp47"])}]</title>
<style>
  :root {{
    --bg-primary: #0a0e14;
    --bg-surface: #111822;
    --bg-card: #16202c;
    --bg-card-hover: #1e2c3d;
    --border-color: #243447;
    --border-subtle: #1b2636;
    --accent-gold: #e5b567;
    --accent-gold-soft: rgba(229, 181, 103, 0.15);
    --accent-teal: #4fd1c5;
    --accent-teal-soft: rgba(79, 209, 197, 0.15);
    --accent-maroon: #800020;
    --accent-coral: #fc8181;
    --accent-green: #48bb78;
    --accent-green-soft: rgba(72, 187, 120, 0.15);
    --accent-blue: #63b3ed;
    --text-primary: #f7fafc;
    --text-secondary: #a0aec0;
    --text-muted: #718096;
    --font-sanskrit: 'Noto Sans Devanagari', 'Siddhanta', 'Nirmala UI', serif;
    --font-indic: {font_family};
    --font-iast: 'Charis SIL', 'Gentium Plus', 'Georgia', serif;
    --font-ui: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
  }}

  * {{ box-sizing: border-box; margin: 0; padding: 0; }}
  body {{
    background-color: var(--bg-primary);
    color: var(--text-primary);
    font-family: var(--font-ui);
    line-height: 1.5;
    padding: 16px 24px;
    font-size: 14px;
  }}

  /* Focus visible accessibility */
  *:focus-visible {{
    outline: 2px solid var(--accent-gold);
    outline-offset: 2px;
  }}

  /* Header bar */
  header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 2px solid var(--border-color);
    padding-bottom: 12px;
    margin-bottom: 14px;
    flex-wrap: wrap;
    gap: 12px;
  }}
  .logo-title h1 {{
    font-size: 1.45rem;
    color: var(--accent-gold);
    display: flex;
    align-items: center;
    gap: 10px;
    letter-spacing: -0.01em;
  }}
  .logo-title p {{
    font-size: 0.8rem;
    color: var(--text-secondary);
  }}
  .header-badges {{
    display: flex;
    gap: 8px;
    align-items: center;
    flex-wrap: wrap;
  }}
  .gov-pill {{
    background-color: var(--accent-gold-soft);
    border: 1px solid var(--accent-gold);
    color: var(--accent-gold);
    padding: 4px 10px;
    border-radius: 16px;
    font-size: 0.75rem;
    font-weight: 600;
  }}
  .gov-pill-green {{
    background-color: var(--accent-green-soft);
    border-color: var(--accent-green);
    color: var(--accent-green);
  }}
  .gov-pill-draft {{
    background-color: rgba(237, 137, 54, 0.15);
    border: 1px solid #ed8936;
    color: #f6ad55;
    font-weight: bold;
  }}

  /* Governance Census Notice Bar */
  .notice-bar {{
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 10px 16px;
    margin-bottom: 16px;
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(220px, 1fr));
    gap: 12px;
    font-size: 0.8rem;
  }}
  .notice-item-label {{ color: var(--text-muted); display: block; font-size: 0.7rem; text-transform: uppercase; }}
  .notice-item-val {{ color: var(--text-primary); font-weight: 600; }}

  /* Interactive Navigation Bar */
  .control-grid {{
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 14px 16px;
    margin-bottom: 18px;
    display: grid;
    grid-template-columns: 2fr 1.5fr 1.2fr 1fr 1fr 1.6fr;
    gap: 12px;
    align-items: flex-end;
  }}
  @media (max-width: 1400px) {{
    .control-grid {{ grid-template-columns: 1fr 1fr 1fr; }}
  }}
  @media (max-width: 800px) {{
    .control-grid {{ grid-template-columns: 1fr; }}
  }}
  .control-group {{
    display: flex;
    flex-direction: column;
    gap: 4px;
  }}
  .control-label {{
    font-size: 0.75rem;
    color: var(--text-secondary);
    font-weight: 600;
  }}
  select, input, textarea {{
    background-color: var(--bg-card);
    border: 1px solid var(--border-color);
    color: var(--text-primary);
    padding: 8px 10px;
    border-radius: 6px;
    font-size: 0.85rem;
    width: 100%;
    transition: border-color 0.15s ease;
  }}
  select:hover, input:hover, textarea:hover {{
    border-color: var(--accent-gold);
  }}

  /* 6-Column Workbench Grid */
  .workbench-grid {{
    display: grid;
    grid-template-columns: repeat(6, 1fr);
    gap: 14px;
    margin-bottom: 20px;
  }}
  @media (max-width: 1600px) {{
    .workbench-grid {{ grid-template-columns: repeat(3, 1fr); }}
  }}
  @media (max-width: 1000px) {{
    .workbench-grid {{ grid-template-columns: 1fr; }}
  }}

  /* Column Card Styling */
  .col-card {{
    background-color: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 14px;
    display: flex;
    flex-direction: column;
    min-height: 620px;
  }}
  .col-header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    border-bottom: 1px solid var(--border-color);
    padding-bottom: 8px;
    margin-bottom: 12px;
  }}
  .col-header h2 {{
    font-size: 0.95rem;
    color: var(--accent-gold);
    font-weight: 600;
  }}
  .col-badge {{
    background-color: var(--accent-teal-soft);
    color: var(--accent-teal);
    font-size: 0.7rem;
    padding: 2px 6px;
    border-radius: 10px;
    font-weight: 600;
  }}

  /* Typography text containers */
  .indic-source-box {{
    font-family: var(--font-sanskrit);
    font-size: 1.15rem;
    line-height: 1.7;
    color: #ffffff;
    background-color: rgba(0, 0, 0, 0.3);
    padding: 12px;
    border-radius: 6px;
    border-left: 3px solid var(--accent-maroon);
    margin-bottom: 10px;
    white-space: pre-wrap;
    word-break: break-word;
  }}
  .iast-box {{
    font-family: var(--font-iast);
    font-size: 0.9rem;
    line-height: 1.5;
    color: var(--accent-gold);
    background-color: rgba(0, 0, 0, 0.2);
    padding: 8px 10px;
    border-radius: 6px;
    margin-bottom: 10px;
    font-style: italic;
  }}
  .view-content-box {{
    font-family: var(--font-indic);
    font-size: 1.05rem;
    line-height: 1.7;
    color: #f0f4f8;
    background-color: rgba(0, 0, 0, 0.25);
    padding: 12px;
    border-radius: 6px;
    margin-bottom: 10px;
    flex-grow: 1;
    word-break: break-word;
  }}
  .meta-row {{
    font-size: 0.75rem;
    color: var(--text-secondary);
    margin-bottom: 6px;
    display: flex;
    justify-content: space-between;
  }}
  .meta-row strong {{ color: var(--text-primary); }}

  /* Legacy Gap Alert */
  .legacy-gap-box {{
    background-color: rgba(237, 137, 54, 0.1);
    border: 1px solid rgba(237, 137, 54, 0.4);
    border-radius: 6px;
    padding: 12px;
    color: #fbd38d;
    font-size: 0.85rem;
    margin-bottom: 12px;
    line-height: 1.5;
  }}
  .legacy-gap-box strong {{ display: block; margin-bottom: 4px; color: #f6ad55; }}

  /* Badges */
  .badge {{
    font-size: 0.68rem;
    padding: 2px 6px;
    border-radius: 4px;
    font-weight: 600;
    text-transform: uppercase;
  }}
  .badge-success {{ background-color: var(--accent-green-soft); color: var(--accent-green); border: 1px solid var(--accent-green); }}
  .badge-warning {{ background-color: rgba(237, 137, 54, 0.15); color: #f6ad55; border: 1px solid #ed8936; }}
  .badge-danger {{ background-color: rgba(245, 101, 101, 0.15); color: var(--accent-coral); border: 1px solid var(--accent-coral); }}
  .badge-info {{ background-color: rgba(99, 179, 237, 0.15); color: var(--accent-blue); border: 1px solid var(--accent-blue); }}
  .badge-muted {{ background-color: rgba(113, 128, 150, 0.2); color: var(--text-secondary); }}

  /* Transliterations Accordion / Scroll */
  .proj-container {{
    overflow-y: auto;
    max-height: 480px;
    display: flex;
    flex-direction: column;
    gap: 8px;
    padding-right: 4px;
  }}
  .proj-card {{
    background-color: rgba(0, 0, 0, 0.25);
    border: 1px solid var(--border-subtle);
    border-radius: 6px;
    padding: 8px 10px;
  }}
  .proj-head {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 4px;
  }}
  .proj-name {{ font-size: 0.75rem; color: var(--accent-gold); font-weight: 600; }}
  .proj-text {{ font-size: 0.95rem; line-height: 1.5; color: #edf2f7; }}
  .proj-warn {{ font-size: 0.7rem; color: #f6ad55; margin-top: 4px; }}

  /* Action Form in Col 6 */
  .auth-banner {{
    padding: 8px 10px;
    border-radius: 6px;
    margin-bottom: 12px;
    font-size: 0.78rem;
    line-height: 1.4;
  }}
  .auth-granted {{ background-color: var(--accent-green-soft); border: 1px solid var(--accent-green); color: #9ae6b4; }}
  .auth-denied {{ background-color: rgba(245, 101, 101, 0.15); border: 1px solid var(--accent-coral); color: #feb2b2; }}
  .auth-demo {{ background-color: rgba(237, 137, 54, 0.15); border: 1px solid #ed8936; color: #fbd38d; }}

  .action-form textarea {{
    min-height: 70px;
    resize: vertical;
    margin-bottom: 8px;
  }}
  .btn-grid {{
    display: grid;
    grid-template-columns: 1fr 1fr;
    gap: 6px;
    margin-bottom: 12px;
  }}
  .btn {{
    padding: 8px 10px;
    border: none;
    border-radius: 4px;
    font-size: 0.75rem;
    font-weight: 600;
    cursor: pointer;
    text-align: center;
    transition: opacity 0.15s ease;
  }}
  .btn:disabled {{
    opacity: 0.4;
    cursor: not-allowed;
  }}
  .btn-approve {{ background-color: #2f855a; color: #fff; }}
  .btn-correct {{ background-color: #2b6cb0; color: #fff; }}
  .btn-revise {{ background-color: #d69e2e; color: #000; }}
  .btn-dispute {{ background-color: #c53030; color: #fff; }}

  .action-item {{
    border-left: 2px solid var(--accent-teal);
    padding-left: 8px;
    margin-bottom: 8px;
    font-size: 0.78rem;
  }}
  .action-comment {{ color: var(--text-secondary); margin-top: 2px; }}

  .dispute-box {{
    background-color: rgba(245, 101, 101, 0.1);
    border: 1px solid rgba(245, 101, 101, 0.3);
    padding: 8px;
    border-radius: 4px;
    margin-bottom: 8px;
    font-size: 0.78rem;
  }}
  .dispute-title {{ display: flex; justify-content: space-between; align-items: center; margin-bottom: 2px; }}
  .dispute-desc {{ color: var(--text-secondary); }}

  /* Unicode Expandable Diagnostics */
  .diagnostics-section {{
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 12px 16px;
    margin-bottom: 20px;
  }}
  details.diag-drawer summary {{
    font-size: 0.9rem;
    font-weight: 600;
    color: var(--accent-teal);
    cursor: pointer;
    display: flex;
    align-items: center;
    gap: 8px;
    user-select: none;
  }}
  .diag-grid {{
    display: grid;
    grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
    gap: 12px;
    margin-top: 12px;
    padding-top: 12px;
    border-top: 1px solid var(--border-color);
    font-size: 0.8rem;
  }}
  .diag-cell {{
    background-color: var(--bg-card);
    padding: 8px 10px;
    border-radius: 6px;
  }}
  .diag-label {{ color: var(--text-muted); font-size: 0.7rem; }}
  .diag-val {{ font-weight: 600; color: var(--text-primary); }}
  .codepoint-pill-box {{
    display: flex;
    flex-wrap: wrap;
    gap: 4px;
    margin-top: 8px;
  }}
  .cp-pill {{
    background-color: rgba(0, 0, 0, 0.3);
    border: 1px solid var(--border-subtle);
    padding: 2px 6px;
    border-radius: 4px;
    font-size: 0.68rem;
    font-family: monospace;
    color: var(--accent-gold);
  }}

  /* Publication Preview Section */
  .pub-preview-section {{
    background-color: var(--bg-surface);
    border: 1px solid var(--border-color);
    border-radius: 8px;
    padding: 14px 18px;
    margin-bottom: 20px;
  }}
  .pub-header {{
    display: flex;
    justify-content: space-between;
    align-items: center;
    margin-bottom: 12px;
    flex-wrap: wrap;
    gap: 10px;
  }}
  .pub-header h3 {{
    font-size: 1rem;
    color: var(--accent-gold);
    display: flex;
    align-items: center;
    gap: 8px;
  }}
  .pub-formats-grid {{
    display: grid;
    grid-template-columns: repeat(4, 1fr);
    gap: 12px;
  }}
  @media (max-width: 1100px) {{
    .pub-formats-grid {{ grid-template-columns: 1fr 1fr; }}
  }}
  @media (max-width: 600px) {{
    .pub-formats-grid {{ grid-template-columns: 1fr; }}
  }}
  .pub-format-card {{
    background-color: var(--bg-card);
    border: 1px solid var(--border-color);
    border-radius: 6px;
    padding: 12px;
    display: flex;
    flex-direction: column;
    gap: 6px;
  }}
  .pub-format-card.limited-preview {{
    border-color: #ed8936;
    background-color: rgba(237, 137, 54, 0.05);
  }}
  .format-title {{
    font-size: 0.85rem;
    font-weight: bold;
    display: flex;
    justify-content: space-between;
    align-items: center;
  }}
  .format-desc {{
    font-size: 0.75rem;
    color: var(--text-secondary);
    line-height: 1.4;
  }}
  .format-warn {{
    font-size: 0.72rem;
    color: #fbd38d;
    background-color: rgba(237, 137, 54, 0.15);
    padding: 4px 6px;
    border-radius: 4px;
    margin-top: 4px;
    line-height: 1.3;
  }}
</style>
</head>
<body>

<header role="banner">
  <div class="logo-title">
    <h1>
      <span>&#2384;</span>
      <bdi>Vedic Scholarly Review Workbench</bdi>
    </h1>
    <p>Multilingual Script-Aware Scholarly Review, Non-Destructive Diagnostics & RBAC-Governed Publication Platform</p>
  </div>
  <div class="header-badges">
    <div class="gov-pill gov-pill-draft" role="status">
      &#9888; <bdi>{html.escape(pub["watermark_text"])}</bdi>
    </div>
    <div class="gov-pill" role="status">
      Gate: <bdi>{pub["gatekeeper_verdict"]}</bdi>
    </div>
    <div class="gov-pill gov-pill-green" role="status">
      Rule PUB-010 / PUB-011 Active
    </div>
  </div>
</header>

<!-- Governance & Quality Census Bar -->
<section class="notice-bar" aria-label="Governance and Corpus Census">
  <div>
    <span class="notice-item-label">Reviewer Authenticity (Rule REV-005)</span>
    <span class="notice-item-val" style="color:var(--accent-gold);">0 Living Humans Approved (Onboarding In-Flight)</span>
    <small style="color:var(--text-muted); display:block;">5 Synthetic Personas, 1 Demo Sandbox</small>
  </div>
  <div>
    <span class="notice-item-label">Legacy TranslationView Gaps (Rule PUB-011)</span>
    <span class="notice-item-val" style="color:#f6ad55;">747 Staged Missing Records</span>
    <small style="color:var(--text-muted); display:block;">Gaps Preserved Transparently (No Auto-Fill)</small>
  </div>
  <div>
    <span class="notice-item-label">Corpus Scale & Active Translations</span>
    <span class="notice-item-val" style="color:var(--accent-teal);">18 Texts (307 Verses) | 3,070 Active Translations</span>
    <small style="color:var(--text-muted); display:block;">100% Retained in DRAFT Lifecycle</small>
  </div>
  <div>
    <span class="notice-item-label">Script & Typography Support</span>
    <span class="notice-item-val" style="color:#68d391;">22 Languages + English | 14 Scripts</span>
    <small style="color:var(--text-muted); display:block;">Directionality: <bdi>{payload["direction"].upper()}</bdi> ({'RTL' if payload['is_rtl'] else 'LTR'})</small>
  </div>
</section>

<!-- Interactive Control Navigation Bar -->
<section class="control-grid" aria-label="Workbench Navigation and Filters">
  <div class="control-group">
    <label for="comp-select" class="control-label">Sacred Composition:</label>
    <select id="comp-select" onchange="alert('In production, switching compositions reloads live database record.')">
      {text_options}
    </select>
  </div>
  <div class="control-group">
    <label for="verse-select" class="control-label">Verse / Stanza:</label>
    <select id="verse-select">
      {verse_options}
    </select>
  </div>
  <div class="control-group">
    <label for="lang-select" class="control-label">Target Language:</label>
    <select id="lang-select" onchange="alert('Switching target language updates translation views and script options.')">
      {lang_options}
    </select>
  </div>
  <div class="control-group">
    <label for="script-select" class="control-label">Target Script:</label>
    <select id="script-select">
      {script_options}
    </select>
  </div>
  <div class="control-group">
    <label for="mode-select" class="control-label">Orthographic Mode:</label>
    <select id="mode-select">
      {mode_options}
    </select>
  </div>
  <div class="control-group">
    <label for="reviewer-select" class="control-label">Simulate Reviewer Persona (RBAC):</label>
    <select id="reviewer-select">
      {reviewer_options}
    </select>
  </div>
</section>

<!-- 6-Column Workbench Workspace -->
<main class="workbench-grid" role="region" aria-label="Scholarly Review Columns">

  <!-- COLUMN 1: Original Sanskrit Source -->
  <article class="col-card" aria-labelledby="col1-heading">
    <div class="col-header">
      <h2 id="col1-heading"><bdi>1. Original Source</bdi></h2>
      <span class="col-badge">Col 1</span>
    </div>
    <div class="meta-row"><span><bdi>Scripture:</bdi></span><strong><bdi>{html.escape(col1["source_scripture"])}</bdi></strong></div>
    <div class="meta-row"><span><bdi>Verse ID:</bdi></span><strong><bdi>{col1["verse_id"]}</bdi></strong></div>
    <div class="meta-row"><span><bdi>Meter:</bdi></span><strong><bdi>{col1["chandas_meter"]}</bdi></strong></div>
    <div class="meta-row"><span><bdi>Vedic Accents:</bdi></span><strong><bdi>{'Preserved & Highlighted' if col1['vedic_accents_present'] else 'Classical Sanskrit'}</bdi></strong></div>
    
    <div class="indic-source-box" lang="sa" dir="ltr">{html.escape(col1["devanagari_text"])}</div>
    <div class="iast-box" lang="sa-Latn" dir="ltr">{html.escape(col1["iast_text"])}</div>

    <div class="meta-row"><span><bdi>Composer / Rishi:</bdi></span><strong><bdi>{html.escape(col1["composer"])}</bdi></strong></div>
    <div class="meta-row"><span><bdi>Verse Type:</bdi></span><strong><bdi>{col1["verse_type"]}</bdi></strong></div>
  </article>

  <!-- COLUMN 2: Script Projections & Transliterations -->
  <article class="col-card" aria-labelledby="col2-heading">
    <div class="col-header">
      <h2 id="col2-heading"><bdi>2. Transliterations</bdi></h2>
      <span class="col-badge">Col 2</span>
    </div>
    <div class="meta-row"><span><bdi>Source Script:</bdi></span><strong><bdi>Devanagari (Deva)</bdi></strong></div>
    <div class="meta-row"><span><bdi>Target Projection:</bdi></span><strong><bdi>{payload["target_script_name"]}</bdi></strong></div>
    <div class="meta-row"><span class="badge badge-info"><bdi>Phonetic Projection Only — Not a Translation</bdi></span></div>

    <div class="proj-container" role="region" aria-label="Script Projections List">
      {projections_block}
    </div>
  </article>

  <!-- COLUMN 3: Literal Translation View -->
  <article class="col-card" aria-labelledby="col3-heading">
    <div class="col-header">
      <h2 id="col3-heading"><bdi>3. Literal Translation</bdi></h2>
      <span class="col-badge">Col 3</span>
    </div>
    <div class="meta-row">
      <span><bdi>Status:</bdi></span>
      <span class="badge {'badge-warning' if col3['is_legacy_gap'] else 'badge-success'}"><bdi>{col3["review_status"]}</bdi></span>
    </div>
    <div class="meta-row"><span><bdi>Source:</bdi></span><strong><bdi>{html.escape(col3["source_reference"])}</bdi></strong></div>

    {f'<div class="legacy-gap-box" dir="ltr"><strong>&#9888; STAGED IN 747 GAP QUEUE</strong>{html.escape(col3["display_notice"])}</div>' if col3["is_legacy_gap"] else ''}

    <div class="view-content-box" lang="{doc_lang}" dir="{doc_dir}">
      {f'<span dir="ltr">{html.escape(col3["text"] or "View pending scholarly extraction.")}</span>' if (doc_dir == 'rtl' and not col3.get('text')) else html.escape(col3["text"] or "View pending scholarly extraction.")}
    </div>

    <div class="meta-row" style="margin-top:auto;"><span><bdi>Padachheda Analysis:</bdi></span></div>
    <div class="meta-row" style="color:var(--text-secondary); font-size:0.75rem;">
      <bdi>{", ".join(html.escape(w) for w in col3["padachheda_words"]) if col3["padachheda_words"] else "Grammatical dissection recorded in database."}</bdi>
    </div>
  </article>

  <!-- COLUMN 4: Traditional Tatparya View -->
  <article class="col-card" aria-labelledby="col4-heading">
    <div class="col-header">
      <h2 id="col4-heading"><bdi>4. Traditional Tatparya</bdi></h2>
      <span class="col-badge">Col 4</span>
    </div>
    <div class="meta-row">
      <span><bdi>Status:</bdi></span>
      <span class="badge {'badge-warning' if col4['is_legacy_gap'] else 'badge-success'}"><bdi>{col4["review_status"]}</bdi></span>
    </div>
    <div class="meta-row"><span><bdi>Commentator:</bdi></span><strong><bdi>{html.escape(col4["commentator_citation"])}</bdi></strong></div>

    {f'<div class="legacy-gap-box" dir="ltr"><strong>&#9888; STAGED IN 747 GAP QUEUE</strong>{html.escape(col4["display_notice"])}</div>' if col4["is_legacy_gap"] else ''}

    <div class="view-content-box" lang="{doc_lang}" dir="{doc_dir}">
      {f'<span dir="ltr">{html.escape(col4["text"] or "Commentary collation pending authorized human review.")}</span>' if (doc_dir == 'rtl' and not col4.get('text')) else html.escape(col4["text"] or "Commentary collation pending authorized human review.")}
    </div>

    <div class="meta-row" style="margin-top:auto;"><span><bdi>Source Reference:</bdi></span><strong><bdi>{html.escape(col4["source_reference"])}</bdi></strong></div>
  </article>

  <!-- COLUMN 5: Devotional Bhavartha View -->
  <article class="col-card" aria-labelledby="col5-heading">
    <div class="col-header">
      <h2 id="col5-heading"><bdi>5. Devotional Bhavartha</bdi></h2>
      <span class="col-badge">Col 5</span>
    </div>
    <div class="meta-row">
      <span><bdi>Target Language:</bdi></span>
      <strong><bdi>{payload["target_language_name"]} ({payload["target_script"]})</bdi></strong>
    </div>
    <div class="meta-row">
      <span><bdi>Directionality:</bdi></span>
      <span class="badge badge-info"><bdi>{payload["direction"].upper()}</bdi></span>
    </div>

    <div class="view-content-box" lang="{doc_lang}" dir="{doc_dir}" style="border-left: 3px solid var(--accent-gold);">
      {f'<span dir="ltr">{html.escape(col5["text"] or "Translation pending regional language draft.")}</span>' if (doc_dir == 'rtl' and not col5.get('text')) else html.escape(col5["text"] or "Translation pending regional language draft.")}
    </div>

    <div class="meta-row" style="margin-top:auto;">
      <span><bdi>Review Status:</bdi></span>
      <span class="badge badge-warning"><bdi>{col5["review_status"]}</bdi></span>
    </div>
    <div class="meta-row"><span><bdi>Liturgical Purpose:</bdi></span><strong><bdi>Daily Bhakti Chanting</bdi></strong></div>
  </article>

  <!-- COLUMN 6: Reviewer RBAC Governance & Audit -->
  <article class="col-card" aria-labelledby="col6-heading">
    <div class="col-header">
      <h2 id="col6-heading"><bdi>6. Reviewer RBAC & Actions</bdi></h2>
      <span class="col-badge">Col 6</span>
    </div>

    <div class="auth-banner {auth_banner_class}">
      <strong><bdi>Reviewer Authorization Status:</bdi></strong><br/>
      <bdi>{html.escape(col6["authorization_message"])}</bdi>
    </div>

    <div class="meta-row">
      <span><bdi>Reviewer ID:</bdi></span>
      <strong><bdi>{gov_profile["reviewer_id"] or "Unauthenticated"}</bdi></strong>
    </div>
    <div class="meta-row">
      <span><bdi>Primary Role:</bdi></span>
      <strong><bdi>{gov_profile["primary_role"]}</bdi></strong>
    </div>
    <div class="meta-row">
      <span><bdi>Accreditation:</bdi></span>
      <span class="badge badge-info"><bdi>{gov_profile["verification_status"]}</bdi></span>
    </div>

    <div class="action-form" style="margin-top:8px;">
      <label for="correction-notes" class="control-label"><bdi>Scholarly Correction / Rationale:</bdi></label>
      <textarea id="correction-notes" placeholder="Enter grammatical, theological, or idiomatic commentary..." {'disabled' if not can_approve else ''}></textarea>
      
      <div class="btn-grid">
        <button class="btn btn-approve" {'disabled' if not can_approve else ''}>Approve View</button>
        <button class="btn btn-correct" {'disabled' if not can_approve else ''}>Approve w/ Edits</button>
        <button class="btn btn-revise" {'disabled' if not can_approve else ''}>Request Revision</button>
        <button class="btn btn-dispute" {'disabled' if not can_approve else ''}>Flag Dispute</button>
      </div>
    </div>

    <div class="meta-row"><span><bdi>Audit History ({len(col6["recent_actions"])} logs):</bdi></span></div>
    <div style="overflow-y:auto; max-height:140px; margin-bottom:8px;">
      {actions_html}
    </div>

    <div class="meta-row"><span><bdi>Preserved Disputes:</bdi></span></div>
    <div style="overflow-y:auto; max-height:100px;">
      {disputes_html}
    </div>
  </article>

</main>

<!-- Expandable Unicode & Vedic Svara Diagnostics Panel -->
<section class="diagnostics-section" aria-label="Unicode and Svara Diagnostics">
  <details class="diag-drawer">
    <summary>
      <span>&#128269;</span>
      <bdi>Non-Destructive Unicode & Vedic Svara Diagnostics Panel</bdi>
      <span class="badge badge-success" style="margin-left:auto;">Read-Only Diagnostic — 100% Database Immutability Guaranteed</span>
    </summary>
    
    <div class="diag-grid">
      <div class="diag-cell">
        <span class="diag-label">NFC Normalized</span>
        <div class="diag-val" style="color:var(--accent-green);">{'PASSED (True)' if diag['is_nfc_normalized'] else 'FAILED'}</div>
      </div>
      <div class="diag-cell">
        <span class="diag-label">NFD Normalized</span>
        <div class="diag-val">{'True' if diag['is_nfd_normalized'] else 'False'}</div>
      </div>
      <div class="diag-cell">
        <span class="diag-label">Character / UTF-8 Byte Count</span>
        <div class="diag-val">{diag["char_count"]} chars / {diag["byte_count_utf8"]} bytes</div>
      </div>
      <div class="diag-cell">
        <span class="diag-label">Vedic Swaras (Tones)</span>
        <div class="diag-val" style="color:var(--accent-gold);">{diag["vedic_accent_count"]} tone accents ({', '.join(diag["vedic_accents"]) or 'None'})</div>
      </div>
      <div class="diag-cell">
        <span class="diag-label">Combining Marks Count</span>
        <div class="diag-val">{diag["combining_mark_count"]} combining marks</div>
      </div>
      <div class="diag-cell">
        <span class="diag-label">Control Chars (ZWJ / ZWNJ)</span>
        <div class="diag-val">ZWJ: {str(diag["has_zwj"])} | ZWNJ: {str(diag["has_zwnj"])}</div>
      </div>
      <div class="diag-cell">
        <span class="diag-label">Script Purity & Detection</span>
        <div class="diag-val">{diag["script_detected"]} (Pure: {str(diag["is_pure_script"])})</div>
      </div>
    </div>

    <div style="margin-top:10px;">
      <span class="diag-label">Codepoints Breakdown (First 25 characters):</span>
      <div class="codepoint-pill-box">
        {"".join(f'<span class="cp-pill">{html.escape(cp)}</span>' for cp in diag["sample_codepoints"])}
      </div>
    </div>
  </details>
</section>

<!-- Publication Preflight & Gatekeeper Preview Section -->
<section class="pub-preview-section" aria-label="Publication Preflight and Gatekeeper Status">
  <div class="pub-header">
    <h3>
      <span>&#128196;</span>
      <bdi>Publication Preflight Gating & Multi-Format Exporter Preview</bdi>
    </h3>
    <div style="display:flex; gap:8px; align-items:center;">
      <span class="badge badge-warning">Gate Verdict: {pub["gatekeeper_verdict"]}</span>
      <span class="badge badge-info">Channel: {pub["channel"]}</span>
    </div>
  </div>

  <div class="pub-formats-grid">
    <!-- HTML Format -->
    <div class="pub-format-card">
      <div class="format-title">
        <span>HTML Web Edition</span>
        <span class="badge badge-success">READY</span>
      </div>
      <div class="format-desc">{pub["formats"]["html"]["description"]}</div>
    </div>

    <!-- DOCX Format -->
    <div class="pub-format-card">
      <div class="format-title">
        <span>Word (.docx) Manuscript</span>
        <span class="badge badge-success">READY</span>
      </div>
      <div class="format-desc">{pub["formats"]["docx"]["description"]}</div>
    </div>

    <!-- EPUB 3 Format -->
    <div class="pub-format-card">
      <div class="format-title">
        <span>EPUB 3 Package</span>
        <span class="badge badge-success">READY</span>
      </div>
      <div class="format-desc">{pub["formats"]["epub"]["description"]}</div>
    </div>

    <!-- PDF Format with MANDATORY Limited Preview Only Badge -->
    <div class="pub-format-card limited-preview">
      <div class="format-title">
        <span>PDF Edition</span>
        <span class="badge badge-warning" style="background-color:#ed8936; color:#000;">LIMITED PREVIEW ONLY</span>
      </div>
      <div class="format-desc">ReportLab PDF exporter is strictly restricted to draft layout preview.</div>
      <div class="format-warn">
        <strong>&#9888; NOT PRINT-READY:</strong> {pub["formats"]["pdf"]["warning"]}
      </div>
    </div>
  </div>
</section>

</body>
</html>
"""
        out_path = Path(output_file)
        out_path.parent.mkdir(parents=True, exist_ok=True)
        with open(out_path, "w", encoding="utf-8") as f:
            f.write(html_content)

        logger.info("Multilingual scholarly workbench HTML exported to: %s", out_path)
        return str(out_path)
