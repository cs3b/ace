---
id: 8mq000
title: "Retro: Task Definition and Subtask Workflow Improvements"
type: conversation-analysis
tags: []
created_at: "2025-11-27 00:00:00"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8mq000-subtask-workflow-improvements.md
---
# Retro: Task Definition and Subtask Workflow Improvements

**Date**: 2025-11-27
**Context**: Learnings from defining ace-prompt task 121 with subtasks 121.01-121.06
**Author**: Development Team
**Type**: Process Improvement | Conversation Analysis

## What Went Well

### Task Structure Innovation
- **Orchestrator + Subtasks pattern**: Created 121.00-orchestrator.s.md as main task with 6 incremental subtasks (121.01-121.06)
- **Incremental Value Delivery**: Each subtask delivers working functionality that builds on previous
- **Clear Naming Convention**: `{id}.{NN}-{slug}.s.md` provides natural sorting and clarity
- **Separate Branch/Worktree per Subtask**: Enables focused, reviewable PRs (<500 lines each)

### Configuration Decisions
- **Nested params: structure**: Flaggable options under `params:` key for consistency
- **Hyphen naming convention**: CLI-friendly (`system-prompt`, `task-detection`)
- **Full config examples in task docs**: Self-contained task documentation

### Documentation Strategy
- **ux/usage.md evolves with each subtask**: Living documentation
- **docs/ folder for reference files**: Preserved templates, configs, prompts from existing implementation

## What Could Be Improved

### Missing Workflow Support for Subtasks
Current ace-taskflow workflows don't support:
1. **Orchestrator task creation** - No template for main task with subtask links
2. **Subtask creation** - No support for `121.NN` naming pattern
3. **Parent-child relationship** - No `parent:` field in standard templates
4. **Subtask dependencies** - No auto-generation of subtask dependency chains

### Manual Process Required
- Created all 7 task files (orchestrator + 6 subtasks) manually
- No CLI command: `ace-taskflow subtask create --parent 121 --title "..."`
- No automatic ID sequencing for subtasks (121.01, 121.02, etc.)

### Workflow Gaps Identified
- `draft-task.wf.md`: Only creates single tasks, no subtask support
- `plan-task.wf.md`: Doesn't handle orchestrator vs. subtask distinction
- `create-task.wf.md`: No subtask orchestration capability
- `work-on-task.wf.md`: May need updates for subtask workflow (worktrees)

## Key Learnings

### Subtask Pattern Benefits
1. **Focused scope**: Each subtask is small enough to complete in one session
2. **Clear verification**: Each subtask has specific acceptance criteria
3. **Parallel potential**: Multiple subtasks could be worked in parallel with worktrees
4. **Easier reviews**: Smaller PRs are easier to review and less risky

### Naming Convention Insights
- `.00` for orchestrator sorts first naturally
- Two-digit suffix (`.01`, `.02`) allows up to 99 subtasks
- `.s.md` suffix distinguishes from other markdown files

### Configuration Structure Pattern
```yaml
# Non-flaggable (fixed)
prompt:
  default-dir: .cache/ace-prompt/prompts

# Flaggable (CLI overrides)
  params:
    context: false       # --context / --no-context
    enhance: false       # --enhance / --no-enhance
```

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Manual Subtask Creation**: All 7 task files created by hand
  - Occurrences: 7 files
  - Impact: Time-consuming, error-prone ID management
  - Root Cause: No ace-taskflow support for subtask patterns

- **Config Format Iteration**: Multiple rounds to finalize config structure
  - Occurrences: 3 iterations (flat → nested → nested+params)
  - Impact: Required updates to multiple task files after decisions
  - Root Cause: No established pattern for gem configuration

#### Medium Impact Issues

- **Protocol Path Naming**: Changed from `prompt://ace-prompt/enhance-instructions` to `prompt://prompt-enhance-instructions`
  - Occurrences: 2 files
  - Impact: Minor rework
  - Root Cause: Initial over-verbose naming

### Improvement Proposals

#### Process Improvements

- Formalize orchestrator + subtasks pattern in ace-taskflow workflows
- Create standard config structure template for ace-* gems
- Document subtask pattern in development guides

#### Tool Enhancements

- `ace-taskflow subtask create --parent 121 --title "Archive Output"`
- `ace-taskflow subtasks --parent 121` (list subtasks)
- `ace-git-worktree create --task 121.01` (auto-detect branch)

#### Workflow Proposals

| Workflow | Change Needed |
|----------|---------------|
| `draft-task.wf.md` | Add orchestrator mode for multi-subtask features |
| `plan-task.wf.md` | Handle subtask planning (smaller scope per subtask) |
| `work-on-task.wf.md` | Integrate worktree creation for subtasks |
| `review-task.wf.md` | Review subtask in context of parent orchestrator |

## Action Items

### Stop Doing

- Creating complex tasks as single monolithic specs
- Manual ID management for related tasks

### Continue Doing

- Behavior-first specifications
- ux/usage.md documentation alongside implementation
- docs/ folder for reference files in task directory

### Start Doing

- **Implement subtask workflow support in ace-taskflow**
- **Create orchestrator template (`task.orchestrator.md`)**
- **Create subtask template (`task.subtask.md`)**
- **Update existing workflows for subtask awareness**
- **Document subtask pattern in ace-taskflow guide**

## Technical Details

### Files to Create/Modify in ace-taskflow

**New Files:**
- `handbook/workflow-instructions/draft-subtasks.wf.md`
- `handbook/templates/task.orchestrator.md`
- `handbook/templates/task.subtask.md`

**Modify:**
- `lib/ace/taskflow/commands/task.rb` - Add subtask subcommand
- `lib/ace/taskflow/task_id_generator.rb` - Support NN.MM format
- `handbook/workflow-instructions/work-on-task.wf.md` - Worktree integration

### Subtask ID Schema

```
{release-id}+task.{major}.{minor}
v.0.9.0+task.121.01

Where:
- 121 = orchestrator/parent task
- 01-99 = subtask sequence
```

### Proposed Template: task.orchestrator.md

```yaml
---
id: {id}
status: pending
priority: high
estimate: {total-estimate}
subtasks:
  - {id}.01
  - {id}.02
---
# {title} (Orchestrator)

## Overview
## Phase 1: {subtask-1-title}
## Phase 2: {subtask-2-title}
## Final Validation
```

### Proposed Template: task.subtask.md

```yaml
---
id: {parent-id}.{NN}
status: pending
parent: {parent-id}
dependencies: [{parent-id}.{NN-1}]
branch: {parent-id}.{NN}-{slug}
---
# {parent-id}.{NN} - {title}
```

## Additional Context

### Pattern Used in Task 121

```
.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/
├── 121.00-orchestrator.s.md    # Main task with phases
├── 121.01-archive-output.s.md  # Phase 1
├── 121.02-setup-reset.s.md     # Phase 2
├── 121.03-context-loading.s.md # Phase 3
├── 121.04-llm-enhance.s.md     # Phase 4
├── 121.05-system-prompt.s.md   # Phase 5
├── 121.06-task-folder.s.md     # Phase 6
├── ux/usage.md                 # Living documentation
└── docs/                       # Reference files
    ├── examples/
    ├── prompts/
    └── templates/
```

### References
- Task 121: `.ace-taskflow/v.0.9.0/tasks/121-ace-prompt/`
- Superseded tasks: 118, 120
- Related PR: PR 46 (kept as reference)
