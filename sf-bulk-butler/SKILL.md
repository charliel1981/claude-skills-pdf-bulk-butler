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
  version: "0.1.0"
  author: "Charlie Lang"
  sibling_skills:
    - "sf-pdf-butler (required — BULK Butler runs PDF Butler DocConfigs/Packs in a loop)"
  sources:
    - "https://www.pdfbutler.com/academy/bulk-butler-academy/"
    - "https://eu1.pdfbutler.com/files/api/cadmusbatch/"
---

# BULK Butler skill

Bulk-generate PDFs/DOCX from many Salesforce records at once. Runs **on top of PDF Butler** — it iterates records and calls the same DocConfig/Pack you'd use for single generation.

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

BULK Butler drives everything from a **Batch Info** record. Every batch run, scheduled or ad-hoc, references one of these.

| Field | Purpose |
|---|---|
| **Name** | Human label |
| **Cron** | Cron expression for scheduled runs, or `NA` for manual/Apex-triggered |
| **SOQL** | Query returning the records to iterate |
| **Emails** | Notification recipients on completion/failure (`;`-separated) |
| **Doc Config** / **Pack** | Which PDF Butler template to run per record |
| **Batch Size** | Records per chunk — **5 is default**, **1 if any Run-Actionable is configured** (per Actionable performance trade-off). Never set above 10 for safety. |
| **Delivery Option** | `Attachments`, `Files`, `Base64`, `Files_Async`, etc. (same set as PDF Butler's `deliveryOverwrite`) |
| **Locale Field API Name** / **Currency Field API Name** | Field on the iterated record supplying per-record locale/currency (so different records can render in different languages from the same batch) |
| **Target Type** | `PDF` or `DOCX` — same semantics as `ConvertDataModel.targetType` |

**Key design choice**: put Actionables on the **Batch Info**, not on the DocConfig/Pack. Reason: a batch of 1000 records with a Pack-level Actionable forces Batch Size = 1, which is slow. A Batch Info–level Actionable runs once per doc and keeps Batch Size at 5–10.

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

### `Batch_ProcessController` — full API

| Method | Signature |
|---|---|
| `schedulebatchMethod` | `@AuraEnabled webService static void schedulebatchMethod(Id batchInfoId)` |
| `startBatch` | `@AuraEnabled webService static void startBatch(Id batchInfoId)` |
| `startBatch` (overload) | `global static void startBatch(Id batchInfoId, Map<String, Object> inputMap)` |

All three are void — BULK Butler runs async, so status comes via the email notification list and/or Run Actionables. Don't expect a sync return value.

---

## Run Actionables per record

**Purpose**: fire side-effects (email the doc, update the record, call a Flow, sign via SIGN Butler) once per successfully generated document, without collapsing Batch Size to 1.

**Setup**:
1. Add the **"Run From Batch Info"** lookup field to the target Actionable record type's Page Layout.
2. Create an Actionable record referencing the Batch Info via that lookup.
3. Multiple Run Actionables execute **in alphabetical order by Name** — use naming conventions like `10_UpdateRecord`, `20_SendEmail` to control order.

**Flow Actionable requirement**: the target Flow must declare an **INPUT variable named `batchInfoId`** (Text). BULK Butler passes the Batch Info Id so the Flow knows which run it's operating within. If your Flow also needs per-record context, the post-generation hooks from PDF Butler still apply — see `AfterActionableFlow_Info` in the sf-pdf-butler skill.

**Performance rule**: Run Actionables per record (via Batch Info) are far cheaper than DocConfig/Pack-level Actionables in a batch, because Batch Size can stay at 5–10.

---

## Report-driven batches

For admin-friendly "run this DocConfig for every row in a report" workflows. Provided pattern:

**Components**:
1. **Salesforce Report** (**tabular**, like PDF Butler's Report DataSource) with **Record Id as the first column**
2. **Batch Info record** with Delivery Option = `BASE64`
3. **Apex class `GetReportRecordsAndLaunchBatch`** — invocable, reads the report, passes `recordIds` into SOQL/Count SOQL variables
4. **Screen Flow** prompting for Report Name → calls the invocable
5. **Button** on the Batch Info object triggering the Screen Flow

**Constraint**: report **first column MUST be the Id** — the Apex class literally reads column index 0 as the record Id.

### SharePoint delivery (optional)

Add a Run Actionable that calls **`cadmus_una.Actionable_CollabStoreFile`** (from Collaboration Butler). It pushes each generated doc into a SharePoint library + folder. Requires Collaboration Butler fully configured — see SharePoint section in sf-pdf-butler skill.

---

## Batch Backend (high-throughput add-on)

Separately licensed. Use when batches exceed ~50 documents.

**What it adds**:
- **Much faster processing** + better scalability
- **Better error handling** than the standard Salesforce batch Apex path
- **Merged PDF output** — all docs concatenated into one file
- **ZIP output** — all docs zipped into one archive

**Opt-in steps**:
1. **BULK Butler Admin tab** → enter PDF Butler credentials
2. **Accept addendum** (additional licence terms)
3. **Contact PDF Butler Support** to confirm licensing eligibility
4. **Assign `PDF Butler Batch` permission set** to batch-running users

**Limits**:
- Merged PDF — **1,000 records per file max**; larger batches split into multiple merged PDFs
- ZIP — same 1,000-record cap per archive

**When to use**: any batch over 50 docs. The default Salesforce-native batch path has worse error handling and slower throughput.

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