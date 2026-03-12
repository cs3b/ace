# Goal 3 — Count Mode

## Goal

Run `ace-search --type content --files-with-matches "test" "$PROJECT_ROOT_PATH/ace-search"`
and `ace-search --type content --count "def" "$PROJECT_ROOT_PATH/ace-search/test"`,
then capture count-style output summary.

## Workspace

Save artifacts to `results/tc/03/`.
## Constraints

- Use only declared scenario tools (`ace-*` and explicit exceptions from `requires.tools`).
- Execute actions and capture evidence only; do not assign PASS/FAIL verdicts.
- Keep all artifacts under `results/tc/03/`.
- Do not write outside the sandbox.
- Use explicit search paths rooted at `$PROJECT_ROOT_PATH` so count behavior is
  measured against stable repo content rather than the transient sandbox root.
