# SPEC: <project-name>

<!--
Authoritative technical specification. This is the contract: AGENTS.md points here
for anything design-related, instead of duplicating it. Number sections and
subsections (## N., ### N.M) so other docs and code comments can cite them stably,
e.g. "per SPEC §3.2".

Delete this comment once the project's real sections are in place.
-->

## 1. Purpose and architecture

<!-- What this project does, and the shape of how it does it. One or two
     paragraphs plus a component list is usually enough. -->

### 1.1 Non-goals

<!-- What this project explicitly does NOT do. This matters as much as what it
     does, to keep scope from creeping in later sessions. -->

## 2. <Interface / CLI / API>

<!-- The contract a caller/user interacts with: commands, endpoints, arguments. -->

## 3. <Core data model / schema>

<!-- Any schema this project reads, writes, or owns. Mark anything sourced from an
     external, non-negotiable contract (e.g. an upstream API's response shape) as
     "authoritative and out of scope for this repo to change." If it needs to
     change, that's a stop-and-ask, not a silent workaround. -->

## 4. Cross-cutting conventions

<!-- Conventions that apply everywhere, rather than to one component: naming
     schemes, date/locale formats, error-handling philosophy, idempotency
     requirements, etc. -->

## 5. Testing strategy

<!-- What "tested" means for this project: unit vs integration, golden files,
     pinned tool versions for anything that renders/compares output, etc. -->

## 6. Acceptance criteria

<!-- The concrete, checkable conditions under which this project (or its current
     milestone) is considered done. -->

---

## When this file grows too large

Once a single `SPEC.md` gets unwieldy, split it into `specs/*.md` by topic and
turn this file into a thin index, e.g.:

```markdown
# SPEC.md

Technical constraints and conventions for this repo. See `AGENTS.md` for
process/workflow guidance.

This file is an index. The actual conventions live in `specs/`, split by topic so
only the relevant file needs loading for a given task:

| File | Covers |
|---|---|
| [`specs/topic-a.md`](specs/topic-a.md) | ... |
| [`specs/topic-b.md`](specs/topic-b.md) | ... |

Pick the file that matches what you're doing, rather than reading all of them.
Each is self-contained for its own topic, with pointers to the others where a
convention spans more than one.
```
