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
- Page numbers, title headers, and watermarks on the merged output: set `cdm.mergeActions` to a `cadmus_core.PdfActions` instance. Fully in-package — see `reference/automation.md` → "PdfActions". Replaces the older `PB_AddPdfMergeActions` add-on class pattern.
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

**Integration**: pairs with the SIGN Butler V2 managed package (namespace `cadmus_sign2`).
**Actionable class**: `cadmus_sign2.Actionable_SignButlerSilent` (emails the signer) or `cadmus_sign2.Actionable_SignButlerSignNow` (redirects in-page, no email).
**Record Type on Actionable**: `Sign Butler`. **When**: always `AFTER`.
**Requires** on the Actionable: `Sign Request Template` lookup (the template defines stakeholders + emails + expiry + branding).
**Placeholder ConfigType** on the PDF Butler side: `SIGN_PLACEHOLDER` / `INITIAL_PLACEHOLDER` (auto-counter, `-1` reset, 100/75/50/25% sizing). See `reference/configtypes.md`.
**Use when**: you want everything in one vendor. Cheaper than DocuSign/AdobeSign per envelope at scale.

Full SIGN Butler V2 coverage — template fields, Certificate of Completion, custom branding, reminder / warning / expiry batch jobs, `[[!SignButler.*!]]` email merge tokens, `SignButlerEmails` folder — lives in the sibling [sf-sign-butler](../../sf-sign-butler/SKILL.md) skill.

### DocuSign — push to DocuSign envelope

**Integration**: requires DocuSign for Salesforce package installed.
**Actionable**: sends the generated doc into a DocuSign envelope/template.
Consult DocuSign's own docs for template ID format and signer mapping; PDF Butler's role ends at posting the doc.

### AdobeSign — push to Adobe Sign agreement

**Class**: `cadmus_core.Actionable_AdobeSign`
**Required config** (verbatim parameter names):
- `Template Id` — "The AdobeSign Agreement Template identifier"
- `Recipient` — "A DataSource providing recipient information (User/Lead/Contact)"

**Limitation** (Academy verbatim): "We only support 1 signer in our setup".

**Support disclaimer** (verbatim): "FYI: We do not provide support on AdobeSign and we use the standard page from AdobeSign '/apex/echosign_dev1__AgreementTemplateProcess', any questions or issues must be directed to Adobe."

_Source: [Actionable AdobeSign](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-adobesign/)._

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

**Class**: `PDFButler_Actionable_GetThumbnailsV2` (verbatim)
**Configuration parameters** (verbatim labels):
- `Get Thumbnail Files DataSource`
- `Get Thumbnail Pictures DataSource`
- `Get Thumbnail Size` — one of `THUMB120BY90`, `THUMB240BY180`, `THUMB720BY480`

**Max count** (Academy verbatim): "The number of images that can be retrieved depends on the size of the thumbnails, can be up to 20" — i.e. 20 is a **ceiling**, not a documented default. Smaller sizes fit more.

**Required SOQL** (Academy verbatim — "This must be a SOQL Data Source and the SOQL must have following fields"):

```sql
SELECT Id, ContentDocument.Id, ContentDocument.LatestPublishedVersionId, ContentDocument.FileType
FROM ContentDocumentLink
WHERE LinkedEntityId = :recordId
AND ContentDocument.FileType IN ('JPG', 'PNG')
```

**Setup**:
1. Create the SOQL DataSource above
2. Create a child `PICTURE` DataSource marked `NotApplicable` (so it doesn't re-query)
3. Use a `PICTURE` ConfigType in the template pointing at the child DS

**Win**: works without `API Enabled` user permission → suitable for Community / Experience Cloud.

_Source: [Actionable Get Thumbnail](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-get-thumbnail/)._

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
**Apex class**: `cadmus_core.DocxToPdfInvocable`
**Method**: `global static List<InvocableConvertDocxToPdfDataModelReturn> convertToPdf(List<InvocableConvertDocxToPdfDataModel> data)`

### Input wrapper — `DocxToPdfInvocable.InvocableConvertDocxToPdfDataModel`

| Property | Type | `@InvocableVariable` label | Required |
|---|---|---|---|
| `contentDocumentId` | `Id` | `'Content Document Id'` | Yes (`required=true`) |
| `recordId` | `Id` | `'Record Id'` | Yes (`required=true`) |
| `runAsync` | `Boolean` | `'Run Async'` | No |
| `saveAsNewVersion` | `Boolean` | `'Save as new Content Document version'` | No |

### Output wrapper — `DocxToPdfInvocable.InvocableConvertDocxToPdfDataModelReturn`

| Property | Type | `@InvocableVariable` label |
|---|---|---|
| `contentDocumentId` | `Id` | `'Content Document Id'` |
| `contentVersionId` | `Id` | `'Content Version Id'` |

Outputs populate only when `runAsync = false`. When `saveAsNewVersion = false`, only `contentDocumentId` is returned.

### Async semantics

- **Set `runAsync = true`** when:
  - Called from a trigger
  - The same transaction has prior DML (callouts-after-DML rule)
- With async, no output vars — downstream Flow must wait for `ON_CONTENT_VERSION` hook or a platform event.

_Source: [`DocxToPdfInvocable.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/DocxToPdfInvocable.html)._

---

## Flow invocable: Convert DocConfig / Pack

Exposed via `cadmus_core.ConvertInvocableWithReturnVariables`. Used when you want to run a full DocConfig or Pack (not just DOCX→PDF) from Flow.

**Method**:

```apex
global static List<InvocableConvertOutput> convertWithWrapper(
    List<ConvertInvocable.InvocableConvertDataModel> data
)
```

Note: the input type `ConvertInvocable.InvocableConvertDataModel` lives on a sibling class (`ConvertInvocable`) that is **not** published in the public ApexDoc — verify fields in-org if building a custom invocation. In practice, the Flow UI surfaces variables that mirror `ConvertController.ConvertDataModel` (see `reference/automation.md`).

### Output wrapper — `ConvertInvocableWithReturnVariables.InvocableConvertOutput`

| Property | Type | `@InvocableVariable` label |
|---|---|---|
| `attachmentId` | `Id` | _(no label — unannotated)_ |
| `contentDocumentId` | `Id` | `'contentDocument Id'` |
| `contentDocumentLinkId` | `Id` | `'contentDocumentLink Id'` |
| `contentVersionId` | `Id` | `'ContentVersion Id'` |
| `targetName` | `String` | `'Name of the generated document'` |

**Heads-up**: the Flow output has **no `result` / `SUCCESS` field** — unlike the Apex `DocGenerationWrapper`. Downstream Flow logic can't short-circuit on the server-side result. Check `contentVersionId != null` as a success proxy in Flow.

_Source: [`ConvertInvocableWithReturnVariables.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/ConvertInvocableWithReturnVariables.html)._

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

---

## Academy child pages (per-Actionable citations)

Confirmed slug → URL mapping for the 13 Packs section pages:

| Title | URL |
|---|---|
| Lightning Flow Action – Convert DOCX to PDF | [/lightning-flow-action-convert-docx-to-pdf/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/lightning-flow-action-convert-docx-to-pdf/) |
| Create PACK with additional DocConfigs | [/create-pack-with-additional-docconfigs/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/create-pack-with-additional-docconfigs/) |
| Actionable AUTO_EMAIL | [/actionable-auto_email/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-auto_email/) |
| Actionable EMAIL_DOCCONFIG | [/actionable-email_docconfig/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-email_docconfig/) |
| Actionable EMAIL Quick Action | [/actionable-email-quick-action/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-email-quick-action/) |
| Actionable SIGN Butler | [/actionable-sign-butler/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-sign-butler/) |
| Actionable DocuSign | [/actionable-docusign/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-docusign/) |
| Actionable AdobeSign | [/actionable-adobesign/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-adobesign/) |
| Actionable run APEX Class | [/actionable-run-apex-class/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-run-apex-class/) |
| Actionable Get Thumbnail | [/actionable-get-thumbnail/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-get-thumbnail/) |
| Actionable Get Thumbnail URL | [/actionable-get-thumbnail-url/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-get-thumbnail-url/) |
| Actionable Image by URL that is in a field | [/actionable-image-by-url-that-is-in-a-field/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/actionable-image-by-url-that-is-in-a-field/) |
| Quick Chart Setup | [/quick-chart-setup/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/quick-chart-setup/) |

Base: `https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/`

---

_Sources: [PDF Butler Packs section](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-packs/) — 13 child pages above._