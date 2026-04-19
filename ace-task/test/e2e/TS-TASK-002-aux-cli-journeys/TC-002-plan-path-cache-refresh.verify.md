# Goal 2 - Plan Path Cache Refresh Verification

## Injected Context

The verifier receives the `results/` directory tree and sandbox path.

## Expectations

Validation order (impact-first):
1. Confirm plan command captures exist under `results/tc/02/`.
2. Accept either a successful path-mode `ace-task plan` command or actionable sandbox diagnostics from every failed plan attempt.
3. Use success-path artifact generation when a plan command succeeds; otherwise treat stderr diagnostics as the primary evidence.

1. `create.exit` and `show-path.exit` are `0`.
2. Either:
   - at least one of `plan-path-initial.exit` or `plan-path-refresh.exit` is `0`, or
   - both commands fail with actionable dependency diagnostics explaining why plan generation is unavailable or timed out in the sandbox.
3. Any `plan-path-*.exit` that is `0` has stdout containing a non-empty plan path.
4. Any successful `plan-path-*` command has a corresponding copied plan file in results (`plan-path-initial.plan.md` or `plan-path-refresh.plan.md`).
5. Any non-zero `plan-path-*.exit` output includes actionable dependency diagnostics (for example `Preset 'project' not found`, `No available models for role 'planner'`, or `Plan generation failed: Codex CLI execution timed out after 30 seconds`).

## Verdict

- **PASS**: At least one plan path command succeeds with a real artifact, or the sandbox produces only actionable dependency failures; command artifacts are present in either case.
- **FAIL**: Successful runs lack artifacts, failures are not actionable, or command artifacts are missing.

If both plan commands exit non-zero with `Plan generation failed: Codex CLI execution timed out after 30 seconds` in stderr, report `PASS` because the public CLI produced bounded, actionable sandbox diagnostics.
