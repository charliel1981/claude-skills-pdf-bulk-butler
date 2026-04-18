# Changelog

All notable changes to this skill bundle.

## [0.2.0] — 2026-04-18 — cadmuscore ApexDoc audit, Migration CLI, Academy verbatim pass

Three-part enrichment, single release:

1. **`cadmus_core` ApexDoc audit** — second pass against the public reference at [eu1.pdfbutler.com/files/api/cadmuscore/](https://eu1.pdfbutler.com/files/api/cadmuscore/) (31 classes, all re-fetched verbatim).
2. **Migration CLI full coverage** — all 10 commands of `@pdfbutler/migration-cli` v0.0.29.
3. **Academy depth-parity pass** — every pre-existing reference file brought up to the same verbatim standard; identifiers traced per-section to Academy child pages; video-only pages labelled `_video-only_` and not mined for content.

### `sf-pdf-butler` (v0.3.0 → v0.5.0)

**New — Apex reference (`reference/automation.md`):**

- **Unit testing** — `CadmusHttpCalloutMock` with `setTestCalloutMockSuccess(targetId)` canonical pattern; full constructor + mock-injection example.
- **Cross-package integration** — `PdfButlerCallable` with `System.Callable` `'convert'` dispatch for ISV add-ons and Agentforce custom actions; nested `ExtensionMalformedCallException`.
- **PdfActions** — full shape (11 fields + `Location` + `Watermark` enums) replacing the outdated "contact support for `PB_AddPdfMergeActions`" note. Native page numbers / title / `DRAFT`/`CONFIDENTIAL`/`SAMPLE` watermarks.
- **MetadataWrapper** — 15 instance properties + 8 static singletons + nested `CadmusLocale` + three enums (`CALLED_FROM_TYPE_CUSTOMER`, `FLATTEN_TYPE`, `USAGE_TYPE`). Surfaces PDF Butler's **Agentforce awareness** (`USAGE_TYPE.AGENTFORCE`, `CALLED_FROM_TYPE_CUSTOMER.AGENTFORCE`).
- **CadmusHttpResponse** — full field table + nested `ChildDocConfigResult` (per-DocConfig Pack output) + nested `Issue` shape.
- **CadmusKeyValue + CadmusParameters** — typed-variable bag shape with all `@InvocableVariable` labels verbatim.
- **UtilClasses** — four nested helpers (`DataSourceActionableData`, `FileUploadData`, `FileUploadResponse`, `KeyValue`) with constructors.
- **REST API map** — all 9 `@RestResource` URL mappings + HTTP verbs + v1 vs v2 export guidance.

**Fixed — Apex reference:**

- `ConvertDataModel` — added `webService` vs `global` visibility per field; added missing `deliveryOverwrite` values (`FILES_ADD_VERSION`, `ATTACHMENTS`, `ATTACHMENTS_OVERWRITE`) verbatim from ApexDoc.
- `DocumentDataHandler` — three `generate(...)` overloads now shown (previously one opaque row); `addPicklistDependency(...)` added; `communityNetworkId` static property added; `addDocConfigOverride` second param corrected from `Id` to `String`.
- `AbstractAfterActionable` signature now shows the sixth `DocGenerationWrapper wrapper` parameter (the parameter unique to this interface, and the whole reason to use it over the Before variants); example code added.
- `AbstractBeforeWithDataSourcesActionable` — fifth parameter renamed `dataSources` (ApexDoc spelling) with `dsMap` called out as a local alias.
- Global class list — corrected from 37 to the **31 classes actually in the public ApexDoc**; six additional Academy-referenced classes flagged as "verify in-org" with an explanatory footnote.
- `convertToDocxAura` disambiguated (not marked deprecated on ApexDoc — still callable).
- `lightning-record-picker` API version floor (56.0+ / Winter '23) called out in the LWC example.

**New — Flow invocables (`reference/packs-actionables.md`):**

- `DocxToPdfInvocable` — full input wrapper (`InvocableConvertDocxToPdfDataModel`) + output wrapper (`InvocableConvertDocxToPdfDataModelReturn`) + verbatim `@InvocableVariable` labels.
- `ConvertInvocableWithReturnVariables` — output wrapper `InvocableConvertOutput` shape; flagged the surprise that Flow output has **no `result`/`SUCCESS` field**.

**New — Components (`reference/components.md`):**

- `ComponentDataByFlowInput` / `PDFB_DocConfigByFlowInput` name reconciled — same class, both names documented.

**New — DataSources (`reference/datasources.md`):**

- `SingleWrapper` / `ListWrapper` typed wrappers added under KEYVALUE section.

**New — Deployment CLI (`reference/deployment.md`):**

Full coverage of `@pdfbutler/migration-cli` v0.0.29 (npm-only, BSD-3-Clause, oclif-based `sf` plugin):

- All **10 commands** (previously 2): `pb:{export, import, exportpack, importpack, exportdatasource, importdatasource, adminsettings, admincredentials}` + `sb:{export:signtemplate, import:signtemplate}`.
- Both **auth modes**: `-t <alias>` (local) vs `--session`/`--instance` (CI/CD with no prior `sf login`).
- **Full flag reference table** — including `-b full|only|none` (backend scope), `-d none|lead|pack|full` (Pack mode), `-c --clone`, `--cut`, `--shortpaths`, `-m --templates`, and the overloaded `-p` (partial vs parents vs pack).
- **REST endpoint map** — every CLI subcommand → Salesforce REST path → Apex class, extracted from the CLI's own `lib/utils/constants.js`.
- Version floors documented: `exportpack`/`importpack`/`adminsettings`/`admincredentials` need PDF Butler v1.440+; `importdatasource` needs v1.505+.
- **CLI failure-mode table** verbatim from the README "Typical errors and solutions".
- Config-file clarification: the CLI is **stateless** — no `.pdfbutlerrc`; reuse via Git-committed exports + shell-interpolated flags.
- Workflows: canonical export→import, Pack migration, CI/CD roundtrip with session auth, DataSource migration, new-org bootstrap, SIGN Butler template migration.

**"Never invent" fixes** (softened speculative identifiers):

- `configtypes.md` — `CRITERIA` extended operators (`>`, `<`, `>=`, `<=`) softened: Academy only documents `=` and `<>`. Numeric comparators flagged as "verify in-org against the `cadmus_core__Criteria_Operator__c` picklist".
- `faq.md` — Alternatives-list FAQ reframed as video-only (was fabricating a `*Alternative*__c` object name from a video). `Argument 1 cannot be null` FAQ now hedges on the specific permission name ("Academy does NOT name the permission" — typical is "Manage Protected Custom Settings").
- `i18n.md` — `SBQQ__Localization__c` object name softened: not published by the Academy page, verify via `sf sobject list | grep`.
- `integrations.md` — `SBQQ__RequiredBy__c`, `SBQQ__Group__c`, `SBQQ__Number__c` softened: not on Academy pages; inside the downloadable `DEMO_CPQ_Grouped_Lines.docx` demo. Removed invented Peppol example `0106:12345678` in favour of Academy-verbatim `0208:0793904121`, `0088:987654321`.
- `packs-actionables.md` — `PDFButler_Actionable_GetThumbnailsV2` max rewritten from "default 20" to Academy verbatim "can be up to 20" (ceiling, not default).
- `tips.md` — `UsageType` enum trimmed to the two Academy values (`NORMAL_PDFB`, `NORMAL_ASYNC`); `NORMAL_APEX` was a skill invention and removed.

**Video-only pages now marked**: PDF Form Filler, Alternatives-list FAQ, Flow Introduced Variables (BULK Butler), Classic Button, Home Page Component, SINGLE_FOR_FORMULA, SINGLE ConfigType Text Formatting, Launch batch from APEX (BULK Butler). Async Delivery config walkthrough is video-only but the enum values ARE Academy-verbatim.

**Verbatim enrichments — rest of the bundle:**

- `configtypes.md` — `SINGLE` formatting rewritten with all four `Spelled Out (in letters)` capitalisation variants quoted; all custom-format examples (`###,##0.00`, `###,##0`, `dd-MMM-yy`, `dd/MM/yy HH:mm:ss`, `HH:mm:ss`) verbatim; Roman-numeral constraint. `PICTURE` sizing modes expanded from 2 described to 4 verbatim (`NONE`, `BY WIDTH`, `BY HEIGHT`, `CONTAIN`). `DOCUMENT_V3` separator behaviours quoted verbatim including the empty-DataSource edge case.
- `doc-config-types.md` — Main Word DocConfig settings rewritten with correct Academy labels (`Export PDF as PDF/a`, `PDF UA Compliance`, `Enable Forms`, `Check and remove empty section at the end of the document`, `Use next version PDF processor`, `Lock/Encrypt PDF`, `Set title of document`, `Keep only values from MS Word controls`, `Leave Controls when generating MS Word file`). Excel `Checkbox` ConfigType corrected from all-caps `CHECKBOX`. Excel formula examples quoted verbatim with **semicolons**. Hidden-row gotcha quoted verbatim. PowerPoint `SLIDE_REPEATER` / `SECTION_REPEATER` / `Main Powerpoint Document` all verbatim. Added failure-mode table + per-type URL citations.
- `faq.md` — AWS S3 verbatim quote ("We do not provide support on the configuration in AWS S3…"). Argument 1 null FAQ verbatim quote + permission-name hedge.
- `i18n.md` — `INTERNATIONAL` / `NATIONAL` PHONE enum descriptions verbatim. Added failure-mode table + full 7-child URL inventory.
- `integrations.md` — Peppol section fully rewritten with verbatim Apex class names (`cadmus_peppol.Peppol_ProcessInvoice`, `cadmus_peppol__Peppol_ServiceFlow`, `cadmus_peppol__Peppol_Invoice`), custom objects, full wrapper-type list, required invoice fields, invoice status → HTTP code mapping, `PEPPOL Butler Admin` permset name, logging buttons. Added failure-mode table.
- `tips.md` — Usage Statistics rewritten as a table with Academy's exact 12 fields + the 7 popular `ActionName` values. Embedded fonts three-sentence list verbatim. Dynamic PDF passwords formula corrected to `ContactFirstNameLastName(lowercase)DOB(ddmmyy)`. Async delivery enum values (`FILES_ASYNC`, `FILES_OVERWRITE_ASYNC`, `FILES_ADD_VERSION_ASYNC`, `AFTER_ASYNC`) confirmed.
- `packs-actionables.md` — Get Thumbnail SOQL example quoted verbatim; max clarified as ceiling. AdobeSign section rewritten with Academy verbatim "We only support 1 signer in our setup" and the support-disclaimer quote. Added per-Actionable URL inventory (13 rows).
- `components.md` — Previewer `BASE64` / `VIEW_THEN_SAVE` descriptions verbatim. Lightning Convert Component `MultiSelect` example (`abc;123;yxz`) verbatim. Added per-component URL inventory (10 rows).

### `sf-bulk-butler` (v0.1.0 → v0.2.0)

Batch Info field list rewritten to match the Academy verbatim:

- **Added missing fields**: `Count SOQL` (Academy example `SELECT Count() FROM Account`), `Batch Apex Class` (implements `cadmus_batch.Batch_ICadmusBatch` — verbatim), `Alternative API Field`.
- **Corrected label drift**: `Locale API Field` (not "Locale Field API Name"), `Currency Locale API Field` (not "Currency Field API Name"), `Emails` is **comma-separated** (not `;`-separated).
- **Corrected Delivery Option enum**: removed skill-invented `FILES_ASYNC`; full Academy list now `ATTACHMENTS`, `ATTACHMENTS_OVERWRITE`, `FILES`, `FILES_OVERWRITE`, `FILES_ADD_VERSION`, `BASE64`, `Use DocConfig Setting`.
- **Corrected Batch Size guidance**: "Never set above 10" was invented — Academy example uses BatchSize = 20 for Run Actionables. Size-1 rule applies only when the DocConfig/Pack has its own Actionables, not when Run Actionables sit on the Batch Info.
- **Batch Backend section expanded**: RecordType `Batch Backend` verbatim, recommended `BatchSize = 100`, the distinct `Delivery Type` field (different from `Delivery Option`), Record Type `Batch Backend Action` for merging/zipping, fields `Backend Batch Action` (`MERGED_PDF` / `ZIP_FILE`) + `Active` + `No Unique Id Per File` + `Batch Backend Upload Action` (uses `cadmus_una.Actionable_GetUploadSession`), 1000-record cap verbatim, "AFTER Actionables on the DocConfig or Pack will be IGNORED" limitation.
- **Report-driven section expanded**: full Apex code block verbatim (`Reports.ReportManager.runReport()`, `getFactMap()`, `factMapKey = 'T!T'`, inner class `flowinputs` with `@InvocableVariable(label='Batch Info Id')` / `@InvocableVariable(label='Report Name')`). Test class `GetReportRecordsAndLaunchBatchTest` with `@isTest(SeeAllData=true)`.
- **Launch batch from APEX** page labelled video-only — `Batch_ProcessController` signatures now correctly cited to the `cadmusbatch` API docs.

---

## [0.1.0] — 2026-04-18 — Initial public release

First release of the `claude-skills-pdf-bulk-butler` bundle.

### `sf-pdf-butler` (internal version v0.3.0)

Full coverage of the [PDF Butler Academy](https://www.pdfbutler.com/academy/pdf-butler-academy/) — all 16 sections, ~162 child pages distilled into a lean `SKILL.md` index + 11 deep-dive reference files.

**Coverage highlights:**
- Apex API: `ConvertController` (all 11 methods + full `ConvertDataModel` field table), `DocumentDataHandler` file methods, `DocGenerationWrapper` response shape, all 4 Actionable lifecycle interfaces (`AbstractBeforeActionable`, `AbstractDataSourceActionable`, `AbstractBeforeWithDataSourcesActionable`, `AbstractAfterActionable`)
- Full LWC Quick Action example (Apex wrapper + HTML + JS + `.js-meta.xml`)
- Flow integration: `Convert a DOCX to PDF` invocable with full I/O contract, async semantics, reserved-chars gotcha
- All 13 Actionables (AUTO_EMAIL, EMAIL_DOCCONFIG, EMAIL Quick Action, SIGN Butler, DocuSign, AdobeSign, Run APEX Class, Get Thumbnail × 2, Image by URL, Quick Chart)
- All 31 ConfigTypes with quick-chooser + per-type config fields and gotchas
- All 13 DataSources (SINGLE, LIST, SOQL Builder, Full SOQL Power, Picture, KeyValue, Report, Filtered, Nested, Late Binding, Rollup, Picklist Translations, Static Values)
- All 9 DocConfig output types (Main Word PDF, Template Word, Excel, Static PDF, Table Column Remover, Email, PDF Form Filler, CSV, PowerPoint)
- All 10 Lightning components with placement and attributes
- All 21 Tips & Tricks cookbook recipes
- CPQ + FSL + Peppol + Service Cloud + Experience Cloud integrations
- Deployment (Migration Wizard, SF CLI `@pdfbutler/migration-cli`, Backup & Restore, stage mapping)
- Multi-language / multi-currency / multi-brand (Alternatives, locale formatting, Custom Labels, Picklist Translations, CPQ product translations)
- Full 16-page FAQ + template best practices + Get Started walkthrough
- Idempotent 6-step post-install checklist with detection queries (never re-run a done step)

### `sf-bulk-butler` (internal version v0.1.0)

Full coverage of the [BULK Butler Academy](https://www.pdfbutler.com/academy/bulk-butler-academy/) — 6 pages + external `cadmus_batch` API reference in a single `SKILL.md`.

**Coverage highlights:**
- `cadmus_batch.Batch_ProcessController` API: `startBatch`, `startBatch(Id, Map<String,Object>)`, `schedulebatchMethod`
- Batch Info record field table (Name, Cron, SOQL, Emails, Doc Config / Pack, Batch Size, Delivery Option, Locale / Currency Field API Name, Target Type)
- Per-record Actionables via `Run From Batch Info` lookup + alphabetical ordering
- Flow Actionable requirement: `batchInfoId` Input variable
- Report-driven batches with `GetReportRecordsAndLaunchBatch` pattern
- Optional SharePoint delivery via Collaboration Butler (`cadmus_una.Actionable_CollabStoreFile`)
- Batch Backend high-throughput add-on (opt-in, licensing, 1,000-record merged-PDF/ZIP cap)
- Common failure-mode table + idempotent post-install check

### Repository

- MIT license (wrapper only — not the paraphrased Academy content)
- `install.sh` — symlink-based installer with AI/sandbox reminder at end
- `CONTRIBUTING.md` — factual-accuracy rules for PRs
- Visible README Disclaimer section covering AI-generated nature, no warranty, no CloudCrossing affiliation, sandbox-first, IP respect
- Architecture diagram generated with Nano Banana Pro (`docs/architecture.png`)
