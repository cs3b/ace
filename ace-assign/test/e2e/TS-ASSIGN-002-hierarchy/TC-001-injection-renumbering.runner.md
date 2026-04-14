# Goal 1 — Injection and Renumbering

## Goal

Test child injection and cascade renumbering: create an assignment, inject child steps under a parent (`add --after X --child`), inject a sibling after a child (triggers renumbering), then verify descendant numbering shifts when the parent shifts.

## Workspace

Save only command captures to `results/tc/01/`.

## Constraints

- Create assignment from the copied local fixture path `injection/jobs/8qbyvw-job.yml` inside the sandbox root.
- Extract assignment id from create output, then run `ace-assign select <id>` before mutation commands.
- For all `add` commands in this goal, do NOT pass `--assignment`; use the selected active assignment context.
- `ace-assign add` must use `--yaml`; do not use free-form titles.
- Write exact scratch YAML inputs under `.ace-local/e2e-inputs/tc01/`, each with a top-level `steps:` array containing exactly one named step:
  - `child-01.yaml` -> `child-01`
  - `child-02.yaml` -> `child-02`
  - `child-03.yaml` -> `child-03`
  - `sibling-after-child.yaml` -> `sibling-after-child`
  - `grandchild-01.yaml` -> `grandchild-01`
  - `sibling-after-parent-renumber.yaml` -> `sibling-after-parent-renumber`
- Execute this exact mutation sequence and capture each command with the stable names below:
  1. `ace-assign add --yaml .ace-local/e2e-inputs/tc01/child-01.yaml --after 010 --child` -> `add_child1.*`
  2. `ace-assign add --yaml .ace-local/e2e-inputs/tc01/child-02.yaml --after 010 --child` -> `add_child2.*`
  3. `ace-assign add --yaml .ace-local/e2e-inputs/tc01/child-03.yaml --after 010 --child` -> `add_child3.*`
  4. `ace-assign status --mode full` -> `status_after_children.*`
  5. `ace-assign add --yaml .ace-local/e2e-inputs/tc01/sibling-after-child.yaml --after 010.01` -> `add_sibling_after_child.*`
  6. `ace-assign status --mode full` -> `status_after_renumber1.*`
  7. `ace-assign add --yaml .ace-local/e2e-inputs/tc01/grandchild-01.yaml --after 010.03 --child` -> `add_grandchild_under_renumbered.*`
  8. `ace-assign status --mode full` -> `status_after_grandchild.*`
  9. `ace-assign add --yaml .ace-local/e2e-inputs/tc01/sibling-after-parent-renumber.yaml --after 010.02` -> `add_sibling_after_010_02.*`
  10. `ace-assign status --mode full` -> `status_final.*`
- Do not retry with alternate capture names or additional mutation attempts once this sequence has started.
- The required end state is explicit:
  - after step 4: children `010.01`, `010.02`, `010.03`
  - after step 6: `sibling-after-child` at `010.02`, original `child-02` shifted to `010.03`
  - after step 8: `grandchild-01` at `010.03.01`
  - after step 10: `sibling-after-parent-renumber` at `010.03`, `child-02` at `010.04`, and `grandchild-01` cascaded to `010.04.01`
- Mention the assignment id and the final renumbered descendant path in final runner observations.
