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

### Main Word / PDF — `Main Word Document`

**Primary generator**. Upload a DOCX template; output as PDF or DOCX (`cdm.targetType = 'PDF'` or `'DOCX'`).

**Key settings on the DocConfig record**:
- **Sync Alternative Names** — stores Alternative names in output metadata
- **Calculate Table of Contents** — refreshes a Word TOC against dynamic content
- **PDF Processor version** — opt into the latest PDF engine
- **PDF/A** (archival) + **PDF/UA** (accessibility) compliance toggles
- **Enable Form Fields** — lets FORM Butler / SIGN Butler attach
- **Password** — hardcoded or DataSource-driven (see `reference/tips.md` → Dynamic PDF passwords)
- **Document Title** — static name or mergefield-driven (`[[!NAME!]]` syntax)

**Use when**: 90% of document generation. Default choice unless you know you need a different output format.

### Template Word — `Template Word`

**Purpose**: reusable DOCX fragment — NOT a standalone document.
**Consumed by**:
- `DOCUMENT_V3` ConfigType on a main doc (picks templates by DataSource)
- `ADDITIONAL_DOCS` ConfigType (glues as appendix)
- DocConfig Document Override pattern

**Use for**: Terms & Conditions blocks, product sheets, standard clauses — any snippet re-used across many main docs.

### Excel Generator — `Main Excel Document`

**Template**: a real .xlsx with merge fields in cells.

**Setup gotcha (required)**:
- After placing merge fields in a row, **select the entire merge-field row → Name Box → give it a name** (e.g. `opportunity`). This named region becomes the **Region ConfigType** target for repetition.

**Capabilities**:
- **Region ConfigType** repeats rows driven by a LIST DataSource
- Child `SINGLE` ConfigTypes map cell merge fields
- Percent fields: enable "cell type in Excel is set to Percentage" so Salesforce `75` → Excel `0.75` (Excel multiplies by 100 for display)
- **Inline Excel functions** supported: use `INDIRECT()` for dynamic row references; SUM/AVG rewrite automatically to the rendered range
- **Checkbox ConfigTypes** with conditional logic
- **LINK ConfigType** for hyperlinks
- **Image repetition** for product thumbnails
- **Criteria** on Region controls whether entire regions render

**Hard constraint**: **one merge field per cell**. No cramming two `[[!A!]] [[!B!]]` into the same cell.

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

**Purpose**: accept an existing PDF with form fields (`AcroForm`) and fill those fields from Salesforce data.
**Common sources**: government forms, insurance intake, partner onboarding PDFs — anywhere you can't redesign the template.
**Field mapping**: PDF form field name → DataSource field via SINGLE ConfigTypes.
**Flatten option**: optional — renders form fields as static text so recipients can't edit. Also achievable via the `DO_NOT_DEPLOY_FlattenPdf` Actionable (see `reference/tips.md` → Flatten PDF).

### CSV — `CSV (Character-Separated Value)`

**Setup gotchas**:
- **Document Title is required** — blank title causes errors
- Title must include extension: `.csv` or `.txt`
**Capability**: standard delimiter-separated output. Delimiter customisation isn't explicitly documented — default is comma; escalate to support for non-comma setups.

### PowerPoint — `Main Powerpoint Document`

**Template**: .pptx with merge fields on slides.
**Two repeaters** for multi-slide output:

| Repeater | Behaviour |
|---|---|
| `SLIDE_REPEATER` | Duplicates a single slide per record (e.g. one product per slide) |
| `SECTION_REPEATER` | Repeats entire sections (e.g. accounts → their opportunities → their products across a section of slides) |

**Supported ConfigTypes inside slides**: `SINGLE`, `LINK`, and `PICTURE` for hyperlinks and product images. Repeater fields control duplication; child `SINGLE`s fill merge fields.

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

_Sources: 9 child pages under [pdf-butler-by-doc-config/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/)._