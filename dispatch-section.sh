#!/usr/bin/env bash
# Assemble a paste-ready cross-repo dispatch message for one or more of this
# repo's shared AGENTS.md sections. See AGENTS.md's "Cross-session tasking"
# and README.md's "Cross-repo documentation governance".
#
# Usage:
#   dispatch-section.sh --list
#   dispatch-section.sh --check
#   dispatch-section.sh --to <repo-root> [--tier sibling|descendant] <section>...
#
# --list   Print extractable shared sections and their canonical file.
# --check  Assert template/AGENTS.md's "Cross-session tasking" matches
#          AGENTS.md's, apart from the two documented root-only blocks.
#          Exits non-zero with a diff on drift.
# --to     Absolute root of the repo to dispatch to. Emits a paste-ready
#          message on stdout: To:/From: header, each section's exact text,
#          and a closing block that demands a completion report later.
# --tier   sibling (default) keeps the "Shared section." trailer as-is.
#          descendant strips it, per "Proposing a section to a descendant".
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
template_agents="$repo_root/template/AGENTS.md"
root_agents="$repo_root/AGENTS.md"

section_order=(
  "Cross-session tasking"
  "Documentation style"
  "Git workflow"
  "Backlog entry conventions"
  "Changing a convention"
  "Context after compaction"
  "Changelog procedure"
)

section_file() {
  # Every canonical section currently lives in template/AGENTS.md.
  case "$1" in
    "Cross-session tasking"|"Documentation style"|"Git workflow"| \
    "Backlog entry conventions"|"Changing a convention"|\
    "Context after compaction"|"Changelog procedure")
      printf '%s\n' "$template_agents" ;;
    *) return 1 ;;
  esac
}

usage() {
  sed -n '2,20p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

# Prints the heading line (with its "##"/"###" marker) plus the section body,
# up to but not including the next "##"/"###" heading. Command substitution
# around a call to this trims the trailing blank lines that precede that
# next heading, so callers never have to strip them by hand.
extract_section() {
  local file="$1" heading="$2"
  awk -v sec="$heading" '
    BEGIN { found = 0 }
    /^#{2,3} / {
      if (found) exit
      text = $0
      sub(/^#{2,3} /, "", text)
      if (text == sec) { found = 1; print; next }
      next
    }
    found { print }
  ' "$file"
}

# Drops a trailing "Shared section." trailer line, if the body ends with one.
strip_trailer() {
  printf '%s\n' "$1" | sed -e '$ { /^Shared section\./d }'
}

cmd_list() {
  echo "Extractable shared sections:"
  for s in "${section_order[@]}"; do
    printf '  %-28s %s\n' "$s" "$(section_file "$s")"
  done
}

cmd_check() {
  local root_body tpl_body
  tpl_body="$(extract_section "$template_agents" "Cross-session tasking")"
  tpl_body="$(strip_trailer "$tpl_body")"

  root_body="$(extract_section "$root_agents" "Cross-session tasking")"
  root_body="$(strip_trailer "$root_body")"
  # Documented root-only block 1: the closing sentence on the last bullet
  # ("A shared section changes in the parent first.") that has no
  # counterpart in the template copy.
  root_body="$(printf '%s\n' "$root_body" | sed \
    -e '/^  This repo is the parent, so this rule governs the other repos, not itself\.$/d')"
  # Documented root-only block 2: the paragraph explaining why this repo
  # duplicates the section at all, plus the one blank line it displaces.
  root_body="$(printf '%s\n' "$root_body" | awk '
    /^This repo receives cross-repo documentation proposals/ { skip = 1; next }
    skip == 1 && /downstream projects\.$/ { skip = 2; next }
    skip == 2 { skip = 0; next }
    skip == 1 { next }
    { print }
  ')"

  if diff -u <(printf '%s\n' "$root_body") <(printf '%s\n' "$tpl_body"); then
    echo "OK: Cross-session tasking matches between AGENTS.md and template/AGENTS.md" \
      "(root-only blocks excluded)."
    return 0
  fi
  echo "DRIFT: the two Cross-session tasking copies no longer match." >&2
  echo "Fix template/AGENTS.md (or document a new carve-out here) before" \
    "trusting it as the dispatch source." >&2
  return 1
}

cmd_dispatch() {
  local target="$1" tier="$2"
  shift 2
  local -a sections=("$@")

  local target_root target_name from_root from_name
  target_root="$target"
  target_name="$(basename "$target_root")"
  from_root="$(cd "$repo_root" && git rev-parse --show-toplevel)"
  from_name="$(basename "$from_root")"

  printf 'To: %s, %s\n' "$target_name" "$target_root"
  printf 'From: %s, %s\n\n' "$from_name" "$from_root"

  local sec file body
  for sec in "${sections[@]}"; do
    file="$(section_file "$sec")" || {
      echo "Unknown section: $sec (see --list)" >&2
      return 1
    }
    body="$(extract_section "$file" "$sec")"
    if [[ "$tier" == "descendant" ]]; then
      body="$(strip_trailer "$body")"
    fi
    printf -- '--- %s ---\n' "$sec"
    printf '```\n%s\n```\n\n' "$body"
  done

  cat <<EOF
File this as a Backlog entry, then reply saying you filed it.
When you later implement it, message this repo again before deleting the
entry, naming the commits and what changed. Refusing, deferring, or
blocking on your user's sign-off are complete answers -- silence is not.
This dispatch stays open until that second message arrives.

Originating repo (report here): $from_name, $from_root
EOF
}

main() {
  if [[ $# -eq 0 ]]; then
    usage
    exit 1
  fi

  case "$1" in
    --list) cmd_list ;;
    --check) cmd_check ;;
    --to)
      local target="${2:-}"
      [[ -n "$target" ]] || { echo "--to needs a repo root" >&2; exit 1; }
      shift 2
      local tier="sibling"
      if [[ "${1:-}" == "--tier" ]]; then
        tier="${2:-}"
        [[ "$tier" == "sibling" || "$tier" == "descendant" ]] || {
          echo "--tier must be 'sibling' or 'descendant'" >&2
          exit 1
        }
        shift 2
      fi
      [[ $# -ge 1 ]] || { echo "Name at least one section (see --list)" >&2; exit 1; }
      cmd_dispatch "$target" "$tier" "$@"
      ;;
    -h|--help) usage ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
