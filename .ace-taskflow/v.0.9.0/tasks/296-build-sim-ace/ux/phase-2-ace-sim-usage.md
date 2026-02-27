# Phase 2 ace-sim Usage (Package Contract)

## Goal

Run generic step-based simulation through `ace-sim run` using contracts proven in phase 1.

## Canonical Command

```bash
ace-sim run \
  --scenario next-phase \
  --source <idea-ref|task-ref> \
  --steps draft,plan \
  --provider google:gflash \
  --provider codex:mini \
  --repeat 2 \
  --dry-run
```

## Minimal Single-Provider Repeat

```bash
ace-sim run \
  --scenario next-phase \
  --source <idea-ref|task-ref> \
  --steps draft,plan \
  --provider codex:mini \
  --repeat 2 \
  --no-writeback
```

## Expected Artifacts

- `.cache/ace-sim/simulations/<run-id>/session.yml`
- `.cache/ace-sim/simulations/<run-id>/stages/draft.yml`
- `.cache/ace-sim/simulations/<run-id>/stages/plan.yml`
- `.cache/ace-sim/simulations/<run-id>/synthesis.yml`

## Behavioral Guarantees

- Linear step chain for v1 (`draft` -> `plan`)
- Step N input includes output of step N-1
- Provider labels retained in synthesis/comparison outputs
- Writeback defaults to disabled unless explicitly enabled
- `--dry-run` is always non-mutating for source ideas/tasks

## Error and Edge Cases

### Source cannot be resolved

- Command fails with non-zero exit.
- Error message identifies unresolved `--source` value.
- No writeback occurs.

### Partial provider failure

- If one provider fails and at least one succeeds, session output records per-provider status.
- Successful provider artifacts are retained.
- Failure classification records `provider unavailable` for the failing provider.

### Dry run behavior

- Dry-run creates cache artifacts only.
- Dry-run never mutates source files or taskflow state.

## Smoke Gate Note

- Required smoke provider for `TS-SIM-001-next-phase-smoke` is `codex:mini`.
- This smoke is mandatory as a manual acceptance gate; CI execution is optional when credentials and budget are available.
