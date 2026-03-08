# Skill-Backed Assign Composition - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Inspect the skill-backed assign catalog

**Goal**: See phases derived from canonical skills instead of phase YAML ownership.

```bash
ace-assign catalog

# Expected output:
# Available phases reflect canonical skill metadata and source attribution.
```

### Scenario 2: Create from the skill registry

**Goal**: Compose and create an assignment from skill-backed metadata while keeping deterministic runtime creation.

```bash
/as-assign-create work-on-task --taskref 123

# Expected output:
# The hidden spec is rendered from skill-backed metadata
# Runtime handoff still uses ace-assign create FILE
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
