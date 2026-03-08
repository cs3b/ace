# Skill Registry Migration - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Discover canonical skills across packages

**Goal**: See the package-owned skills that drive assign composition and provider views.

```bash
ace-nav skill://*

# Expected output:
# as-task-work
# as-review-pr
# as-e2e-run
# ...
#
# Results are resolved from package-owned handbook/skills registrations.
```

### Scenario 2: Compose from migrated skill metadata

**Goal**: Build an assignment from skills without relying on phase YAML as the source of truth.

```bash
/as-assign-compose "work on task 123 and create a PR"

# Expected output:
# Proposed assignment uses phases sourced from canonical package skills
# Runtime creation still flows through ace-assign create FILE
```

### Scenario 3: Inspect one canonical skill path

**Goal**: Resolve the authoritative package-owned skill file for a capability.

```bash
ace-nav skill://as-task-work

# Expected output:
# /home/mc/ace-meta/ace-task/handbook/skills/as-task-work/SKILL.md
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
