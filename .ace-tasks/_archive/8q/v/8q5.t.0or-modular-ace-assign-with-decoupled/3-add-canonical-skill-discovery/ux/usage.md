# Canonical Skill Discovery

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: List canonical skills

**Goal**: Discover canonical package skills across all supported types.

```bash
ace-nav list skill://*

# Expected output:
# skill://as-task-plan -> .../handbook/skills/as-task-plan/SKILL.md
# skill://as-assign-start -> .../handbook/skills/as-assign-start/SKILL.md
# ...
```

### Scenario 2: Resolve one canonical skill

**Goal**: Resolve the authoritative package-owned file for a skill name.

```bash
ace-nav resolve skill://as-task-plan

# Expected output:
# /path/to/<winning-source>/handbook/skills/as-task-plan/SKILL.md
# Winner follows normal source priority/precedence rules.
```

### Scenario 3: Unknown skill lookup

**Goal**: Return a deterministic not-found result for a missing canonical skill.

```bash
ace-nav resolve skill://missing-skill

# Expected output:
# Resource not found: skill://missing-skill
# The command reports searched sources as part of the standard nav not-found path.
```
