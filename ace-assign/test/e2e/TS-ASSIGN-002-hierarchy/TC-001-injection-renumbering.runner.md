# Goal 1 — Injection and Renumbering

## Goal

Test child injection and cascade renumbering: create an assignment, inject child steps under a parent (`add --after X --child`), inject a sibling after a child (triggers renumbering), and verify cascade renumbering of descendants. Capture step listings at each step.

## Workspace

Save all output to `results/tc/01/`. Required artifact:
- `results/tc/01/` — injection and renumbering execution evidence

## Constraints

- Create assignment from the fixture job file.
- Extract assignment id from create output, then run `ace-assign select <id>` before mutation commands.
- For all `add` commands in this goal, do NOT pass `--assignment`; use the selected active assignment context.
- Add child steps under 010 (`add --after 010 --child`): three children should become 010.01, 010.02, 010.03.
- Verify child metadata: parent: "010", added_by: child_of:010.
- Inject sibling after 010.01 (`add --after 010.01`): new step becomes 010.02, old 010.02 renumbers to 010.03.
- Verify renumbering via status snapshots before/after sibling injection (step numbers shift as expected).
- Add grandchild under renumbered child, then inject sibling to trigger cascade renumbering.
- Verify cascade: when parent numbering shifts, descendant numbering also shifts in later status output.
- All artifacts must come from real tool execution.
