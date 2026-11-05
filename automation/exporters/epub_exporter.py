"""
Vedic Heritage Platform — Reflowable Multilingual EPUB 3 Exporter
Part D.6: Standards-compliant EPUB 3 reflowable publication generator
built natively with Python standard library (zipfile), supporting bidirectional
page progression, Dublin Core metadata, semantic XHTML5, and DRAFT governance.
"""

from datetime import datetime, timezone
import html
import io
import logging
from pathlib import Path
from typing import Any, Dict, List, Optional, Union
import uuid
import zipfile

from automation.exporters.bidi_layout import BidiLayoutEngine
from automation.exporters.publication_gatekeeper import PublicationGatekeeper, ReleaseGateVerdict
from automation.exporters.publication_model import PublicationDocument, VerseEntry
from automation.exporters.typography import MultilingualTypographyEngine

logger = logging.getLogger("vedam.automation.exporters.epub_exporter")


class MultilingualEPUBExporter:
    """
    Generates standards-compliant EPUB 3 reflowable digital publications.
    """

    DEFAULT_OUTPUT_DIR = "exports/multilingual_publication/epub"

    @classmethod
    def export(
        cls,
        document: PublicationDocument,
        output_path: Optional[str] = None,
        enforce_gate: bool = True,
    ) -> str:
        """
        Generate reflowable EPUB 3 archive and write to output_path.
        Returns the absolute path of the generated .epub file.
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
            fname = f"{document.metadata.content_id}_{slug}_{document.target.bcp47}_{document.governance.publication_channel}.epub"
            out_path = out_dir / fname
        else:
            out_path = Path(output_path)
            out_path.parent.mkdir(parents=True, exist_ok=True)

        epub_bytes = cls.generate_epub_bytes(document)
        with open(out_path, "wb") as f:
            f.write(epub_bytes)

        logger.info("Exported EPUB 3 publication to %s (%d bytes)", out_path, len(epub_bytes))
        return str(out_path.resolve())

    @classmethod
    def generate_epub_bytes(cls, document: PublicationDocument) -> bytes:
        """
        Generates byte stream of valid EPUB 3 file.
        """
        # Generate EPUB components
        container_xml = cls._generate_container_xml()
        styles_css = cls._generate_styles_css(document)
        nav_xhtml = cls._generate_nav_xhtml(document)
        content_opf = cls._generate_content_opf(document)
        titlepage_xhtml = cls._generate_titlepage_xhtml(document)
        content_xhtml = cls._generate_content_xhtml(document)

        # Build ZIP archive in memory
        epub_buffer = io.BytesIO()
        with zipfile.ZipFile(epub_buffer, mode="w") as zf:
            # 1. mimetype MUST be the first file and uncompressed (ZIP_STORED)
            mimetype_bytes = b"application/epub+zip"
            zf.writestr(
                "mimetype",
                mimetype_bytes,
                compress_type=zipfile.ZIP_STORED,
            )

            # 2. META-INF/container.xml
            zf.writestr(
                "META-INF/container.xml",
                container_xml.encode("utf-8"),
                compress_type=zipfile.ZIP_DEFLATED,
            )

            # 3. OEBPS contents
            zf.writestr(
                "OEBPS/content.opf",
                content_opf.encode("utf-8"),
                compress_type=zipfile.ZIP_DEFLATED,
            )
            zf.writestr(
                "OEBPS/nav.xhtml",
                nav_xhtml.encode("utf-8"),
                compress_type=zipfile.ZIP_DEFLATED,
            )
            zf.writestr(
                "OEBPS/styles.css",
                styles_css.encode("utf-8"),
                compress_type=zipfile.ZIP_DEFLATED,
            )
            zf.writestr(
                "OEBPS/titlepage.xhtml",
                titlepage_xhtml.encode("utf-8"),
                compress_type=zipfile.ZIP_DEFLATED,
            )
            zf.writestr(
                "OEBPS/content.xhtml",
                content_xhtml.encode("utf-8"),
                compress_type=zipfile.ZIP_DEFLATED,
            )

        return epub_buffer.getvalue()

    @classmethod
    def _generate_container_xml(cls) -> str:
        return (
            '<?xml version="1.0" encoding="UTF-8"?>\n'
            '<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">\n'
            '  <rootfiles>\n'
            '    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>\n'
            '  </rootfiles>\n'
            '</container>\n'
        )

    @classmethod
    def _generate_content_opf(cls, doc: PublicationDocument) -> str:
        pub_id = f"urn:vedam:text:{doc.metadata.content_id}:{doc.target.bcp47}"
        modified = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
        page_dir = "rtl" if doc.target.is_rtl else "ltr"

        title = html.escape(f"{doc.metadata.canonical_title} ({doc.metadata.devanagari_title})")
        lang = html.escape(doc.target.bcp47)
        creator = html.escape(doc.metadata.composer or doc.metadata.rishi or "Vedic Tradition")
        rights = "Vedic Sacred Heritage Platform. Traditional canonical texts in public domain."
        if not doc.governance.is_approved_for_public_release:
            rights += " Unapproved translation manuscript: strictly internal scholarly review only."

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<package xmlns="http://www.idpf.org/2007/opf" unique-identifier="pub-id" version="3.0" prefix="rendition: http://www.idpf.org/vocab/rendition/#">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:identifier id="pub-id">{pub_id}</dc:identifier>
    <dc:title>{title}</dc:title>
    <dc:language>{lang}</dc:language>
    <dc:language>sa</dc:language>
    <dc:creator>{creator}</dc:creator>
    <dc:publisher>Vedic Heritage Platform</dc:publisher>
    <dc:rights>{html.escape(rights)}</dc:rights>
    <meta property="dcterms:modified">{modified}</meta>
    <meta property="rendition:layout">reflowable</meta>
    <meta property="rendition:spread">auto</meta>
  </metadata>
  <manifest>
    <item id="nav" href="nav.xhtml" media-type="application/xhtml+xml" properties="nav"/>
    <item id="styles" href="styles.css" media-type="text/css"/>
    <item id="titlepage" href="titlepage.xhtml" media-type="application/xhtml+xml"/>
    <item id="content" href="content.xhtml" media-type="application/xhtml+xml"/>
  </manifest>
  <spine page-progression-direction="{page_dir}">
    <itemref idref="titlepage"/>
    <itemref idref="content"/>
  </spine>
</package>
"""

    @classmethod
    def _generate_nav_xhtml(cls, doc: PublicationDocument) -> str:
        lang = doc.target.bcp47
        direction = doc.target.direction
        title = html.escape(doc.metadata.canonical_title)

        nav_items = [
            '        <li><a href="titlepage.xhtml">Title Page</a></li>',
            '        <li><a href="content.xhtml">Canonical Verses</a></li>',
        ]
        # Verse sub-navigation
        verse_links = []
        for v in doc.verses:
            verse_links.append(f'            <li><a href="content.xhtml#verse-{v.verse_number}">Verse {v.verse_number}</a></li>')
        if verse_links:
            nav_items.append('        <li><span>Verses List</span>\n          <ol>\n' + '\n'.join(verse_links) + '\n          </ol>\n        </li>')

        nav_content = "\n".join(nav_items)

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="{lang}" dir="{direction}">
  <head>
    <meta charset="utf-8"/>
    <title>Navigation — {title}</title>
    <link rel="stylesheet" type="text/css" href="styles.css"/>
  </head>
  <body dir="{direction}">
    <nav epub:type="toc" id="toc">
      <h1>Table of Contents</h1>
      <ol>
{nav_content}
      </ol>
    </nav>
    <nav epub:type="landmarks" hidden="">
      <h2>Landmarks</h2>
      <ol>
        <li><a epub:type="toc" href="#toc">Table of Contents</a></li>
        <li><a epub:type="bodymatter" href="content.xhtml">Verses</a></li>
      </ol>
    </nav>
  </body>
</html>
"""

    @classmethod
    def _generate_styles_css(cls, doc: PublicationDocument) -> str:
        target_css_stack = MultilingualTypographyEngine.get_css_font_family(doc.target.script_code)
        deva_css_stack = MultilingualTypographyEngine.get_css_font_family("Deva")

        return f"""/* Vedic Heritage Platform — Reflowable Multilingual EPUB Stylesheet */
@charset "UTF-8";

body {{
    font-family: {target_css_stack}, serif;
    font-size: 1.0em;
    line-height: 1.6;
    margin: 5%;
    color: #1a1a1a;
    background-color: #ffffff;
}}

[dir="rtl"] {{
    direction: rtl;
    text-align: right;
}}

[dir="ltr"] {{
    direction: ltr;
    text-align: left;
}}

/* Typography */
h1, h2, h3, h4 {{
    font-family: {target_css_stack}, serif;
    color: #4a0e17;
    margin-top: 1.2em;
    margin-bottom: 0.5em;
}}

h1.main-title {{
    font-size: 1.8em;
    text-align: center;
    border-bottom: 2px solid #b38b47;
    padding-bottom: 0.3em;
}}

.devanagari-title {{
    font-family: {deva_css_stack};
    font-size: 1.5em;
    text-align: center;
    color: #781c2b;
    margin-top: -0.2em;
}}

.meta-table {{
    width: 100%;
    margin: 1.5em 0;
    border-collapse: collapse;
    font-size: 0.9em;
}}

.meta-table td {{
    padding: 6px 10px;
    border-bottom: 1px solid #e0d5c1;
}}

.meta-label {{
    font-weight: bold;
    color: #4a0e17;
    width: 30%;
}}

/* Draft Banner */
.draft-banner {{
    border: 2px dashed #b71c1c;
    background-color: #ffebee;
    color: #b71c1c;
    padding: 12px 16px;
    margin: 1.5em 0;
    border-radius: 6px;
    font-weight: bold;
    text-align: center;
}}

.draft-disclaimer {{
    font-size: 0.8em;
    color: #7f0000;
    margin-top: 6px;
    font-weight: normal;
}}

/* Verses */
.verse-card {{
    border: 1px solid #dcd3c2;
    border-radius: 6px;
    padding: 16px;
    margin: 2em 0;
    background-color: #fdfbf7;
    page-break-inside: avoid;
}}

.verse-header {{
    font-size: 1.1em;
    font-weight: bold;
    color: #4a0e17;
    border-bottom: 1px solid #e2d9cc;
    padding-bottom: 4px;
    margin-bottom: 12px;
}}

.source-sanskrit {{
    font-family: {deva_css_stack};
    font-size: 1.25em;
    line-height: 1.8;
    color: #2b1100;
    white-space: pre-line;
    margin: 10px 0;
    direction: ltr;
    text-align: center;
}}

.iast-text {{
    font-family: 'Times New Roman', Georgia, serif;
    font-style: italic;
    color: #444444;
    font-size: 0.95em;
    line-height: 1.5;
    margin: 8px 0 14px 0;
    direction: ltr;
    text-align: center;
}}

.target-script-text {{
    font-family: {target_css_stack};
    font-size: 1.15em;
    line-height: 1.7;
    color: #3b220e;
    margin: 8px 0 14px 0;
    text-align: center;
}}

.view-section {{
    margin-top: 12px;
    padding-top: 8px;
    border-top: 1px dashed #dcd3c2;
}}

.view-label {{
    font-weight: bold;
    color: #781c2b;
    font-size: 0.85em;
    text-transform: uppercase;
    letter-spacing: 0.05em;
    margin-bottom: 4px;
}}

.view-content {{
    font-size: 1.0em;
    line-height: 1.6;
    color: #1a1a1a;
    margin: 4px 0;
}}

.missing-note {{
    font-style: italic;
    color: #c62828;
    background-color: #ffebee;
    padding: 4px 8px;
    border-radius: 3px;
    font-size: 0.85em;
    display: inline-block;
}}

.status-badge {{
    font-size: 0.75em;
    padding: 2px 6px;
    border-radius: 3px;
    font-weight: bold;
    text-transform: uppercase;
}}

.badge-draft {{
    background-color: #fff3e0;
    color: #e65100;
}}

.badge-approved {{
    background-color: #e8f5e9;
    color: #2e7d32;
}}
"""

    @classmethod
    def _generate_titlepage_xhtml(cls, doc: PublicationDocument) -> str:
        lang = doc.target.bcp47
        direction = doc.target.direction
        c_title = html.escape(doc.metadata.canonical_title)
        d_title = html.escape(doc.metadata.devanagari_title)

        banner_html = ""
        if not doc.governance.is_approved_for_public_release:
            banner_html = f"""
    <div class="draft-banner">
      <div style="font-size: 1.2em; text-transform: uppercase;">*** {html.escape(doc.governance.watermark_text or "UNAPPROVED DRAFT")} ***</div>
      <div class="draft-disclaimer">{html.escape(doc.governance.disclaimer)}</div>
    </div>
"""

        rows = []
        if doc.metadata.source_scripture:
            rows.append(f'<tr><td class="meta-label">Source Scripture</td><td>{html.escape(doc.metadata.source_scripture)}</td></tr>')
        if doc.metadata.composer:
            rows.append(f'<tr><td class="meta-label">Composer / Rishi</td><td>{html.escape(doc.metadata.composer)}</td></tr>')
        if doc.metadata.deity:
            rows.append(f'<tr><td class="meta-label">Deity</td><td>{html.escape(doc.metadata.deity)}</td></tr>')
        if doc.metadata.chandas:
            rows.append(f'<tr><td class="meta-label">Chandas</td><td>{html.escape(doc.metadata.chandas)}</td></tr>')
        rows.append(f'<tr><td class="meta-label">Target Language</td><td>{html.escape(doc.target.language_name)} ({html.escape(doc.target.script_name)})</td></tr>')
        rows.append(f'<tr><td class="meta-label">Total Canonical Verses</td><td>{len(doc.verses)}</td></tr>')
        rows.append(f'<tr><td class="meta-label">Publication Channel</td><td><code>{html.escape(doc.governance.publication_channel)}</code></td></tr>')
        rows.append(f'<tr><td class="meta-label">Review Status</td><td><strong>{html.escape(doc.governance.overall_review_status)}</strong></td></tr>')

        meta_rows_html = "\n".join(rows)

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="{lang}" dir="{direction}">
  <head>
    <meta charset="utf-8"/>
    <title>{c_title}</title>
    <link rel="stylesheet" type="text/css" href="styles.css"/>
  </head>
  <body dir="{direction}">
    <section epub:type="titlepage">
      <h1 class="main-title">{c_title}</h1>
      <div class="devanagari-title">{d_title}</div>
{banner_html}
      <table class="meta-table">
{meta_rows_html}
      </table>
    </section>
  </body>
</html>
"""

    @classmethod
    def _generate_content_xhtml(cls, doc: PublicationDocument) -> str:
        lang = doc.target.bcp47
        direction = doc.target.direction
        is_rtl = doc.target.is_rtl

        articles = []
        for v in doc.verses:
            articles.append(cls._render_verse_article(v, is_rtl))

        all_articles = "\n\n".join(articles)

        return f"""<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE html>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops" lang="{lang}" dir="{direction}">
  <head>
    <meta charset="utf-8"/>
    <title>{html.escape(doc.metadata.canonical_title)} — Verses</title>
    <link rel="stylesheet" type="text/css" href="styles.css"/>
  </head>
  <body dir="{direction}">
    <section epub:type="bodymatter chapter">
      <h2 style="text-align: center;">Canonical Verses and Translations</h2>
{all_articles}
    </section>
  </body>
</html>
"""

    @classmethod
    def _render_verse_article(cls, v: VerseEntry, is_rtl: bool) -> str:
        dir_attr = ' dir="rtl"' if is_rtl else ' dir="ltr"'
        v_num = v.verse_number

        deva_escaped = html.escape(v.devanagari_source)
        iast_escaped = html.escape(v.iast_transliteration) if v.iast_transliteration else ""

        target_trans_html = ""
        if v.target_script_transliteration:
            target_trans_html = f'      <div class="target-script-text"{dir_attr}>{html.escape(v.target_script_transliteration)}</div>\n'

        views_html = []

        # Literal translation view
        if v.literal_translation:
            badge_class = "badge-approved" if v.literal_status == "APPROVED" else "badge-draft"
            text_bidi = BidiLayoutEngine.wrap_html_bidi(v.literal_translation, is_rtl)
            views_html.append(
                f'      <div class="view-section">\n'
                f'        <div class="view-label">Literal Translation <span class="status-badge {badge_class}">{v.literal_status}</span></div>\n'
                f'        <div class="view-content"{dir_attr}>{text_bidi}</div>\n'
                f'      </div>'
            )
        else:
            views_html.append(
                f'      <div class="view-section">\n'
                f'        <div class="view-label">Literal Translation</div>\n'
                f'        <div class="missing-note">[Notice: Literal TranslationView missing or in preparation for Verse {v_num}]</div>\n'
                f'      </div>'
            )

        # Tatparya translation view
        if v.tatparya_translation:
            badge_class = "badge-approved" if v.tatparya_status == "APPROVED" else "badge-draft"
            text_bidi = BidiLayoutEngine.wrap_html_bidi(v.tatparya_translation, is_rtl)
            views_html.append(
                f'      <div class="view-section">\n'
                f'        <div class="view-label">Tatparya (Philosophical Purport) <span class="status-badge {badge_class}">{v.tatparya_status}</span></div>\n'
                f'        <div class="view-content"{dir_attr}>{text_bidi}</div>\n'
                f'      </div>'
            )
        else:
            views_html.append(
                f'      <div class="view-section">\n'
                f'        <div class="view-label">Tatparya</div>\n'
                f'        <div class="missing-note">[Notice: Tatparya TranslationView missing or in preparation for Verse {v_num}]</div>\n'
                f'      </div>'
            )

        # Bhavartha translation view
        if v.bhavartha_translation:
            badge_class = "badge-approved" if v.bhavartha_status == "APPROVED" else "badge-draft"
            text_bidi = BidiLayoutEngine.wrap_html_bidi(v.bhavartha_translation, is_rtl)
            views_html.append(
                f'      <div class="view-section">\n'
                f'        <div class="view-label">Bhavartha (Contextual Meaning) <span class="status-badge {badge_class}">{v.bhavartha_status}</span></div>\n'
                f'        <div class="view-content"{dir_attr}>{text_bidi}</div>\n'
                f'      </div>'
            )
        else:
            views_html.append(
                f'      <div class="view-section">\n'
                f'        <div class="view-label">Bhavartha</div>\n'
                f'        <div class="missing-note">[Notice: Bhavartha TranslationView missing or in preparation for Verse {v_num}]</div>\n'
                f'      </div>'
            )

        # Word-by-word
        if v.word_by_word_json:
            wbw_items = []
            for item in v.word_by_word_json:
                s_word = html.escape(item.get("sanskrit", ""))
                m_word = html.escape(item.get("meaning", ""))
                wbw_items.append(f'          <tr><td style="font-family: \'Noto Sans Devanagari\', serif;">{s_word}</td><td{dir_attr}>{m_word}</td></tr>')
            wbw_table = (
                '      <div class="view-section">\n'
                '        <div class="view-label">Word-by-Word Analysis (Pada-Vibhaga)</div>\n'
                '        <table style="width: 100%; font-size: 0.9em; border-collapse: collapse; margin-top: 4px;">\n'
                + "\n".join(wbw_items) +
                '\n        </table>\n      </div>'
            )
            views_html.append(wbw_table)

        rendered_views = "\n".join(views_html)

        return f"""    <article class="verse-card" id="verse-{v_num}" epub:type="part">
      <div class="verse-header">Verse {v_num}</div>
      <div class="source-sanskrit" dir="ltr">{deva_escaped}</div>
      <div class="iast-text" dir="ltr">{iast_escaped}</div>
{target_trans_html}{rendered_views}
    </article>"""
