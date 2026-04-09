# Goal 3 - Dry-Run Discovers Repo Scenarios Verification

## Expectations

Validation order (impact-first):
1. Confirm explicit artifacts under `results/tc/03/`.
2. Use debug evidence only as fallback.

1. `discovery.exit` is `0`.
2. `discovery.stdout` includes `Dry run: preview of scenarios to execute`.
3. `discovery.stdout` includes `TS-DEMO-001`.
4. `discovery.stderr` is empty or contains no failure text.

## Verdict

- **PASS**: Dry-run successfully discovers and previews at least one existing scenario.
- **FAIL**: Missing artifacts, wrong exit code, or no discovered scenario output.
