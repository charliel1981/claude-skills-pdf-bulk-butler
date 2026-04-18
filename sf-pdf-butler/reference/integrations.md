# Product Integrations — PDF Butler

PDF Butler on top of specific Salesforce products (CPQ, FSL) and the Peppol e-invoicing network.

---

## Salesforce CPQ

### Data model CPQ → PDF Butler

| CPQ object | Role |
|---|---|
| `SBQQ__Quote__c` | Primary record — DocConfig runs against this |
| `SBQQ__QuoteLine__c` | Child lines — typically a LIST DataSource |
| `SBQQ__QuoteLineGroup__c` | Optional grouping — enables per-group sections |

PDF Butler is "designed from the ground up to handle [CPQ] and to convert your bundles and products into perfectly structured quotes."

### Multi-level CPQ products

**Pattern**: 3-tier hierarchy (primary product → bundle children → sub-components).
**Approach**: nested LIST DataSources — parent query on `SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = null`, child queries on `SBQQ__QuoteLine__c WHERE SBQQ__RequiredBy__c = :parent_line_id`.
**UI mirror**: the goal is to mirror the "Edit Lines" view in CPQ inside the generated PDF — admins often use this as the acceptance test.
**Visual elements**: product logos tie into `PICTURE` ConfigType with per-product image DataSources.

### CPQ Groups

**Use case**: split line items by group (Services vs Hardware vs Licences) with headers.
**Approach**: LIST DataSource on `SBQQ__QuoteLineGroup__c` as parent → filtered child LIST on `SBQQ__QuoteLine__c WHERE SBQQ__Group__c = :groupId`.
**Demo asset**: Academy ships `DEMO_CPQ_Grouped_Lines.docx` — request it for a starter template.

### CPQ gotchas

- Line ordering driven by `SBQQ__Number__c`, not created date
- Bundle options hide under `SBQQ__RequiredBy__c` — always filter top-level vs child in parent queries
- Price fields come in multiple currencies if multi-currency enabled — use `locale` / `numCurrLocale` on `ConvertDataModel` to format correctly

---

## Field Service (FSL)

### Data model FSL → PDF Butler

| FSL object | Role |
|---|---|
| `ServiceAppointment` | Typical trigger record for a service-visit report |
| `WorkOrder` | Parent for WOLI/ pictures; often primary doc target |
| `WorkOrderLineItem` (WOLI) | Tasks performed on the visit |
| (Custom WOLI children) | Sub-tasks, parts, measurements |

### Service Report

**Target**: "best-looking Service Report ever."
**Structure** (4 content blocks):
1. **Work Order data** — header, customer, SLA
2. **Work Order pictures** — field-captured images
3. **WOLI data & pictures** — task-level detail
4. **Child WOLI data & pictures** — sub-task granularity

**Required add-on**: "PDF Butler Actionable thumbnail component" (with comments + unit tests) — request via `support@pdfbutler.com`. Needed because FSL-captured images often need thumbnail rendering before embedding.

**Template**: Academy provides a downloadable Word template to seed the layout.

### Embedded SIGN via FSL App

**Goal**: technician triggers SIGN flow from within FSL mobile, no app switch.
**Wiring**:
1. Custom URL field on `WorkOrder`, e.g. `Embedded_SIGN_URL__c`
2. Record-Triggered Flow: when WorkOrder status → "In Progress", generate the signing URL via PDF Butler callout, write to the field
3. **FSL App Extension** — point at the URL field so the Sign action appears in the mobile action list
4. Technician taps Sign → WebView opens → PDF Butler renders the doc + creates SIGN request → in-person signing UI launches

### Embedded Form via FSL App (Preview / Fill / Sign)

**Goal**: three-mode form experience in FSL mobile.
**Modes**:
- **Preview** — generated doc, read-only (hide Submit via Form Actionable config)
- **Fill** — capture form data back into Salesforce
- **Sign** — scribble signature (electronic, not digital — i.e. image of signature, not cryptographic)

**Wiring**: same pattern as Embedded SIGN but URL points at a FORM Butler form (separate package). Generate a **public URL** via FORM Butler, wire into an FSL App Extension.

### FSL gotchas

- Thumbnail component is pre-req for picture-heavy reports — don't skip
- Scribble sign is NOT legally binding like a digital signature — position correctly to clients
- Public form URL must be regenerated if FORM Butler's endpoint rotates

---

## Peppol e-invoicing

### Install order

1. **PDF Butler** managed package — **must be installed FIRST**
2. **Peppol Invoicing** managed package
3. Pair them in the **Peppol Admin** tab

### Authentication

- Credentials issued by PDF Butler during registration (same tenant credentials)
- Paste into Peppol Admin tab → **Check Credentials** verification step
- Sandbox install: append `/test` instead of `/login` in package-install URL

### Required Account fields

| Field | Purpose |
|---|---|
| `CustomerPeppolId__c` | Customer's Peppol participant ID |
| Billing Street / City / PostalCode / Country | Standard Salesforce address fields used in UBL XML |

**Peppol ID format**: ISO 6523 → `<Scheme ID>:<Participant ID>`, e.g. `9915:test-sender` (test), `0106:12345678` (Belgian VAT producer).

### Apex integration

- **Flow-invocable class**: `cadmus_peppol__Peppol_ServiceFlow` — send invoice via Flow
- **Logging**: configurable from Peppol Admin tab for debugging outbound requests

### Test → Production promotion

By default, the package registers on **Peppol Test Network** — invoices have no legal value there.

**Promotion steps**:
1. Migrate config to PROD org
2. Email `support@pdfbutler.com` / call `+32 3361 35 30` requesting network promotion
3. Support confirms → you're on the live Peppol network
4. Only then do invoices have legal standing

**Gotcha**: your username stays on Test Network until support manually flips it — don't assume PROD env alone does it.

---

## Service Cloud — Case articles

**Pattern**: generate case documentation that combines the Case record + its related Knowledge articles.
**Composition**:
- SINGLE DataSource on the Case (subject, description, owner)
- LIST DataSource on related Knowledge articles (via `CaseArticle` junction)
- Main Word PDF DocConfig on the Case object
**Use for**: support teams sending consolidated case + KB article PDFs to customers; escalation handover docs.

---

## Experience Cloud (Community) — Partner / Customer

### Permission sets

Assign to community members: **`PDF Butler User`** (and **`SIGN Butler User`** if using e-signature).

### Object sharing rules (for external users)

Set the following to **Public Read Only** in Setup → Sharing Settings:

- `cadmus_core__Actionable__c`
- `cadmus_core__Data_Source__c`
- `cadmus_core__Doc_Config__c`
- `cadmus_core__Pack__c`
- `cadmus_core__Pack_DocConfigs__c`

For SIGN Butler additionally:

- `Sign Request` — **Public Read/Write**
- `Sign request template` — **Public Read/Write**
- `Lightning Email Templates` — **Public Read Only**

### System permissions

Grant **`View All Custom Settings`** to the community user profile / permset — required for PDF Butler to read its runtime configuration.

### Licensing

External users still need PDF Butler licenses assigned (`Setup → Installed Packages → PDF Butler → Manage Licenses`).

### Known limitation

**EMAIL Quick Action Actionable does NOT work in Experience Cloud** — Salesforce platform limit on Quick Action APIs. Use `AUTO_EMAIL` or `EMAIL_DOCCONFIG` instead.

---

## Multi-currency org (product-level view)

Orthogonal to the `reference/i18n.md` multi-currency content — both pages overlap. Summary:
- Enable multi-currency on the org (Salesforce setting)
- Include `CurrencyIsoCode` in DataSource SOQL
- Set `cdm.numCurrLocale` per-record for customer-locale formatting of amounts
- See `reference/i18n.md` → Multi-currency orgs for the runtime pattern

---

## Cross-product notes

- **SIGN Butler** pairs best with PDF Butler in the same install — native integration, no envelope-template mapping quirks.
- **FORM Butler** required for FSL embedded forms — separate package, covered in FORM Butler Academy.
- **Collaboration Butler** (`cadmus_una`) required for SharePoint image retrieval — see `reference/automation.md`.

---

_Sources: Academy sections [for CPQ](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-cpq/), [for FSL](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-field-service-lighting-fsl/), [Peppol](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-peppol-integration/), [by Salesforce Product](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-salesforce-product/)._
