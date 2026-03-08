# Canonical Skill Discovery - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: List canonical skills

**Goal**: Discover canonical package skills across all supported types.

```bash
ace-nav skill://*

# Expected output:
# Canonical skills from registered package handbook/skills sources are listed.
```

### Scenario 2: Resolve one canonical skill

**Goal**: Resolve the authoritative package-owned file for a skill name.

```bash
ace-nav skill://as-task-plan

# Expected output:
# /home/mc/ace-meta/ace-task/handbook/skills/as-task-plan/SKILL.md
```

### Scenario 3: Unknown skill lookup

**Goal**: Return a deterministic not-found result for a missing canonical skill.

```bash
ace-nav skill://missing-skill

# Expected output:
# Not found in registered canonical skill sources
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
