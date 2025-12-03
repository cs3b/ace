---
name: review-pr
description: Review PR and plan feedback application
argument-hint: "[pr-number]"
allowed-tools: Read, Bash, TodoWrite, AskUserQuestion
update:
  frequency: on-change
  last-updated: '2025-12-03'
---

# Review PR and Plan Feedback Workflow

## Goal

Review a GitHub Pull Request using ace-review, read the synthesis report, and create a plan for applying the feedback.

## Arguments

- `$ARGUMENTS`: PR number (e.g., `64`, `123`)

## Instructions

### Step 1: Run PR Review

```bash
ace-review --pr $ARGUMENTS
```

Wait for the review to complete. Note the synthesis report path from the output.

### Step 2: Read Synthesis Report

Read the synthesis report path shown in the command output.

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
