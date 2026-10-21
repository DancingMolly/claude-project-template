# Tasks

Backlog for the template repo itself. Downstream projects get their own copy at
`template/TASKS.md`. Format and conventions: see `template/AGENTS.md`'s "Backlog
entry conventions".

## Backlog

- **Require a repo to be on the latest commit of its branch before any work.**
  Add a new first step to `template/AGENTS.md`'s "Task workflow", before
  "Read `SPEC.md` in full", so stale work is caught before it starts.
  - Step text: run `git fetch`, then compare `HEAD` to the branch's upstream
    (`git rev-list --count HEAD..@{u}`). Zero means current; proceed.
  - Behind and the tree is clean: `git pull --ff-only`, then proceed.
  - Behind with uncommitted changes, diverged, detached `HEAD`, or no
    upstream: stop and tell the user. Don't pull, rebase, or guess.
  - `git fetch` fails (offline, auth): say so and ask whether to proceed on
    the local state. Don't proceed silently.
  - Applies to every session start, and to a peer-dispatched entry's pickup
    turn, since a filed entry may be stale by then.
  - Renumber the later steps in "Task workflow". Root `AGENTS.md` follows
    the template's sections, so it needs no separate edit.
  - Add the new step to the root `AGENTS.md` "Shared sections" list, so
    the family syncs to it. Today the list names only the "Backlog entry
    conventions" and "Changing a convention" subsections of Task workflow.
  - Once it lands here, dispatch it with `dispatch-section.sh` to each
    sibling, one repo at a time, and to descendants as a proposal (see
    "Proposing a section to a descendant"). Include the shared-section
    trailer for siblings.
  - Assumption, unverified: each member's Task workflow numbers its steps
    like the template's. Read each repo's copy before dispatching, and
    adapt the step placement, not the step text.
  - Verify: `template/AGENTS.md` step 1 names the fetch and compare, the
    four stop cases, and the later steps are renumbered. `grep -n "fetch"
    template/AGENTS.md` shows the new step.
