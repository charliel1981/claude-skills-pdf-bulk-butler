# Packs & Actionables — PDF Butler

Every Actionable type with exact class names, config fields, and gotchas. Claude reads this when building Packs or debugging multi-step generation.

---

## Mental model

A **Pack** (`cadmus_core__Pack__c`) is an ordered container of DocConfigs + Actionables. One `convert()` call against a Pack:

1. Runs all `BEFORE` Actionables
2. Resolves DataSources (with `DATA_SOURCE` Actionables mutating them)
3. Runs `BEFORE_BUT_AFTER_DATASOURCES` Actionables
4. Renders each DocConfig in the Pack (optionally merging per `pdfActionType`)
5. Runs `AFTER` Actionables (email, sign, etc.)
6. Saves/delivers per `deliveryType` (triggering `ON_CONTENT_VERSION` hooks)

Order within each phase is controlled by the Actionable `Order` field. Every Actionable has `Active = true/false`, `Pack` / `DocConfig` lookup, `Class Name` (for Apex), and phase-specific config fields.

---

## Creating a Pack with multiple DocConfigs

- Link DocConfigs via junction records; set `Order` per DocConfig.
- Control output: `cdm.pdfActionType = 'MERGE'` combines into one PDF; `NONE` keeps separate files.
- The add-on class `PB_AddPdfMergeActions` adds page numbers / merged titles (separate package — contact support).
- Override at runtime: `cdm.docConfigIds = new List<Id>{ id1, id2 }` to subset a Pack.

---

## Actionable catalog

### AUTO_EMAIL — fully automated email send

**Class**: `cadmus_core.Actionable_AutoEmail`
**Required fields on Actionable**:
- `Email Template Unique Name` — template's **unique name**, NOT display label
- `Email Target Object Data Source` — DS resolving the recipient record (Contact/Lead/User)
- `Email Target Object Field` — API name of the recipient Id field on that DS
- `Org Wide Email Address Data Source` — DS resolving OWEA
- `Org Wide Email Address Display Name` — API name of the display-name field

**Gotchas**:
- Actionable **must be Active**
- Recipient DataSource SOQL must include `Id`
- Org-wide Email Address record must pre-exist

### EMAIL_DOCCONFIG — HTML email rendered from a DocConfig

**Class family**: `cadmus_core.Actionable_PrepEmailDocConfig` + `Actionable_AutoEmail2`
**Use when**: you want email HTML beyond what standard email templates allow (complex data, charts, tables).
**Required fields**: TO / CC / BCC (each max 255 chars), Subject, Body/DocConfig reference.
**Long recipient lists**: create a `STATIC VALUES` DataSource with `;`-separated addresses, reference that DS field in TO/CC/BCC.

### EMAIL Quick Action — user-editable email send

**Class variants** (pick based on email style):
- Lightning Email Template → `cadmus_core.Actionable_AutoEmailQuickAction`
- Email DocConfig (HTML) → `cadmus_core.Actionable_EmailDocConfigQuickAction`

**Difference from AUTO_EMAIL**: opens the Send Email Quick Action pre-populated — user reviews and clicks Send. AUTO_EMAIL skips the UI.

**Limitations**:
- **Not supported on Experience Cloud** (Salesforce platform limitation on Quick Action APIs for Communities)
- Post-Spring '23: enable **Activity Tabbed View** in org for proper rendering

### SIGN Butler — native e-sign

**Integration**: pairs with the SIGN Butler managed package.
**Use when**: you want everything in one vendor. Cheaper than DocuSign/AdobeSign per envelope at scale.
Full config lives in the SIGN Butler Academy (separate product docs).

### DocuSign — push to DocuSign envelope

**Integration**: requires DocuSign for Salesforce package installed.
**Actionable**: sends the generated doc into a DocuSign envelope/template.
Consult DocuSign's own docs for template ID format and signer mapping; PDF Butler's role ends at posting the doc.

### AdobeSign — push to Adobe Sign agreement

**Class**: `cadmus_core.Actionable_AdobeSign`
**Required config**:
- `Template Id` — Adobe Sign Agreement Template Id
- `Recipient DataSource` — resolves to User / Lead / Contact
- Signer mapping — **single signer only** supported

**Notes**:
- Uses the standard Adobe Sign page: `/apex/echosign_dev1__AgreementTemplateProcess`
- PDF Butler does not support Adobe Sign directly — Adobe-side issues go to Adobe.

### Run APEX Class — custom logic

**Actionable Record Type**: `Run Class`
**When values** (phase):
- `BEFORE` → `AbstractBeforeActionable`
- `DATA_SOURCE` → `AbstractDataSourceActionable`
- `BEFORE_BUT_AFTER_DATASOURCES` → `AbstractBeforeWithDataSourcesActionable`
- `AFTER` → `AbstractAfterActionable`
- `ON_CONTENT_VERSION` → uses `cadmus_core.Actionable_RunOnContentVersionFlow` (for Flow, not Apex)

Class must be global, implement the matching interface. Full interface signatures in `reference/automation.md`.

**Downloadable example**: `APEXActionablesKEYVALUES.pdf` from the Academy covers transforming JSON → DataSources.

### Get Thumbnail — embed file thumbnails into the doc

**Class**: `PDFButler_Actionable_GetThumbnailsV2`
**Sizes**: `THUMB120BY90`, `THUMB240BY180`, `THUMB720BY480`
**Max count**: ~20 images (smaller sizes = more possible per call).
**Setup**:
1. Create a DataSource fetching the files (ContentDocumentLink query)
2. Create a child `PICTURE` DataSource marked `NotApplicable` (so it doesn't re-query)
3. Use a `PICTURE` ConfigType in the template pointing at the child DS

**Win**: works without `API Enabled` user permission → suitable for Community / Experience Cloud.

### Get Thumbnail URL — embed via URL reference

**Class**: `PDFButler_Actionable_GetThumbnailsUrl`
**Output**: populates a `pdfbutler_url` TEXT field on the DataSource with the thumbnail URL.
**Sizes**: same as Get Thumbnail, plus `FULL` for full-resolution.
**Full-res requirement**: include `ContentDocument.LatestPublishedVersionId` in the SOQL.
**Use when**: large files — URL reference is cheaper than base64-embedding.

### Image by URL — embed remote images

Three options depending on source:

| Use case | Class | Required fields |
|---|---|---|
| Salesforce File via URL | `PDFButler_Actionable_GetPicturesUrlfilled` | `Get Url Pics Master DataSource`, `Get Url Field API Name` |
| External URL (base64 fetch) | `PB_Actionable_GetPicsFromUrlV2` | `Get Url Pics Master DataSource`, `Get Url Field API Name`, `Get Url Parent Query Field Name`, `Get Url Pics DataSource` |
| Publicly available + high volume | **no Actionable** — use Late Binding Dynamic Pictures instead | — |

**Limit**: option 2 has ~4 MB total image size cap.

### Quick Chart Setup — embed charts

**Class**: `PDFButler_Act_ChartMultiDataSet`
**Chart engine**: [QuickChart](https://quickchart.io/) (open-source Chart.js server).
**Output fields on target DS**:
- `pdfbutler_charturl` — the generated chart URL
- `pdfbutler_id` — row identifier

**Config**: two DataSources —
1. SOQL (raw data, e.g. Opportunities)
2. KEYVALUE (receives the generated URL)

**Field mapping**: Label field (X-axis), Dataset field (series), Value field (Y-axis numeric). Chart renders into a `PICTURE` ConfigType in the template.

**Example covered in docs**: stacked-bar of Opportunity amount by month.

---

## Flow invocable: Convert a DOCX to PDF

**Label in Flow**: `Convert a DOCX to PDF`
**Apex class**: `cadmus_core.DocxToPdfInvocable` (inferred from global class list)

### Inputs

| Name | Type | Required | Default |
|---|---|---|---|
| `Content Document Id` | ID | Yes | — |
| `Record Id` | ID | Yes | — |
| `Run Async` | Boolean | No | `false` |
| `Save as new Content Document Version` | Boolean | No | `false` |

### Outputs (only when `Run Async = false`)

| Name | Type | Notes |
|---|---|---|
| `Content Document Id` | ID | Only when `Save as new Content Document Version = false` |
| `Content Version Id` | ID | Always present sync |

### Async semantics

- **Set `Run Async = true`** when:
  - Called from a trigger
  - The same transaction has prior DML (callouts-after-DML rule)
- With async, no output vars — downstream Flow must wait for `ON_CONTENT_VERSION` hook or a platform event.

---

## Flow invocable: Convert DocConfig / Pack

Exposed via `cadmus_core.ConvertInvocableWithReturnVariables`. Used when you want to run a full DocConfig or Pack (not just DOCX→PDF) from Flow. Variables broadly mirror `ConvertDataModel` — consult the external PDF `PDF Butler via Invocable v1.pdf` for the full variable list.

---

## Actionable failure modes

| Symptom | Likely cause |
|---|---|
| Actionable silently skipped | `Active` unchecked or wrong `When` value |
| AUTO_EMAIL no recipient | Template Unique Name vs Display Name mismatch, or recipient DS missing `Id` |
| EMAIL Quick Action blank on Community | Unsupported — platform limitation |
| AdobeSign fails with multiple signers | Only 1 signer supported |
| Image by URL hits size cap | Total base64 image payload > 4 MB — use late-binding / URL approach |
| Chart renders blank | Mapping fields missing or DS labels contain `:` / `\|` (reserved) |

---

_Sources: [PDF Butler Packs section](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/) — 13 child pages._