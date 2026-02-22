---
description: Create complete task from plan (draft behavioral spec + commit)
bundle:
  params:
    output: cache
  embed_document_source: true
  files:
  - wfi://task/draft
  - wfi://git/commit
variables:
  plan_description: Plan text, behavioral requirements, or Claude Code plan results
doc-type: workflow
purpose: Create complete task from plan (draft behavioral spec + commit)
update:
  frequency: on-change
  last-updated: '2026-02-16'
---

# Create Task

Orchestrates complete task creation: behavioral specification → commit changes.

## Goal

Transform a plan or behavioral requirements into a ready-to-execute task by running the draft-task workflow and committing the result.

## ⚠️ Implementation Prohibition

**This workflow produces specification files ONLY.**

DO NOT during this phase:
- Write or modify code files (.rb, .ts, .js, etc.)
- Create implementation directories or structures
- Run tests or builds
- Make commits to project source code

All code implementation happens during `/ace-task-work` (status: in-progress).

## Variables

**$plan_description**: The input plan/requirements. Can be:
- Explicit plan text describing what to build
- Behavioral requirements or user stories
- Reference to Claude Code plan mode results
- Enhanced idea from `ace-idea`

## Context Workflows

This workflow automatically loads the following workflows via frontmatter `context.files`:
- **draft-task** (`wfi://task/draft`): Creates behavior-first task specification
- **commit** (`wfi://git/commit`): Commits the completed task to git

All workflow content is embedded automatically by ace-bundle protocol resolution.

**Note**: Implementation planning (plan-task) is no longer part of task creation. Planning happens JIT via ace-assign phases just before implementation begins. Use `ace-review-run-task` to validate and promote drafts to pending.

## Process Steps

### Step 1: Draft Behavioral Specification

**Execute**: Follow the draft-task workflow (loaded in context above)

**Input**: `$plan_description` as behavioral requirements

**Process**:
- Creates draft task with behavioral specification
- Defines user experience and interface contract
- Sets `status: draft`
- Documents success criteria and validation questions
- Returns task file path in output

**Expected Output**:
```
Created task v.0.9.0+task.XXX
Path: /Users/mc/Ps/ace-meta/.ace-taskflow/v.0.9.0/t/XXX-title/task.XXX.md
```

**Capture**: Extract the task file path from the output for the next step.

### Step 2: Commit Changes

**Execute**: Follow the commit workflow (loaded in context above)

**Process**:
- Stages all changes in .ace-taskflow directory
- Creates git commit with appropriate message referencing task ID
- Applies Claude Code co-authorship tags
- Returns commit hash

**Output**: Committed draft task ready for review

## Input Formats Supported

### Format 1: Direct Plan Text
```
ARGUMENTS: "Add git diff support to ace-bundle so ace-review
can use unified content aggregation for files, commands, and diffs"
```

### Format 2: Claude Code Plan Reference
```
ARGUMENTS: "Use the plan from Claude Code plan mode.
Summary: [brief summary of what was planned]"
```

### Format 3: Enhanced Idea Reference
```
ARGUMENTS: "Create task from idea file:
.ace-taskflow/v.0.9.0/ideas/20251006-git-diff-support.md"
```

### Format 4: Direct Behavioral Requirements
```
ARGUMENTS: "As a developer, I want to be able to compose files,
commands, diffs, and presets in one unified configuration so that
I can have consistent content loading across all ACE tools."
```

## Success Criteria

- [ ] Draft task created with complete behavioral specification (`status: draft`)
- [ ] Changes committed to git with proper message and co-authorship
- [ ] Task discoverable via `ace-task XXX`
- [ ] Task file contains proper YAML frontmatter with task ID
- [ ] Task ready for review via `ace-review-run-task`

## Next Steps After Task Creation

- Run `ace-review-run-task` to validate the draft and promote to pending
- Implementation planning happens JIT via ace-assign phases when work begins

## Notes

- This workflow **eliminates duplication** by referencing draft-task and commit workflows
- Context workflows are **loaded automatically** via frontmatter protocol resolution
- Task creation is now a **single command** instead of manual orchestration
- All task creation logic is **centralized** in the referenced workflows
- No need to maintain duplicate documentation - everything is in the source workflows
- Implementation planning (plan-task) is decoupled from task creation; it runs JIT via ace-assign

## Output / Success Criteria

* Task created with proper structure and metadata
* Behavioral specification captures WHAT, not HOW
* Task ready for review and promotion
* All requirements captured as acceptance criteria
* Task file committed to git repository
