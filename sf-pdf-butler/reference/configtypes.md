# ConfigTypes — PDF Butler

Catalog of every ConfigType. Claude reads this when building/editing DocConfig elements — "user wants a repeating table" → look up the right type.

## Quick chooser

| User intent | ConfigType |
|---|---|
| Single field → single merge field | `SINGLE` |
| Filename / document title | `TITLE` |
| Multi-line text from a textarea field | `TEXTAREA` |
| HTML-formatted text from Rich Text Area | `RICH_TEXT` |
| Images embedded in a Rich Text field | `RICH_TEXT` + `PDFButler_Actionable_RichTextPics` |
| Calculation without a formula field | `SINGLE_FOR_FORMULA` |
| Product table / line items | `TABLE` + `TABLE_ROW` + child `SINGLE`s |
| Table rows only show when data exists | `TABLE_ROW_NON_EMPTY_LIST` |
| Entire table hidden when data empty | `TABLE_BLOCK_NON_EMPTY_LIST` |
| Repeating paragraph block (no table) | `PARAGRAPH` |
| Show/hide based on field value | `CRITERIA` on the target ConfigType |
| Show/hide entire MS Word section | `CONDITIONAL_SECTIONS` |
| Embed image from file/URL/blob | `PICTURE` |
| Logo via public URL (email templates) | `PICTURE_TO_URL` |
| Many images bypassing SFDC limits | Late Binding DS + `PICTURE` |
| QR code or Code 128 barcode | `PICTURE` with barcode configuration |
| Checkbox ticked by boolean field | `FORM_CHECKBOX` |
| Hyperlink with dynamic URL + label | `LINK` |
| Colour a table cell based on data | `COLOR_CELL` |
| Colour a table row based on data | `COLOR_ROW` |
| Append additional DocConfigs dynamically | `ADDITIONAL_DOCS` or `DOCUMENT_V3` |
| Repeat columns across a table | `SIMPLE_COLUMN_REPEATER` |
| Repeat both columns AND rows | Complex Column Repeater |
| Inline list like "A, B, C" in a paragraph | `INLINE_REPEATER` |
| Complex MS Word content control nesting | `CONTENT_CONTROLLER` + `ROWS_CONTROLLER` |
| Show/hide a watermark | `TEXT_WATERMARK` |
| Signature placeholder for SIGN Butler V2 | `SIGN_PLACEHOLDER` / `INITIAL_PLACEHOLDER` |

---

## Catalog

### `SINGLE`

**Purpose**: 1-on-1 field → merge field replacement. Academy: "Use the SINGLE to do 1-on-1 replacements from SFDC Data into the document."
**Field type options**: `TEXT`, `PERCENT`, `PHONE`, `CURRENCY`, `NUMBER`, `DATE`, `DATETIME`, `TIME`.

**TEXT formatting**:
- `Translate` — picklist → Translation DataSource (refer Picklist Translation DataSource)
- `Strip tags` — "Check this checkbox if the input contains HTML tags or enters and you do not want these to show"
- `Text Formatting` — "Different types of formatting were provided to choose here. More Information at: SINGLE ConfigType Text Formatting" (that sub-page is video-only)

**PERCENT and NUMBER formatting** (same option set):

| Option | Behaviour |
|---|---|
| `Custom format` | "Format by international formatting rules." Examples from Academy: `###,##0.00` → "1000-separator, always 1 number in front of the decimal sign and 2 numbers after"; `###,##0` → "1000-separator and always 1 number in front of the decimal sign but no decimals". |
| `Spelled Out (in letters)` | "This option will show Numbers in letters" — Example: `510` → `five hundred ten` |
| `Spelled Out (in letters) and Capitalize` | "This option will Capitalize all the words" — Example: `510` → `Five Hundred Ten` |
| `Spelled Out (in letters) and Capitalize first word only` | "This option will Capitalize the first word only" — Example: `510` → `Five hundred ten` |
| `Roman numeral` | "can be placed in both uppercase and lowercase." Constraints (verbatim): "negative numbers will be converted into positive numbers"; "decimal numbers will cut off at the decimal sign. So we only allow integer numbers"; "the number must be smaller the 4000. So the biggest possible number is 3999". |

**DATE / DATETIME / TIME formatting**:

| Field type | Example custom format |
|---|---|
| `DATE` | `dd-MMM-yy` |
| `DATETIME` | `dd/MM/yy HH:mm:ss` |
| `TIME` | `HH:mm:ss` |

"Construct your own format (always dependent on locale (country and language))."

**PHONE** and **CURRENCY**: "You can choose no formatting or format depending on the locale supplied when generating." PHONE's `INTERNATIONAL` / `NATIONAL` enum labels are documented on the separate "Phone number formatting" Academy page (see `reference/i18n.md`), not on the SINGLE page itself.

**Gotchas**: if a TEXT field contains HTML, enable Strip tags or raw markup appears in output.

_Sources: [SINGLE](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/single/), [SINGLE ConfigType Text Formatting](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/single-configtype-text-formatting/) (video-only)._

### `TITLE`

**Purpose**: compose the generated file's filename.
**Merge syntax in DocConfig's Document Title field**: `[[!FIELDNAME!]]`, e.g. `[[!ACC_NAME!]] - [[!DocGeneratedTime!]]`.
**Setup**: one TITLE ConfigType per placeholder; each maps to a DataSource + field.
**Special**: `$Now` DataSource gives document-generation timestamp.
**Formatting**: Translate / Strip tags / text formatting (see SINGLE).

### `PARAGRAPH`

**Purpose**: repeating paragraph blocks (no table). "Every Enter in MS Word is a paragraph" — including bulleted/numbered lists.
**Setup**: LIST DataSource → PARAGRAPH parent on the START merge field → child `SINGLE`s for fields within the paragraph.
**Use when**: repeating text blocks without tabular alignment (product descriptions, clauses).

### `TEXTAREA`

**Purpose**: render a Salesforce textarea field preserving line breaks.
**Key setting**: **"Use new paragraph for every carriage return"**
- Enabled → each `\n` becomes a new paragraph (bulleted/numbered lists render properly)
- Disabled → `\n` becomes an in-paragraph line break (single paragraph)
**Gotcha**: apply bold/italic to the merge field in Word — style extends to rendered textarea content.

### `RICH_TEXT`

**Purpose**: render Salesforce Rich Text Area (HTML) into the document.
**Filter modes**:
1. No filtering — output HTML as stored
2. Fixed styles — overlay (e.g. `font-family:Arial`) on existing styles
3. Ignore all styles — plain-text-ish output
4. Selective filtering — drop specific CSS properties (e.g. `color`) while keeping the rest
**Prerequisite**: fetch the rich text via a SOQL DataSource first.

### Rich Text Pictures (images in Rich Text fields)

**Class (standard)**: `PDFButler_Actionable_RichTextPics` — needs SOQL DS + PICTURE LIST child DS + `RICH_TEXT V3` config.
**Class (URL/bulk)**: `PDFB_Act_RichTextPicsByUrl` — runs as `BEFORE_BUT_AFTER_DATASOURCES` Actionable, works around SFDC limits for many/large images.
**Header/footer placement**: images in rich text that should appear in header/footer require a separate PICTURE ConfigType + placeholder.
**Position constraint**: images must sit at the top or bottom of the rich text field to align with placeholder positioning.
**Note**: PDF Butler describe this as "not our favourite" but "the most rock-solid" support for Rich Text pictures on Salesforce.

### `TABLE`

**Purpose**: repeat an entire table block per record in a List DataSource.
**Setup**:
- LIST DataSource returning SObjects
- Start merge field marks table start
- Child `SINGLE`s for each column
- **Remove Mergefield Action** typically "merge field only"
**Spacing**: between-table spacing is configurable on the ConfigType.

### `TABLE_ROW`

**Purpose**: repeat a single row within a table (most common table-level pattern).
**Setup**:
- Start merge field in the first cell of the row
- Child `SINGLE`s for each column merge field
**Gotchas**: Start field must be in the correct first-column cell; DataSource must include every field.

### `TABLE_BLOCK_NON_EMPTY_LIST`

**Purpose**: hide the ENTIRE table (structure + headers) when the DataSource list is empty.
**Use when**: "Products Ordered" table on a quote that may have no products yet.

### `TABLE_ROW_NON_EMPTY_LIST`

**Purpose**: hide a SINGLE row when its associated list is empty.
**Use when**: multi-section document where empty sections would leave vertical gaps — structure content inside table rows so empty rows collapse.
**Gotcha**: spacing must sit INSIDE the rows, not between them.

### `CRITERIA`

**Purpose**: conditional logic on other ConfigTypes (`TABLE_ROW`, `PARAGRAPH`, `TABLE`, `CONDITIONAL_SECTIONS`).
**Operators**: `=` and `<>` are the only operators the [CRITERIA Academy page](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/criteria/) shows explicitly. Numeric comparators (`>`, `<`, `>=`, `<=`) are not documented there — verify in-org against the `cadmus_core__Criteria_Operator__c` picklist before relying on them.
**Composition**: AND/OR supported.
**Examples**:
- `Product2.Family='Hardware'` — only hardware rows
- `Product2.Family<>'Hardware'` — non-hardware only
- Multi-condition combos gate entire table visibility
**Field access**: dot notation for related objects (`Product2.Family`).

### Single criteria rules

Applied on `SINGLE` ConfigTypes to choose between multiple fields/static fallbacks:
- **Fallback chain**: evaluate fields in order, show first non-empty
- **Spacing toggles**: "Add space before/after when value present"
- **Comparisons**: numeric operators (`>1`, etc.) are not listed on the Academy — verify in-org before using

### `CONDITIONAL_SECTIONS`

**Purpose**: show/hide entire MS Word sections (sections control landscape/portrait, different headers/footers, etc.).
**Setup**:
1. SOQL DS with needed fields
2. Upload Word template with sections
3. Create `CONDITIONAL_SECTIONS` ConfigType tied to a criterion (e.g. `Type='New Customer'`)
4. Remove Mergefield Action: "Containing Paragraph"

### `PICTURE`

**Image sources**: Salesforce records, PICTURE LIST DataSource, Blob/Attachment, URL.
**Required**: placeholder in Word template, matching ConfigType, backing DataSource.
**Sizing modes** (Academy verbatim — "There are 4 ways to scale an image"):

| Mode | Behaviour (verbatim) |
|---|---|
| `NONE` | "The system will stretch or squeeze the image to make it fit the placeholder while keeping the placeholder's exact height and width." |
| `BY WIDTH` | "The system will keep the width of the placeholder to fit the image and automatically recalculate the height." |
| `BY HEIGHT` | "The system will keep the height of the placeholder to fit the image and automatically recalculate the width." |
| `CONTAIN` | "The system will always contain the image within the placeholder, as in the 'NONE' option, but it will adjust either the height or the width to ensure the image scales correctly." |

No `COVER` or `FIT` mode is listed on the Academy page.

_Source: [PICTURE](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/picture/)._

### `PICTURE_TO_URL`

**Purpose**: embed images by URL reference (instead of binary) — for EMAIL DocConfigs.
**Why**: email clients render external URLs reliably; embedded images often break.
**Setup**:
- Upload image to Salesforce Files → public link
- Static Values DataSource row contains the URL
- Merge field in email template matches picture placeholder name
- DocConfig type must be `EMAIL`

### Barcode / QR Code

**Implementation**: a `PICTURE` ConfigType configured with a barcode generator.
**Supported symbologies**: "many types" — most used are `CODE 128` and `QR`.
**Setup**: SOQL DS fetching the text to encode → PICTURE ConfigType → named picture placeholder in Word.
**Example**: Account Id → Code 128 barcode on rendered PDF.

### MergeField Replace Action (on every ConfigType)

| Value | Behaviour |
|---|---|
| `None` | Leaves merge field AND its containing paragraph in place |
| `Containing Paragraph` | Removes merge field + the paragraph holding it (use for section markers, conditional blocks) |
| `Merge field only` | Removes the merge field string but keeps the surrounding paragraph (use for inline substitutions) |

### `DOCUMENT_V3`

**Purpose**: dynamically include TEMPLATE DocConfigs based on a DataSource. Academy verbatim: "REMARK: make sure to use DOCUMENT_V3 instead of DOCUMENT_V2".

**How it works** (verbatim): "The DOCUMENT_V3 ConfigType will loop over all records in the DataSource and retrieve each TEMPLATE to import it into the resulting document."

**Required**: a DataSource field containing the **Customer DocConfig Id** (not the Salesforce Id). Recommended pattern: "create a Lookup to a DocConfig in Salesforce and via the Lookup use the field `cadmus_core__CustomerDocumentConfigId__c` as this field has the Customer DocConfig Id that is required in this ConfigType."

**Header/footer**: "By default, the header and footer of the MAIN DocConfig are used for the inserted TEMPLATES."

**Separator options** (verbatim):

| Option | Behaviour |
|---|---|
| `Double spacing` | "this looks like 2 enters are added between the TEMPLATES" |
| `Single spacing` | "this looks like 1 enter is added between the TEMPLATES" |
| `Page break` | "each TEMPLATE is added to a new page" |
| `None` | "directly add the TEMPLATES after each other" |
| `Section break` | "This is a special case!" — uses the header/footer from each TEMPLATE (a Section Break is added between TEMPLATES, and also after the last one unless no TEMPLATES loaded). |

**Empty-DataSource edge case** (verbatim): "After the last TEMPLATE, there will be no separator added. Also where there are no TEMPLATES to load (empty DataSource or all TEMPLATES are filtered out by the Criteria Logic), no separator is added (There is an exception for 'Section break')".

**Section break gotcha** (verbatim): "As there is an Section Break added for each TEMPLATE, even the last one, make sure the mergefield for this ConfigType is not in a separate Section! If this is in a separate section, there will be an empty section in the generated document and this can be an empty page."

_Source: [DOCUMENT_V3](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/document_v2/) (URL slug is `document_v2` but page title reads DOCUMENT_V3)._

### `DOCUMENT_V2`

Deprecated — use `DOCUMENT_V3`.

### `SINGLE_FOR_FORMULA`

_Video-only Academy page. Full Academy prose: "Need calculations, summations, averages, … and you do not want to add Formula fields in Salesforce. Use the SINGLE_FOR_FORMULA". See [SINGLE_FOR_FORMULA](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/single_for_formula/)._

**Purpose**: perform calculations (sum, avg, etc.) without adding a Salesforce formula field — exact formula syntax is shown via video only. Consult support or inspect existing configs in-org for the concrete expression grammar.

### `CONTENT_CONTROLLER`

**Purpose**: replicate a block of information. Alternative to `TABLE` for repeated content outside table structures.
**Prerequisite**: enable the Developer menu in MS Word to insert content controls.
**Pairs with**: `ROWS_CONTROLLER`.

### `ROWS_CONTROLLER`

**Purpose**: replicate multiple rows inside a table, driven by a LIST DataSource.
**Pairs with**: `CONTENT_CONTROLLER` (combined for nested layouts).

### Combining `CONTENT_CONTROLLER` + `ROWS_CONTROLLER`

Nesting pattern: a `CONTENT_CONTROLLER` can parent another `CONTENT_CONTROLLER` OR a `ROWS_CONTROLLER`. Used for sophisticated layouts combining content-level control with row-level iteration. Requires Parent-Child (Nested) DataSources.

### `SIMPLE_COLUMN_REPEATER`

**Purpose**: repeat columns across a table (horizontal iteration), driven by a List DataSource.
**Counterpart**: Complex Column Repeater for row+column matrices.

### Complex Column Repeater (repeat columns AND rows)

**Components needed**:
- SOQL DataSource for column values (e.g. Lead Source picklist values)
- KEYVALUE DataSource for row values (populated by Apex)
- Complex Column Repeater ConfigType mapped to column merge fields
- `TABLE_ROW` ConfigType for rows
- `SINGLE_FOR_TABLE_COLUMN_REPEATER` ConfigType for the cell values
**Apex requirement**: `AbstractBeforeWithDataSourcesActionable` that generates dynamically-suffixed field names (`Item`, `Item_1`, `Item_2`, ...) matching column count.
**Canonical example**: leads × lead sources matrix with `Yes` markers where they intersect.

### `INLINE_REPEATER`

**Purpose**: in-line repetition within a paragraph.
**Two flavours**:
- INLINE_REPEATER for PICTURE — repeats pictures on the same line
- INLINE_REPEATER for SINGLE — repeats text on the same line with a separator (e.g. `, `)

### `FORM_CHECKBOX`

**Purpose**: check/uncheck MS Word form checkboxes based on a boolean field.
**Related recipe**: see `reference/tips.md` → "Checkboxes" (covers the raw Word setup for checked/unchecked symbols).

### `ADDITIONAL_DOCS`

**Purpose**: dynamically glue PDFs generated from other DocConfigs onto the main document.
**Flexibility**: referenced DocConfigs need NOT be TEMPLATE type.
**Rule**: any DataSources used by the attached DocConfigs must ALSO be declared on the main DocConfig.
**Use for**: T&Cs, product spec sheets, appendices.

### `TEXT_WATERMARK`

**Purpose**: dynamically set / hide / vary watermark text.
**Features**: conditional visibility via criteria, multi-section support (different watermark per MS Word section).
**Related**: see `reference/tips.md` → "Watermarks" for the Word-side template setup.

### `LINK`

**Purpose**: create hyperlinks dynamically.
**Three flavours**:
- `LINK` — external URL
- `BOOKMARK` — internal document reference
- `PICTURE` — image that is itself a hyperlink

### `SIGN_PLACEHOLDER` / `INITIAL_PLACEHOLDER`

**Purpose**: auto-placed signature / initial boxes for the SIGN Butler V2 integration. Configured on the PDF Butler (`cadmus_core`) side; consumed by SIGN Butler V2 (`cadmus_sign2`) at signing time.

| Behaviour (Academy verbatim) | Detail |
|---|---|
| Auto-counter | Placeholders auto-increment across multiple signers (1, 2, 3, …) when looped over a LIST DataSource of stakeholders |
| Numbering reset | "If you want to re-start the numbering from 1, use `-1` here" |
| Size options | "100%, 75%, 50% or 25%" |
| DataSource shape | LIST DataSource required for loop processing |
| Sibling | `INITIAL_PLACEHOLDER` — same mechanics, for initials rather than full signatures |

Exact backing field API names on `cadmus_core__ConfigType__c` are not published on the Academy — verify in-org if generating metadata programmatically. Full SIGN Butler V2 wiring (Pack + Actionable + Template) lives in the sibling [sf-sign-butler](../../sf-sign-butler/SKILL.md) skill.

_Source: [SIGN_PLACEHOLDER ConfigType with PDF Butler](https://www.pdfbutler.com/academy/sign-butler-academy/sign-butler-v2/sign-butler-v2-sign_placeholder-configtype-with-pdf-butler/)._

### `COLOR_CELL` / `COLOR_ROW`

**Purpose**: conditional background colour on table cells (`COLOR_CELL`) or full rows (`COLOR_ROW`).
**Colour values**: RGB hex, supplied directly or via picker.
**Criteria**: standard PDF Butler criteria framework.
**Merge field placement**:
- `COLOR_CELL` — merge field in the target cell
- `COLOR_ROW` — merge field in ANY cell of the row
**Precedence rule**: when multiple criteria overlap, the ConfigType created LAST wins. Order your ConfigTypes deliberately.
**Example colour-ladder**: amount < 10k red, 10k–100k orange, > 100k green.

---

## Notes on merge syntax

- Configs match **Word merge fields** by name. Merge field must exist in the DOCX template; ConfigType references it.
- Child ConfigTypes (`SINGLE` under `TABLE_ROW`, etc.) use the **child merge field names**, not dot paths.
- Filename templating uses `[[!NAME!]]` syntax only inside the DocConfig's Document Title field.
- Criteria reference **field API names** on DataSource records, with `.` for related objects.

---

_Sources: all 31 child pages under [pdf-butler-by-configtype/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-configtype/)._