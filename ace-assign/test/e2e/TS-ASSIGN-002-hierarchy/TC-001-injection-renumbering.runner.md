# Goal 1 — Injection and Renumbering

## Goal

Test child injection and cascade renumbering: create an assignment, inject child phases under a parent (`add --after X --child`), inject a sibling after a child (triggers renumbering), and verify cascade renumbering of descendants. Capture phase listings at each step.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `results/tc/01/create.stdout`, `.exit` — assignment creation
- `results/tc/01/child-inject-1.stdout`, `.exit` — first child injection
- `results/tc/01/child-inject-2.stdout`, `.exit` — second child injection
- `results/tc/01/child-inject-3.stdout`, `.exit` — third child injection
- `results/tc/01/sibling-inject.stdout`, `.exit` — sibling injection (triggers renumbering)
- `results/tc/01/cascade.stdout`, `.exit` — grandchild + cascade renumbering
- `results/tc/01/phase-listing-pre.stdout` — phase files before renumbering
- `results/tc/01/phase-listing-post.stdout` — phase files after renumbering
- `results/tc/01/phase-metadata.stdout` — renumbered_from/renumbered_at metadata

## Setup

Environment provides:
- `CACHE_BASE=.cache/ace-assign` (create it: `mkdir -p .cache/ace-assign`)
- `PROJECT_ROOT_PATH=.`
- Fixture: `fixtures/injection/job.yml` (copy to `job.yaml` before use)

## Constraints

- Create assignment from the fixture job file.
- Add child phases under 010 (`add --after 010 --child`): three children should become 010.01, 010.02, 010.03.
- Verify child metadata: parent: "010", added_by: child_of:010.
- Inject sibling after 010.01 (`add --after 010.01`): new phase becomes 010.02, old 010.02 renumbers to 010.03.
- Verify renumbered phase has renumbered_from and renumbered_at metadata.
- Add grandchild under renumbered child, then inject sibling to trigger cascade renumbering.
- Verify cascade: parent renumbered -> grandchild also renumbered (e.g., 010.03.01 -> 010.04.01).
- All artifacts must come from real tool execution.
