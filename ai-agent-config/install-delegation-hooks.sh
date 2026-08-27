#!/bin/bash
# Installs the delegation-compliance hooks without replacing the rest of
# ~/.claude/settings.json. Override HOME to test against an isolated home.

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
HOOK_SRC_DIR="$SRC_DIR/hooks"
CLAUDE_DIR="$HOME/.claude"
HOOK_DEST_DIR="$CLAUDE_DIR/hooks/delegation"
SETTINGS_FILE="$CLAUDE_DIR/settings.json"
FRAGMENT_FILE="$HOOK_SRC_DIR/hooks-fragment.json"

command -v jq >/dev/null 2>&1 || {
  echo "jq is required" >&2
  exit 1
}

scripts=(
  user-prompt-delegation-reminder.sh
  pre-edit-composition-check.sh
  post-tool-delegation-logger.sh
  delegation-status.sh
)

for script in "${scripts[@]}"; do
  [ -f "$HOOK_SRC_DIR/$script" ] || {
    echo "Missing source: $HOOK_SRC_DIR/$script" >&2
    exit 1
  }
done
jq empty "$FRAGMENT_FILE"

umask 077
mkdir -p "$HOOK_DEST_DIR"
for script in "${scripts[@]}"; do
  cp "$HOOK_SRC_DIR/$script" "$HOOK_DEST_DIR/$script"
  chmod 0755 "$HOOK_DEST_DIR/$script"
done

if [ -f "$SETTINGS_FILE" ]; then
  timestamp="$(date '+%Y%m%d%H%M%S')"
  backup_file="$SETTINGS_FILE.bak.$timestamp"
  suffix=0
  while [ -e "$backup_file" ]; do
    suffix=$((suffix + 1))
    backup_file="$SETTINGS_FILE.bak.$timestamp.$suffix"
  done
  cp "$SETTINGS_FILE" "$backup_file"
fi

current_file="$(mktemp "$CLAUDE_DIR/settings.json.current.XXXXXX")"
merged_file="$(mktemp "$CLAUDE_DIR/settings.json.merged.XXXXXX")"
cleanup() {
  rm -f "$current_file" "$merged_file"
}
trap cleanup EXIT

if [ -f "$SETTINGS_FILE" ]; then
  cp "$SETTINGS_FILE" "$current_file"
else
  printf '{}\n' >"$current_file"
fi

jq --slurpfile fragment "$FRAGMENT_FILE" '
  def hook_equal($left; $right):
    (($left.type // null) == ($right.type // null)) and
    (($left.command // null) == ($right.command // null)) and
    (($left.prompt // null) == ($right.prompt // null));

  def matcher_equal($left; $right):
    (($left.matcher // "") == ($right.matcher // ""));

  def add_hook_group($groups; $incoming):
    if any($groups[]?; matcher_equal(.; $incoming)) then
      reduce (($incoming.hooks // [])[]) as $hook (
        $groups;
        if any(.[]?;
          matcher_equal(.; $incoming) and
          any((.hooks // [])[]?; hook_equal(.; $hook))
        ) then
          .
        else
          ([to_entries[] | select(matcher_equal(.value; $incoming)) | .key] | first) as $index
          | .[$index].hooks = ((.[$index].hooks // []) + [$hook])
        end
      )
    else
      $groups + [$incoming]
    end;

  reduce ($fragment[0].hooks | to_entries[]) as $event (
    .;
    .hooks = (.hooks // {})
    | .hooks[$event.key] = (
        reduce ($event.value[]) as $group (
          (.hooks[$event.key] // []);
          add_hook_group(.; $group)
        )
      )
  )
' "$current_file" >"$merged_file"

jq empty "$merged_file"
mv "$merged_file" "$SETTINGS_FILE"

echo "Installed delegation hooks:"
for script in "${scripts[@]}"; do
  echo "  $HOOK_DEST_DIR/$script"
done
echo "Merged hooks into:"
echo "  $SETTINGS_FILE"
