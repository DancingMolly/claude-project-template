# claude-project-template

Default scaffolding for a new Claude-Code-developed project. It's distilled from
conventions that emerged independently across several existing projects. They
include a scripts workspace, a Python QA pipeline, and an infrastructure repo.
This README is about the template itself. It is **not** part of what gets
copied into a new project. Everything meant to be copied lives under [`template/`](template/).

## Workflow this template establishes

- **Single-stage backlog.** `TASKS.md` has just `## Backlog`, no separate
  planning phase or staging directory. Pick the next Backlog entry, implement
  it, verify it, commit as you go, push the finished series, then delete it
  from the list.
- **Session-based changelog.** `CHANGELOG.md` records a human-readable narrative
  history per work session (`## YYYY-MM-DD (session N)`). It's the "what
  actually happened and why" log, including which Backlog entry each session
  completed.
- **ISO dates (`YYYY-MM-DD`)** everywhere, for sortability and to avoid ambiguity.
- **`SPEC.md` as the single source of technical truth**, with a documented path to
  split into `specs/*.md` by topic once it outgrows one file.

## Using this template

1. Copy everything under `template/` into the new project's root:
   ```
   cp -r template/. /path/to/new-project/
   ```
   This brings two instruction files: `AGENTS.md` holds the conventions, and
   `CLAUDE.md` is a one-line `@AGENTS.md` import, kept so the conventions still
   load in a Claude Code session that can't read `AGENTS.md` directly.
2. Fill in every `<placeholder>` token (project name, purpose, install/usage
   steps).
3. Delete the sample Backlog entry in `TASKS.md` and add real ones.
4. Delete the explanatory HTML comments in `SPEC.md`/`TASKS.md`/`CHANGELOG.md`
   once real content replaces them. They're scaffolding, not permanent structure.
5. `template/.claude/settings.json` ships a security-hardened default. It has a
   permissions deny list for reading credential paths, an ask list for
   destructive git operations, and a fail-closed sandbox filesystem block.
   Adjust it per project if it needs different permissions, or different sandbox
   filesystem or network access. The same file wires a `SessionStart` hook
   that restores context after `/compact`. Edit `.claude/post-compact-files`
   to list the files your project needs back.
6. Extend `.gitignore` with any project-specific secret/output paths as they
   come up.

## Cross-repo documentation governance

This repo and the repos that name it as parent share a documentation and
task-tracking convention. When it needs to change, orchestrate the change
from this repo, not from a sibling repo in isolation. Independent changes
are how the family drifted out of sync before.

- Know which repos are on this host. The family is not a committed list.
  `family-scan.sh --root <dir>` searches `<dir>` for repos whose `AGENTS.md`
  names this one as parent, and records them in `registry.local`, which is
  gitignored. Set each repo's project and tier with
  `--set <name> --project <p> --tier <t>`. `--list` prints the registry, and
  `--check` fails on a repo that is missing from it or still `unassigned`. Two
  hosts can hold different repos, since the file never leaves the host.
- Resolve each repo's current session by repo root, per `AGENTS.md`'s
  "Cross-session tasking" ("Address a repo, not a session"), not by a
  remembered name. Cross-check the result against `ListAgents` before
  starting a new one. The sandbox blocks writes outside a session's own
  launch directory, so a session already rooted in the target repo can
  commit and push there when this one can't.
- Run `/clear` on a reused session before loading it with a new task. Its
  own accumulated history otherwise inflates the cost of every message this
  repo sends it.
- Drive each sibling session with exact, mechanical instructions, rather
  than handing it the plan to interpret. A shared-section dispatch carries
  that section's exact final text, not prose for the sibling to reconstruct
  wording from: reconstructing is how the two copies drifted before.
  Keeping judgment calls in this repo's session is what keeps the family
  converging, instead of diverging again.
- Batch every section bound for one repo into a single dispatch, so its
  user confirms once instead of once per section. Six separate round trips
  to one sibling burned most of a session on confirmation overhead alone.
- Roll out to one repo at a time. A rollout may cover one project, such as
  `./family-scan.sh --list --project <name>`. Send nothing to the next repo
  until the current one is verified in place on its origin. A filing acknowledgement
  does not count, and neither does an implementation report on its own.
  Verify from the repo itself:
  - its commits are ancestors of the pushed branch, and `git status -sb`
    shows nothing ahead;
  - each section diffs clean against the parent, apart from its documented
    local carve-outs;
  - any hook or script is tracked, executable, and identical to the
    parent's copy;
  - `git status --porcelain -uall` shows no placeholder, and `git
    check-ignore` hits no tracked file;
  - its own `TASKS.md` and `CHANGELOG.md` record the work, and its report
    arrived before it deleted the entry.
  One repo at a time also spares the operator's token budget, since a
  failure surfaces in one repo, not several. Order the repos by dependence.
  Where a repo needs a placeholder replaced, hand the operator a one-liner
  and wait.
- A sync is not done when the edits land in the siblings; it is done once
  each sibling has reported its *implementation* back and this repo has read
  the commits it names. Reading them means more than checking the diff.
  Run `git -C <root> status -sb` and confirm the branch is not ahead of
  origin. Run `grep -n '^## '` around the changed section to confirm it sits
  under the right heading. Check the peer's own `TASKS.md` and `CHANGELOG.md`
  record it. One sibling's sync passed a diff-only read, yet was unpushed,
  spliced under the wrong intro, and unrecorded. A run once stalled for this
  reason: a filing acknowledgement was mistaken for a completed sync, so both
  sides sat waiting on the other. See `AGENTS.md`'s "Cross-session tasking" for
  the rule that now requires that report.
- Use `dispatch-section.sh` (repo root) to assemble a dispatch message: it
  extracts a shared section's exact text, batches several into one message,
  and appends the closing block that demands a completion report. Run
  `./dispatch-section.sh --check` before a sync. It fails if the two
  `Cross-session tasking` copies have drifted, which would make the
  extracted text wrong.
- Expect every sibling session to insist on its own user's direct
  confirmation before acting on an instruction from this one, especially
  one that edits its `AGENTS.md` or deletes content. That's correct
  behaviour, not a bug. See `AGENTS.md`'s "Cross-session tasking" for the
  rules this follows. Keep every sibling session's terminal attended
  during a sync, so that confirmation is quick when it's asked for.
- Say so up front. The first message to a repo's session should flag
  anything likely to need its user's sign-off, so that check happens
  once for that repo, rather than surfacing bottleneck by bottleneck as
  each edit lands.
- Before dictating a reversal of a sibling session's own prior decision,
  ask whether that decision exists, and why. Discovering the conflict only
  when a peer refuses costs a full round trip; asking first does not.

## What's deliberately not included

- No two-phase plan/execute workflow, `plans/` staging directory, or slash
  commands. That machinery earns its keep on a project with a real lint/test
  gate and multiple parallel workstreams. It's overhead for a typical new
  project. Reintroduce it per-project if and when that complexity shows up.
