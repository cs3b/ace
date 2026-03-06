# Enhanced FORK Delegation - Draft Usage

## API Surface
- [ ] CLI (user-facing commands)
- [ ] Developer API (modules, classes)
- [ ] Agent API (workflows, protocols, slash commands)
- [x] Configuration (config keys, env vars)

## Usage Scenarios

### Scenario 1: Delegate Complete Review Workflow via Fork

**Goal**: A phase in an assignment delegates a full code review to a forked agent

```yaml
# In assignment phase file: 020-run-review.ph.md
---
name: run-review
status: pending
context: fork
fork_mode: workflow
skill: ace-review-run
---

Run code review on the current PR using the code-deep preset.
```

```
# Driver output after fork completes:
# Phase 020 (fork:workflow) completed:
#   Status: done
#   Output: .ace-local/review/sessions/2026-03-06-abc123/
#   Summary: 3 critical, 5 medium findings across 12 files
```

### Scenario 2: Existing Fork Behavior Unchanged

**Goal**: Current fork phases continue working without modification

```yaml
# Existing phase file (no fork_mode = defaults to prompt)
---
name: quick-check
status: pending
context: fork
---

Check if tests pass on the current branch.
```

```
# Behavior identical to today - child agent runs the prompt in assignment context
```

### Scenario 3: Fork Mode Without Skill Reference

**Goal**: Graceful fallback when fork_mode is set but skill is missing

```yaml
---
name: broken-fork
status: pending
context: fork
fork_mode: workflow
# skill: missing!
---
```

```
# Expected: WARNING: fork_mode: workflow without skill reference, falling back to prompt mode
```

## Notes for Implementer
- Full usage documentation to be completed during work-on-task phase using `wfi://docs/update-usage`
