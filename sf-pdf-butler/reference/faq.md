# FAQ & Troubleshooting — PDF Butler

Quick answers to the 16 FAQs + Get-Started + Use Cases. Claude reads this when a user reports an error or asks "can PDF Butler do X?"

---

## Licensing & access

### How do I assign licenses?

**Manual**: Setup → Installed Packages → **PDF Butler** → **Manage Licenses** → assign to users.
**Automated**: drive assignments from a Salesforce Flow for large/dynamic user sets.
**Who needs one**: end users who generate documents; admins building configurations (check via `PermissionSetAssignment` whether the package permsets are granted).

### How do I grant login access for support?

Grant temporary login access via Salesforce's standard "Grant Account Login Access" feature. Grant it to **CloudCrossing Support** (the company behind PDF Butler) — no need to provision a user account for them.

### Password reset / forgot ADMIN or USER password?

Registration email (subject: "PDF Butler registration completed") contains **two** passwords: ADMIN and USER. If both are lost, request replacements via support — Academy has a video walk-through.

### Why do I get `Argument 1 cannot be null`?

**Cause**: PDF Butler uses **Protected Custom Settings** for sensitive data, but Salesforce introduced a permission that ISV packages can't auto-assign.
**Fix**: manually add the permission to your permission sets.

### When I open PDF Butler config screen, I'm redirected to Home

**Cause**: browser's **"Block third-party cookies"** setting prevents the package's Canvas app from authenticating.
**Fix**: allow third-party cookies for your Salesforce domain.

---

## Platform compatibility

### Does PDF Butler work on a Scratch Org?

**Document generation**: works.
**DocConfig configuration via IDE**: **does NOT work** — errors like "Your browsing session has ended" or "Oops, there was an error rendering Canvas application."
**Workaround**: generate a password for the scratch org user, log in via web browser (not IDE):

```bash
sf org generate password -o <scratch-alias>   # sf CLI v2
sf org display user -o <scratch-alias>         # show password
```

Practical implication: use a persistent sandbox for CI integration tests rather than per-PR scratch orgs.

### Can we handle library files?

Yes. Component `PDFButler_LibraryFiles` supports Salesforce Libraries content — request from support if not in your install.

### Can we handle encrypted fields (Shield Platform Encryption)?

Yes. Add encrypted fields to the DataSource SOQL — Salesforce decrypts for authorised users at query time. Respects standard Shield limitations (indexed fields, etc.).

### Can we support Arabic and right-to-left script?

Yes — "Sure we can!" Academy has a video; for specific fonts (e.g. Noto Sans Arabic), contact support to embed. See `reference/tips.md` → "Embedded fonts".

### Can we store a file in an AWS S3 bucket?

Yes — pattern:

1. **Named Credential** → Authentication: **AWS Signature Version 4**
2. **Remote Site Setting** matching the Named Credential URL
3. Two Apex classes (support provides): `AWSService` + `Actionable_StoreInS3Bucket`
4. **AFTER Actionable** pointed at `Actionable_StoreInS3Bucket`

PDF Butler does **not** support AWS directly — debugging S3-specific issues is your AWS admin's problem. Same pattern works for Azure / Google Cloud Storage — ask support.

### Have a textbox fixed to the bottom of the last page?

Word-side trick (not a PDF Butler config):
1. Insert textbox near end of document
2. **Anchor it to the last paragraph** in the DOCX
3. Size textbox to match content exactly
4. Position at page bottom (centre if needed)

Because it's anchored to the final paragraph, it only appears on the last page regardless of page count.

---

## Email & deliverability

### Why do emails sent from Salesforce end up in spam?

**Root cause**: Salesforce sends on behalf of your domain (e.g. `you@company.com`) but the message originates from Salesforce's MTA — recipient servers reject as spoofing.
**Fix** (works in ~10 min with your domain admin):
1. **DKIM** — add Salesforce's DKIM public key to your DNS
2. **SPF** — add `include:_spf.salesforce.com` to your SPF TXT record
3. Disable **"Enable Sender ID compliance"** in Salesforce Email Settings — it auto-inserts `noreply@salesforce.com` in Sender headers and breaks auth

---

## PDF output features

### How to lock/encrypt a PDF after generation?

Two scenarios in Academy docs:
1. **Lock against editing** — PDF cannot be opened in editors to modify content
2. **Password-protect** — PDF cannot open without password

Both configured in DocConfig metadata — Academy references video tutorials for the exact fields. See also `reference/tips.md` → "Dynamic PDF passwords" for per-record password derivation.

---

## DataSources & runtime

### How to add a SOQL parameter via Actionable?

Pattern: an **APEX BEFORE Actionable** that mutates the DataSource SOQL at runtime.
- For replacing a placeholder in an existing SOQL string, use `AbstractDataSourceActionable` (phase `DATA_SOURCE`) — see example in `reference/automation.md`
- For adding a custom variable to `inputMap` used by DataSources' `:bindVar`, use `AbstractBeforeActionable` setting `inputMap.put('myVar', value)`

### Can I get the list of Alternatives from Salesforce via SOQL?

**Yes** — Alternatives are synchronized from the DocConfig configuration page into the DocConfig record (exact child object name not shown on the FAQ; query the schema for `cadmus_core__*Alternative*__c` after a sync). Academy video `oZQwZB-KzK0` walks through the sync. Use when you need to show Alternatives in a Salesforce UI list for end-user selection.

---

## Template best practices

Curated from the Academy's "Best Practices for Templates" FAQ — these are the rules that matter when authoring a new DocConfig template.

### Layout

- **Use TABLES, not text boxes**, to align content — Word re-flow preserves tables better
- **Anchor images as "In Line with Text"** — floating images drift during conversion
- Avoid multi-column layouts; if required, fixed-width columns only
- In Table Properties, set Preferred Width to **percentage**
- Table text-wrapping → **"None"** (never "Around")
- Nested tables work but kill perf at scale — prefer `CONTENT_CONTROLLER` for heavy nesting

### Fonts

**Supported out of the box**: Arial, Times New Roman, Calibri, Alegreya, Lato, Montserrat, OpenSans, PTSans, Roboto, Cambria, Comic, Courier, Georgia, Tahoma, Verdana.
**NOT supported**: Adobe fonts, anything requiring Adobe licensing.
**Custom fonts**: email support@pdfbutler.com with your tenant username + font .ttf file — they enable embedding on your tenant. See `reference/tips.md` → "Embedded fonts" for format constraints (TTF only, no OTF, no variable fonts).

### Mergefield naming

**Format**: `[[!OBJECT_Fieldname!]]`
**Convention**: prefix object abbreviation — `ACC_` for Account, `OPP_` for Opportunity, `PROD_` for Product.
Example: `[[!ACC_Name!]]`, `[[!OPP_Stage!]]`, `[[!OPP_CloseDate!]]`.

**Prevent blank lines when empty**: keep merge fields **inline in a sentence**, not on their own line.

### Images

- Use picture placeholders (Word Insert → Picture) — not Shapes
- Formats: **PNG** (transparent OK) or **JPEG**
- For stable positioning, embed logos in a **single-cell table** inline with text
- Dynamic image merge fields: `[[!Products_PictureRef01!]]`

### Anti-patterns

- Avoid **continuous section breaks** — use Page or Next Page section breaks
- Don't put merge fields inside text boxes — use inline paragraph text
- Don't over-merge/un-merge cells — it causes content to shift during render
- Avoid floating images

---

## Get Started summary

Academy's Get Started section points to install + first doc + "Full Sales Cloud in minutes":

### Install, Setup & Register

"Install from the AppExchange and configure PDF Butler in 10 minutes." Registration delivers an email with ADMIN + USER passwords (reused across all orgs — see root `SKILL.md` for the idempotent checklist).

### Create your first document (15 min)

- **Object**: typically Opportunity or Quote
- **Template**: download starter DOCX from Academy (with or without merge fields)
- **DocConfig type**: Main Word Document
- **Flow**: upload template → add SINGLE SOQL DataSource → create SINGLE ConfigTypes mapped to merge fields → test

### Full Sales Cloud in Minutes

Pre-built set of DocConfigs for Opportunity — for demos / fast onboarding. Available on AppExchange as a separate package.

---

## Example use cases

### Gift Card

End-to-end pattern:
- **Object**: custom `Gift_Card__c` with recipient, value, message fields
- **DocConfig**: Main Word Document type + uploaded template
- **DataSource**: SINGLE SOQL against the gift card record
- **Features shown**: barcode config (see `reference/configtypes.md` → Barcode), inline merge fields, image pulled from Files, email delivery via Pack + Actionable
- **Placement**: PDF Butler Convert Component on the record page

A good starter pattern to study for any "generate-and-email-a-personalised-single-page-doc" workflow.

---

_Sources: 16 FAQ pages + 3 Get Started pages + Gift Card use case under [pdf-butler-faq/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-faq/), [get-started/](https://www.pdfbutler.com/academy/pdf-butler-academy/get-started/), [pdf-butler-example-use-cases/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-example-use-cases/)._
