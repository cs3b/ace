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
ls ace-task/handbook/skills/as-task-plan

# Expected output:
# Projected ACE-neutral skill path exists for the canonical skill
# Canonical package skill path exists as authored source
```

### Scenario 2: Inspect provider-specific projections

**Goal**: Verify provider-facing views are projected from the same canonical skill.

```bash
ls .claude/skills/as-task-plan
ls .codex/skills/as-task-plan
ls .gemini/skills/as-task-plan
ls .pi/skills/as-task-plan

# Expected output:
# Provider-facing projected skill paths exist for the same canonical capability
```

### Scenario 3: Validate provider rewrite defaults point at projected tree

**Goal**: Verify provider defaults use `.agent/skills` projection path.

```bash
rg -n "skills_dir:" ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml ace-llm-providers-cli/.ace-defaults/llm/providers/pi.yml

# Expected output:
# skills_dir defaults are .agent/skills for projected neutral tree consumption
```

### Scenario 4: Detect projection drift

**Goal**: Verify projected views match canonical skill content for representative skills.

```bash
diff -u ace-task/handbook/skills/as-task-plan/SKILL.md .agent/skills/as-task-plan/SKILL.md
diff -u ace-assign/handbook/skills/as-assign-start/SKILL.md .agent/skills/as-assign-start/SKILL.md

# Expected output:
# no differences for synchronized projected files
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
