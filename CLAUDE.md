# CLAUDE.md — working ON this repo (not with it)

This file is for **Claude sessions spent maintaining this skill bundle itself** — editing `sf-pdf-butler/` or `sf-bulk-butler/`, adding a new Butler-product skill, fixing a stale reference. Don't confuse this with `sf-pdf-butler/SKILL.md` or `sf-bulk-butler/SKILL.md`, which are the skill definitions that teach other Claude sessions about PDF Butler / BULK Butler.

## What this repo is

Two Claude Code skills that turn Claude into a specialist on **PDF Butler** and **BULK Butler** Salesforce AppExchange packages. Full background in [README.md](./README.md). The skills are distilled from the public [PDF Butler Academy](https://www.pdfbutler.com/academy/pdf-butler-academy/) and [BULK Butler Academy](https://www.pdfbutler.com/academy/bulk-butler-academy/).

## Directory structure

```
claude-skills-pdf-bulk-butler/
├── CLAUDE.md                     ← this file (maintainer notes)
├── README.md                     ← public-facing docs, disclaimer, install
├── LICENSE                       ← MIT (wrapper only)
├── CHANGELOG.md                  ← per-release coverage notes
├── CONTRIBUTING.md               ← factual-accuracy rules for contributors
├── install.sh                    ← symlink-based installer for end users
├── docs/architecture.png         ← README diagram (Nano Banana generated)
├── sf-pdf-butler/
│   ├── SKILL.md                  ← lean index, always-loaded by Claude
│   └── reference/
│       ├── automation.md         ← Apex API + LWC/Flow (biggest file)
│       ├── configtypes.md        ← 31 ConfigTypes
│       ├── datasources.md        ← 13 DataSource types
│       ├── doc-config-types.md   ← 9 DocConfig output types
│       ├── packs-actionables.md  ← 13 Actionables + Flow invocable
│       ├── components.md         ← 10 Lightning components
│       ├── tips.md               ← 21 Tips & Tricks recipes
│       ├── integrations.md       ← CPQ / FSL / Peppol / Service / Experience Cloud
│       ├── deployment.md         ← Migration Wizard + SF CLI
│       ├── i18n.md               ← multi-language, locale, currency
│       └── faq.md                ← 16 FAQs + Get Started + template best practices
└── sf-bulk-butler/
    └── SKILL.md                  ← single file (BULK has a smaller surface)
```

## Rules for editing the skills

Lifted from [CONTRIBUTING.md](./CONTRIBUTING.md). Apply whenever modifying anything inside a skill folder:

- **Facts must be traceable.** Every claim, class name, field name, method signature → cite an official source (Academy page, `eu1.pdfbutler.com/files/api/cadmuscore/`, `cadmusbatch/`, a linked PDF, or a verified release note). Add `_Source: [title](url)_` lines at section ends.
- **Never invent API names.** If the Academy doesn't document a method, field, or flag, say "verify in-org" — don't guess. Inventions surface later as broken code and erode trust.
- **Quote verbatim for code/field/method identifiers.** Prose can be paraphrased; symbols cannot.
- **Flag video-only stubs.** Academy pages that defer detail to YouTube get a `_video-only; see [URL]_` note, not a fabricated summary.
- **`SKILL.md` stays lean** (~200 lines). It's always loaded into Claude's context. Depth goes in `reference/*.md` and is routed via the decision tree table.
- **Every reference file starts with a quick-chooser table** or index — helps Claude grep to the right section fast.
- **New reference files must be linked** from the decision tree in the corresponding `SKILL.md`.

## How to test a change locally

The skills are installed on my machine via symlinks — editing a file here is live in Claude immediately.

```bash
# If install.sh hasn't been run yet:
./install.sh

# Then: edit sf-pdf-butler/reference/automation.md (or wherever)
# Start a new Claude Code session (or /compact in an existing one)
# Ask Claude a question that would exercise the change
# Verify Claude's answer cites the new content
```

If the skills aren't symlinked (e.g. colleague install via copy), changes won't propagate until they re-run install.

## Release flow

When changes are ready for a tagged release:

```bash
# 1. Bump version in relevant frontmatter (sf-pdf-butler/SKILL.md `metadata.version`
#    and/or sf-bulk-butler/SKILL.md `metadata.version`)

# 2. Update CHANGELOG.md with a new [X.Y.Z] — YYYY-MM-DD section
#    documenting what changed + which Academy pages were re-verified

# 3. Commit the changes
git add -A
git commit -m "Release vX.Y.Z — <short description>"

# 4. Tag and push
git tag -a vX.Y.Z -m "vX.Y.Z — <short description>"
git push && git push origin vX.Y.Z

# 5. Create GitHub release using the CHANGELOG entry
gh release create vX.Y.Z --title "vX.Y.Z — <description>" --notes-file CHANGELOG.md --latest
```

## Adding a new Butler-product skill (future work)

If covering SIGN Butler / FORM Butler / COLLABORATION Butler / CONTRACT Butler:

1. Create `sf-<product>-butler/SKILL.md` at the repo root (sibling to existing two).
2. Follow the same frontmatter shape: `name`, `description` (comprehensive enough to auto-trigger), `license`, `metadata.version`, `metadata.sources`.
3. Enumerate the Academy section's child URLs → fetch each → write verbatim. Don't paraphrase code.
4. If the surface is large (> ~15 articles), split into `reference/*.md` files and use a decision-tree router in `SKILL.md` — same pattern as `sf-pdf-butler`.
5. Update root `README.md` skill table.
6. Update `install.sh` to `install_skill sf-<product>-butler`.
7. Update `CHANGELOG.md` with a new version entry.

## Working style in this repo

- **Small, focused commits.** Don't bundle a new reference file with a typo fix.
- **Don't leak project-specific context.** Nothing in a skill file should mention a specific client org, project, or implementation detail from elsewhere on my machine. The skills are intentionally product-scoped, not project-scoped.
- **Respect CloudCrossing's IP.** Paraphrase and link — don't mirror. When in doubt, cite and shorten.
- **Re-verify before claiming "current".** The Academy shifts. Before releasing a version that claims to reflect the current Academy state, spot-check 10–15% of the pages for drift (class renames, new ConfigTypes, deprecated fields).

## Not in scope

- Don't build in automated Academy-scraping tooling. The skills are hand-curated; staleness gets fixed with a manual pass, not by scraping.
- Don't add telemetry / analytics. This is an offline MD-file artefact.
- Don't add a package manager config (`package.json` etc.). The skills are pure markdown + shell.
