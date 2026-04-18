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
**Approach**: nested LIST DataSources on `SBQQ__QuoteLine__c` — parent filters to top-level lines, child queries filter to each bundle's children.
**UI mirror**: the goal is to mirror the "Edit Lines" view in CPQ inside the generated PDF — admins often use this as the acceptance test.
**Visual elements**: product logos tie into `PICTURE` ConfigType with per-product image DataSources.

The specific CPQ field names used to distinguish parent lines from bundle children (`SBQQ__RequiredBy__c`, `SBQQ__Group__c`, `SBQQ__Number__c`, etc.) are **not** published in the Academy prose — they're CPQ-package conventions. Verify each against the CPQ schema in your target org (`sf sobject describe -o <alias> SBQQ__QuoteLine__c`) or inspect the downloadable `DEMO_CPQ_Grouped_Lines.docx` which ships with the Academy page.

### CPQ Groups

**Use case**: split line items by group (Services vs Hardware vs Licences) with headers.
**Approach**: LIST DataSource on `SBQQ__QuoteLineGroup__c` as parent → filtered child LIST on `SBQQ__QuoteLine__c`. Academy verbatim: "Using groups in your 'Edit Lines' is very powerful. To use these groups to build a better structure and overview in your quote is even more powerful."
**Demo asset**: Academy ships `DEMO_CPQ_Grouped_Lines.docx` — downloadable directly from the Using CPQ Groups page.

### CPQ gotchas

- Line ordering — CPQ typically uses a sort-order field; verify the exact API name in your org
- Bundle options hide under a "required-by" relationship — verify the exact SBQQ field name in your org
- Price fields come in multiple currencies if multi-currency enabled — use `locale` / `numCurrLocale` on `ConvertDataModel` to format correctly

_Sources: [CPQ – Introduction](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-cpq/cpq-introduction/), [Multi-level CPQ products](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-cpq/multi-level-cpq-products/), [Using CPQ Groups](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-cpq/using-cpq-groups/) (video-only on the last — downloadable DOCX provides the concrete pattern)._

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
- Paste into Peppol Admin tab → **Check Credentials** (verbatim button label)
- Sandbox install: append `/test` instead of `/login` in package-install URL
- Permission Set to assign to Peppol administrators: **`PEPPOL Butler Admin`** (verbatim)

### Custom objects + namespace

Installed under `cadmus_peppol` namespace. Key objects (verbatim):

- `cadmus_peppol__PeppolSalesInvoice__c` (label: "Peppol Sales Invoice")
- `cadmus_peppol__PeppolLog__c` (label: "Peppol Log")

### Peppol participant IDs — ISO 6523

Format `<Scheme ID>:<Participant ID>`. Examples verbatim from the Academy:

- `9915:test-sender` (Test Network)
- `0208:0793904121`
- `0088:987654321`

### Apex integration

Classes verbatim (Peppol Setup & Configuration Guide):

- `cadmus_peppol.Peppol_ProcessInvoice` — top-level processor
- `cadmus_peppol__Peppol_ServiceFlow` — Flow-invocable; send invoice via Flow
- `cadmus_peppol__Peppol_Invoice` — invoice entity

Wrapper Apex types on the page: `Peppol_Invoice`, `Peppol_InvoiceSupplier`, `Peppol_InvoiceCustomer`, `Peppol_InvoiceDelivery`, `Peppol_InvoiceLine`, `Peppol_InvoiceVatTotals`, `Peppol_InvoicePaymentMethod`, `Peppol_InvoiceAttachment`, `Peppol_InvoiceExtraIdentifier`, `Peppol_AdditionalProperty`.

Required invoice fields (verbatim): `INVOICE_NUMBER`, `INVOICE_ISSUE_DATE` (format `YYYY-MM-DD`), `INVOICE_TOTAL_EXCL_VAT`, `INVOICE_TOTAL_INCL_VAT`, `INVOICE_TOTAL_VAT`, `DEFAULT_CURRENCY` (default `EUR`), `SENDER_PEPPOL_ID`, `SENDER_NAME`, `SENDER_VAT`, `SENDER_COUNTRY`, `RECIPIENT_PEPPOL_ID`, `RECIPIENT_NAME`, `RECIPIENT_COUNTRY`.

**Logging**: configurable from Peppol Admin tab with buttons `Switch On Logging (for 1 hour only)` / `Extend Logging` / `Remove logging`.

### Invoice status → HTTP code mapping

| Status | HTTP code |
|---|---|
| `Created` | `201` |
| `Processed` | `202` |
| `Error` | `500` |
| `Error already sent` | `409` |
| `Error not on Peppol` | `422` |

### Test → Production promotion

Academy verbatim: "the PDF Butler username is automatically connected to the **Peppol Test Network**." Test invoices carry "no legal value or commitment."

**Promotion steps**:

1. Go live by requesting the PDF Butler **Support team** to connect your user to the **Peppol Production Network**
2. Even after moving to a production org, the account "will remain connected to the Test Network by default" — your username stays on Test Network until support manually flips it

_Sources: [Peppol Invoicing for Salesforce: Setup & Configuration Guide](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-peppol-integration/peppol-invoicing-for-salesforce-setup-configuration-guide/), [How to get promoted from the Test Network to the Peppol Network](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-peppol-integration/how-to-get-promoted-from-the-test-network-to-the-peppol-network/)._

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

---

## Failure modes

| Symptom | Root cause | Fix |
|---|---|---|
| CPQ quote renders flat list, not nested bundles | Parent query didn't filter to top-level lines; children picked up both | Split into parent + child LIST DataSources with the appropriate "required-by" filter (verify field name in-org) |
| CPQ lines out of order | No ORDER BY in SOQL | Add `ORDER BY` with CPQ's line-order field (verify name in-org) |
| Peppol sends but invoice fails validation | Missing required invoice fields (e.g. `SENDER_PEPPOL_ID`) | Cross-check against the required-fields list above |
| Peppol "test" invoices appear successful but no partner received them | Account still on Peppol Test Network after PROD migration | Email `support@pdfbutler.com` to promote the username to Production Network |
| FSL embedded Sign button missing in mobile | FSL App Extension not pointed at the URL field | Add the App Extension, point at `Embedded_SIGN_URL__c` |
| Experience Cloud user cannot generate doc | Sharing not set to Public Read Only on `cadmus_core__*` objects | Update org-wide sharing as per table above |
| Experience Cloud EMAIL Quick Action blank | Salesforce platform limit — Quick Action APIs not supported in Communities | Switch to `AUTO_EMAIL` or `EMAIL_DOCCONFIG` |

---

_Sources: [for CPQ](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-cpq/), [for FSL](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-for-salesforce-field-service-lighting-fsl/), [Peppol](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-peppol-integration/), [by Salesforce Product](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-by-salesforce-product/). Per-child-page citations appear in each section above._
