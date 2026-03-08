# Repo-Wide Skill Migration - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Discover migrated skills across packages

**Goal**: See canonical skills from multiple packages after the migration.

```bash
ace-nav skill://*

# Expected output:
# Canonical skills from ace-task, ace-review, ace-docs, ace-search, and other migrated packages are listed.
```

### Scenario 2: Verify projected provider compatibility

**Goal**: Ensure provider-facing skill views still exist after canonical migration.

```bash
ls .agent/skills/as-task-work
ls .agent/skills/as-review-pr

# Expected output:
# Projected provider-facing skill paths exist for representative migrated skills.
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
