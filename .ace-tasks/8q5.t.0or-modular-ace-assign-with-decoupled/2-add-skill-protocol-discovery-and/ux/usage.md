# Skill Protocol Discovery - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: List canonical package skills

**Goal**: Discover the canonical skills available across registered gems.

```bash
ace-nav skill://*

# Expected output:
# Canonical skills are listed from registered package handbook/skills sources.
```

### Scenario 2: Resolve one canonical skill

**Goal**: Find the authoritative path for a specific skill name.

```bash
ace-nav skill://as-task-work

# Expected output:
# /home/mc/ace-meta/ace-task/handbook/skills/as-task-work/SKILL.md
```

### Scenario 3: Unknown skill lookup

**Goal**: Return a deterministic error for a missing canonical skill.

```bash
ace-nav skill://missing-skill

# Expected output:
# Not found in registered skill sources
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
