---
id: 8o2000
title: 'Retro: Workflow Context Embedding - Reducing Tool Calls with Embedded Context'
type: conversation-analysis
tags: []
created_at: '2026-01-03 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8o2000-workflow-context-embedding.md"
---

# Retro: Workflow Context Embedding - Reducing Tool Calls with Embedded Context

**Date**: 2026-01-03
**Context**: PR #120 introduced `ace-context wfi://protocol` with `embed_document_source: true`, enabling workflows to include dynamic context when loaded. This retro captures the workflow improvement work that leverages this new capability.
**Author**: Development Team
**Type**: Conversation Analysis / Self-Review

## What Went Well

- **Massive efficiency gain**: `/ace:commit` went from 5 tool calls to 2 tool calls (60% reduction)
- **Immediate context availability**: Agents now have repository status and available options from workflow load
- **Clear pattern documentation**: Created `workflow-context-embedding.g.md` guide with reusable patterns
- **Explicit guidance**: Updated CLAUDE.md to teach agents about embedded context usage
- **Two concrete examples**: Both `commit.wf.md` and `load-context.wf.md` now leverage embedded context effectively

## What Could Be Improved

- **Only 2 of 84 workflows updated**: Most workflows still use manual "run this command" patterns
- **No automated detection**: No way to automatically find workflows that would benefit from embedded context
- **Pattern guide in dev-handbook**: Will need migration to ace-handbook gem when ready
- **Limited testing**: Only manually tested commit and load-context workflows

## Key Learnings

- **Embedded context changes the paradigm**: Workflows transform from "instructions to gather context" to "instructions with context already included"
- **Explicit references matter**: Instructions must explicitly point to embedded sections (`<current_repository_status>`, `<available_presets>`)
- **Three core patterns emerged**: "Context Already Available", "Interactive Selection", and "Validation"
- **Section naming is semantic**: Names like `current_repository_status` and `available_presets` make context self-documenting

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Redundant command execution**: Prior to embedded context, agents ran commands like `git status` even when workflow already had this information available
  - Occurrences: Nearly every workflow invocation
  - Impact: 5 tool calls vs 2 tool calls for commit workflow (60% overhead)
  - Root Cause: Workflow instructions said "run this command" without checking if context was already embedded

#### Medium Impact Issues

- **Implicit context availability**: Workflows had embedded context but instructions didn't explicitly reference it
  - Occurrences: commit.wf.md had empty `()`, load-context.wf.md never referenced `<available_presets>`
  - Impact: Agents didn't realize context was pre-loaded, ran redundant commands
  - Root Cause: Workflow frontmatter had `embed_document_source: true` but instructions weren't updated to use it

#### Low Impact Issues

- **No patterns documented**: 84 workflows exist, only 4 use embedded context, no guidance on when/how
  - Occurrences: One-time analysis effort
  - Impact: Slow adoption of new capability across workflows
  - Root Cause: Capability was new (PR #120), patterns not yet codified

### Improvement Proposals

#### Process Improvements

- **Audit workflows for embedded context candidates**: Prioritize workflows that:
  - Run commands to gather state (git status, task lists, config validation)
  - Present options to users (available presets, tasks, workflows)
  - Orchestrate multiple workflows
- **Create validation test**: Verify workflows don't tell agents to run commands for embedded context
- **Document success metrics**: Track tool call reduction before/after workflow updates

#### Tool Enhancements

- **ace-context lint**: Check if workflow has `embed_document_source` but instructions don't reference embedded sections
- **Workflow analyzer**: Find workflows that would benefit from embedded context (pattern: "run X to get Y")
- **Auto-suggest**: Suggest `embed_document_source` frontmatter for workflows with "get context" patterns

#### Communication Protocols

- **Template includes**: Add embedded context reference to workflow template
- **Review checklist**: When reviewing workflows, check if context could be embedded
- **PR guidance**: Mention embedded context patterns in review criteria

### Token Limit & Truncation Issues

- **Large Output Instances**: None encountered during this work
- **Truncation Impact**: N/A
- **Mitigation Applied**: N/A
- **Prevention Strategy**: Embedded context is typically small (command output), workflows themselves use auto-format by line count (task 152)

## Action Items

### Stop Doing

- Writing workflows that say "run this command to get status" when `embed_document_source: true` could provide it
- Assuming agents will magically discover embedded context without explicit instructions

### Continue Doing

- Using semantic section names for embedded context (`current_repository_status`, `available_presets`)
- Explicitly referencing embedded sections in workflow instructions
- Documenting patterns as they emerge for reuse across workflows

### Start Doing

- **Audit 30 workflow candidates**: Identify high-value workflows for embedded context adoption
- **Create validation tool**: Check workflows for "run command" patterns that could use embedded context
- **Track metrics**: Measure tool call reduction as workflows are updated
- **Migrate guide to ace-handbook**: When gem migration is complete, move pattern guide

## Technical Details

### Embedded Context Frontmatter Pattern

```yaml
context:
  embed_document_source: true
  sections:
    current_repository_status:
      commands:
        - git status -sb
        - git diff --stat
    available_presets:
      commands:
        - ace-context --list
```

### Instruction Pattern: Before vs After

**Before** (manual gathering):
```markdown
1. Get repository status:
   git status
   git diff --stat
```

**After** (embedded context):
```markdown
1. **Repository status is embedded above** in `<current_repository_status>`.

   The current git state is already loaded in this workflow.
   Review it to understand what will be committed.
   No need to run git commands - the context is already provided.
```

### Tool Call Reduction Evidence

**Commit workflow before embedded context:**
1. Load workflow instructions
2. Run `git status` (redundant if status embedded)
3. Run `git diff --stat` (redundant if diff embedded)
4. Execute `ace-git-commit`
5. Verify with `ace-git status`

**Commit workflow after embedded context:**
1. Load workflow instructions (with embedded status)
2. Execute `ace-git-commit`
3. Verify with `ace-git status` (optional, could also use embedded status)

**Result**: 5 calls → 2-3 calls (40-60% reduction)

## Additional Context

- **PR #120**: Replace ace-nav wfi:// with ace-context wfi:// in Claude Code commands and workflows
- **Task 152**: ace-context auto-format output by line count threshold (500 lines)
- **Pattern guide**: `dev-handbook/guides/workflow-context-embedding.g.md`
- **Files modified**: CLAUDE.md, commit.wf.md, load-context.wf.md, workflow-context-embedding.g.md (new)
- **Commit**: `1738787f feat(workflow): Embed context in workflows and improve context loading`