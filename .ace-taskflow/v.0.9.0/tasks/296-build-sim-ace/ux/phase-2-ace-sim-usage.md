# Phase 2 ace-sim Usage (Package Contract)

## Goal

Run generic step-based simulation through `ace-sim run` using the contracts proven in phase 1.

## Canonical Command

```bash
ace-sim run \
  --scenario next-phase \
  --source <idea-ref|task-ref> \
  --steps draft,plan \
  --provider <providerA:model> \
  --provider <providerB:model> \
  --repeat 2 \
  --dry-run
```

## Minimal Single-Provider Repeat

```bash
ace-sim run \
  --scenario next-phase \
  --source <idea-ref|task-ref> \
  --steps draft,plan \
  --provider <provider:model> \
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
- Provider labels retained in comparison synthesis
- Writeback is explicit and never implicit in dry-run mode
