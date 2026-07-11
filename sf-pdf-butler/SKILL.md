---
name: sf-pdf-butler
description: >
  Salesforce PDF generation with the PDF Butler AppExchange package (namespace
  `cadmus_core`). Use when building, invoking, or troubleshooting DocConfigs,
  Packs, Actionables, the Apex Convert API (`ConvertController`,
  `DocumentDataHandler`, `PdfActions` for page numbers/title/watermark,
  `MetadataWrapper` for runtime stage/locale/Agentforce detection,
  `CadmusParameters` typed variables, `PdfButlerCallable` cross-package
  dispatch, `CadmusHttpCalloutMock` for unit tests), Flow actions for
  DOCX→PDF, DataSources (SINGLE, LIST, KEYVALUE, Report, Full SOQL Power,
  etc.), ConfigTypes (Table, Criteria, Picture, Conditional Sections, etc.),
  DocConfig output types (Word/PDF, Excel, PowerPoint, CSV, PDF Form Filler,
  Static PDF, Table Column Remover, Email, Template Word), Lightning
  components (Convertor, Previewer, Inline Edit), CPQ/FSL/Peppol/Service
  Cloud/Experience Cloud integrations, deployment via Migration Wizard or
  the `@pdfbutler/migration-cli` sf CLI plugin (10 commands: DocConfig/Pack/
  DataSource/SignTemplate export/import, adminsettings, admincredentials),
  multi-language/ multi-locale output, and the heap-size-safe "Handle Files
  Via API" pattern.
license: MIT
metadata:
  version: "0.5.0"
  author: "Charlie Lang"
  sources:
    - "https://www.pdfbutler.com/academy/pdf-butler-academy/"
    - "https://eu1.pdfbutler.com/files/api/cadmuscore/"
    - "https://www.npmjs.com/package/@pdfbutler/migration-cli"
---

# PDF Butler skill

Developer + admin reference for **PDF Butler** (`cadmus_core` managed package) — Salesforce's most complete document-generation toolkit. This file is a **lean index**; details live in `reference/*.md` files — read them when the user's task matches a section below.

## When to trigger this skill

Any of:
- User mentions **PDF Butler**, **DocConfig**, **Pack**, **Actionable**, **`cadmus_core`**, **SIGN Butler**, **FORM Butler**, **Peppol Invoicing**.
- Request shape: "generate a PDF from this record", "build a quote document", "call the PDF template from Apex/Flow/LWC", "merge files in a PDF Butler pack", "migrate DocConfigs to prod".
- Troubleshooting: heap-size errors on merges, Flow DOCX→PDF returning nothing, missing fonts, Arabic/RTL render, email going to spam, scratch-org setup.

## Core concept map

| Thing | What it is | SObject (when relevant) |
|---|---|---|
| **DocConfig** | Template definition — bound to an object, holds Configs + DataSources | `cadmus_core__DocConfig__c` |
| **Config** | One element on the template (text, table, picture, criteria) — has a ConfigType | child record of DocConfig |
| **DataSource** | Declarative data fetch — SOQL, list, report, pictures, key-value, etc. | child record of DocConfig |
| **Pack** | Ordered bundle of DocConfigs + Actionables → multi-doc run | `cadmus_core__Pack__c` |
| **Actionable** | Side-effect step (email / sign / run Apex / add file) around a generation | `cadmus_core__Actionable__c` |
| **Alternative** | Named variant of a DocConfig (language/brand) | selected via `cdm.alternativeName` |

Always establish up front: is the user working with a **single DocConfig** or a **Pack**?

## The one Apex pattern

```apex
cadmus_core.ConvertController.ConvertDataModel cdm =
    new cadmus_core.ConvertController.ConvertDataModel();
cdm.objectId    = recordId;             // the record the template runs against
cdm.docConfigId = 'a05XXXXXXXXXXXXXXX'; // OR cdm.packId for a Pack
// optional: cdm.locale, cdm.alternativeName, cdm.inputMap, cdm.targetType, ...
cadmus_core.DocGenerationWrapper w =
    cadmus_core.ConvertController.convertWithWrapper(cdm);
Blob   bytes = w.response.base64;          // Blob, not a base64 string
String name  = w.response.metadata.targetName;
```

`wrapper.response.base64` is a **Blob**. Returning to LWC: `EncodingUtil.base64Encode(w.response.base64)`. Returning empty bytes despite no exception → inspect `w.response.metadata` for server-side error text. Full API surface in [reference/automation.md](reference/automation.md).

## Decision tree — read the right reference

Based on the user's task, read the matching file. They're all under `reference/` in this skill's directory.

| User task / intent | Open |
|---|---|
| Picking the DocConfig **output type** (Main Word PDF, Template Word, Excel, Static PDF, Table Column Remover, Email, PDF Form Filler, CSV, PPTX) | [reference/doc-config-types.md](reference/doc-config-types.md) |
| Writing Apex that calls PDF Butler (`ConvertController`, `DocumentDataHandler`, `PdfActions`, `MetadataWrapper`, `CadmusParameters`, Abstract* interfaces), **unit testing with `CadmusHttpCalloutMock`**, **cross-package `PdfButlerCallable` dispatch**, LWC/Aura examples, Flow invocable wrappers, REST URL map, Permission Set Groups | [reference/automation.md](reference/automation.md) |
| Building or debugging a Pack, wiring an Actionable (email, SIGN, DocuSign, AdobeSign, Run Apex, Thumbnail, Image-by-URL, Chart), Flow action DOCX→PDF | [reference/packs-actionables.md](reference/packs-actionables.md) |
| Choosing or editing a ConfigType (Single, Table, Paragraph, Criteria, Picture, Form_Checkbox, Color_Cell, Document_V3, etc.) | [reference/configtypes.md](reference/configtypes.md) |
| Choosing or editing a DataSource (Single, List, SOQL Builder, Full SOQL Power, Picture, KeyValue, Report, Nested, Late Binding, Picklist Translations) | [reference/datasources.md](reference/datasources.md) |
| Placing a Lightning component on a FlexiPage (Convertor, Previewer, Inline Edit, Document Selector, Dynamic Selector, Classic Button) | [reference/components.md](reference/components.md) |
| Template cookbook: checkboxes, watermarks, auto-numbering, PDF/A, approval history, multiselect picklists, conditional formatting, track changes, embedded fonts, dynamic passwords, etc. | [reference/tips.md](reference/tips.md) |
| Multi-language / multi-brand / multi-currency output, Alternatives, locale formatting, picklist translations, CPQ product translations | [reference/i18n.md](reference/i18n.md) |
| Salesforce CPQ, Field Service (FSL), Peppol invoicing, **Service Cloud / Knowledge case articles, Experience Cloud (Community) setup** | [reference/integrations.md](reference/integrations.md) |
| Moving DocConfigs / Packs / DataSources / SIGN Butler templates between orgs (Migration Wizard UI; `@pdfbutler/migration-cli` sf-plugin with all 10 commands, both auth modes, REST-endpoint map, CI/CD session auth, new-org bootstrap; Backup/Restore; Stage mapping) | [reference/deployment.md](reference/deployment.md) |
| Error messages / FAQs / licensing / scratch orgs / S3 storage / template best practices / Get Started walkthrough | [reference/faq.md](reference/faq.md) |

Don't dump reference content — only read the file you need. If a user's question spans two areas, read both files before answering.

## Post-install setup — detect first, then fix

**Never run setup steps blindly.** Always detect what's already in place and skip whatever's done. Run this sequence top-to-bottom when a user asks "is PDF Butler set up?" or "install PDF Butler in this org". Substitute `-o <alias>` with the target org alias.

### Step 0 — Is the package installed?

```bash
sf package installed list -o <alias> --json | \
  jq '.result[] | select(.SubscriberPackageNamespace=="cadmus_core")'
```

Empty → install via AppExchange / `sf package install --package <04t...>`.

### Step 1 — Is registration complete?

```apex
for (cadmus_core__CadmusSettings__c s :
     [SELECT Name, cadmus_core__Username__c, cadmus_core__Stage__c
      FROM cadmus_core__CadmusSettings__c]) {
    System.debug(s);
}
```

*(Setting object may be `cadmus_core__Cadmus_Settings__c` on older versions.)*

No row / null username → open **PDF Butler Admin** tab, paste ADMIN + USER credentials from the registration email. Tenant-wide creds — **reuse across every org**.

### Step 2 — Is the Stage set?

Same custom setting, `cadmus_core__Stage__c` field. Valid: `PROD`, `UAT`, `TEST`, `TRG`, `STAGING`, `INT`, `QA`, `DEMO`, `DEV1`–`DEV20`. Wrong Stage = broken record-ID references after imports. Cross-check org type:

```bash
sf data query -o <alias> -q "SELECT IsSandbox, OrganizationType FROM Organization" --json
```

### Step 3 — Is the callout endpoint trusted?

```bash
sf data query -o <alias> -t \
  -q "SELECT MasterLabel, EndpointUrl, IsActive FROM RemoteSiteSetting WHERE EndpointUrl LIKE '%pdfbutler.com%'" --json
sf data query -o <alias> -t \
  -q "SELECT DeveloperName, Endpoint FROM NamedCredential WHERE Endpoint LIKE '%pdfbutler.com%'" --json
```

Expect at least one active entry for the region — `eu1.pdfbutler.com`, `us1.pdfbutler.com`, or `au1.pdfbutler.com`.

### Step 4 — Are permission sets assigned?

```bash
sf data query -o <alias> -q \
  "SELECT Name, Label FROM PermissionSet WHERE NamespacePrefix='cadmus_core'" --json
sf data query -o <alias> -q \
  "SELECT PermissionSet.Name, Assignee.Username FROM PermissionSetAssignment
   WHERE PermissionSet.NamespacePrefix='cadmus_core'" --json
```

Wrap into **Admin PSG** (template builders) + **User PSG** (end users) per PDF Butler guidance — don't clone package permsets.

### Step 5 — Are there any DocConfigs yet?

```bash
sf data query -o <alias> -q "SELECT COUNT() FROM cadmus_core__DocConfig__c" --json
```

If 0 → fresh install, use Migration Wizard or SF CLI (see [reference/deployment.md](reference/deployment.md)). If > 0 → confirm Stage mapping before assuming they work.

### Step 6 — Smoke test

```apex
cadmus_core.ConvertController.ConvertDataModel cdm =
    new cadmus_core.ConvertController.ConvertDataModel();
cdm.objectId    = '<real record id>';
cdm.docConfigId = '<existing DocConfig id>';
cadmus_core.DocGenerationWrapper w =
    cadmus_core.ConvertController.convertWithWrapper(cdm);
System.debug('Bytes: ' + (w.response?.base64 == null ? 0 : w.response.base64.size()));
System.debug('Name:  ' + w.response?.metadata?.targetName);
```

Failure → step mapping:

| Failure | Step to fix |
|---|---|
| `Unauthorized endpoint` | Step 3 (RSS / NC) |
| `AuthenticationException` / 401 | Step 1–2 (registration / stage) |
| `INSUFFICIENT_ACCESS_OR_READONLY` | Step 4 (permsets) |
| Null `response.base64` but no exception | DocConfig exists but DataSource fails — inspect `response.metadata` for error text |

### Scratch org caveat

PDF Butler's config UI fails inside VSCode-launched scratch orgs ("Your browsing session has ended" / Canvas errors). Workaround: generate a scratch org password and open the config via browser. For CI, use a persistent dev sandbox instead of per-PR scratch orgs. Detail in [reference/faq.md](reference/faq.md).

## Reporting pattern

When a user says "set up PDF Butler" or "check the install", run Steps 0–5 and report one line per step (`✓` / `✗` + reason) BEFORE touching anything. Do not propose fixes for steps that are already ✓.

## Top failure-mode → fix lookup

| Symptom | Root cause | Deep dive |
|---|---|---|
| `Apex heap size too large` during multi-file merge | `addDynamicFile` holds content in heap | [reference/automation.md](reference/automation.md) → Handle Files Via API + `addDynamicFileWithoutContent` |
| Flow action "Convert a DOCX to PDF" produces no file | Trigger context without `Run Async = true` | [reference/packs-actionables.md](reference/packs-actionables.md) → Flow action async semantics |
| LWC gets `[object Blob]` | Missing `EncodingUtil.base64Encode` | [reference/automation.md](reference/automation.md) → LWC Quick Action example |
| Text truncated at `:` or `\|` from Flow | Reserved chars | Wrap formula value in `URLENCODE()` |
| Import fails / references wrong IDs | Wrong Stage on target org | [reference/deployment.md](reference/deployment.md) → Stage mapping |
| Emails in spam | SPF / DKIM missing | [reference/faq.md](reference/faq.md) → Email deliverability |
| Config screen → redirect to Home | Third-party cookies blocked | [reference/faq.md](reference/faq.md) |
| "Argument 1 cannot be null" | Protected Custom Settings permission not auto-assigned | [reference/faq.md](reference/faq.md) |

## Hard rules

- **Always use `convertWithWrapper`** for new Apex, not deprecated `convertToPdf` / `convertToDocx`.
- **Don't clone package permission sets.** Wrap them in PSGs.
- **Reserved chars** in Flow-sourced DataSource values: `:` and `|`. Wrap with `URLENCODE()` in Flow formulas.
- **Before adding fonts, check supported list** ([reference/faq.md](reference/faq.md) → template best practices). Adobe fonts and OTF files require support intervention.
- **DocConfig filename templating** uses `[[!NAME!]]` only inside the Document Title field — NOT a general merge syntax.
- **Test with real record IDs in anonymous Apex** before assuming a config is broken. `wrapper.response.metadata` often surfaces errors that don't hit debug logs.

## Non-PDF-Butler dependencies

- **SIGN Butler V2** (`cadmus_sign2`) — sister package for native e-signature Actionables. Covered by the sibling skill [sf-sign-butler](../sf-sign-butler/SKILL.md).
- **BULK Butler** (`cadmus_batch`) — mass-generation sibling. Covered by [sf-bulk-butler](../sf-bulk-butler/SKILL.md).
- **FORM Butler** — sister package for embedded fillable forms (used by FSL). No dedicated skill yet.
- **Collaboration Butler** (`cadmus_una`) — required for SharePoint image retrieval. No dedicated skill yet.
- **Peppol Invoicing** package — installs on top of PDF Butler for e-invoicing. Covered in `reference/integrations.md`.

Each has its own Academy/docs — this skill covers PDF Butler proper.

## Model Routing — Fable 5 First

This skill is orchestrated by Claude Fable 5 (`claude-fable-5`) as the session model. Keep judgment in the Fable session: requirement analysis, architecture decisions, and final review. Delegate self-contained subtasks via the Agent tool `model` param: `opus` (Claude Opus 4.8) is the DEFAULT tier for delegated work, `sonnet` ONLY when the task is genuinely basic (simple lookups, boilerplate), `haiku` for purely mechanical bulk. Do not spawn a subagent for work completable directly in a single response. Prompting reference: `~/.claude/skills/prompting-fable-opus/SKILL.md`.


## Ultracode micro-task mode

If the user's prompt contains the keyword `ultracode` (or the common typo `untracode`), do NOT work the items sequentially: follow the `ultracode-micro` skill and fan the work out as parallel micro-task agents via the Workflow tool (script: `~/.claude/skills/ultracode-micro/workflows/micro-tasks.js`).

- **Fan-out unit for this skill:** one agent per DocConfig or DataSource being built/migrated
- Keep file sets disjoint across agents; default tier `opus` — drop to `sonnet` only when the unit is genuinely basic, `haiku` for purely mechanical bulk stamps.
- If the user asks for cross-AI checking or a Claude+Codex fleet, pass `crossCheck: true` so each result gets an independent Codex review.
- Fewer than 3 independent units → say inline is cheaper and just do the work directly.
- Without the keyword this section does not apply — follow the lean defaults in CLAUDE.md.


## Autonomous web research

Whenever knowledge could be stale or incomplete, look online WITHOUT being asked — verify before you build. Default triggers: version-specific behavior (Spring/Summer '26+), unfamiliar errors, design decisions, "best practice" or coding-pattern questions, and before writing any non-trivial pattern from scratch — search GitHub for a proven implementation first.

- **First sources for this skill:** PDF Butler docs/knowledge base (pdfbutler.com), AppExchange listing changelog
- Keep it inline and lightweight: 1-3 targeted WebSearch/WebFetch calls — NOT research agents.
- Check this skill's bundled references first; the web is for what they don't cover or what may have changed since.
- State what you verified and where it came from. If current docs contradict this skill's content, the docs win — say so and offer to update the skill.


## Working discipline

- **Docs are autonomous:** when work under this skill changes behavior or adds artifacts, update the relevant documentation in the same pass (ApexDoc/JSDoc headers, module README/CHANGELOG, .planning SUMMARY where present) — without being asked.
- **Keep context low:** Grep before Read, read targeted line ranges not whole files, delegate bulk multi-file reading to subagents (or the Gemini satellite pass) and keep only conclusions. Subagents return condensed summaries, never raw file dumps.
- **Self-improve:** when work under this skill goes wrong and gets fixed (user correction, failed deploy/test traced to guidance here, stale content), append one JSON line to `~/.claude/ultracode-micro/runs.jsonl`: `{"ts":"<ISO>","source":"sf-skill","skill":"<this skill>","lesson":"<one sentence>"}` — and grep that log for this skill's lessons before substantive work. If the same lesson already exists, edit this skill to fix the root cause instead, then suggest `/pack-build`.
