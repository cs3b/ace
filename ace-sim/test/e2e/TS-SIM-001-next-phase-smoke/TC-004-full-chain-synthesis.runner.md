# Goal 4: Full-Chain Final Synthesis Coverage

## Objective
Verify the default full chain (`draft,plan,work`) is aggregated into final synthesis inputs and that synthesis outcome is recorded cleanly. If the external synthesis provider succeeds, capture the final artifacts; if it fails, preserve the failure evidence and artifact paths without treating missing live-provider success as a scenario defect.

## Steps
1. Create source file `results/tc/04/source.md` with realistic markdown content.
2. Run:
   `ace-sim run --preset validate-idea --source results/tc/04/source.md --provider glite --repeat 1 --synthesis-workflow wfi://task/review --synthesis-provider claude:haiku`
   Save stdout/stderr/exit to:
   - `results/tc/04/run.stdout`
   - `results/tc/04/run.stderr`
   - `results/tc/04/run.exit`
3. Extract `Run Dir:` value from stdout and save it to `results/tc/04/run-dir.txt`.
4. If a run dir is present, recursively list it into `results/tc/04/run-tree.txt`.
5. If present, capture:
   - `session.yml` -> `results/tc/04/session.yml`
   - `synthesis.yml` -> `results/tc/04/synthesis.yml`
   - `final/input.md` -> `results/tc/04/final.input.md`
   - `final/source.original.md` -> `results/tc/04/source.original.md`
   - `final/output.sequence.md` -> `results/tc/04/output.sequence.md`
   - `final/suggestions.report.md` -> `results/tc/04/suggestions.report.md`
   - `final/source.revised.md` -> `results/tc/04/source.revised.md`
6. If any final synthesis artifact in step 5 is missing, create a placeholder file at the target path with a short note that synthesis output was unavailable for this run.
7. Preserve the actual run outcome. Do not fabricate success. The verifier will accept either:
   - a successful synthesis run with final output artifacts, or
   - a failed final synthesis where the full chain completed and `synthesis.yml` clearly records the final-stage failure.
