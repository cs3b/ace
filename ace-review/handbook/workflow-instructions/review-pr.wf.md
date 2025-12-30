---
name: review-pr
description: Review PR and plan feedback application with comment resolution
argument-hint: "[pr-number] [--preset <name>] [flags]"
allowed-tools: Read, Bash, TodoWrite, AskUserQuestion
update:
  frequency: on-change
  last-updated: '2025-12-30'
---

# Review PR and Plan Feedback Workflow

## Goal

Review a GitHub Pull Request using ace-review, read the synthesis report, and create a plan for applying the feedback. When feedback comes from PR comments, resolve those comments after implementing fixes.

## Arguments

- `$ARGUMENTS`: Optional PR number and/or additional flags (e.g., `123`, `--preset code-deep`, `123 --preset security`)

## Instructions

### Step 1: Determine PR Number

If `$ARGUMENTS` contains a PR number, use it. Otherwise, detect the current PR:

```bash
gh pr view --json number -q '.number'
```

### Step 2: Run PR Review

**Always use `--pr` flag.** Append any additional parameters from `$ARGUMENTS`:

```bash
# If PR number provided in arguments:
ace-review --pr <pr-number> [additional-flags]

# If no PR number, use detected PR:
ace-review --pr $(gh pr view --json number -q '.number') [additional-flags]
```

**Examples:**
- `/ace:review-pr 123` → `ace-review --pr 123`
- `/ace:review-pr --preset code-deep` → `ace-review --pr <current-pr> --preset code-deep`
- `/ace:review-pr 123 --preset security` → `ace-review --pr 123 --preset security`

**Important for Claude Code**: Run with 10-minute timeout (600000ms) and wait for completion inline (not background). Review typically takes 3-5 minutes.

Wait for the review to complete. Note the synthesis report path from the output.

The review includes:
- LLM model reviews (e.g., `review-gemini.md`, `review-gpt4.md`)
- Developer feedback from PR comments (`review-dev-feedback.md`) - if the PR has comments
- Synthesis combining all sources (`synthesis-report.md`)

### Step 3: Read Synthesis Report

Read the synthesis report path shown in the command output.

Note which feedback items come from **Developer Feedback** - these are from PR comments and should be resolved after implementation.

### Step 4: Verify Action Items

Before presenting action items to the user, verify each Critical and High priority item.

**For each item:**

1. **Check the claim** - Use grep/read to verify the issue exists:
   - If claim is "X doesn't exist" → `grep -rn "class X" lib/`
   - If claim is "method missing" → check the actual file
   - If claim is "file not deleted" → `ls path/to/file`

2. **Categorize the result:**

   | Status | Meaning | Action |
   |--------|---------|--------|
   | ✅ VALID | Issue confirmed in code | Include in plan |
   | ❌ INVALID | False positive, code is correct | Exclude from plan |
   | ⚠️ EDGE CASE | Known limitation, not a bug | Note as limitation |
   | 📝 SUGGESTION | Code improvement, not required | Include as optional |

3. **Document verification** - Note what was checked and the result

**Example verification:**
```bash
# Claim: "TaskPatternExtractor is undefined"
grep -rn "class TaskPatternExtractor" ace-git/lib/
# Result: Found at ace-git/lib/ace/git/atoms/task_pattern_extractor.rb:10
# Status: ❌ INVALID - class exists
```

**Skip verification for:**
- Low priority items (verify only if time permits)
- Documentation-only suggestions
- Style/formatting recommendations
- Developer Feedback items (these are human-verified)

### Step 5: Create Feedback Plan

Based on the synthesis report's **Prioritized Action Items** and **verification results**, create a plan:

1. List only VALID, SUGGESTION, and Developer Feedback items by priority (Critical → High → Medium → Low)
2. Note any INVALID items that were filtered out
3. For each item, note:
   - Location (file:line)
   - Description of the issue
   - Recommended fix
   - Verification evidence (for LLM items)
   - **Source**: LLM review or Developer Feedback (PR comment)
4. Identify which items to implement now vs capture as ideas for later

### Step 6: Present Plan and Wait for Confirmation

Present the plan to the user with a summary:
- Number of items per priority level
- Number of items from PR comments (require resolution)
- Estimated scope of changes
- Any items recommended to defer

Use AskUserQuestion to confirm:
- "Which items should I implement?"
- Options: All items, High priority only, Custom selection

Only proceed with implementation after user confirmation.

### Step 7: Implement Fixes

Implement the confirmed fixes. After each fix:
- Commit with a clear message referencing the issue
- Note the commit SHA for PR comment resolution

### Step 8: Resolve PR Comments (for Developer Feedback items)

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
- [ ] Action items verified (Critical/High priority)
- [ ] False positives identified and excluded
- [ ] Feedback plan created and confirmed by user
- [ ] Confirmed items implemented
- [ ] PR comments addressed with commit references
- [ ] Review threads resolved (if applicable)
