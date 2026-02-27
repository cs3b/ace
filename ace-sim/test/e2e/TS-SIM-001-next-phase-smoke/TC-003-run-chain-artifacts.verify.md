# Goal 3 Verification: Explicit CLI Override Behavior

PASS when:
- `results/tc/03/run.exit` is `0`
- `results/tc/03/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/03/run-tree.txt` includes `chains/`
- `results/tc/03/run-tree.txt` includes `01-draft/input.md` and `01-draft/output.md`
- `results/tc/03/run-tree.txt` includes `01-draft/user.bundle.md` and `01-draft/user.prompt.md`
- `results/tc/03/run-tree.txt` does not include `02-plan/`
- `results/tc/03/run-tree.txt` does not include `03-work/`
- `results/tc/03/session.yml` exists and contains `preset: validate-idea`
- `results/tc/03/session.yml` contains `steps:` with only `draft`
- `results/tc/03/synthesis.yml` exists and contains `chains:`
