# Intent Resolution - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Explicit step list

**Goal**: Ask for concrete steps without knowing catalog internals.

```bash
/as-assign-create "run tests, reorganize commits, push to remote"

# Expected output:
# Assignment is created with phases that reflect the requested steps
# Hard ordering adjustments, if any, are explainable
```

### Scenario 2: High-level skill-backed request

**Goal**: Use one higher-level intent and still get deeper sub-phases.

```bash
/as-assign-create "work on task 123 and create a PR"

# Expected output:
# Assignment is created
# Task-work behavior expands through assign.source metadata rather than remaining a flat opaque phase
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
