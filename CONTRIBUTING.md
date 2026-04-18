# Contributing

PRs welcome. This repo tries to stay accurate to the official PDF Butler / BULK Butler Academy, so a few rules:

## Content rules

- **Facts must be traceable.** Every claim, class name, field name, or method signature should come from an official source: Academy page, the external API reference at `eu1.pdfbutler.com/files/api/cadmuscore/` (or `cadmusbatch`), a linked PDF guide, or a verified release note. Include a `_Source: [title](url)_` line for major sections.
- **Don't invent API names.** If the Academy doesn't document a method or a field name, say "verify in-org" rather than guessing. Inventions surface later as broken code and erode trust in the skill.
- **Prefer verbatim quoting over paraphrase for code and field names.** Paraphrased prose is fine for narrative.
- **Call out when content came from a YouTube video.** If the Academy page is a video-only stub, say so: `_video-only; see [URL]_`.

## Structural rules

- `SKILL.md` stays lean — it's always loaded into Claude's context. Aim for ~200 lines. Route to `reference/*.md` for depth.
- `reference/*.md` files open with a "quick chooser" or index table so Claude can jump to the right row fast.
- New reference files must be linked from the decision tree in `SKILL.md`.
- Keep tables and code blocks — Claude reads structured content better than prose walls.

## Proposing a new Butler skill

Sibling products (SIGN Butler, FORM Butler, COLLABORATION Butler, CONTRACT Butler) should each be a top-level `sf-<product>-butler/` folder in this repo — same structure as `sf-bulk-butler` or `sf-pdf-butler`. Update the root `README.md` table and `install.sh` to include them.

## Testing a change

1. Install the skill locally (see root `README.md`).
2. Start a fresh Claude Code session.
3. Ask Claude a question that exercises your change. Verify the response cites the right section and reads correctly.
4. Open the PR.

## Running into inaccuracy?

If you hit real-world behaviour that contradicts what the skill says — open an issue with:
- Which file/section was wrong
- What you did and what actually happened
- Org context (package version, Stage, etc.)

The Academy pages drift over time. This skill can drift with them.
