# Public Create and Drive - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Normal public creation

**Goal**: Create an assignment using the only supported public creation skill.

```bash
/as-assign-create "work on task 123 and create a PR"

# Expected output:
# Assignment created
# User is told to continue with /as-assign-drive
```

### Scenario 2: Create and begin immediately

**Goal**: Skip the extra drive step when explicitly requested.

```bash
/as-assign-create "work on task 123 and create a PR" --run

# Expected output:
# Assignment created
# Drive workflow starts immediately as the last create step
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
