# Goal 2 Verification: Default Preset Behavioral Run

PASS when:
- `results/tc/02/run.exit` is `0`
- `results/tc/02/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/02/run-tree.txt` includes `chains/`
- `results/tc/02/run-tree.txt` includes `01-draft/input.md`, `01-draft/user.bundle.md`, `01-draft/user.prompt.md`, and `01-draft/output.md`
- `results/tc/02/run-tree.txt` includes `02-plan/input.md` and `02-plan/output.md`
- `results/tc/02/run-tree.txt` includes `03-work/input.md` and `03-work/output.md`
- `results/tc/02/session.yml` exists and contains `preset: validate-idea`
- `results/tc/02/synthesis.yml` exists and contains `chains:`
- `results/tc/02/handoff-check.txt` exists and indicates plan input matches draft output
