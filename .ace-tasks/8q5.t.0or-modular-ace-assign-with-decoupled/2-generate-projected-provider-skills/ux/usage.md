# Provider Projection Generation - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Inspect generated ACE-neutral projection

**Goal**: Verify `.agent/skills` is generated from the canonical source rather than authored directly.

```bash
ls .agent/skills/as-task-plan

# Expected output:
# Projected ACE-neutral skill path exists for the canonical skill
```

### Scenario 2: Inspect provider-specific projections

**Goal**: Verify provider-facing views are projected from the same canonical skill.

```bash
ls .claude/skills/as-task-plan
ls .codex/skills/as-task-plan

# Expected output:
# Provider-facing projected skill paths exist for the same canonical capability
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
