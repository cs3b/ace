# Goal 1 - Real Package Scenario Run Produces Report Tree Verification

## Expectations

1. `real_run.stdout` shows a real scenario execution attempt for `TS-DEMO-001`
   (for example lines such as `Running E2E test: TS-DEMO-001`).
2. `real_run.stdout` includes a concrete `Report:` path under `.ace-local/test-e2e/runner-002-report`.
3. The report path exists after execution and contains scenario report artifacts.
4. `real_run.stderr` is captured when present (for triage), but report tree creation is the
   primary oracle for this goal.

## Verdict

- **PASS**: Non-dry-run command executes and creates a report tree with artifacts.
- **FAIL**: Missing execution evidence or missing report tree artifacts.
