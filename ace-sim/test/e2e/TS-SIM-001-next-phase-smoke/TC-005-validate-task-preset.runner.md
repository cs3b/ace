# Goal 5: Validate-Task Preset Contract

## Objective
Exercise the shipped `validate-task` preset and capture run artifacts that prove the preset contract and plan/work chain structure are intact.

## Workspace

Save all output to `results/tc/05/`.

Capture:
- `results/tc/05/run.stdout|stderr|exit`
- `results/tc/05/run-dir.txt`
- `results/tc/05/run-tree.txt`
- `results/tc/05/session.yml`
- `results/tc/05/synthesis.yml`
- `results/tc/05/final.input.md`

## Steps
1. Create source file `results/tc/05/source.md` with realistic markdown task content.
2. Run:
   `ace-sim run --preset validate-task --source results/tc/05/source.md --provider glite --repeat 1`
   Save stdout/stderr/exit to `results/tc/05/run.*`.
3. Extract `Run Dir:` value from stdout and save it to `results/tc/05/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/05/run-tree.txt`.
5. If present, capture:
   - `session.yml` -> `results/tc/05/session.yml`
   - `synthesis.yml` -> `results/tc/05/synthesis.yml`
   - `final/input.md` -> `results/tc/05/final.input.md`
6. Preserve the actual run outcome. Do not fabricate success. The verifier will accept either:
   - a successful synthesis run with final output artifacts, or
   - a failed final synthesis where chain completion evidence and `synthesis.yml` final-stage failure are present.
