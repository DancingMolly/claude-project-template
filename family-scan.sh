#!/usr/bin/env bash
# Find the repos on this host that name this repo as their parent, and keep
# them in an uncommitted registry (registry.local, beside this script). See
# AGENTS.md's "Repo family" and README.md's "Cross-repo documentation
# governance".
#
# Usage:
#   family-scan.sh [--root <dir>]...
#   family-scan.sh --list [--project <name>]
#   family-scan.sh --set <name> [--project <p>] [--tier <t>] [--name <new>]
#   family-scan.sh --check [--root <dir>]...
#
# (none)   Scan the saved roots (and any --root given) and add new repos as
#          project "unassigned", tier "descendant". Prints what it added.
# --root   A directory to search to depth 3. Repeatable. Saved in the
#          registry, so later runs need no argument.
# --list   Print the registry. A path that no longer exists shows "missing".
# --set    Change one repo's project, tier (sibling|descendant) or name.
# --check  Rescan without writing. Exit 1 if a repo is unregistered or still
#          "unassigned".
# A repo counts when its AGENTS.md "Repo family" has a Parent line naming this
# repo's directory. Existing projects and tiers are never rewritten by a scan.
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
parent_name="$(basename "$repo_root")"
registry="$repo_root/registry.local"

usage() {
  sed -n '2,24p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'
}

die() {
  printf 'family-scan.sh: %s\n' "$1" >&2
  exit "${2:-1}"
}

saved_roots() {
  [ -f "$registry" ] || return 0
  sed -n 's/^# root //p' "$registry"
}

registered_paths() {
  [ -f "$registry" ] || return 0
  awk -F'\t' '!/^#/ && NF >= 4 { print $2 }' "$registry"
}

# True when the AGENTS.md "Repo family" section has a Parent line naming us.
names_us_as_parent() {
  awk -v parent="$parent_name" '
    /^## Repo family/ { in_sec = 1; next }
    in_sec && /^## / { exit }
    in_sec && /\*\*Parent:\*\*/ && index($0, "`" parent "`") { found = 1; exit }
    END { exit !found }
  ' "$1"
}

# Prints the directory of each repo under the given roots that names us.
discover() {
  local root agents dir
  for root in "$@"; do
    [ -d "$root" ] || { printf 'family-scan.sh: no such root: %s\n' "$root" >&2; continue; }
    while IFS= read -r agents; do
      dir="$(cd "$(dirname "$agents")" && pwd)"
      [ "$dir" = "$repo_root" ] && continue
      names_us_as_parent "$agents" && printf '%s\n' "$dir"
    done < <(find "$root" -maxdepth 3 \
      \( -name .git -o -name node_modules -o -name .venv -o -name template \) -prune \
      -o -name AGENTS.md -print | sort)
  done
}

# Roots for this run: saved ones, then any --root not yet saved.
all_roots() {
  { saved_roots; printf '%s\n' ${new_roots[@]+"${new_roots[@]}"}; } | awk 'NF && !seen[$0]++'
}

mode=scan
new_roots=()
project_filter=""
set_name=""
set_project=""
set_tier=""
set_newname=""

while [ $# -gt 0 ]; do
  case "$1" in
    --root)    [ $# -ge 2 ] || die "--root needs a directory" 2
               new_roots+=("$(cd "$2" 2>/dev/null && pwd || printf '%s' "$2")"); shift 2 ;;
    --list)    mode=list; shift ;;
    --check)   mode=check; shift ;;
    --set)     [ $# -ge 2 ] || die "--set needs a repo name" 2
               mode=set; set_name="$2"; shift 2 ;;
    --project) [ $# -ge 2 ] || die "--project needs a value" 2
               project_filter="$2"; set_project="$2"; shift 2 ;;
    --tier)    [ $# -ge 2 ] || die "--tier needs a value" 2
               set_tier="$2"; shift 2 ;;
    --name)    [ $# -ge 2 ] || die "--name needs a value" 2
               set_newname="$2"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *)         usage >&2; die "unknown argument: $1" 2 ;;
  esac
done

case "$mode" in
  scan)
    mapfile -t roots < <(all_roots)
    [ "${#roots[@]}" -gt 0 ] || die "no root given and none saved; pass --root <dir>" 2
    [ -f "$registry" ] || : > "$registry"
    for r in "${roots[@]}"; do
      grep -qxF "# root $r" "$registry" || printf '# root %s\n' "$r" >> "$registry"
    done
    known="$(registered_paths)"
    added=0
    while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      grep -qxF "$dir" <<<"$known" && continue
      printf '%s\t%s\tunassigned\tdescendant\n' "$(basename "$dir")" "$dir" >> "$registry"
      printf 'added %s (%s): set its project and tier with --set\n' "$(basename "$dir")" "$dir"
      added=$((added + 1))
    done < <(discover "${roots[@]}")
    printf '%d added; registry %s\n' "$added" "$registry"
    ;;

  list)
    [ -f "$registry" ] || die "no registry yet; run with --root <dir>" 2
    awk -F'\t' -v want="$project_filter" '
      /^#/ || NF < 4 { next }
      want != "" && $3 != want { next }
      { cmd = "test -d \"" $2 "\""; st = (system(cmd) == 0) ? "" : "\tmissing"
        printf "%s\t%s\t%s\t%s%s\n", $1, $3, $4, $2, st }
    ' "$registry"
    ;;

  set)
    [ -f "$registry" ] || die "no registry yet; run with --root <dir>" 2
    [ -n "$set_project$set_tier$set_newname" ] || die "--set needs --project, --tier or --name" 2
    case "$set_tier" in ""|sibling|descendant) ;; *) die "tier must be sibling or descendant" 2 ;; esac
    tmp="$(mktemp "$registry.XXXXXX")"
    if awk -F'\t' -v OFS='\t' -v n="$set_name" -v p="$set_project" -v t="$set_tier" -v nn="$set_newname" '
         !/^#/ && NF >= 4 && $1 == n { if (p != "") $3 = p; if (t != "") $4 = t; if (nn != "") $1 = nn; hit = 1 }
         { print }
         END { exit !hit }
       ' "$registry" > "$tmp"; then
      mv "$tmp" "$registry"
    else
      rm -f "$tmp"
      die "no repo named $set_name in the registry" 1
    fi
    ;;

  check)
    mapfile -t roots < <(all_roots)
    [ "${#roots[@]}" -gt 0 ] || die "no root given and none saved; pass --root <dir>" 2
    known="$(registered_paths)"
    bad=0
    while IFS= read -r dir; do
      [ -n "$dir" ] || continue
      if ! grep -qxF "$dir" <<<"$known"; then
        printf 'unregistered: %s\n' "$dir"; bad=1
      fi
    done < <(discover "${roots[@]}")
    if [ -f "$registry" ]; then
      while IFS=$'\t' read -r name path project _; do
        if [ "$project" = unassigned ]; then
          printf 'unassigned: %s (%s)\n' "$name" "$path"; bad=1
        fi
      done < <(awk -F'\t' '!/^#/ && NF >= 4' "$registry")
    fi
    exit "$bad"
    ;;
esac
