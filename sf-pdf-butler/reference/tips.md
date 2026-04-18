# Tips & Tricks — PDF Butler

Cookbook of template-authoring recipes. Claude reads this when a user asks "how do I do X" and X is a template detail rather than an API call.

## Recipe index

| Problem | Recipe |
|---|---|
| Checkbox that ticks based on a boolean | [Checkboxes](#checkboxes) |
| Show/hide a watermark | [Conditional watermarks](#conditional-watermarks) |
| Same page repeated per record | [Page repeat](#page-repeat) |
| Pick template at runtime | [Dynamically load templates](#dynamically-load-templates) |
| Sequential 1, 1.1, 1.2 numbering | [Auto numbering](#auto-numbering) |
| Blank lines when a field is empty | [Remove white spaces](#remove-white-spaces) |
| Generator on the Home page | [Home Page Component](#home-page-component) |
| PDF/A archival output | [PDF/A output](#pdfa-output) |
| Include approval history in a doc | [Approval History](#approval-history) |
| Multiselect picklist → list of items | [Multiselect picklists](#multiselect-picklists) |
| Dynamic cell/row colour | [Conditional formatting](#conditional-formatting) |
| Swap the template at runtime | [DocConfig document override](#docconfig-document-override) |
| Different headers/footers per section | [MS Word sections](#ms-word-sections) |
| Usage / billing data | [Usage statistics](#usage-statistics) |
| Run generation async (non-blocking) | [Async delivery](#async-delivery) |
| Debug datasource data mid-render | [Butler Inspector (Chrome plugin)](#butler-inspector) |
| Style hyperlinks (colour, underline) | [Custom hyperlink styles](#custom-hyperlink-styles) |
| Preserve Word Track Changes | [Enable track changes on DOCX output](#track-changes-on-docx) |
| Remove form fields from final PDF | [Flatten PDF / remove form fields](#flatten-pdf) |
| Password-protect generated PDF per record | [Dynamic PDF passwords](#dynamic-pdf-passwords) |
| Embed custom font in Word template | [Embedded fonts](#embedded-fonts) |

---

## Recipes

### Checkboxes

**Approach**: inline conditional images (not font characters). Upload a "checked" and an "unchecked" image to Salesforce Files. Use a PICTURE ConfigType that switches image source based on a boolean/criteria field. Related ConfigType: `FORM_CHECKBOX` (Word-side checkboxes driven by boolean).

### Conditional watermarks

**Principle**: one template, not duplicated per variant. Add the watermark in MS Word. Use `TEXT_WATERMARK` ConfigType + `CRITERIA` to toggle visibility. Multi-section docs: support one watermark per Word section.

### Page repeat

**Use case**: per-record certificates, labels, attendance slips — one page per record in a list.
**Approach**: a Word template with a page break, repeated via a LIST DataSource + a repeating ConfigType. Academy provides a demo DOCX.

### Dynamically load templates

**Approach**:
- **Declarative**: use DocConfig Alternatives selected at runtime via `cdm.alternativeName`
- **Data-driven**: use `DOCUMENT_V3` ConfigType with a DataSource that returns a Customer DocConfig Id for each record
- **Programmatic**: use an `AbstractBeforeActionable` to choose template via Apex and call `DocumentDataHandler.addDocConfigOverride()`
**Canonical example**: GenWatt Diesel 10kW vs GenWatt Propane 100kW spec sheets chosen by product type.

### Auto numbering

**Two approaches**:
- **MS Word native lists** — use Word's numbered list styling; PDF Butler preserves it in repeated blocks
- **`@Number` function** — PDF Butler's own counter, handles nested sub-levels (`1`, `1.1`, `1.2`) across complex layouts
**When to choose `@Number`**: nested repeaters or when Word's own numbering resets incorrectly.

### Remove white spaces

**Root cause**: empty fields / empty list DataSources leave blank paragraphs.
**Primary fix**: wrap content in a `PARAGRAPH` ConfigType linked to a SINGLE DataSource with a `CRITERIA` ("show if field not blank"). Nest child `SINGLE`/`TEXTAREA`/`RICH_TEXT` inside.
**Alternative**: `CRITERIA` on `TABLE_ROW`, `TABLE`, or `PARAGRAPH` — don't render the container at all.
**Related**: `TABLE_ROW_NON_EMPTY_LIST`, `TABLE_BLOCK_NON_EMPTY_LIST`.

### Home Page Component

_Video-only Academy page; details above are the high-level pattern; see [Home Page Component](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/home-page-component/)._

**Purpose**: trigger generation from the Salesforce Home page (not tied to a specific record).
**Use for**: sales home page "Generate Opportunity Overview" buttons, weekly summary reports.
**Placement**: Home Lightning App Page in App Builder.

### PDF/A output

**Standard compliance** (Academy verbatim): "we targeted for the full conformance level of PDF/A-1a! So this means that we are completely compliant with PDF/A-1a and PDF/A-1b (as this is a subset of PDF/A-1a)."
**Use for**: archival requirements (ISO 19005-1), long-term retention mandates.
**How to enable**: on a **Main Word Document** DocConfig, tick the `Export PDF as PDF/a` setting (verbatim label from the Main Word PDF Academy page; lowercase `a`). For other DocConfig types, contact support.

_Sources: [PDF/A](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/pdf-a/) (conceptual), [Main Word PDF](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-doc-config/main-word-pdf/) (toggle label)._

### Approval History

**Class**: `PDFButler_Act_GetApprovalHistory`
**Mechanism**: collects Salesforce Approval History into a KEYVALUE DataSource.
**Fields exposed**:
- `ProcessInstanceId`, `ProcessNodeId`
- `ProcessNodeName` (empty for initial submission)
- `CreatedDate`
- `StepStatus`
- `OriginalActorId`, `OriginalActorName`
- `ActorId`, `ActorName`
- `Comments`

Bind to a `TABLE_ROW` or `PARAGRAPH` in the template.

### Multiselect picklists

**Problem**: multiselect picklist values stored as `;`-separated text in one field — hard to iterate.
**Class**: `PDFButler_Actionable_MultiSelect`
**Approach**: runs as a BEFORE Actionable, splits values into a KEYVALUE DataSource with `parentId` + `value` fields. Bind to a repeating ConfigType.

### Conditional formatting

**Mechanism**: `COLOR_CELL` / `COLOR_ROW` ConfigTypes (covered in `reference/configtypes.md`) with `CRITERIA`-based RGB hex colouring.
**Canonical pattern**: colour ladder (red < threshold < orange < threshold < green).
**Precedence**: when two criteria overlap, the ConfigType **created last** wins.

### DocConfig document override

**Class**: `PDFB_Actionable_DocConfigOverride`
**Approach**: runs as BEFORE Actionable, calls `DocumentDataHandler.addDocConfigOverride(contentVersion, customerDocumentConfigId)` to substitute the template at runtime.
**Use for**: per-customer branding where each customer has a DOCX stored in their Salesforce account record.

### MS Word sections

**Critical rule**: **"Unlink every Section from the previous Section. No 'Link to Previous'!"**
- Different headers/footers per section only work if unlinked
- Landscape + portrait mixing requires sections
**Pair with**: `CONDITIONAL_SECTIONS` ConfigType to show/hide entire sections at render time.

### Usage statistics

**Access**: CSV extract on request (no live dashboard).
**Covers** (Academy verbatim): "PDF Butler, SIGN Butler, FORM Butler, BULK Butler, MASS Volume Butler, PEPPOL, …"
**Workflow**: email `support@pdfbutler.com` for an extract.

**Fields** — the Academy lists exactly these 12:

| Field | Description |
|---|---|
| `CreatedAt` | Date and time the request was done |
| `DocumentConfigName` | Empty unless PDF Butler action — then the DocConfig name |
| `CustomerDocumentConfigId` | Empty unless PDF Butler action — then the Customer DocConfig Id |
| `Month` | Month of the extract |
| `Stage` | Stage the request ran against (`TEST`, `PROD`, etc.) |
| `SalesforceUserId` | Id of the Salesforce user that started the request |
| `ActionName` | The action requested (popular values below) |
| `UsageType` | How the request was initiated |
| `DocSize` | Size of the document in bytes |
| `GenerationTime` | Time of the request in milliseconds |
| `ExportFormat` | e.g. `PDF`, `DOCX` |
| `RequestPayloadSize` | Size of the request data |

**`ActionName` popular values** (Academy: "Here a few popular ones" — list is **not exhaustive**):

| Value | Meaning |
|---|---|
| `MAIN_DOC_CONFIG` | Change made to a DocConfig |
| `CONVERT_DOC_CONFIG` | Document generated |
| `FP_SUBMIT` | FORM Butler form submit |
| `EMAIL_SIGN` | SIGN Butler sign request opened from an email |
| `SIGN_EMAIL_SIGN` | SIGN Butler stakeholder signed while opening from an email |
| `DONE_FINISHED` | SIGN Butler — all stakeholders signed |
| `PEPPOL_V1_INVOICE_INIT` | PEPPOL invoice sent |

**`UsageType` values** (Academy lists only these two):

- `NORMAL_PDFB` — user clicked a button to generate a document
- `NORMAL_ASYNC` — async request, e.g. via Flow

_Source: [PDF Butler Usage Statistics](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/pdf-butler-usage-statistics/)._

### Async delivery

**Three async save modes** (set on `ConvertDataModel.deliveryOverwrite`) — enum values verbatim from Academy:

- `FILES_ASYNC`
- `FILES_OVERWRITE_ASYNC`
- `FILES_ADD_VERSION_ASYNC`

**Async After Actionable**: `AFTER_ASYNC` phase — runs AFTER Actionables async, post-generation without blocking.

**Use for**: batch generations, trigger contexts, anywhere you can't tolerate callout latency in the user's transaction.

_Source: [PDF Butler Async Delivery Option and After Actionables](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/pdf-butler-async-delivery-option-and-after-actionables/) — the enum values are literally named, but configuration walkthrough is video-only._

### Butler Inspector

**What it is**: a **Chrome plugin** that exposes PDF Butler's internal DataSource state during render.
**Install**: Chrome Web Store → search "Butler Inspector".
**Use for**: "my table is empty but the SOQL looks right" — inspector shows what data actually reached the renderer.

### Custom hyperlink styles

**Where**: MS Word's Styles panel → edit the **Hyperlink style** directly in the template.
**Why**: PDF Butler inherits Word styles — no CSS or separate config needed.
**What you can change**: colour, font, underline, size — anything Word supports.

### Track changes on DOCX

**Purpose**: any subsequent MS Word edit is captured as a tracked change automatically.
**Enable**: per-DocConfig setting; Academy has a video walk-through.
**Use for**: contract review workflows where legal needs to see what changed.

### Flatten PDF

**Class**: `DO_NOT_DEPLOY_FlattenPdf` (implements `AbstractBeforeActionable`)
**Purpose**: strip form fields from the final PDF so recipients can't edit the flattened output.
**Flatten types** (set via `cadmus_core.MetadataWrapper.flattenTypeStatic`):
- `NONE` — leave untouched
- `REMOVE_CONFIG_ONLY` — remove embedded config JSON but keep form fields
- `FULL_FLATTEN` — remove config AND form fields

```apex
global class DO_NOT_DEPLOY_FlattenPdf implements cadmus_core.AbstractBeforeActionable {
    global void execute(cadmus_core__Actionable__c actionable, Id docConfig,
            Id objectId, Map<String, Object> inputMap,
            cadmus_core.ConvertController.ConvertDataModel cdm) {
        cadmus_core.MetadataWrapper.flattenTypeStatic =
            cadmus_core.MetadataWrapper.FLATTEN_TYPE.FULL_FLATTEN;
    }
}
```

### Dynamic PDF passwords

**Approach**:
1. Create a **formula field** on the triggering object returning the desired password string. Academy's verbatim example format: `ContactFirstNameLastName(lowercase)DOB(ddmmyy)`.
2. Create a DataSource fetching that formula field.
3. On the DocConfig, enable password protection in the metadata section and map it to the DataSource field (the exact setting label is shown via screenshot only on the Academy page).
4. Generated PDF prompts for password on open.

**Benefit**: password is per-record, derived from data (no manual entry).

_Source: [Dynamic PDF Passwords](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/dynamic-pdf-passwords/)._

### Embedded fonts

**Prerequisite**: "Please contact your PDF Butler Account Manager for this feature to be enabled." (Academy verbatim)
**Format requirement**: "**PDF Butler only supports .ttf fonts!**" (Academy verbatim)

**NOT supported** (Academy verbatim sentences):

1. **"Fonts of type OTF are NOT supported."** — check with your font supplier on how to convert OTF to TTF.
2. **"Fonts with variations are not supported."** — variable fonts combining regular, bold, italic, … into one file.
3. **"Fonts with only 'TrueType Outlines' are not supported"** — on Windows, open the font: the setting must show full TTF not outline-only.

**Trade-off**: embedded fonts inflate DOCX size — watch Salesforce storage limits. Academy: "The DOCX template will be very big with embedded fonts."

_Source: [Use Word Template with Embedded Fonts](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/generate-word-template-with-embedded-fonts/)._

---

## When to escalate

Several Tips pages list "contact support@pdfbutler.com" — these features are bundled add-ons or non-default config:
- Lightning Quick Action Previewer
- Lightning Convert Component
- DocConfig Selector Logic by Flow
- FSL thumbnail component
- Font embedding enablement
- Usage statistics extract
- Add-on packs for list-view buttons

If your DocConfig needs one of these, raise a ticket — don't attempt to reverse-engineer it.

---

_Sources: 21 child pages under [pdf-butler-tips-tricks/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-tips-tricks/)._
