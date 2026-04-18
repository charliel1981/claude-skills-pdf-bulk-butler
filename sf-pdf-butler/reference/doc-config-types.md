# DocConfig Types — PDF Butler

Every DocConfig **output type** — chosen when you create the DocConfig record. Each type drives a different renderer and template format. Claude reads this when a user says "I need to generate X" and X is a format choice.

## Quick chooser

| Output wanted | DocConfig type |
|---|---|
| PDF or Word doc from a MS Word template | **Main Word / PDF** |
| Reusable snippet to attach via `DOCUMENT_V3` or `ADDITIONAL_DOCS` | **Template Word** |
| Spreadsheet (XLSX) | **Main Excel Document** |
| Fixed brochure / T&Cs PDF with image placeholder replacement | **Static PDF** |
| Column hidden dynamically in a Word table | **TABLE_COLUMN_REMOVER** |
| HTML email (beyond native Salesforce templates) | **Email** |
| Fill an existing PDF form (gov/company form) | **PDF Form Filler** |
| CSV / delimited export | **CSV** |
| Slide deck (PPTX) | **Main PowerPoint Document** |

---

## Catalog

### Main Word / PDF — `MAIN WORD / PDF`

**Primary generator**. Upload a DOCX template; output as PDF or DOCX (`cdm.targetType = 'PDF'` or `'DOCX'`).

**DocConfig MetaData settings** (verbatim label → description, page order):

| Setting | Purpose |
|---|---|
| `Sync Alternative Names` | Stores Alternative names in the `Config MetaData` field on the DocConfig — useful when a customisation lets users pick an Alternative from a UI list. |
| `Calculate Table Of Contents` | Updates a Word TOC if page numbers changed or sections were added/removed dynamically. |
| `Use next version PDF processor` | Toggle (not a version dropdown). "If this option is presented to you, congratz, you are a customer for a long time. Best to always enable." |
| `Export PDF as PDF/a` | Archival compliance (lowercase `a` — verbatim). "PDF will always open on any system." |
| `PDF UA Compliance` | Accessibility compliance — structure + titles are still your responsibility; PDF Butler handles data correctness. |
| `Enable Track Changes when generating DOCX` | Enables Track Changes on DOCX output. |
| `Enable Forms` | Add Form Fields for FORM Butler / SIGN Butler. **If you do not see this option, contact support.** |
| `Lock/Encrypt PDF` | Password-protect the PDF. Passwords can be hardcoded or sourced from a SINGLE DataSource. See `reference/tips.md` → Dynamic PDF passwords. |
| `Check and remove empty section at the end of the document` | Cleans up trailing empty pages caused by unresolved `CONDITIONAL_SECTIONS`. |
| `Set title of document` | Sets the document Title (not the filename) in the generated DOCX/PDF. Can come from a SINGLE DataSource; if unset, the document name is used. |
| `Keep only values from MS Word controls` | Cleans ActiveX / legacy Word controls at generation time. |
| `Leave Controls when generating MS Word file` | Companion toggle — keep controls in DOCX output, only clean them for PDF output. |

**Use when**: 90% of document generation. Default choice unless you know you need a different output format.

_Source: [MAIN WORD / PDF](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/main-word-pdf/)._

### Template Word — `Template Word`

**Purpose**: reusable DOCX fragment — NOT a standalone document.
**Consumed by**:
- `DOCUMENT_V3` ConfigType on a main doc (picks templates by DataSource)
- `ADDITIONAL_DOCS` ConfigType (glues as appendix)
- DocConfig Document Override pattern

**Use for**: Terms & Conditions blocks, product sheets, standard clauses — any snippet re-used across many main docs.

### Excel Generator — `EXCEL Generator`

**Template**: a real .xlsx with merge fields in cells. DocConfig type name verbatim from Academy: `EXCEL Generator`.

**Setup gotcha (required)** — verbatim: "After adding merge fields, select the entire row of merge fields and give a name (Let's say 'opportunity') in the Name box and press enter. Then save the excel file. As PDF Butler need to know which region in the excel should be repeated, this has to be done."

**Capabilities**:

- **Region ConfigType** repeats rows driven by a LIST DataSource; Criteria on Region controls whether the entire region renders ("There is no partial rendering: the entire Region is removed from the final Excel document.")
- **`Checkbox` ConfigType** — note exact casing: `Checkbox` with a single capital C (not `CHECKBOX` all-caps) — verbatim from Academy in single-quotes.
- **`LINK` ConfigType** — hyperlinks from SINGLE or LIST DataSource
- **`RICH_TEXT` ConfigType** — "Excel support a downgraded version of Rich Text" (a subset of Excel's rich-text features)
- **Percent fields**: tick the option `Check this box if the cell type in Excel is set to "Percentage"` so Salesforce `75` → Excel `0.75` (Excel multiplies by 100 for display).
- **Inline Excel functions** — `INDIRECT()` for dynamic row references; SUM auto-rewrites to the rendered range.

**Formula examples** (verbatim — note **semicolons** in the IF arguments):

```
=INDIRECT("E" & ROW()) * 'Static Data'!B1
=IF(INDIRECT("F"&ROW())>1000;"YES"; "NO")
```

**Hidden-row gotcha (important)** — Academy verbatim: "If you add any static text, formulas, or other Excel content in the same row where the Region is placed – but outside the Region boundaries, this content will also be hidden when the Region is hidden by criteria. Because the entire row is removed when a Region is not rendered, any data on that row (even if not part of the Region) will not appear in the generated Excel file." Recommendation: "Place unrelated content above or below the Region's row(s) to ensure it always remains visible, regardless of criteria."

**Hard constraint** (verbatim): "You cannot use multiple merge fields in a single cell of your excel template. Only use one merge field per cell."

**Excel → PDF**: "PDF Butler provides an ability to generate your excel file as PDF. You can contact support team to enable this feature." (licensed add-on).

_Source: [EXCEL Generator](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/excel-generator/)._

### Static PDF — `Static PDF`

**Purpose**: include a pre-existing PDF (brochure, general conditions, regulatory notice) in the pipeline.
**Dynamic aspect**: **image placeholder replacement** — you can swap images in a static PDF based on DataSource fields. Text content stays static.
**Typical role**: an `ADDITIONAL_DOCS` entry in a Pack — appended to a Main Word PDF.

### TABLE_COLUMN_REMOVER — `Table Column Remover`

**Purpose**: dynamically show/hide a **column** of a Word table.
**Canonical example**: hide the Discount column when no line item has a discount.
**Placement rules (strict)**:
- Place the column-remover merge field **as high as possible** in the table
- Only **merged rows** may sit above it
- **Never** put it in a row that uses `TABLE_ROW`, `ROWS_CONTROLLER`, or any repeating ConfigType
**Availability**: **disabled by default** — email `support@pdfbutler.com` for free activation.

### Email — `Email`

**Purpose**: generate rich HTML email body from a MS Word template instead of Salesforce's native email templates (native templates limit layout and conditional logic).
**Paired Actionables** (deliver the output):
- `AUTO_EMAIL` — auto-send
- `EMAIL Quick Action` — user-edit-then-send
**Image handling**: use `PICTURE_TO_URL` ConfigType instead of `PICTURE` — email clients rely on URL-referenced images for rendering (see `reference/configtypes.md`).

### PDF Form Filler — `PDF Form Filler`

_Video-only Academy page (YouTube `3TS2-N4pY5k`) — the field-mapping mechanism below is inferred from the public ConfigType surface and needs in-org verification. See [PDF Form Filler](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/pdf-form-filler/)._

**Purpose**: accept an existing PDF with form fields (`AcroForm`) and fill those fields from Salesforce data.
**Common sources**: government forms, insurance intake, partner onboarding PDFs — anywhere you can't redesign the template.
**Field mapping (likely)**: PDF form field name → DataSource field via SINGLE ConfigTypes. **Verify in-org** — the Academy page does not publish the mapping syntax.
**Flatten option**: renders form fields as static text so recipients can't edit. Also achievable via the `DO_NOT_DEPLOY_FlattenPdf` Actionable (see `reference/tips.md` → Flatten PDF).

### CSV — `CSV (Character-Separated Value)`

**Setup gotchas**:
- **Document Title is required** — blank title causes errors
- Title must include extension: `.csv` or `.txt`
**Capability**: standard delimiter-separated output. Delimiter customisation isn't explicitly documented — default is comma; escalate to support for non-comma setups.

### PowerPoint — `Main Powerpoint Document`

**Template**: .pptx with merge fields on slides. DocConfig type name verbatim: `Main Powerpoint Document`.

**Two repeaters** for multi-slide output:

| Repeater | Academy description |
|---|---|
| `SLIDE_REPEATER` | "With the help of SLIDE_REPEATER configType, you can repeat a slide in PPTX file." Example: one product per slide. |
| `SECTION_REPEATER` | "With the help of SECTION_REPEATER configType, you can repeat a section in PPTX file." Example: Account slide → Opportunity slides → Opportunity Products slides per account. |

**Supported ConfigTypes inside slides** — `LINK` on a single mergefield, in a Table Row, or on a Picture. Also `SINGLE` for basic mergefield replacement, `PICTURE` for product images.

_Source: [PPTX – Powerpoint](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/pptx-powerpoint/)._

---

## Pattern: when to combine types in a Pack

| Goal | Pack composition |
|---|---|
| Quote with T&Cs appendix | Main Word PDF (quote body) + Static PDF (T&Cs) with `MERGE` |
| Quote with dynamic T&Cs | Main Word PDF + `DOCUMENT_V3` child referencing Template Word snippets |
| Contract sent for signature | Main Word PDF → Pack → SIGN Butler / DocuSign Actionable |
| Product catalogue | Main Word PDF (cover) + `ADDITIONAL_DOCS` (product sheets from Template Word) |
| Analyst-ready data dump | Excel Generator (summary) + CSV (raw data) packed together |

---

---

## Academy child pages (per-type citations)

| DocConfig type | URL |
|---|---|
| MAIN WORD / PDF | [main-word-pdf/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/main-word-pdf/) |
| TEMPLATE WORD | [template-word/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/template-word/) |
| EXCEL Generator | [excel-generator/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/excel-generator/) |
| STATIC PDF | [static-pdf/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/static-pdf/) |
| TABLE COLUMN REMOVER | [table-column-remover/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/table-column-remover/) |
| EMAIL | [email/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/email/) |
| PDF FORM FILLER | [pdf-form-filler/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/pdf-form-filler/) (video-only) |
| CSV – Character-separated value | [csv-character-separated-value/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/csv-character-separated-value/) |
| PPTX – Powerpoint | [pptx-powerpoint/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/pptx-powerpoint/) |

---

## Failure modes

| Symptom | Root cause | Fix |
|---|---|---|
| Region rendered row has unexpected empty cells | Static content placed on the same row as the Region was hidden with the Region | Move static content above/below the Region row |
| Excel `IF` formula throws | Used commas instead of semicolons | Use `;` separators: `=IF(...;"YES";"NO")` |
| DocConfig title shows as the filename instead of the Word title | `Set title of document` not configured | Enable it and map a SINGLE DataSource field |
| PDF/A not exporting | `Export PDF as PDF/a` toggle off | Enable on Main Word DocConfig |
| `Enable Forms` toggle absent | Licensed feature | Contact `support@pdfbutler.com` |
| Static PDF image replacement yields original image | Image placeholder not marked as replaceable | Use a named picture placeholder in the Static PDF + matching PICTURE DataSource |

---

_Sources: 9 child pages under [pdf-butler-by-doc-config/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/) — per-type URLs in the table above._