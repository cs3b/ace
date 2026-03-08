# Typed Skill Ecosystem Migration - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [ ] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Discover migrated canonical skills across packages

**Goal**: Confirm the repo exposes typed canonical skills after the migration inventory is applied.

```bash
ace-nav skill://*

# Expected output:
# Canonical skills from multiple packages and multiple types are listed.
```

### Scenario 2: Verify canonical skill coverage on disk

**Goal**: Confirm public capabilities are migrating into package-owned `handbook/skills`.

```bash
find ace-*/handbook/skills -name SKILL.md

# Expected output:
# Canonical skill files exist in packages that own migrated public capabilities.
```

### Scenario 3: Verify projected provider compatibility

**Goal**: Ensure provider-facing skill trees still reflect the migrated canonical set.

```bash
find .agent/skills -name SKILL.md

# Expected output:
# Generated provider-facing skill files exist for the migrated canonical set.
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
