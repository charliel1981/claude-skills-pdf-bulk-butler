#!/usr/bin/env bash
# Installer for the PDF Butler + BULK Butler + SIGN Butler V2 Claude Code skills.
# Symlinks all three skills into ~/.claude/skills/ so `git pull` on this repo
# automatically updates them.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILLS_DIR="$HOME/.claude/skills"

mkdir -p "$SKILLS_DIR"

install_skill() {
    local name="$1"
    local src="$REPO_DIR/$name"
    local dst="$SKILLS_DIR/$name"

    if [[ ! -d "$src" ]]; then
        echo "✗ $name: source missing at $src"
        return 1
    fi

    if [[ -L "$dst" ]]; then
        echo "↻ $name: symlink already exists, refreshing"
        rm "$dst"
    elif [[ -e "$dst" ]]; then
        echo "✗ $name: $dst exists and is not a symlink — backup + remove it first"
        return 1
    fi

    ln -s "$src" "$dst"
    echo "✓ $name: linked $dst → $src"
}

install_skill sf-pdf-butler
install_skill sf-bulk-butler
install_skill sf-sign-butler

echo
echo "Done. Start a new Claude Code session and run /skills to verify."
echo "Update later: cd $REPO_DIR && git pull"
echo
echo "⚠️  REMINDER: these skills are AI-generated community content, not"
echo "   affiliated with CloudCrossing / PDF Butler. Claude may produce"
echo "   incorrect class names, API signatures, or behaviour. ALWAYS verify"
echo "   against the official PDF Butler Academy and TEST IN A SANDBOX"
echo "   before running skill-suggested changes in a production org."
echo "   Full disclaimer: see README.md § Disclaimer"
