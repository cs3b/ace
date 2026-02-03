---
name: apply-feedback
description: Apply verified feedback items from code review
argument-hint: "[--session <path>] [--priority <level>]"
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
update:
  frequency: on-change
  last-updated: '2026-02-03'
---

# Apply Feedback Workflow

## Goal

Work through verified (pending) feedback items one by one, implementing fixes and marking items as resolved.

## Arguments

- `$1`: Optional session path or priority filter
  - `--session <path>` - Specific session directory
  - `--priority medium+` - Filter by priority (critical, high, medium, or "medium+" for medium and above)

## Prerequisites

Before running this workflow:
1. Run a code review: `/ace:review` or `/ace:review-pr`
2. Verify feedback items: `ace-review feedback verify <id> --valid` for confirmed issues

## Instructions

### Step 1: List Verified Feedback Items

List all items that have been verified as valid (status: pending):

```bash
# List pending items (verified valid, ready to fix)
ace-review feedback list --status pending

# Filter by priority
ace-review feedback list --status pending --priority critical
ace-review feedback list --status pending --priority high
```

If no items are shown, either:
- No feedback has been verified yet → run verification first
- Use `--session <path>` to specify the session directory

### Step 2: Work Through Items by Priority

Process items in priority order: Critical → High → Medium → Low

For each pending item:

#### 2a. Read the Feedback Details

```bash
ace-review feedback show <id>
```

Note the:
- **Files** affected
- **Finding** description
- **Context** explaining why this matters
- **Reviewer quotes** (if multiple reviewers identified this)

#### 2b. Verify the Issue Still Exists

Before implementing, confirm the issue is still present:

```bash
# Read the affected file(s)
# Check if the issue described actually exists
```

If the issue was already fixed or doesn't exist:
```bash
ace-review feedback resolve <id> --resolution "Already fixed"
# or
ace-review feedback verify <id> --invalid --research "Issue not found in code"
```

#### 2c. Implement the Fix

Apply the recommended fix or an appropriate alternative:
- Make the necessary code changes
- Follow existing patterns in the codebase
- Keep changes minimal and focused

#### 2d. Mark as Resolved

After implementing the fix:

```bash
ace-review feedback resolve <id> --resolution "Fixed: <brief description>"
```

Example:
```bash
ace-review feedback resolve 8p3abc --resolution "Added input validation in user_handler.rb"
```

### Step 3: Handle Items That Can't Be Fixed

For items that are out of scope or not worth fixing:

```bash
ace-review feedback skip <id> --reason "Out of scope for this PR"
```

Valid reasons for skipping:
- Out of scope for current work
- Would require significant refactoring
- Known limitation, documented elsewhere
- Low priority, deferred to future work

### Step 4: Final Check

After processing all items:

```bash
# Verify no pending items remain
ace-review feedback list --status pending

# Check overall stats
ace-review feedback list
```

## Priority Guidelines

**Default behavior**: Implement **Medium and higher** severity items.

| Priority | Action |
|----------|--------|
| Critical | Must implement - security or data integrity issues |
| High | Should implement - significant bugs or problems |
| Medium | Implement - code quality improvements |
| Low | Optional - skip unless specifically requested |

## Quick Reference

```bash
# Feedback commands
ace-review feedback list --status pending     # Items ready to fix
ace-review feedback show <id>                 # View details
ace-review feedback resolve <id> --resolution "Fixed in commit abc"
ace-review feedback skip <id> --reason "Out of scope"

# If feedback is empty, try specifying session
ace-review feedback list --session .cache/ace-review/sessions/review-xxx
```

## Success Criteria

- [ ] All critical/high priority items addressed
- [ ] Medium priority items addressed (unless explicitly deferred)
- [ ] Each fixed item marked as resolved with commit reference
- [ ] Skipped items have documented reasons
- [ ] No pending items remain (or only intentionally deferred Low items)
