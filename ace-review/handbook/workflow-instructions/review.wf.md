---
name: review
description: Review code with preset and plan feedback application
argument-hint: "[preset] [subject]"
allowed-tools: Read, Bash, TodoWrite, AskUserQuestion
update:
  frequency: on-change
  last-updated: '2025-12-14'
---

# Code Review Workflow

## Goal

Review code using ace-review, read the synthesis report, and create a plan for applying feedback.

## Arguments

- `$1`: Preset name (default: `code-pr`). Run `ace-review --list-presets` to see options.
- `$2`: Subject (optional) - what to review:
  - `staged` - staged changes
  - `working` - unstaged changes
  - `origin/main...HEAD` - git range (auto-detected)
  - `lib/**/*.rb` - file pattern (auto-detected)
  - `'diff: {ranges: ["origin/main...HEAD"]}'` - explicit YAML

## Instructions

### Step 1: Run Code Review

```bash
# With preset only (uses preset's default subject)
ace-review --preset ${1:-code-pr} --auto-execute

# With custom subject
ace-review --preset ${1:-code-pr} --subject "$2" --auto-execute
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

# Common patterns
ace-review --preset code-pr --auto-execute                    # PR changes
ace-review --preset code --subject staged --auto-execute      # Staged only
ace-review --preset ruby-atom --subject 'origin/main...HEAD' --auto-execute  # vs main

# Debug
ace-review --preset code-pr --dry-run   # See what would run
```

## Success Criteria

- [ ] Review completed with synthesis report
- [ ] Feedback plan created and confirmed by user
- [ ] Confirmed items implemented with commits
