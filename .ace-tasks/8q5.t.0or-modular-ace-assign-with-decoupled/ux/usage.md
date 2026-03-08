# Typed Canonical Skills - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Discover canonical skills across types

**Goal**: See capability, workflow, and orchestration skills from package-owned canonical sources.

```bash
ace-nav skill://*

# Expected output:
# as-b36ts
# as-task-plan
# as-assign-start
# ...
#
# Results are resolved from package-owned handbook/skills sources.
```

### Scenario 2: Inspect a canonical capability skill

**Goal**: Resolve the authoritative package-owned skill file for a non-assign capability.

```bash
ace-nav skill://as-b36ts

# Expected output:
# /home/mc/ace-meta/ace-b36ts/handbook/skills/as-b36ts/SKILL.md
```

### Scenario 3: Compose from the assign-capable subset

**Goal**: Build an assignment from workflow/orchestration skills while capability skills remain discoverable but excluded.

```bash
/as-assign-compose "plan task 123 and then start the assignment"

# Expected output:
# Proposed assignment uses phases sourced from canonical workflow/orchestration skills
# Capability skills like as-b36ts are discoverable through skill:// but do not appear as phases
```

### Scenario 4: Inspect a projected provider skill

**Goal**: Verify provider-facing skills are generated from the canonical source.

```bash
ls .agent/skills/as-task-plan
ls .claude/skills/as-task-plan

# Expected output:
# Generated provider-facing skill paths exist for the canonical skill
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
