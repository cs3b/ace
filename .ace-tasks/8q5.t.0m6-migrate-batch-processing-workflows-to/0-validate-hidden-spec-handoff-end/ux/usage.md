# Hidden Spec Handoff - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Smart create renders a hidden spec

**Goal**: Create an assignment without manually writing `job.yaml`.

```bash
/as-assign-create work-on-task --taskref 123

# Expected output:
# Assignment is created
# The normalized spec lives under .ace-local/assign/jobs/
```

### Scenario 2: Creation failure stays deterministic

**Goal**: Preserve current CLI failure behavior if the rendered spec is invalid.

```bash
/as-assign-create work-on-task --taskref broken

# Expected output:
# Hidden-spec rendering or ace-assign create reports a concrete error
# No partial assignment is left active
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
