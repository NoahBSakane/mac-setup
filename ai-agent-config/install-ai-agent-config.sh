#!/bin/bash
# Installs (or re-installs) this Mac's AI coding agent config — the shared
# rules + Claude Code/Codex CLI specific instructions — from this repo onto
# the current Mac. See ./ai-agent-config.md for what this does and why.
#
# ~/AGENTS.md is the source of truth for rules common to both tools.
# Claude Code can `@AGENTS.md`-import it directly, so ~/.claude/AGENTS.md is
# made a symlink to ~/AGENTS.md instead of a copy. Codex CLI has no import
# mechanism, so ~/.codex/AGENTS.md stays a real file that must duplicate the
# common rules by hand (it also carries Codex-only persona/style rules that
# don't belong in the shared file).
#
# Portable across any Mac/user account: everything below resolves through
# $HOME, no hardcoded paths.
#
# Safe to re-run any time (e.g. after this Mac was reset, restoring from
# this repo, or setting up a different Mac/user account). Existing files at
# the destinations are overwritten without backup — if you've made
# machine-local edits directly to the live files since the last snapshot,
# copy them back into this repo first or you'll lose them.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SRC_DIR/.." && pwd)"

mkdir -p "$HOME/.claude" "$HOME/.codex"

# AGENTS.md / CLAUDE.md live at the repo root, not next to this script: they
# double as this mac-setup repo's own project instructions for Claude
# Code/Codex CLI, so they can't be moved into this subfolder.
cp "$REPO_ROOT/AGENTS.md" "$HOME/AGENTS.md"
cp "$REPO_ROOT/CLAUDE.md" "$HOME/.claude/CLAUDE.md"
cp "$SRC_DIR/codex-AGENTS.md" "$HOME/.codex/AGENTS.md"
ln -sf "$HOME/AGENTS.md" "$HOME/.claude/AGENTS.md"

echo "Installed:"
echo "  $HOME/AGENTS.md"
echo "  $HOME/.claude/AGENTS.md  -> symlink to ~/AGENTS.md"
echo "  $HOME/.claude/CLAUDE.md"
echo "  $HOME/.codex/AGENTS.md"
echo
echo "Note: ~/AGENTS.md and ~/.codex/AGENTS.md must be kept in sync by hand"
echo "going forward (Codex CLI can't import files, so the common rules are"
echo "duplicated, not shared)."
