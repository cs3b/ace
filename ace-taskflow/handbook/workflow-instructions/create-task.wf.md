---
description: Create complete task from plan (draft behavioral spec + implementation
  planning + commit)
context:
  params:
    output: cache
  embed_document_source: true
  files:
  - wfi://draft-task
  - wfi://plan-task
  - wfi://commit
variables:
  plan_description: Plan text, behavioral requirements, or Claude Code plan results
doc-type: workflow
purpose: Create complete task from plan (draft behavioral spec + implementation planning
  + commit)
update:
  frequency: on-change
  last-updated: '2025-10-06'
---

# Create Task

Orchestrates complete task creation: behavioral specification → implementation planning → commit changes.

## Goal

Transform a plan or behavioral requirements into a ready-to-execute task by running the draft-task and plan-task workflows sequentially, then committing the result.

## Variables

**$plan_description**: The input plan/requirements. Can be:
- Explicit plan text describing what to build
- Behavioral requirements or user stories
- Reference to Claude Code plan mode results
- Enhanced idea from `ace-taskflow idea`

## Context Workflows

This workflow automatically loads the following workflows via frontmatter `context.files`:
- **draft-task** (`wfi://draft-task`): Creates behavior-first task specification
- **plan-task** (`wfi://plan-task`): Adds detailed implementation planning
- **commit** (`wfi://commit`): Commits the completed task to git

All workflow content is embedded automatically by ace-context protocol resolution.

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

### Step 2: Plan Implementation Details

**Execute**: Follow the plan-task workflow (loaded in context above)

**Input**: Task file path from Step 1 (pass as ARGUMENTS or let plan-task discover it)

**Process**:
- Loads the draft task created in Step 1
- Adds technical research and architectural approach
- Creates detailed implementation plan with Planning Steps and Execution Steps
- Updates `status: draft` → `status: pending`
- Creates UX/usage documentation if applicable (for user-facing features)
- Returns updated task file

**Output**: Task file with complete planning, ready for execution

### Step 3: Commit Changes

**Execute**: Follow the commit workflow (loaded in context above)

**Process**:
- Stages all changes in .ace-taskflow directory
- Creates git commit with appropriate message referencing task ID
- Applies Claude Code co-authorship tags
- Returns commit hash

**Output**: Committed task ready for execution

## Input Formats Supported

### Format 1: Direct Plan Text
```
ARGUMENTS: "Add git diff support to ace-context so ace-review
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
- [ ] Task planned with detailed implementation steps (`status: pending`)
- [ ] Changes committed to git with proper message and co-authorship
- [ ] Task discoverable via `ace-taskflow task XXX`
- [ ] Task file contains proper YAML frontmatter with task ID
- [ ] Task ready for execution with clear acceptance criteria

## Notes

- This workflow **eliminates duplication** by referencing draft-task, plan-task, and commit workflows
- Context workflows are **loaded automatically** via frontmatter protocol resolution
- Task creation is now a **single command** instead of manual orchestration
- All task creation logic is **centralized** in the referenced workflows
- No need to maintain duplicate documentation - everything is in the source workflows

## Output / Success Criteria

* Task created with proper structure and metadata
* Implementation plan derived from original plan/specification
* Task ready for execution with clear steps
* All plan requirements captured as acceptance criteria
* Task file committed to git repository
