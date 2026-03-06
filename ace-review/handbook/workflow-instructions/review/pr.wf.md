---
name: review/pr
description: Review PR and plan feedback application with comment resolution
argument-hint: "[pr-number] [--preset <name>] [flags]"
allowed-tools: Read, Bash, TodoWrite
update:
  frequency: on-change
  last-updated: '2026-02-03'
---

# Review PR and Plan Feedback Workflow

## Goal

Review a GitHub Pull Request using ace-review, verify feedback items, and create a plan for applying the feedback. When feedback comes from PR comments, resolve those comments after implementing fixes.

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
- `/as-review-pr 123` → `ace-review --pr 123`
- `/as-review-pr --preset code-deep` → `ace-review --pr <current-pr> --preset code-deep`
- `/as-review-pr 123 --preset security` → `ace-review --pr 123 --preset security`

**Important for Claude Code**: Run with 10-minute timeout (600000ms) and wait for completion inline (not background). Review typically takes 3-5 minutes.

#### Execution Guard (Mandatory)

- Completion is defined by **process exit** (success or failure), not by partial output.
- Do **not** treat temporary silence/no new output as completion.
- Do **not** run any Step 3+ commands until Step 2 process exit is confirmed.
- If 10-minute timeout (600000ms) is reached, report timeout and last observed output, then stop dependent steps.

Wait for the review process to exit. Note the session directory path from the output.

The review includes:
- LLM model reviews (e.g., `review-gemini.md`, `review-gpt4.md`)
- Developer feedback from PR comments (`review-dev-feedback.md`) - if the PR has comments
- Feedback items in `feedback/` directory

### Step 3: List Feedback Items

List the feedback items extracted from the review:

```bash
ace-review-feedback list --status draft
```

**Precondition**: Run this step only after Step 2 process exit is confirmed.

When session ambiguity is possible, use explicit session path from Step 2:

```bash
ace-review-feedback list --status draft --session <session-dir-from-step-2>
```

This shows all draft feedback items with their IDs, severity, summaries, and sources (LLM or Developer).

#### Understanding Feedback Context

Feedback items are **session-scoped**. The `feedback list` command discovers items based on:
1. Explicit `--session <path>` flag (if provided)
2. `.ace-review-session` cache file in current directory (auto-created after reviews)

If `feedback list` returns empty after a review, first verify Step 2 process completion.
The session may not be linked to current context.
Use `ace-review-feedback list --session <session-dir>` to list from a specific session:

```bash
# List feedback from a specific session (path shown in review output)
ace-review-feedback list --session .ace-local/review/sessions/review-8p2pk3
```

### Step 4: Verify Each Feedback Item

For each feedback item (prioritize Critical and High severity):

```bash
# Read the finding details
ace-review-feedback show {id}
```

**Note which items come from Developer Feedback** - these are from PR comments and should be resolved after implementation.

**Then verify in the codebase:**

1. **Check the claim** - Use grep/read to verify the issue exists:
   - If claim is "X doesn't exist" → `grep -rn "class X" lib/`
   - If claim is "method missing" → check the actual file
   - If claim is "file not deleted" → `ls path/to/file`

2. **Mark the verification result:**

   ```bash
   # If issue is confirmed (valid finding)
   ace-review-feedback verify {id} --valid --research "Confirmed: issue exists at line X"

   # If issue is not real (false positive)
   ace-review-feedback verify {id} --invalid --research "False positive: handled by Y"
   ```

3. **Categorization guide:**

   | Result | Command | When |
   |--------|---------|------|
   | ✅ VALID | `--valid` | Issue confirmed in code |
   | ❌ INVALID | `--invalid` | **False positive** - claim is factually incorrect |
   | ✅ DONE | `feedback resolve {id}` | Already fixed in this PR |
   | ⏭️ SKIP | `verify --skip --research "Design: ..."` | **Correct finding**, but not being fixed |
   | 📋 DEFER | `verify --skip --research "Tracked in task XXX"` | Important, but not this PR (create task first) |

   **Key distinction:**
   - `verify --invalid`: The finding is **wrong** (false positive)
     - "Code doesn't exist" → Actually exists
     - "Missing validation" → Exists elsewhere
     - "Fails in CI" → Doesn't run in CI
   - `verify --skip`: The finding is **correct**, but you're not fixing it
     - Design decision: Intentional choice
     - Deferred: Tracking in separate task

   **Before skipping**: Always verify the issue still exists by reading the code. Never skip with "out of scope" - either it's a design decision or it should be tracked in a task.

**Example verification:**
```bash
# Claim: "TaskPatternExtractor is undefined"
grep -rn "class TaskPatternExtractor" ace-git/lib/
# Result: Found at ace-git/lib/ace/git/atoms/task_pattern_extractor.rb:10
ace-review-feedback verify {id} --invalid --research "Class exists at ace-git/lib/ace/git/atoms/task_pattern_extractor.rb:10"
```

**Skip verification for:**
- Low priority items (verify only if time permits)
- Documentation-only suggestions
- Style/formatting recommendations
- Developer Feedback items (these are human-verified)

### Step 5: List Pending Items

After verification, list items ready to work on:

```bash
ace-review-feedback list --status pending
```

This shows only verified valid items that need fixing.

### Step 6: Apply Priority Threshold

**Default behavior**: Implement **Medium and higher** severity items (skip Low).

This means:
- 🔴 Critical → Implement
- 🟡 High → Implement
- 🟢 Medium → Implement
- 🔵 Low → Skip (unless explicitly requested)

### Step 7: Implement Fixes

**CRITICAL: Every fix MUST be marked as resolved before moving to next item.**

For each pending item:

1. **Read the full details:**
   ```bash
   ace-review-feedback show {id}
   ```

2. **Implement the fix** based on the recommendation

3. **IMMEDIATELY mark as resolved** (do NOT skip this step):
   ```bash
   ace-review-feedback resolve {id} --resolution "Fixed: <description>"
   ```

4. **Commit the fix** with a clear message referencing the feedback item

5. **Note the commit SHA** for PR comment resolution (if from Developer Feedback)

⚠️ **Never leave a fixed item as "pending"** - this breaks feedback tracking.

### Step 8: Handle Not-Applicable Items

Before skipping, complete the verification checklist:

1. **Read the code** - Does the issue actually still exist?
2. **Check current changes** - Was this already fixed in this PR?
3. **Consider effort** - Is this a quick win (< 5 min) that should just be done?

For items that won't be fixed in this PR:

```bash
# Design decision - intentionally this way
ace-review-feedback verify {id} --skip --research "Design: uses polling for simplicity"

# Important but deferred - ALWAYS create/reference a task
ace-review-feedback verify {id} --skip --research "Tracked in task 253"
```

**Never skip with "out of scope"** - either:
- It's a design decision (explain why)
- It needs a follow-up task (create one and reference it)

### Step 9: Resolve PR Comments (for Developer Feedback items)

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

## Quick Reference

```bash
# Feedback commands
ace-review-feedback list                      # All feedback
ace-review-feedback list --status draft       # Unverified items
ace-review-feedback list --status pending     # Verified valid items
ace-review-feedback list --session <path>     # From specific session
ace-review-feedback show {id}                 # Full item details
ace-review-feedback verify {id} --valid       # Mark as valid
ace-review-feedback verify {id} --invalid     # Mark as false positive
ace-review-feedback verify {id} --skip        # Mark as skipped
ace-review-feedback resolve {id}              # Mark as fixed

# PR comment resolution
gh pr comment $PR --body "Fixed in $(git rev-parse --short HEAD)"
```

## Output / Success Criteria

- [ ] PR review completed with feedback items
- [ ] Feedback items verified (Critical/High priority)
- [ ] False positives marked as invalid
- [ ] Confirmed items implemented
- [ ] PR comments addressed with commit references
- [ ] Review threads resolved (if applicable)
- [ ] All items marked as resolved or skipped
