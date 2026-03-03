---
id: 8l1000
title: Workflow Migration from dev-handbook to ace-taskflow
type: self-review
tags: []
created_at: '2025-10-02 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8l1000-workflow-migration-session.md"
---

# Reflection: Workflow Migration from dev-handbook to ace-taskflow

**Date**: 2025-10-02
**Context**: Migration of three idea and feature management workflows from dev-handbook to ace-taskflow, completed as task v.0.9.0+047
**Author**: Claude Code
**Type**: Self-Review

## What Went Well

- **Clear task structure**: The task file had well-defined behavioral specifications and scope that made implementation straightforward
- **Systematic approach**: Breaking down the work into research, planning, and execution phases kept the work organized
- **Successful integration**: All three workflows (prioritize-align-ideas, capture-application-features, document-unplanned-work) integrated seamlessly with ace-nav's wfi:// protocol
- **Test-driven validation**: Testing workflow resolution with ace-nav before completion caught any issues early
- **Clean organization**: Moving from scattered .claude/commands/*.md files to organized .claude/commands/ace/*.md structure improved discoverability

## What Could Be Improved

- **API reliability**: Encountered Google API overload (503 error) when attempting to use ace-git-commit with LLM-generated message, had to fall back to manual commit message
- **Workflow reference updates**: Had to manually update multiple context loading references from relative paths to ace-nav protocol URLs - could be automated
- **Command cleanup timing**: Deleted old commands in a separate step after task completion - could have been part of the original task scope

## Key Learnings

- **ace-nav protocol flexibility**: The wfi:// protocol makes workflow files location-agnostic and easily discoverable across different ace-* components
- **Slash command pattern**: Simple pattern of frontmatter + two ace-nav calls (workflow + commit) provides clean separation of concerns
- **Project context evolution**: Moving from dev-handbook references to ace-nav protocol references makes workflows more portable and maintainable
- **ace-taskflow CLI maturity**: The idea subcommand already has robust functionality (create, reschedule, done, archive, to-task)

## Action Items

### Stop Doing

- Creating standalone slash commands at project root - organize under namespaces instead
- Using hardcoded paths for project context loading in workflows
- Keeping duplicate commands in multiple locations

### Continue Doing

- Following task-driven development with clear behavioral specifications
- Testing integration points (like ace-nav resolution) during implementation
- Using todo lists to track progress through complex tasks
- Creating implementation plans before execution

### Start Doing

- Consider automation for bulk reference updates in workflow files (ace-nav protocol migration tool)
- Include old command cleanup as part of migration tasks
- Document slash command organization conventions in handbook
- Add fallback/retry logic for LLM-based tools to handle API overload

## Technical Details

**Files Created:**
- `ace-taskflow/handbook/workflow-instructions/prioritize-align-ideas.wf.md`
- `ace-taskflow/handbook/workflow-instructions/capture-application-features.wf.md`
- `ace-taskflow/handbook/workflow-instructions/document-unplanned-work.wf.md`
- `.claude/commands/ace/prioritize-ideas.md`
- `.claude/commands/ace/capture-features.md`
- `.claude/commands/ace/document-unplanned.md`

**Files Removed:**
- 30+ old command files from `.claude/commands/` (moved to organized ace/ namespace)

**Key Changes:**
- Updated `dev-handbook/workflow-instructions/load-project-context.wf.md` references to `ace-nav wfi://load-project-context`
- Updated `dev-handbook/.meta/gds/` references to `ace-nav guide://` protocol
- Updated `task-manager` CLI references to `ace-taskflow` commands

**Validation:**
- All three workflows resolve correctly via `ace-nav wfi://[workflow-name]`
- Slash commands properly delegate to workflow instructions
- Task marked as done and moved to `.ace-taskflow/v.0.9.0/t/done/`

## Additional Context

- Task: v.0.9.0+047
- Commit: b5aa9069 feat(ace-taskflow): Migrate idea and feature workflows from dev-handbook
- Related workflows: wfi://work-on-task, wfi://commit
- Time estimate: 6h (task completed within estimate)