# Canonical Skill Schema - Draft Usage

## API Surface
- [ ] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Author one canonical package skill

**Goal**: Define one package-owned skill that can be used for provider views and assign composition.

```bash
ace-nav skill://as-task-work

# Expected output:
# Canonical path resolves to ace-task/handbook/skills/as-task-work/SKILL.md
# The file carries provider-compatible fields plus additive assign metadata
```

### Scenario 2: Reject invalid canonical assign metadata

**Goal**: Prevent malformed canonical skills from entering discovery and composition.

```bash
ace-nav skill://broken-skill

# Expected output:
# Skill validation reports a concrete missing/invalid assign field
# The invalid skill is not accepted as a composition source
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
