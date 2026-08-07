# Deployment & Migration — PDF Butler

How to move DocConfigs/Packs between orgs and keep multi-environment installs in sync.

## Deployment paths (pick one)

| Path | Best for | Round-trip friction |
|---|---|---|
| **Doc Config Migration Wizard** (UI) | Admin pushing 1–many DocConfigs between orgs | Lowest — clicks only |
| **SF CLI plugin** (`@pdfbutler/migration-cli`) | CI/CD, Git-backed ops, scratch org bootstrap | Medium — needs pipeline setup |
| **Backup + Restore** (UI) | Snapshot before big change, restore on single org | Lowest — clicks only |

## Stage-based environment model

PDF Butler identifies which config to use via a **Stage** field on each org. You register ONCE with PDF Butler and reuse the same credentials across every org — Stage disambiguates.

| Stage | Typical org |
|---|---|
| `PROD` | Production |
| `UAT` | Full-copy sandbox |
| `TEST` | Partial-copy / test sandbox |
| `STAGING`, `TRG`, `INT`, `QA`, `DEMO` | Specialised environments |
| `DEV1`–`DEV20` | Up to 20 development sandboxes |

Setting the wrong Stage leaves imported DocConfigs pointing at source-org record Ids. Always confirm Stage before importing.

---

## Doc Config Migration Wizard

**Purpose**: 1-step UI deploy of one or more DocConfigs between orgs.
**Access**: PDF Butler Admin tab → Migration Wizard.
**Scope**: DocConfigs + their DataSources + Templates + Alternatives + Actionables.
**Prerequisite**: the target org must already be registered to PDF Butler using the SAME tenant username.
**Pattern**: select source DocConfigs → map to target org → run.
**Video**: Academy has a demo video (no textual walkthrough published).

---

## PDF Butler Migration CLI (`@pdfbutler/migration-cli`)

An **oclif-based `sf` CLI plugin** — not a standalone binary. Registers `sf butler pb …` (PDF Butler) and `sf butler sb …` (SIGN Butler) topics. Closed-source, **npm-only** (no public source repo as of v0.0.29, BSD-3-Clause licence).

### Install

```bash
npm install -g @salesforce/cli          # prerequisite: sf CLI v2, Node ≥ 16
sf plugins install @pdfbutler/migration-cli
```

Shell: README recommends **PowerShell on Windows**, **zsh on macOS**, **bash on Linux**. Windows `cmd.exe` mis-parses quoted arguments.

### Authentication — two modes

**Mode A — `sf` CLI org alias** (local dev):

```bash
sf org login web                         # once
sf butler pb export -t my-sandbox@example.com ...
```

**Mode B — session + instance** (CI/CD — no prior login):

```bash
sf butler pb export \
    --session "$SF_SESSION_ID" \
    --instance "https://acme.my.salesforce.com" ...
```

README: _"if you also include the --session and --instance flags, these values will take precedence"_ over `-t`.

**Separate — PDF Butler backend credentials** (`-a / --auth-env-var`): passed as a literal string `USERNAME-ADMIN:PASSWORD` (no whitespace). Despite the flag name, the docs show the plain value inlined — you shell-interpolate env vars yourself:

```bash
-a "$PB_BACKEND_CREDS"           # e.g. "acme_dev-ADMIN:hunter2"
```

### All 10 commands

| Command | Purpose | Required flags | Notable optionals |
|---|---|---|---|
| `sf butler pb export` | Export DocConfigs (SFDC JSON + backend zip) | `-t`, `-i`, `-o`, `-s`, `-a`, `-e` | `-b full\|only\|none`, `-u`, `-l`, `-p` (partial), `-m`, `--cut`, `--shortpaths` |
| `sf butler pb import` | Import DocConfigs | `-t`, `-i`, `-a`, `-e`, `-s`, `-f` | `-c` (clone/insert), `-m`, `-l` |
| `sf butler pb exportpack` | Export a Pack | `-t`, `-p`, `-o` | `-d none\|lead\|pack\|full`, `-a`, `-e`, `-s`, `-u`, `-m`, `-l` |
| `sf butler pb importpack` | Import a Pack | `-t`, `-p`, `-f` | `-d pack\|lead\|full`, `-a`, `-e`, `-s`, `-m`, `-c`, `-l` |
| `sf butler pb exportdatasource` | Export DataSources to JSON | `-i`, `-f`, `-s` | `-t`, `-a`, `-e`, `-p` (recurse **parents**), `-l` |
| `sf butler pb importdatasource` | Import DataSources (**needs PDF Butler ≥ v1.505**) | `-i`, `-f` | `-t`, `-s`, `-a`, `-e`, `-p`, `-l` |
| `sf butler pb adminsettings` | Set endpoint + region + stage in the target org | `-t`, `-u` (URL), `-r` (region), `-s` (stage) | `--session`, `--instance` |
| `sf butler pb admincredentials` | Write PDF Butler admin + user passwords into the target org | `-t`, `-u` (PB username), `-p` (admin pw), `--user-password` | — |
| `sf butler sb export signtemplate` | Export SIGN Butler Sign Request Templates | `-i`, `-f` | `-t`, `-l` |
| `sf butler sb import signtemplate` | Import SIGN Butler Sign Request Templates | `-i`, `-f` | `-t`, `-l` |

Both `adminsettings` and `admincredentials` require PDF Butler package **v1.440+** in the target org. `exportpack`/`importpack` also require v1.440+.

### Flag reference (shared)

| Flag | Purpose |
|---|---|
| `-t, --target` | SF org alias/username. Required unless `--session`+`--instance` present |
| `-i, --id` | Record ID(s) — separate multiple with whitespace (most commands) or commas (DataSource + some Pack usage). **For `exportdatasource`/`importdatasource` this is the composite `CustomerDataSourceId`, not the Salesforce record Id** — see [DataSource identifiers](#datasource-identifiers) |
| `-o, --out` | Output directory (export commands) |
| `-f, --folder` / `--config` | Input directory (import commands — note: the short flag is `-f` everywhere but the long name is `--config` on `pb:import` and `--folder` elsewhere) |
| `-s, --stage` | CADMUS stage (`DEV1`, `TEST`, `UAT`, `QA`, `STAGING`, `PROD`…) — must match the target org's admin settings |
| `-a, --auth-env-var` | Literal PDF Butler backend creds `USERNAME-ADMIN:PASSWORD` |
| `-e, --endpoint` | Region URL: `https://us1.pdfbutler.com`, `https://eu1.pdfbutler.com`, `https://apac1.pdfbutler.com`, `https://ca1.pdfbutler.com` |
| `-b, --backend` | Export: `full` (SFDC + backend, default) / `only` (backend only) / `none` (SFDC only). Bare `-b` = `--backend none` |
| `-u, --unzip` | Unzip the backend bundle instead of leaving it zipped |
| `-l, --logs` | Verbose `[INFO]` log lines |
| `-p, --partial` (export) | Skip invalid DocConfigs in a bulk run |
| `-p, --parents` (DataSource) | **Same short flag, different meaning** — recurse parent DataSources |
| `-m, --templates` | Include child "Template Word" DocConfigs referenced from a parent |
| `-c, --clone` | On import, insert a new record instead of updating by ID |
| `-d, --docconfig` | Pack export/import mode — `none` (default export) / `lead` / `pack` / `full` (default import) |
| `--cut` | Trim filenames to 150 chars (Windows 255-char path safety) |
| `--shortpaths` | Drop stage + ID suffix from filenames — leaves only the DocConfig name |
| `--session`, `--instance` | Session-ID auth (override `-t`) |
| `--json` | Structured JSON output |

### DataSource identifiers

`exportdatasource` / `importdatasource` do **not** take a Salesforce record Id. They take the
composite `CustomerDataSourceId`:

```
<15-char org Id>_<15-char DataSource record Id>      e.g. 00DXXXXXXXXXXXX_a2LXXXXXXXXXXXX
```

Passing the bare 18-char record Id fails with a message that points you at the wrong thing:

```
[INFO]  Exporting DataSource (1/1): a2LP400000XXXXXXXX.
[ERROR] DataSource export failed for ID: a2LP400000XXXXXXXX.
Error (1): DataSource export failed. Check the IDs and try again.
```

The record exists, so "check the IDs" sends you re-verifying it. Read the composite value off the
record instead of assembling it by hand — truncating 18 chars to 15 is easy to get wrong:

```bash
sf data query --target-org <alias> --result-format csv -q \
  "SELECT Id, Name, cadmus_core__CustomerDataSourceId__c
   FROM cadmus_core__Data_Source__c WHERE Name = '<name>'"
```

**`cadmus_core__CustomerDataSourceId__c` is package read-only.** Attempting to set it returns
`Unable to create/update fields: cadmus_core__CustomerDataSourceId__c. Please check the security
settings of this field…` — which reads like an FLS problem and is not one. No profile can write it.

**Cross-org prefixes are harmless.** An org that received DataSources by migration ends up with a
**mix**: natively-created records carry that org's own Id, migrated ones keep the **source** org's Id.
A child `PICTURE_LIST` created natively will therefore have a different org prefix from a migrated
parent, and (per the above) cannot be aligned to it. This is fine — the org-Id half is provenance,
not a runtime key. Verified by render: a natively-created child resolved correctly under a migrated
parent carrying another org's prefix.

_Source: in-org observation — `cadmus_core` 1.518, `@pdfbutler/migration-cli` 0.0.29, Stage `PROD`.
Not documented in the Academy; verify in-org._

### Which REST endpoint each command hits

Extracted verbatim from the CLI's own `lib/utils/constants.js`. Useful for firewall whitelisting, named-credential setup, and understanding failure modes.

| CLI command | Salesforce REST path | Apex class |
|---|---|---|
| `pb:export` (SFDC side) | `/services/apexrest/cadmus_core/DocConfig/Export2/<Id>` | `RestExportDocConfig2` (streams) |
| `pb:export` (backend) | `<endpoint>/config/export-config/<stage>/<Id>` | PDF Butler backend (not Apex) |
| `pb:import` | `/services/apexrest/cadmus_core/DocConfig/Import/?isInsert=<bool>` | `RestImportDocConfig` |
| `pb:exportpack` | `/services/apexrest/cadmus_core/Pack/Export/` | `RestExportPack` |
| `pb:importpack` | `/services/apexrest/cadmus_core/Pack/Import` | `RestImportPack` |
| `pb:exportdatasource` | `/services/apexrest/cadmus_core/DataSource/Export/` | *(Apex class not in public ApexDoc — verify in-org)* |
| `pb:importdatasource` | `/services/apexrest/cadmus_core/DataSource/Import` | *(Apex class not in public ApexDoc — verify in-org)* |
| `pb:adminsettings` | `/services/apexrest/cadmus_core/Manage/Admin` | `RestManageAdmin` |
| `pb:admincredentials` | `/services/apexrest/cadmus_core/Manage/Admin` | `RestManageAdmin` |
| `sb:export:signtemplate` | `/services/apexrest/cadmus_sign2/SignRequestTemplate/Export/` | SIGN Butler (`cadmus_sign2`) |
| `sb:import:signtemplate` | `/services/apexrest/cadmus_sign2/SignRequestTemplate/Import/` | SIGN Butler (`cadmus_sign2`) |

**Gaps from the public ApexDoc**: `RestTranslationEngine`, `RestReportDataSource`, and `RestDocConfigDynamicActionables` are **not** invoked by any v0.0.29 CLI command. Translation migration is not a direct CLI operation — translations travel as DocConfig-scoped metadata inside the export JSON. Report-type DataSources migrate via the standard `pb:exportdatasource` path.

### Config file — there isn't one

The CLI is **stateless** — no `.pdfbutlerrc` / `pdfbutler.config.json` / YAML. Reuse across orgs via:

1. Commit exported JSON + zip bundles to Git.
2. Parameterise flags with shell vars / CI secrets (`-t "$SF_USERNAME"`, `-a "$PB_CREDS"`, `-e "$PB_ENDPOINT"`, `-s "$PB_STAGE"`).
3. Write **endpoint + region + stage** into the target org itself via `pb:adminsettings` / `pb:admincredentials` — that persists org-side so later runs don't need to re-pass them. (Org state, not CLI state.)

### Workflows

#### Export → import DocConfigs (canonical)

```bash
sf butler pb export \
    -t dev-sandbox@example.com \
    -i 'a0B1x000000AaaaEAA' \
    -o 'butler/docConfigs' \
    -s 'DEV1' \
    -a 'acme_dev-ADMIN:hunter2' \
    -e 'https://eu1.pdfbutler.com' \
    -u -l

sf butler pb import \
    -t uat-sandbox@example.com \
    -i 'a0B1x000000AaaaEAA' \
    -f 'butler/docConfigs' \
    -e 'https://eu1.pdfbutler.com' \
    -a 'acme_dev-ADMIN:hunter2' \
    -s 'UAT'
```

Result of export: `butler/docConfigs/sfdc/<Id>.json` + (with `-u`) unzipped dir `butler/docConfigs/<Id>/` containing `ConfigTypes/`, `DataSources/`, `doc-config.json`, `<TemplateName>.docx`.

Add `-c` to the import to **insert a new DocConfig** with a new `customerDocumentConfigId` instead of updating in place.

#### Migrate a full Pack (lead + children + backend)

```bash
sf butler pb exportpack \
    -t dev-sandbox@example.com \
    -p 'acme-quote-pack-v1' \
    -o './export/pack' \
    -a 'acme_dev-ADMIN:hunter2' \
    -e 'https://eu1.pdfbutler.com' \
    -s 'DEV1' \
    -d full -u -m -l

sf butler pb importpack \
    -t uat-sandbox@example.com \
    -p 'acme-quote-pack-v1' \
    -f './export/pack' \
    -a 'acme_dev-ADMIN:hunter2' \
    -e 'https://eu1.pdfbutler.com' \
    -s 'UAT' \
    -d full -m -c
```

#### CI/CD roundtrip with session auth (no `sf login`)

```bash
sf butler pb export \
    --session "$SF_SESSION_ID" \
    --instance "https://acme.my.salesforce.com" \
    -i 'a0B1x000000AaaaEAA' \
    -o artifacts/pdfbutler \
    -s 'PROD' \
    -a "$PB_BACKEND_CREDS" \
    -e 'https://eu1.pdfbutler.com'

# commit artifacts/pdfbutler to Git → in the deploy job:

sf butler pb import \
    --session "$SF_SESSION_ID_UAT" \
    --instance "https://acme--uat.sandbox.my.salesforce.com" \
    -i 'a0B1x000000AaaaEAA' \
    -f artifacts/pdfbutler \
    -s 'UAT' \
    -a "$PB_BACKEND_CREDS" \
    -e 'https://eu1.pdfbutler.com'
```

#### DataSource migration

```bash
sf butler pb exportdatasource \
    -t dev-sandbox@example.com \
    -i 'a0Dxx0000000001, a0Dxx0000000002' \
    -f './export' \
    -s 'DEV1' \
    -p -l                    # -p recurses PARENTS here, not partial
```

#### Bootstrap a brand-new org (settings + creds)

```bash
sf butler pb adminsettings \
    -t new-sandbox@example.com \
    -u 'https://eu1.pdfbutler.com' \
    -r 'EU' \
    -s 'DEV1'

sf butler pb admincredentials \
    -t new-sandbox@example.com \
    -u 'acme_dev' \
    -p 'ADMIN_pw' \
    --user-password 'USER_pw'
```

#### SIGN Butler Sign Request Templates

```bash
sf butler sb export signtemplate -t dev@example.com -i "a0Bxx0000000011" -f "./export/sb"
sf butler sb import signtemplate -t uat@example.com -i "a0Bxx0000000011" -f "./export/sb"
```

### CLI failure-mode lookup

Every row verbatim from the README's "Typical errors and solutions", plus a few pitfalls evident from the command semantics:

| Symptom | Root cause | Fix |
|---|---|---|
| `EPERM operation not permitted, chmod '<path>'` | Filesystem write permissions on `-o` | `chmod` the directory writable or pick a different `-o` path |
| `Error (1): No authorization information found for <user>.` | `sf` CLI has no saved auth for that username / wrong alias | Run `sf org login web` first; check alias |
| `Error (1): No matching Doc Configs ids found.` | Wrong Ids / wrong org / deleted record | Verify Ids in the source org |
| `Error (1): One or more docConfigs have no backend.` | DocConfig has no backend template registered | Register the backend template, OR pass `-p / --partial` to skip, OR re-run with `--backend none` |
| `Error (1): Response code 401 (Unauthorized).` | Wrong PDF Butler admin creds in `-a` | Recheck `USERNAME-ADMIN:PASSWORD` |
| `System.LicenseException: ... requires a license to use` | Integration user has no PDF Butler licence | Assign the PDF Butler permission set |
| `Error (1): DataSource import failed. Check the JSON and try again.` | Malformed JSON OR target org < PDF Butler v1.505 | Upgrade package; validate JSON |
| `-b` produces unexpected export contents | Bare `-b` (no value) = `--backend none` since v0.0.29 | Always supply a value — `-b full` / `-b only` / `-b none` |
| `-p` does the wrong thing | On export = `--partial`; on DataSource = `--parents`; on Pack = `--pack` | Prefer long forms in CI |

### CI/CD patterns

- Commit `butler/docConfigs/` + `export/pack/` folders into Git — diffable JSON + backend bundle gives review-friendly deltas.
- Scheduled export against PROD + PR of the diff → drift detection.
- Pipeline gated on merge-to-main runs the import against UAT, then PROD, using session auth.
- Bootstrap step for a fresh org: `adminsettings` → `admincredentials` → `pb:import` in sequence.

_Sources: [@pdfbutler/migration-cli on npm](https://www.npmjs.com/package/@pdfbutler/migration-cli) (v0.0.29), [raw README](https://unpkg.com/@pdfbutler/migration-cli@0.0.29/README.md), [constants.js](https://unpkg.com/@pdfbutler/migration-cli@0.0.29/lib/utils/constants.js), [Academy — Deployment CLI via SF CLI](https://pdfbutler.com/academy/pdf-butler-academy/pdf-butler-deployment/deployment-command-line-interface-cli-via-sf-cli/)._

---

## Backup & Restore

In-org snapshot mechanism for admins protecting against their own mistakes.

### Backup (2-step)

1. **Doc Config page** → Export → ZIP file containing DataSources + ConfigTypes + Templates + Alternatives
2. **PDF Butler Admin tab** → Export → JSON file containing DataSource config + DocConfig settings + Actionables

### Restore (2-step)

1. **Doc Config page** → Import the ZIP
2. **PDF Butler Admin tab** → Import the JSON

### Also back up

Packs via the PDF Butler Admin tab (same mechanism as DocConfigs).

---

## Updating the managed package version

**Safety claim from PDF Butler**: "Butler Apps are always backwards compatible so updating is without risk."
**Implication**: upgrade on a schedule, no need for blue-green.
**Practice**: upgrade UAT first, smoke-test one representative DocConfig, then push to PROD the same day.

---

## Setup a new environment (post-install)

Goes hand-in-hand with the idempotent install checklist in the root `SKILL.md`. Key steps:

1. Install the managed package from AppExchange (or `sf package install`)
2. Register for a licence (receive ADMIN + USER passwords via email) — reuse across ALL envs
3. Paste credentials in PDF Butler Admin tab
4. Set **Stage** (`PROD`, `UAT`, `DEV1`, etc.)
5. Verify Remote Site / Named Credential exists for correct region
6. Assign packaged permission sets (wrap in Admin + User PSGs)
7. Import DocConfigs via Migration Wizard or CLI

Anonymous Apex smoke test at the end:

```apex
cadmus_core.ConvertController.ConvertDataModel cdm =
    new cadmus_core.ConvertController.ConvertDataModel();
cdm.objectId    = '<test record id>';
cdm.docConfigId = '<imported DocConfig id>';
System.debug(cadmus_core.ConvertController.convertWithWrapper(cdm).response.metadata.targetName);
```

---

## Common deployment failure modes

| Symptom | Likely cause | Fix |
|---|---|---|
| Imported DocConfig references non-existent record IDs | Wrong Stage on target org | Update Stage, re-import |
| Callout fails with `Unauthorized endpoint` | Remote Site Setting missing for target region | Add `https://eu1.pdfbutler.com` (or us1/au1) under Setup |
| `AuthenticationException` after import | Wrong ADMIN password in CLI `-a` flag | Use the ADMIN password from registration email, not user password |
| Migration Wizard shows no DocConfigs to pick | Target org not registered or wrong tenant username | Re-register target with same username as source |
| Pack imports but Actionables don't fire | Actionable `Active = false` on target | Toggle manually or set via post-import script |

---

_Sources: 7 child pages under [pdf-butler-deployment/](https://www.pdfbutler.com/academy/pdf-butler-academy/pdf-butler-deployment/)._
