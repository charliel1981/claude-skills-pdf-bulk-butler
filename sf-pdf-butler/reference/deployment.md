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

## SF CLI deployment

**Plugin**: `@pdfbutler/migration-cli` from NPM.
**Install**: `npm install -g @pdfbutler/migration-cli` (uses `sf` CLI v2 as base).

### Export a DocConfig

```bash
sf butler pb export \
  -t <FROM_ORG_ALIAS> \
  -i '<DOCCONFIG_ID>' \
  -o 'butler/docConfigs' \
  -s 'DEV1' \
  -a '<PDF_BUTLER_USERNAME>-ADMIN:<PASSWORD>' \
  -e 'https://eu1.pdfbutler.com'
```

| Flag | Purpose |
|---|---|
| `-t` | Source org alias (sf-aliased) |
| `-i` | DocConfig Id (repeat for multiple) |
| `-o` | Output folder on disk |
| `-s` | Source Stage (`DEV1`, `PROD`, etc.) |
| `-a` | `<username>-ADMIN:<admin-password>` — from the PDF Butler registration email |
| `-e` | Region endpoint (`eu1`, `us1`, `au1`) |

### Import a DocConfig

```bash
sf butler pb import \
  -t <TO_ORG_ALIAS> \
  -i '<DOCCONFIG_ID>' \
  -f 'butler/docConfigs' \
  -a '<PDF_BUTLER_USERNAME>-ADMIN:<PASSWORD>' \
  -s 'QA'
```

| Flag | Purpose |
|---|---|
| `-t` | Target org alias |
| `-i` | DocConfig Id |
| `-f` | Source folder (output from export) |
| `-a` | Same ADMIN credentials as export |
| `-s` | Target Stage |

### Clone instead of overwrite

Add `-c` / `--clone` to the import command to duplicate rather than overwrite.

### CI/CD patterns

- Commit `butler/docConfigs/` folders into Git for version control
- Run export in a scheduled job against PROD; PR the diff for review
- Run import in a pipeline gated on merge-to-main, against UAT then PROD

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
