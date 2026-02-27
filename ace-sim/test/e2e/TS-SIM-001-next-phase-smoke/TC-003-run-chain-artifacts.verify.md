# Goal 3 Verification: Preset Run and Chained Artifacts

PASS when:
- `results/tc/03/run.exit` is `0`
- `results/tc/03/run.stdout` includes `Run ID:` and `Run Dir:`
- `results/tc/03/run-tree.txt` includes `chains/`
- `results/tc/03/run-tree.txt` includes `01-draft/input.md` and `01-draft/output.md`
- `results/tc/03/run-tree.txt` includes `user.bundle.md` and `user.prompt.md`
- `results/tc/03/session.yml` exists and contains `preset: validate-idea`
- `results/tc/03/synthesis.yml` exists and contains `chains:`
