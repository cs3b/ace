# Goal 3 — Display and Audit Trail

## Goal

Verify status displays tree structure with hierarchy indicators, and audit trail metadata is correctly populated for child injection, sibling injection, renumbering, and dynamic adds.

## Workspace

Save only real command captures to `results/tc/03/`.

## Constraints

### Tree Display
- Create assignment with the explicit command `ace-assign create --yaml ./fixtures/display/job-tree.yaml`.
- Use `--yaml` step files for all adds in this goal; do not use free-form titles.
- If runtime YAML files are needed, write them under sandbox scratch space such as `.ace-local/e2e-inputs/tc03/`, not under `results/`.
- Add two child steps under 010 and one child under 020 using explicit child insertion commands:
  - `ace-assign add --yaml <child-a-yaml> --after 010 --child`
  - `ace-assign add --yaml <child-b-yaml> --after 010 --child`
  - `ace-assign add --yaml <child-c-yaml> --after 020 --child`
- Capture hierarchy display with `ace-assign status --mode full` as `status_full.*`. Do not use `--tree`.
- Verify the full status output shows all 5 steps, hierarchy indicators, and nested step numbers (`010.01`, `010.02`, `020.01`).

### Audit Trail
- Clean cache, then create a fresh audit assignment with the explicit command `ace-assign create --yaml ./fixtures/display/job-tree.yaml`.
- Use scratch YAML inputs under `.ace-local/e2e-inputs/tc03/`, not under `results/`.
- Add two child steps under 010 with explicit child insertion commands:
  - `ace-assign add --yaml <child-a-yaml> --after 010 --child`
  - `ace-assign add --yaml <child-b-yaml> --after 010 --child`
- Inject a sibling after `010.01` with a non-child insertion command:
  - `ace-assign add --yaml <sibling-after-yaml> --after 010.01`
- Add one top-level dynamic step as described below.
- The dynamic step command must be truly top-level:
  - `ace-assign add --yaml .ace-local/e2e-inputs/tc03/dynamic-top.yaml`
  - do **not** pass `--after`
  - do **not** pass `--child`
  - the copied dynamic step file must therefore show `added_by: dynamic`
- Capture `create_audit.*`, `select_audit.*`, `add_child_a.*`, `add_sibling_after.*`, `add_dynamic_top.*`, and `status_audit_full.*`.
- Create `results/tc/03/step-files/` before copying.
- After the audit mutations, copy the real step files themselves into `results/tc/03/step-files/` using their original filenames:
  - the child step under `010.01-*`
  - the injected sibling under `010.02-*`
  - the renumbered original child under `010.03-*`
  - the dynamic top-level step under its actual number (for example `021-*`)
- If any expected step file is missing, stop and surface that mismatch in runner observations instead of silently continuing.
- These copied `.st.md` files are canonical outcome evidence from the tool, not synthetic helper files.
- Mention the audit assignment id in final runner observations.
