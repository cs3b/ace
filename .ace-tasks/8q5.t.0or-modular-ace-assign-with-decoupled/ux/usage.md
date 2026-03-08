# Modular ace-assign with Decoupled Presets - Draft Usage

## API Surface
- [x] CLI (user-facing commands)
- [x] Developer API (modules, classes)
- [x] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Discover Available Phases from All Gems

**Goal**: See what assignable phases are available across the installed gem ecosystem

```bash
ace-assign catalog

# Expected output:
# Available phases:
#   onboard          (ace-assign)    [setup]
#   work-on-task     (ace-task)      [implementation, task]
#   run-review       (ace-review)    [review, quality]
#   lint             (ace-lint)      [quality, lint]
#   create-pr        (ace-assign)    [delivery]
#   verify-e2e       (ace-test-e2e)  [testing]
#
# 6 phases from 4 sources
```

### Scenario 2: Compose Assignment from Cross-Gem Phases

**Goal**: Build an assignment that uses phases from different gems through the workflow surface

```bash
/as-assign-compose "onboard, work-on-task, review-pr, create-pr"

# Expected output:
# Proposed assignment from 4 phases:
#   010: onboard (ace-assign)
#   020: work-on-task (ace-task)
#   030: review-pr (ace-review)
#   040: create-pr (ace-assign)
#
# Ready for hidden job generation / create flow
```

### Scenario 3: Phase from Uninstalled Gem

**Goal**: Clear error when referencing a phase from a gem that isn't installed

```bash
/as-assign-compose "onboard, vulnerability-scan, create-pr"

# Expected output:
# Error: Phase 'vulnerability-scan' not found in catalog
# Available phases: onboard, work-on-task, run-review, lint, create-pr, verify-e2e
# Hint: This phase may require installing an additional gem
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
