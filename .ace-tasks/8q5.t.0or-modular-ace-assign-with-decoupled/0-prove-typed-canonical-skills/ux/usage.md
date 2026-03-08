# Typed Canonical Tracer - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Resolve the three representative canonical skills

**Goal**: Prove the typed taxonomy with one skill of each kind.

```bash
ace-nav skill://as-b36ts
ace-nav skill://as-task-plan
ace-nav skill://as-assign-start

# Expected output:
# Each command resolves a package-owned canonical SKILL.md path
```

### Scenario 2: Verify projected provider compatibility

**Goal**: Confirm all three representative skills still appear in provider-facing trees.

```bash
ls .agent/skills/as-b36ts
ls .agent/skills/as-task-plan
ls .agent/skills/as-assign-start

# Expected output:
# Generated provider-facing paths exist for all three representative skills
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
