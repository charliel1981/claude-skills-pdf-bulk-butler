---
name: sf-bulk-butler
description: >
  Salesforce bulk document generation with the BULK Butler AppExchange package
  (namespace `cadmus_batch`). Sits on top of PDF Butler — use when generating
  documents for many records in one go (scheduled cron, Apex-launched, or
  Flow-triggered batches). Covers Batch Info record config, per-record
  Actionables, launching from Apex or Flow, report-driven batches with optional
  SharePoint save, and the Batch Backend high-throughput add-on.
license: MIT
metadata:
  version: "0.3.0"
  author: "Charlie Lang"
  sibling_skills:
    - "sf-pdf-butler (required — BULK Butler runs PDF Butler DocConfigs/Packs in a loop)"
  sources:
    - "https://www.pdfbutler.com/academy/bulk-butler-academy/"
    - "https://eu1.pdfbutler.com/files/api/cadmusbatch/"
---

# BULK Butler skill

Bulk-generate PDFs/DOCX from many Salesforce records at once. Runs **on top of PDF Butler** — it iterates records and calls the same DocConfig/Pack you'd use for single generation.

## Data-governance preflight

Before scheduling or launching a batch:

- **SOQL scope** — Batch Info `SOQL`/`Count SOQL` must match exactly; review WHERE clauses so you don't sweep records the business didn't intend (e.g., all Accounts vs a segment).
- **Volume limits** — non-prod caps at 25 records; prod batches can email many stakeholders — confirm `Emails` recipients and `Delivery Option` align with data-handling policy.
- **PII in output** — each generated doc may contain fields from the underlying record; validate DocConfig DataSources against least-privilege field access.
- **Audit trail** — job status emails and generated files are evidence of processing; align retention with compliance requirements before enabling cron schedules.

## When to trigger

- User mentions **BULK Butler**, **Batch Info**, **`cadmus_batch`**, scheduled document generation, bulk PDF, mass document run.
- Request shapes: "generate a quote for every open opportunity nightly", "run this DocConfig for all records in a report", "email a statement to every customer monthly", "launch PDF Butler in a batch".
- Troubleshooting: batches timing out, Actionables not firing per record, missing Flow variables, scaling past 50 docs/run.

## Dependencies

- **PDF Butler** managed package — MUST be installed first (BULK Butler calls it)
- Same PDF Butler tenant credentials reused
- Optional: **Collaboration Butler** (`cadmus_una`) for SharePoint delivery
- Optional: **Batch Backend** add-on for high-throughput (see bottom)

## The Batch Info record — core config

BULK Butler drives everything from a **Batch Info** record. Every batch run, scheduled or ad-hoc, references one of these. Labels below are verbatim from the [Initial Setup Academy page](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/bulk-butler-initial-setup/).

| Field | Purpose |
|---|---|
| **Name** | Name of the Batch Info record |
| **Cron** | Salesforce-supported Cron expression. For manual / Apex-triggered runs, put `NA` as the value. |
| **SOQL** | Query returning the records to iterate |
| **Count SOQL** | Same query as SOQL but counting rows, e.g. `SELECT Count() FROM Account`. Required for Batch Backend; the row count from Count SOQL must match the SOQL row count (WHERE and LIMIT clauses must match). |
| **Emails** | **Comma-separated** list of email recipients for the job status email |
| **Doc Config** | Lookup to the DocConfig to run per record. Empty → Pack is required. |
| **Pack** | Lookup to the Pack to run per record. Empty → DocConfig is required. |
| **Batch Apex Class** | An Apex class implementing `cadmus_batch.Batch_ICadmusBatch`. See the Academy page's attached PDF for the interface. |
| **Batch Size** | Records per chunk. Academy says: "A good size is 5", but **must be set to 1** when the DocConfig / Pack itself has Actionables (SFDC governor limits). The Run Actionables Academy page explicitly uses Batch Size = 20 in an example with Batch-Info-level Run Actionables — so the size-1 constraint applies to **DocConfig/Pack-level** Actionables only, not to Run Actionables. |
| **Delivery Option** | Determines how the generated document is saved related to the record. Valid values (verbatim): `ATTACHMENTS`, `ATTACHMENTS_OVERWRITE`, `FILES`, `FILES_OVERWRITE`, `FILES_ADD_VERSION`, `BASE64`, `Use DocConfig Setting`. (`Use DocConfig Setting` requires Batch Size = 1.) |
| **Alternative API Field** | API name of a field on the SOQL's root SObject whose value is used as the Alternative per record. **Must be directly on the SObject** — cannot be a lookup-traversed field. |
| **Locale API Field** | Same shape — field on the root SObject providing the per-record locale. |
| **Currency Locale API Field** | Field on the root SObject providing the per-record currency/locale. |
| **Target Type** | `PDF` (default) or `DOCX` — same semantics as `ConvertController.ConvertDataModel.targetType` on the PDF Butler side. |

**Non-prod limit (verbatim from the Academy)**: "On non-PROD Orgs, a batch can maximum run 25 records. Make sure to use the "LIMIT" keyword in your SOQL and Count SOQL".

**Key design choice**: put Actionables on the **Batch Info** as **Run Actionables** (via the `Run From Batch Info` lookup — see below), not on the DocConfig/Pack itself. Reason: when the DocConfig/Pack has its own Actionables, BULK Butler forces Batch Size = 1 to stay within governor limits. Run Actionables on the Batch Info run once per successful doc without the size-1 penalty, so Batch Size can stay at 5–20.

_Source: [BULK Butler – Initial Setup](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/bulk-butler-initial-setup/)._

## Launching a batch

Three entry points. Pick based on trigger context.

### 1. Schedule (cron)

Set `Cron` on the Batch Info → call `schedulebatchMethod` once to register:

```apex
cadmus_batch.Batch_ProcessController.schedulebatchMethod('a0XYZ...');  // Batch Info Id
```

The batch then fires automatically per the cron expression. Re-run `schedulebatchMethod` to refresh the schedule after editing the cron.

### 2. Apex (immediate, programmatic)

```apex
// Simple: fire the configured SOQL against current data
cadmus_batch.Batch_ProcessController.startBatch('a0XYZ...');

// With variables for the Batch Info's SOQL bindings
Map<String, Object> inputMap = new Map<String, Object>{
    'region' => 'EU',
    'asOfDate' => Date.today()
};
cadmus_batch.Batch_ProcessController.startBatch('a0XYZ...', inputMap);
```

The `inputMap` values are injected into the Batch Info's SOQL via bind variables (same mechanism as PDF Butler's `inputMap`). Use for parameterised runs.

### 3. Flow / Screen Flow

Invocable action surfaces on both overloads of `startBatch`. Typical pattern:

- Screen Flow captures filters from the user → passes to `inputMap`
- `Launch Batch` invocable action → fires BULK Butler
- Flow variables (documented by PDF Butler in linked video tutorials) cover: `batchInfoId` input, and ID-list pass-through for batches driven by a Lightning Convert Component record-selection step

_The full Flow Introduced Variables inventory is a [video-only Academy page](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/bulk-butler-flow-introduced-variables-2/) — confirm the exact variable set in-org (build a Screen Flow referencing the Launch Batch invocable and inspect the input/output variables surfaced by the Flow Builder)._

### `Batch_ProcessController` — full API

| Method | Signature |
|---|---|
| `schedulebatchMethod` | `@AuraEnabled webService static void schedulebatchMethod(Id batchInfoId)` |
| `startBatch` | `@AuraEnabled webService static void startBatch(Id batchInfoId)` |
| `startBatch` (overload) | `global static void startBatch(Id batchInfoId, Map<String, Object> inputMap)` |

All three are void — BULK Butler runs async, so status comes via the email notification list and/or Run Actionables. Don't expect a sync return value.

_The [Launch batch from APEX Academy page](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/bulk-butler-launch-batch-from-apex-2/) is video-only — these signatures are sourced from the `cadmusbatch` API reference at [eu1.pdfbutler.com/files/api/cadmusbatch/](https://eu1.pdfbutler.com/files/api/cadmusbatch/)._

---

## Run Actionables per record

**Purpose**: fire side-effects (email the doc, update the record, call a Flow, sign via SIGN Butler) once per successfully generated document, without collapsing Batch Size to 1.

**Setup**:
1. Add the **`Run From Batch Info`** lookup field to the target Actionable record type's Page Layout. (Field name is verbatim — the lookup on the Actionable record points back to a Batch Info.)
2. Create an Actionable record referencing the Batch Info via that lookup.
3. Multiple Run Actionables execute **ordered by Name**. Use naming conventions like `10_UpdateRecord`, `20_SendEmail` to control execution order.

**Flow Actionable requirement**: the target Flow must declare an **INPUT variable named `batchInfoId`** (Text). BULK Butler passes the Batch Info Id so the Flow knows which run it's operating within. Academy verbatim: "The Batch Info Id parameter will also be passed on to the flow." If your Flow also needs per-record context, the post-generation hooks from PDF Butler still apply — see `AfterActionableFlow_Info` in the sf-pdf-butler skill.

**Performance rule**: the Academy example uses **Batch Size 20** with a "Run Flow" Run Actionable — so Run Actionables do NOT force Batch Size = 1. The size-1 rule applies only when the DocConfig/Pack itself carries an Actionable. "An optimal Batch Size is mostly 5 or 10."

_Source: [BULK Butler – Run Actionables for each record](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/bulk-butler-launch-actionables-for-each-document-2/) (video + prose)._

---

## Report-driven batches

For admin-friendly "run this DocConfig for every row in a report" workflows. The Academy publishes full code samples.

**Components**:
1. **Salesforce Report** (tabular). Academy verbatim: "Make sure to add Opportunity Id in the first column, so that Apex class can recognize all the Ids for which Bulk Butler want to generate the document." First column MUST be the record Id.
2. **Batch Info record** with `Delivery Option = BASE64` (required when saving to SharePoint).
3. **Apex class** `GetReportRecordsAndLaunchBatch` (verbatim) — exposes an `@InvocableMethod` with `label='Call Bulk Butler Batch Class'` and an inner wrapper class `flowinputs` carrying `@InvocableVariable(label='Batch Info Id') public String batchInfoId;` and `@InvocableVariable(label='Report Name') public String reportName;`. Test class: `GetReportRecordsAndLaunchBatchTest` (`@isTest(SeeAllData=true)`).
4. **Screen Flow** prompting for Report Name → calls the invocable.
5. **Button** on the Batch Info object triggering the Screen Flow.

**The Reports API calls** inside `GetReportRecordsAndLaunchBatch` (verbatim from Academy):

```apex
Report rep = [SELECT Id FROM Report
              WHERE DeveloperName = :reportApiName OR Name = :reportApiName];
Reports.reportResults results = Reports.ReportManager.runReport(rep.Id, true);
Reports.ReportMetadata rm     = results.getReportMetadata();
String factMapKey = 'T!T';
Reports.ReportFactWithDetails factDetails =
    (Reports.ReportFactWithDetails) results.getFactMap().get(factMapKey);
for (Reports.ReportDetailRow detailRow : factDetails.getRows()) {
    Reports.ReportDataCell cell = detailRow.getDataCells()[0];
    recordIds.add(cell.getLabel());
}
Map<String, Object> inputMap = new Map<String, Object>();
inputMap.put('recordIds', recordIds);
if (!Test.isRunningTest()) {
    cadmus_batch.Batch_ProcessController.startBatch(batchInfoId, inputMap);
}
```

Academy verbatim: "The Apex class passes the `recordIds` variable to the SOQL and Count SOQL fields."

### SharePoint delivery (optional)

Add a Run Actionable with Record Type `Upload To SharePoint` that calls **`cadmus_una.Actionable_CollabStoreFile`** (from Collaboration Butler). It pushes each generated doc into a SharePoint library + folder. Requires Collaboration Butler fully configured — see SharePoint section in sf-pdf-butler skill.

_Source: [Bulk Document Creation from a Salesforce Report](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/bulk-butler-bulk-doc-creation-from-a-salesforce-report-with-optional-saving-to-sharepoint-folder/)._

---

## Batch Backend (high-throughput add-on)

Separately licensed. Academy verbatim: "In general, any batch bigger then 50 documents should be done via Batch Backend." [sic — "bigger then"]

**What it adds** (verbatim):

- "Much faster processing"
- "more scalable"
- "better error handling"
- "can generate a merged PDF or ZIP file"
- "Is the future of Batch processing in PDF Butler so main innovations will come to this platform"

**Opt-in steps** (Academy, in order):

1. **BULK Butler Admin tab** → "Enter the PDF Butler Username and password"
2. "Check the Addendum agreement and register" (single checkbox + register button — not a separate acceptance step)
3. "Contact PDF Butler Support to make sure you have the License for BULK generation via Batch Backend"
4. Assign Permission Set **`PDF Butler Batch`** to each User that requires to use the batch

**Batch Info config for Batch Backend** — create a Batch Info with **`RecordType = "Batch Backend"`** (verbatim). Fields on this record type:

| Field | Value / note |
|---|---|
| `Cron` | Schedule your jobs weekly, monthly, … |
| `SOQL` | SOQL that selects the records to process |
| `Count SOQL` | Same SOQL but with `Count()` only. Row count must equal the SOQL row count — WHERE/LIMIT clauses must match. |
| `DocConfig` / `Pack` | Documents to generate. **AFTER Actionables on the DocConfig/Pack will be IGNORED**; only BEFORE and BEFORE_BUT_AFTER_DATASOURCES Actionables are respected in Batch Backend. |
| `BatchSize` | Academy: "set to 100" |
| `Delivery Type` | **(distinct from `Delivery Option` on standard Batch Info)**. `BASE64` (don't save to record) or `FILES` (don't save — Academy phrasing is ambiguous/typo; verify in-org). |
| `Alternative / Locale / Currency Locale API fields` | Field on the record that sets per-record values. Cannot be a field through a Lookup. **Must be added to the SOQL.** |

**Merging / zipping — Record Type `Batch Backend Action`** (optional AFTER Actionable on the Batch Info):

| Field | Purpose |
|---|---|
| `Backend Batch Action` | `MERGED_PDF` — merge all PDFs into one file; `ZIP_FILE` — zip all PDFs. |
| `Active` | Must be checked or the Actionable is ignored. |
| `No Unique Id Per File` | If checked, you must guarantee each PDF has a unique name via the DocConfig Title — else same-name files overwrite. Unchecked = BULK Butler appends a unique Id to each filename. |
| `Batch Backend Upload Action` | Optional — for storing merged PDFs / ZIPs in SharePoint. Uses `cadmus_una.Actionable_GetUploadSession` (Collaboration Butler). Leave empty to store in Salesforce Files linked to the Batch Run record. **Only SharePoint via Collaboration Butler is supported** at time of Academy writing. |

**Standard AFTER Actionables** (PDF Butler / SIGN Butler / COLLABORATION Butler / custom): "Just create the Actionable on the BatchInfo as you would normally do on a DocConfig or Pack."

**Limits (verbatim)**:

- Merged PDF: "If more then 1000 records, each merged PDF will have max 1000 records and there will be multiple merged PDFs" [sic — "then"]
- ZIP: same 1000-record cap per archive.
- Non-PROD orgs: batch maximum 25 records (applies to the standard path too — use `LIMIT` in SOQL + Count SOQL).

_Source: [Batch Backend – Faster processing, More Options](https://www.pdfbutler.com/academy/bulk-butler-academy/bulk-butler/batch-backend-faster-processing-more-options/)._

---

## Typical failure modes

| Symptom | Root cause | Fix |
|---|---|---|
| Batch runs but no Actionables fire | `Run From Batch Info` lookup not on Actionable's page layout | Add the lookup field to the Page Layout |
| Flow Actionable errors on input | Flow missing `batchInfoId` INPUT variable | Add `batchInfoId` (Text) as an Input Variable in the Flow |
| Batch Size = 1 forced | DocConfig/Pack has its own Actionables | Move Actionables to Batch Info level instead |
| `CPU_TIME_EXCEEDED` or governor limit hits | Batch Size too high for heavy DocConfig | Drop to 5, or enable Batch Backend for >50 records |
| Report-driven batch hits no records | Report first column isn't Record Id | Reorder report columns |
| Scheduled batch stopped firing | Cron overwritten without re-calling `schedulebatchMethod` | Edit cron → call `schedulebatchMethod` again |
| Need per-record locale but all docs render in same language | `Locale Field API Name` not set on Batch Info | Point it at a field on the iterated record |

---

## Post-install setup

Same shape as PDF Butler's idempotent check. Substitute `-o <alias>`.

### Step 0 — Package installed?

```bash
sf package installed list -o <alias> --json | \
  jq '.result[] | select(.SubscriberPackageNamespace=="cadmus_batch")'
```

### Step 1 — PDF Butler registered first?

BULK Butler can't operate without PDF Butler. Verify PDF Butler is registered (see sf-pdf-butler skill → Post-install Step 1).

### Step 2 — BULK Butler tenant credentials entered?

BULK Butler Admin tab → paste PDF Butler credentials (same ones from the registration email). Use same Stage as the PDF Butler side.

### Step 3 — Permission sets assigned?

```bash
sf data query -o <alias> -q \
  "SELECT Name, Label FROM PermissionSet WHERE NamespacePrefix='cadmus_batch'" --json
```

Expect `cadmus_batch__*` permsets. Also needed: `PDF Butler Batch` (for Batch Backend users only).

### Step 4 — Smoke test

Create a throwaway Batch Info pointing at a known-good DocConfig + a SOQL returning 1–2 records. Call:

```apex
cadmus_batch.Batch_ProcessController.startBatch('<batchInfoId>');
```

Watch the Email notification + check generated Files on each source record. If nothing generates, inspect PDF Butler's own logs — BULK Butler delegates to PDF Butler, so errors surface there.

---

## Companion skill

This skill is a thin layer on top of [sf-pdf-butler](../sf-pdf-butler/SKILL.md). Always have both active when working on bulk document generation — BULK Butler handles iteration and scheduling, PDF Butler handles the actual render per record.

## Scheduling — recurring batches (optional)

Keep two scheduling layers separate:
- **In-org (Salesforce-side):** schedule the batch itself with the Apex Scheduler — `System.schedule('<name>', '<cron>', new <Schedulable>())` — so it runs whether or not Claude is open. This is the right home for production recurring document runs.
- **Claude-side:** for recurring *agent* work (launch a Batch Info run, poll status, summarise failures) use a scheduled task — `CronCreate`/`CronList`/`CronDelete`, or `/loop` for in-session polling (verified at code.claude.com/docs/en/scheduled-tasks.md). Recurring Claude tasks expire after **7 days**, so use the in-org scheduler for anything permanent.

## Model Routing — Opus 5 First

This skill is orchestrated by Claude Opus 5 (`claude-opus-5`) as the session model. Keep judgment in the main session: requirement analysis, architecture decisions, and final review. Delegate self-contained subtasks via the Agent tool `model` param: `opus` (Claude Opus 5) is the DEFAULT tier for delegated work, `sonnet` ONLY when the task is genuinely basic (simple lookups, boilerplate), `haiku` for purely mechanical bulk. **Opus 5 delegates eagerly — cap it.** Do not spawn a subagent for work you can finish in a handful of tool calls, and never to verify your own work. Prompting reference: `~/.claude/skills/prompting-opus-5/SKILL.md`.


## Ultracode micro-task mode

If the user's prompt contains the keyword `ultracode` (or the common typo `untracode`), do NOT work the items sequentially: follow the `ultracode-micro` skill and fan the work out as parallel micro-task agents via the Workflow tool (script: `~/.claude/skills/ultracode-micro/workflows/micro-tasks.js`).

- **Fan-out unit for this skill:** one agent per Batch Info configuration
- Keep file sets disjoint across agents; default tier `opus` — drop to `sonnet` only when the unit is genuinely basic, `haiku` for purely mechanical bulk stamps.
- If the user asks for cross-AI checking or a Claude+Codex fleet, pass `crossCheck: true` so each result gets an independent Codex review.
- Fewer than 3 independent units → say inline is cheaper and just do the work directly.
- Without the keyword this section does not apply — follow the lean defaults in CLAUDE.md.


## Autonomous web research

Whenever knowledge could be stale or incomplete, look online WITHOUT being asked — verify before you build. Default triggers: version-specific behavior (Spring/Summer '26+), unfamiliar errors, design decisions, "best practice" or coding-pattern questions, and before writing any non-trivial pattern from scratch — search GitHub for a proven implementation first.

- **First sources for this skill:** BULK Butler docs (pdfbutler.com), PDF Butler knowledge base
- Keep it inline and lightweight: 1-3 targeted WebSearch/WebFetch calls — NOT research agents.
- Check this skill's bundled references first; the web is for what they don't cover or what may have changed since.
- State what you verified and where it came from. If current docs contradict this skill's content, the docs win — say so and offer to update the skill.


## Working discipline

- **Docs are autonomous:** when work under this skill changes behavior or adds artifacts, update the relevant documentation in the same pass (ApexDoc/JSDoc headers, module README/CHANGELOG, .planning SUMMARY where present) — without being asked.
- **Keep context low:** Grep before Read, read targeted line ranges not whole files, delegate bulk multi-file reading to subagents (or the Gemini satellite pass) and keep only conclusions. Subagents return condensed summaries, never raw file dumps.
- **Self-improve:** when work under this skill goes wrong and gets fixed (user correction, failed deploy/test traced to guidance here, stale content), append one JSON line to `~/.claude/ultracode-micro/runs.jsonl`: `{"ts":"<ISO>","source":"sf-skill","skill":"<this skill>","lesson":"<one sentence>"}` — and grep that log for this skill's lessons before substantive work. If the same lesson already exists, edit this skill to fix the root cause instead, then suggest `/pack-build`.
