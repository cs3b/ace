# Typed Skill Ecosystem Migration - Usage

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

## Scenario 4: Review migration inventory and dispositions

**Goal**: Confirm every projected skill is explicitly classified as migrated, pending migration, or workflow-only.

```bash
cat .ace-tasks/8q5.t.0or-modular-ace-assign-with-decoupled/5-inventory-and-migrate-typed-skills/migration/typed-skill-inventory.md

# Expected output:
# Inventory includes all projected skills with kind, workflow binding, canonical path (if migrated),
# and explicit disposition for workflow-only exceptions.
```

## Notes
- This repository uses `ace-nav list skill://*` for protocol discovery listing.
- `ace-nav skill://*` is not a direct command form in this CLI.
