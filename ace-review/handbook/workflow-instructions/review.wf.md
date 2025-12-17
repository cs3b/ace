---
name: review
description: Review code with preset and plan feedback application
argument-hint: "[preset] [subjects...]"
allowed-tools: Read, Bash, TodoWrite, AskUserQuestion
update:
  frequency: on-change
  last-updated: '2025-12-17'
---

# Code Review Workflow

## Goal

Review code using ace-review, read the synthesis report, and create a plan for applying feedback.

## Arguments

- `$1`: Preset name (optional). Run `ace-review --list-presets` to see options.
- `$2+`: Subject(s) using `type:value` syntax (optional, additive to preset):
  - `staged`, `working` - keywords
  - `diff:origin/main..HEAD` - git range
  - `pr:123` - PR diff
  - `files:lib/**/*.rb` - file pattern
  - `task:145` - task context

## Instructions

### Step 1: Run Code Review

```bash
# Default preset
ace-review --auto-execute

# With preset
ace-review --preset $1 --auto-execute

# With subject(s) - additive to preset
ace-review --subject "$2" --auto-execute

# Multiple subjects merge automatically
ace-review --subject pr:76 --subject files:CHANGELOG.md --auto-execute
```

Wait for the review to complete. Note the synthesis report path from the output.

The review generates:
- LLM model reviews (e.g., `review-gemini.md`)
- Synthesis combining all findings (`synthesis-report.md`)

### Step 2: Read Synthesis Report

Read the synthesis report path shown in the command output.

Focus on:
- **Prioritized Action Items** - what needs fixing
- **Priority levels** - Critical, High, Medium, Low
- **Locations** - file:line references

### Step 3: Create Feedback Plan

Based on the synthesis report's **Prioritized Action Items**, create a plan:

1. List all action items by priority (Critical → High → Medium → Low)
2. For each item, note:
   - Location (file:line)
   - Description of the issue
   - Recommended fix
3. Identify which items to implement now vs capture as ideas for later

### Step 4: Present Plan and Wait for Confirmation

Present the plan to the user with a summary:
- Number of items per priority level
- Estimated scope of changes
- Any items recommended to defer

Use AskUserQuestion to confirm:
- "Which items should I implement?"
- Options: All items, High priority only, Custom selection

Only proceed with implementation after user confirmation.

### Step 5: Implement Fixes

Implement the confirmed fixes. After each fix:
- Commit with a clear message referencing the issue
- Mark completion in the plan

## Quick Reference

```bash
# Discovery
ace-review --list-presets   # Available presets
ace-review --list-prompts   # Available prompt modules

# Subject types (type:value syntax)
--subject staged                    # Staged changes (keyword)
--subject working                   # Unstaged changes (keyword)
--subject diff:origin/main..HEAD    # Git range
--subject pr:123                    # PR diff
--subject files:lib/**/*.rb         # File pattern
--subject task:145                  # Task context

# Common patterns
ace-review --auto-execute                                  # Default preset
ace-review --subject staged --auto-execute                 # Staged only
ace-review --subject diff:origin/main..HEAD --auto-execute # vs main
ace-review --subject pr:76 --subject files:README.md --auto-execute  # Combined

# Debug
ace-review --dry-run   # See what would run
```

## Success Criteria

- [ ] Review completed with synthesis report
- [ ] Feedback plan created and confirmed by user
- [ ] Confirmed items implemented with commits
