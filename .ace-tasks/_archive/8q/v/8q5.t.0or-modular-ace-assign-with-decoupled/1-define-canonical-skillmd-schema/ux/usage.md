# Canonical Skill Schema - Draft Usage

## API Surface
- [ ] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Author a canonical workflow skill

**Goal**: Define one package-owned workflow skill with explicit type and workflow binding.

```bash
ace-nav skill://as-task-plan

# Expected output:
# Canonical path resolves to ace-task/handbook/skills/as-task-plan/SKILL.md
# The file includes skill.kind: workflow and skill.execution.workflow: wfi://task/plan
```

### Scenario 2: Reject assign metadata on a capability skill

**Goal**: Prevent capability skills from entering the assignment registry.

```bash
ace-lint .agent/skills/as-b36ts/SKILL.md

# Expected output:
# Validation fails if a capability skill declares assign:
```

### Scenario 3: Validate canonical taxonomy and workflow binding

**Goal**: Ensure canonical metadata is complete and typed.

```bash
ace-lint .agent/skills/as-task-plan/SKILL.md

# Expected output:
# Validation passes when skill.kind is set and skill.execution.workflow uses wfi://
```

### Scenario 4: Reject unknown ACE-only nested fields

**Goal**: Prevent silently accepting unsupported schema keys.

```bash
ace-lint path/to/custom/SKILL.md

# Expected output:
# Validation fails with actionable errors for unknown fields under skill:/assign:
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
