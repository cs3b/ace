# Generic Fan-out - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Repeated E2E execution

**Goal**: Replace the bespoke E2E batch wrapper with one reusable assign workflow.

```bash
/as-assign-run-in-batches "Run E2E scenario {{item}}" --items TS-001,TS-002 --run

# Expected output:
# Parent/child assignment created
# Each child targets one scenario
# Drive starts immediately because --run was requested
```

### Scenario 2: Ordered repeated work

**Goal**: Reuse the same workflow when items must run sequentially.

```bash
/as-assign-run-in-batches "Update docs for {{item}}" --items ace-assign,ace-task --sequential

# Expected output:
# Assignment created
# Child phases do not use fork context
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
