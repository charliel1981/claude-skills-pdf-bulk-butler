# Changelog

All notable changes to this skill bundle.

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
