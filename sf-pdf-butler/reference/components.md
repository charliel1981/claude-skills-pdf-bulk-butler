# Lightning Components — PDF Butler

Every packaged UI component (placed on FlexiPages, Quick Actions, or Flows). Claude reads this for UI work — "put a PDF generator on this record page" or "add a preview step before emailing".

## Quick chooser

| User need | Component |
|---|---|
| Button to generate/download PDF on a record page | Convertor |
| Preview the PDF before save/email/sign | Previewer |
| Preview inside a Quick Action / from Flow / mobile / Safari | Lightning Quick Action Previewer |
| Preview in a Screen Flow context with custom parameters | Lightning Convert Component |
| Upload a modified DOCX, re-run pack | Inline Edit (Live Edit) |
| File chooser that triggers PDF Butler actions on related files | Document Selector |
| Screen Flow picks DocConfig(s) from custom logic | DocConfig Selector Logic by Flow |
| Admin-filterable Convertor (show only certain DocConfigs) | Dynamic Selector |
| Salesforce Classic org (no Lightning) | Classic Button |

---

## Catalog

### Convertor (Convert Component)

**Placement**: Lightning App Page, Record Page, Community.
**Purpose**: one-stop shop — list DocConfigs/Packs, run, upload, preview, download.
**Key capabilities**:
- Dynamic Flow integration (which DocConfigs show, which Alternative, which locale)
- Pack Target Override (e.g. force DOCX output via pack instead of PDF)
- DocConfig filtering per placement
- Works with Clickjack Protection enabled

### Previewer

**Placement**: same as Convertor (FlexiPages).
**Purpose**: render the document BEFORE save/email/sign — reviewer workflow.
**Delivery Overwrite values supported** (Academy verbatim):
- `BASE64` — "Never save"
- `VIEW_THEN_SAVE` — "Do not save on preview"

**Features** (verbatim): "enable the previewer toolbar for easy zooming and printing".

**Clickjack gotcha** (verbatim): "In some cases when you generate the document, Visualforce page previewer fails to load with a blank page or white screen. This is because of the Clickjack security settings of Salesforce." Fix is covered in the Academy video — generally, add the Visualforce frame host to Trusted URLs.

_Source: [PRE-VIEWER – PDF Butler Previewer](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/pre-viewer/)._

### Inline Edit (Live Edit)

**Purpose**: allow a user to download the generated DOCX, edit in MS Word (leveraging Restricted Editing), and re-upload. The uploaded DOCX then:
- Converts to PDF (if the pack calls for it)
- Runs associated Actionables (email, sign, storage)
- Respects mergefields from the updated doc
**Canonical workflow**: 2-step contract — generate, legal edits offline, re-upload, dispatch.
**Requires**: enabling MS Word Restricted Editing on the template (protects everything except whitelisted regions).

### Lightning Quick Action Previewer

**Purpose**: the Previewer, but available in contexts where the standard one fails — Lightning Flows, Safari, Salesforce Mobile, VisualForce.
**Availability**: **contact `support@pdfbutler.com`** to obtain; setup doc provided on request.

### Lightning Convert Component

**Purpose**: similar to Convertor but designed for inline use in Lightning Flows / VF.
**Parameter types** (verbatim, case-sensitive): `String`, `Double`, `Date`, `DateTime`, `Boolean`, `MultiSelect`.
**MultiSelect format** (Academy verbatim): "these have to be separated by ';' eg abc;123;yxz".
**Typical consumer**: a KEYVALUE DataSource that receives the params. Academy: "Feed KeyValue DataSources into Lightning Convert Component via Flow."
**Availability**: "Get the component by contacting: support@pdfbutler.com" (verbatim).

_Source: [Lightning Convert Component](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/lightning-convert-component/)._

### Document Selector

**Purpose**: list files related to a record (e.g. an Opportunity's attached docs) + expose PDF Butler actions on each.
**Use for**: email-existing-file workflows, sign-a-specific-attachment patterns.

### DocConfig Selector Logic by Flow

**Purpose**: let a **Screen Flow** implement custom rules for which DocConfigs are mandatory vs optional, then hand off to the Convertor.

**Input Apex-Defined type**: the class is published in the public ApexDoc as `cadmus_core.ComponentDataByFlowInput`; the Flow UI / admin docs commonly refer to the alias `PDFB_DocConfigByFlowInput`. Both resolve to the same class. Verbatim shape:

```apex
global with sharing class cadmus_core.ComponentDataByFlowInput {
    @InvocableVariable(label='objectName') global String objectName;
    @InvocableVariable(label='recordId')   global String recordId;
}
```

**Invocable variables**:

- Input: `input` — Apex-Defined type (see above)
- Outputs (from the selector Flow):
  - `alternative` (Text)
  - `locale` (Text)
  - `docConfigs` (Text collection — mandatory)
  - `optionalDocConfigs` (Text collection — optional, user can toggle)
  - `packs` (Text collection)

**Availability**: add-on component — request from Customer Success team.

_Source: [`ComponentDataByFlowInput.html`](https://eu1.pdfbutler.com/files/api/cadmuscore/ComponentDataByFlowInput.html)._

### Dynamic Selector

**Purpose**: Convertor-style component with extensive admin-level filtering.
**Attributes**:

| Attribute | Purpose |
|---|---|
| `docConfigs` | List of mandatory DocConfig Ids |
| `optionalDocConfigs` | User-selectable optional DocConfigs |
| `packs` | List of mandatory pack Ids |
| `sendSeparate` (Boolean) | Merge output into one file vs keep separate |
| `generateByPack` (Boolean) | Run all DocConfigs as one pack |
| `generateByPackPackId` (String) | Pack whose BEFORE Actionables fire |
| `locale` / `alternative` | Multi-language / multi-brand filtering |
| `keepDocConfigType` | Output in DocConfig native type (DOCX/XLSX) — skip PDF conversion |
| `allowFileUpload` | Let user attach ad-hoc files |
| `imgContentVersions` / `docxContentVersions` / `pdfContentVersions` | Pre-supplied file references to include |

### Classic Button

_Video-only / stub Academy page; no textual pattern is published. See [Classic Button](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/classic-button/) and request sample code from support@pdfbutler.com._

**Purpose**: Salesforce Classic support — call PDF Butler from JS/URL buttons.

### Convertor label translations

**Purpose**: show DocConfig names translated into the user's language.
**Mechanism**: a **Translation DataSource** keyed by DocConfig Id + locale. Convertor reads user locale automatically and resolves labels.
**Use for**: multi-language orgs where admins want one DocConfig with localised display names.

---

## Usage patterns

### Record-page generator

Convertor component → FlexiPage → Record Page for the relevant object (Quote, Opportunity, etc.) → configure to show only the relevant DocConfigs.

### Review-before-send workflow

Previewer component → Record Page → pack configured with `VIEW_THEN_SAVE` delivery → pack's email Actionable fires only after user clicks Save.

### Custom-quote builder

Screen Flow with DocConfig Selector → user picks optional docs → Flow hands DocConfig Ids to a Dynamic Selector-based screen or Convert component → one merged PDF delivered.

### Legal redline loop

1. Convertor generates DOCX (not PDF)
2. Inline Edit component lets counsel download, edit in Word, re-upload
3. Re-upload triggers the pack: DOCX→PDF conversion + Sign Butler / DocuSign

---

## Custom LWC path

When no packaged component fits, wrap `cadmus_core.ConvertController.convertAura(cdm)` in your own `@AuraEnabled` Apex method and build an LWC/Aura component. See `reference/automation.md` for a complete Quick Action example.

---

---

## Academy child pages (per-component citations)

| Component | URL |
|---|---|
| CONVERTOR – PDF Butler Convert Component | [/convertor/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/convertor/) |
| PRE-VIEWER – PDF Butler Previewer | [/pre-viewer/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/pre-viewer/) |
| Inline Edit (or Live Edit) | [/inline-edit/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/inline-edit/) (slug not verified) |
| Lightning Quick Action Previewer | [/lightning-quick-action-previewer/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/lightning-quick-action-previewer/) (slug not verified) |
| Lightning Convert Component | [/lightning-convert-component/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/lightning-convert-component/) |
| Translating DocConfig names for the Convertor Component | [/translating-docconfig-names-for-the-convertor-component/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/translating-docconfig-names-for-the-convertor-component/) (slug not verified) |
| CLASSIC BUTTON | [/classic-button/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/classic-button/) |
| DOCUMENT SELECTOR | [/document-selector/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/document-selector/) (slug not verified) |
| DocConfig Selector – logic by flow | [/docconfig-selector-logic-by-flow/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/docconfig-selector-logic-by-flow/) (slug not verified) |
| Dynamic Selector | [/dynamic-selector/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/dynamic-selector/) (slug not verified) |

Base: `https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-lightning-components/`

_Sources: 10 child pages under the Components Academy section — URLs above. Five slugs confirmed; five inferred from title (visit the index page at the base URL to resolve any 404)._