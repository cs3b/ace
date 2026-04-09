# Goal 1 — Injection and Renumbering

## Goal

Test child injection and subtree cascade renumbering in two phases: first prove direct sibling renumbering, then force a second sibling insertion that shifts an existing child subtree and captures descendant renumber evidence.

## Workspace

Save all output to `results/tc/01/`. Capture:
- `results/tc/01/create.stdout`, `.exit` — assignment creation
- `results/tc/01/steps-dir.txt` — resolved steps directory for the created assignment
- `results/tc/01/child-inject-1.stdout`, `.stderr`, `.exit` — first child injection
- `results/tc/01/child-inject-2.stdout`, `.stderr`, `.exit` — second child injection
- `results/tc/01/child-inject-3.stdout`, `.stderr`, `.exit` — third child injection
- `results/tc/01/first-sibling-inject.stdout`, `.exit` — first sibling injection under 010 (direct renumber)
- `results/tc/01/step-listing-after-first-renumber.stdout` — step files after the first sibling injection
- `results/tc/01/renumbered-parent.stdout` — metadata for the child step renumbered by the first sibling injection
- `results/tc/01/cascade.stdout`, `.exit` — grandchild creation under the renumbered child
- `results/tc/01/step-listing-before-cascade.stdout` — step files after grandchild creation, before subtree shift
- `results/tc/01/second-sibling-inject.stdout`, `.exit` — second sibling injection that forces subtree cascade renumbering
- `results/tc/01/step-listing-after-cascade.stdout` — step files after subtree cascade renumbering
- `results/tc/01/renumbered-grandchild.stdout` — metadata for the grandchild after cascade renumbering

## Constraints

- Create assignment from the fixture job file.
- Resolve the created assignment's `steps/` directory once after create and save it to `steps-dir.txt`; use that exact directory for every later listing and metadata read in this TC.
- Add child steps under 010 using explicit YAML files and `ace-assign add --yaml ... --after 010 --child --assignment "<id>"`.
- Do not use `--step work-on-task`, `--step child*`, or any preset-backed insertion in this TC.
- The three child YAML inserts must produce `child-a`, `child-b`, and `child-c`, becoming 010.01, 010.02, 010.03.
- First renumber phase:
  - Inject sibling after 010.01 using explicit YAML insertion (`ace-assign add --yaml ... --after 010.01 --assignment "<id>"`).
  - The new sibling becomes 010.02 and the old `child-b` shifts from 010.02 to 010.03.
  - Capture the post-renumber listing from the resolved `steps/` directory after the injection command completes.
  - Read the real shifted `child-b` step file into `renumbered-parent.stdout`; do not capture `child-c` or any stale pre-renumber path.
- Cascade phase:
  - Add grandchild under the renumbered parent using explicit YAML insertion with `--after 010.03 --child --assignment "<id>"` so it appears as `010.03.01`.
  - Capture `step-listing-before-cascade.stdout` after the grandchild exists.
  - Inject another sibling after 010.02 using explicit YAML insertion so the existing `010.03` subtree shifts to `010.04`.
  - Capture `step-listing-after-cascade.stdout` after the second sibling injection.
  - Read the real `010.04.01-*.st.md` file into `renumbered-grandchild.stdout`.
- The cascade proof must come from the second sibling injection and the before/after listings, not inferred from grandchild creation alone.
- If the shifted parent or grandchild file cannot be resolved unambiguously, still write `renumbered-parent.stdout` or `renumbered-grandchild.stdout` with an explicit lookup-failure explanation rather than omitting the artifact or writing metadata from the wrong step.
- All artifacts must come from real tool execution.
