# Skill-First Spike - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Resolve the representative canonical skill

**Goal**: Prove one migrated capability is discoverable through the new registry.

```bash
ace-nav skill://as-task-work

# Expected output:
# /home/mc/ace-meta/ace-task/handbook/skills/as-task-work/SKILL.md
```

### Scenario 2: Compose from the representative migrated skill

**Goal**: Prove one assignment path uses the migrated skill metadata.

```bash
/as-assign-create work-on-task --taskref 123

# Expected output:
# Assignment composition uses metadata from the canonical migrated skill
# Runtime creation still flows through ace-assign create FILE
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
