---
name: review-pr
description: Review PR and plan feedback application with comment resolution
argument-hint: "[pr-number]"
allowed-tools: Read, Bash, TodoWrite, AskUserQuestion
update:
  frequency: on-change
  last-updated: '2025-12-08'
---

# Review PR and Plan Feedback Workflow

## Goal

Review a GitHub Pull Request using ace-review, read the synthesis report, and create a plan for applying the feedback. When feedback comes from PR comments, resolve those comments after implementing fixes.

## Arguments

- `$ARGUMENTS`: PR number (e.g., `64`, `123`)

## Instructions

### Step 1: Run PR Review

```bash
ace-review --pr $ARGUMENTS
```

Wait for the review to complete. Note the synthesis report path from the output.

The review includes:
- LLM model reviews (e.g., `review-gemini.md`, `review-gpt4.md`)
- Developer feedback from PR comments (`review-dev-feedback.md`) - if the PR has comments
- Synthesis combining all sources (`synthesis-report.md`)

### Step 2: Read Synthesis Report

Read the synthesis report path shown in the command output.

Note which feedback items come from **Developer Feedback** - these are from PR comments and should be resolved after implementation.

### Step 3: Create Feedback Plan

Based on the synthesis report's **Prioritized Action Items**, create a plan:

1. List all action items by priority (Critical → High → Medium → Low)
2. For each item, note:
   - Location (file:line)
   - Description of the issue
   - Recommended fix
   - **Source**: LLM review or Developer Feedback (PR comment)
3. Identify which items to implement now vs capture as ideas for later

### Step 4: Present Plan and Wait for Confirmation

Present the plan to the user with a summary:
- Number of items per priority level
- Number of items from PR comments (require resolution)
- Estimated scope of changes
- Any items recommended to defer

Use AskUserQuestion to confirm:
- "Which items should I implement?"
- Options: All items, High priority only, Custom selection

Only proceed with implementation after user confirmation.

### Step 5: Implement Fixes

Implement the confirmed fixes. After each fix:
- Commit with a clear message referencing the issue
- Note the commit SHA for PR comment resolution

### Step 6: Resolve PR Comments (for Developer Feedback items)

After implementing fixes for items sourced from **Developer Feedback**:

1. **Reply to the PR with commit reference**:
   ```bash
   gh pr comment $ARGUMENTS --body "Fixed in $(git rev-parse --short HEAD)"
   ```

2. **Resolve review threads** (if feedback was from a review thread with a thread ID):
   ```bash
   # For review threads (PRRT_xxx IDs from review-dev-feedback.md)
   gh api graphql -f query='
     mutation {
       resolveReviewThread(input: {threadId: "PRRT_xxx"}) {
         thread { isResolved }
       }
     }
   '
   ```

Note: The thread IDs are included in `review-dev-feedback.md` in the format `(thread: PRRT_xxx)` or `(comment: IC_xxx)`.

### Comment Resolution Summary

| Feedback Source | Resolution Action |
|-----------------|-------------------|
| LLM Review | No action needed (not a PR comment) |
| Developer Feedback (issue comment) | Reply with commit reference |
| Developer Feedback (review thread) | Reply with commit reference AND resolve thread |

## Output / Success Criteria

- [ ] PR review completed with synthesis report
- [ ] Feedback plan created and confirmed by user
- [ ] Confirmed items implemented
- [ ] PR comments addressed with commit references
- [ ] Review threads resolved (if applicable)
