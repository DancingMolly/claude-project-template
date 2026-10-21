#!/usr/bin/env bash
# SessionStart hook, matcher "compact". Restores the files named in
# .claude/post-compact-files, which compaction drops from context. Stdout
# from this hook is added to the session's context.
set -euo pipefail

root="${CLAUDE_PROJECT_DIR:?CLAUDE_PROJECT_DIR is not set}"
list="$root/.claude/post-compact-files"
max_lines=100

[[ -f "$list" ]] || exit 0

while IFS= read -r path || [[ -n "$path" ]]; do
  path="${path%%#*}"
  path="${path#"${path%%[![:space:]]*}"}"
  path="${path%"${path##*[![:space:]]}"}"
  [[ -n "$path" && -f "$root/$path" ]] || continue
  if (( $(wc -l < "$root/$path") <= max_lines )); then
    printf -- '--- %s ---\n' "$path"
    cat "$root/$path"
    printf '\n'
  else
    printf 'Re-read %s before continuing: it is too long to restore here.\n' "$path"
  fi
done < "$list"
