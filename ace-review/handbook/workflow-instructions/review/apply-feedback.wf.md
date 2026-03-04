---
name: review/apply-feedback
description: Apply verified feedback items from code review
argument-hint: "[--session <path>] [--priority <level>]"
allowed-tools: Read, Bash, Write, Edit, Grep, Glob
bundle:
  embed_document_source: true
  sections:
    feedback_cli_reference:
      commands:
        - ace-review-feedback verify --help
        - ace-review-feedback resolve --help
        - ace-review-feedback skip --help
update:
  frequency: on-change
  last-updated: '2026-02-06'
---

# Apply Feedback Workflow

## Goal

Work through verified (pending) feedback items one by one, implementing fixes and marking items as resolved.

## Arguments

- `$1`: Optional session path or priority filter
  - `--session <path>` - Specific session directory
  - `--priority <level>` - Filter by priority (critical, high, medium, or low)

## Prerequisites

Before running this workflow:
1. Run a code review: `/ace-review-run` or `/ace-review-pr`
2. Verify feedback items: `ace-review-feedback verify <id> --valid` for confirmed issues

## Instructions

### Step 1: List Verified Feedback Items

List all items that have been verified as valid (status: pending):

```bash
# List pending items (verified valid, ready to fix)
ace-review-feedback list --status pending

# Filter by priority
ace-review-feedback list --status pending --priority critical
ace-review-feedback list --status pending --priority high
```

If no items are shown, either:
- No feedback has been verified yet → run verification first
- Use `--session <path>` to specify the session directory

### Step 2: Work Through Items by Priority

Process items in priority order: Critical → High → Medium → Low

For each pending item:

#### 2a. Read the Feedback Details

```bash
ace-review-feedback show <id>
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
ace-review-feedback resolve <id> --resolution "Already fixed"
# or
ace-review-feedback verify <id> --invalid --research "Issue not found in code"
```

#### 2c. Implement the Fix

Apply the recommended fix or an appropriate alternative:
- Make the necessary code changes
- Follow existing patterns in the codebase
- Keep changes minimal and focused

#### 2d. Mark as Resolved

After implementing the fix:

```bash
ace-review-feedback resolve <id> --resolution "Fixed: <brief description>"
```

Example:
```bash
ace-review-feedback resolve 8p3abc --resolution "Added input validation in user_handler.rb"
```

### Step 3: Handle Items That Won't Be Fixed

Before skipping any item, complete the **verification checklist**:

#### Verification Checklist (Required Before Skip)

- [ ] **Read the code** - Did you check if the issue still exists?
- [ ] **Check current changes** - Was this already addressed in this PR?
- [ ] **Consider effort** - Is this a quick win (< 5 min) that should just be done?

#### Decision Table

| Finding | Verdict | Action |
|---------|---------|--------|
| Not actually an issue | INVALID | `feedback verify {id} --invalid` |
| Fixed in this PR | DONE | `feedback resolve {id}` |
| Quick win (< 5 min) | DO IT | Implement, then `feedback resolve {id}` |
| Design decision | SKIP | `feedback skip {id} --reason "Design: ..."` |
| Important but not this PR | DEFER | `feedback skip {id} --reason "Tracked in task XXX"` + create task |

#### Valid Skip Reasons

```bash
# Design decision - intentionally this way
ace-review-feedback skip <id> --reason "Design: uses polling for simplicity"

# False positive confirmed
ace-review-feedback skip <id> --reason "False positive: validation exists in middleware"

# Duplicate of another item
ace-review-feedback skip <id> --reason "Duplicate of 8p3xyz"

# Deferred with task tracking (important items)
ace-review-feedback skip <id> --reason "Tracked in task 253"
```

#### NOT Valid Skip Reasons

These should NOT be used as skip reasons - use alternatives instead:

| Don't Say | Instead |
|-----------|---------|
| "Out of scope" | Create a follow-up task, reference it in skip reason |
| "Would need refactoring" | Create a follow-up task for the refactoring |
| "Low priority" | Check if it's a quick win first, then defer with task |
| "E2E tests needed" | Create task for E2E tests, reference in skip reason |

#### Quick Win Guidelines

Not all "low priority" items should be skipped. Consider effort vs value:

| Effort | Impact | Decision |
|--------|--------|----------|
| < 5 min | Improves readability/maintainability | **DO IT** |
| Any | Removes dead code, fixes warnings | **DO IT** |
| > 15 min | Nice-to-have, optional | DEFER with task |
| Any | Housekeeping, archival | DEFER with task |

**Examples of quick wins to just do:**
- Document terminology (5 min)
- Remove unused variable (1 min)
- Fix typo in error message (1 min)
- Add missing type annotation (2 min)

### Step 4: Final Check

After processing all items:

```bash
# Verify no pending items remain
ace-review-feedback list --status pending

# Check overall stats
ace-review-feedback list
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

> **Tip**: Exact flag syntax per subcommand is available in the embedded `<feedback_cli_reference>` section above (loaded via ace-bundle).

```bash
# Feedback commands
ace-review-feedback list --status pending     # Items ready to fix
ace-review-feedback show <id>                 # View details
ace-review-feedback resolve <id> --resolution "Fixed in commit abc"
ace-review-feedback skip <id> --reason "Design: intentional choice"

# If feedback is empty, try specifying session
ace-review-feedback list --session .ace-local/review/sessions/review-xxx
```

## Success Criteria

- [ ] All critical/high priority items addressed
- [ ] Medium priority items addressed (unless explicitly deferred)
- [ ] Each fixed item marked as resolved with commit reference
- [ ] Skipped items have valid reasons (design decision or task reference)
- [ ] No items skipped with vague "out of scope" reason
- [ ] Quick wins (< 5 min) implemented rather than skipped
- [ ] Important deferred items have follow-up tasks created
- [ ] No pending items remain (or only intentionally deferred Low items)
