---
doc-type: workflow
title: Verify Feedback Workflow
purpose: Verify feedback items through multi-dimensional claim analysis
ace-docs:
  last-updated: 2026-03-12
  last-checked: 2026-03-21
---

# Verify Feedback Workflow

## Goal

Verify each feedback item through systematic claim analysis, marking items as valid, invalid, or skipped based on evidence gathered from the codebase, documentation, and execution context.

## Why This Workflow Exists

Simple verification ("does this code exist?") catches some false positives, but misses **scope claims** - assertions about where or when code executes. For example:

- "E2E tests may fail in CI" → E2E tests don't run in CI (scope error)
- "Missing API key validation" → Keys are validated in middleware (location error)
- "Thread-unsafe code" → Code only runs in single-threaded context (context error)

This workflow ensures each claim dimension is verified.

## Arguments

- `--session <path>` - Specific session directory (optional)
- `--status draft` - Filter to unverified items (default)

## Prerequisites

Before running this workflow, you need feedback items from a code review:
1. Run a code review: `ace-bundle wfi://review/run` or `ace-bundle wfi://review/pr`
2. Feedback items will be in `draft` status

## Instructions

### Step 1: List Draft Feedback Items

```bash
# List unverified items
ace-review-feedback list --status draft

# From specific session
ace-review-feedback list --status draft --session <path>
```

If no items appear, the review may not have generated extractable feedback.

### Step 2: For Each Item, Run Multi-Dimensional Verification

For each feedback item, verify claims across multiple dimensions before marking valid/invalid/skipped.

#### 2a. Read the Feedback Item

```bash
ace-review-feedback show <id>
```

Identify the claim being made. Common claim types:

| Claim Type | Example | Verification Question |
|------------|---------|----------------------|
| **Existence** | "Method X is undefined" | Does X exist in codebase? |
| **Scope** | "Fails in CI environment" | Does this code run in CI? |
| **Documentation** | "Behavior is undocumented" | Are there docs elsewhere? |
| **Pattern** | "Inconsistent with codebase" | What patterns exist? |
| **Security** | "Exposes sensitive data" | What data flows here? |
| **Performance** | "N+1 query issue" | How is this code called? |

#### 2b. Verify Each Claim Dimension

For each feedback item, work through applicable verification questions:

**1. Is the factual claim true?**
- If "X doesn't exist" → Search for X
- If "missing validation" → Check the specific code path
- If "undefined reference" → Verify the symbol resolution

```bash
# Example: Verify class exists
grep -rn "class TaskPatternExtractor" ace-git/lib/

# Example: Check for validation
grep -rn "validate" path/to/file.rb
```

**2. Does the scope match?**
- If "fails in CI" → Does this code execute in CI?
- If "production issue" → Does config differ in production?
- If "user-facing" → Is this actually exposed to users?

```bash
# Example: Check CI workflow for test execution
cat .github/workflows/test.yml | grep -A5 "run:"

# Example: Check if E2E tests run in CI
grep -rn "e2e\|end-to-end" .github/workflows/
```

**3. Is it already addressed elsewhere?**
- If "missing docs" → Check README, handbook, inline comments
- If "no error handling" → Check if caller handles errors
- If "missing validation" → Check middleware/filters

```bash
# Example: Check for documentation
grep -rn "api-key\|API_KEY" README.md docs/ handbook/

# Example: Check frontmatter for requirements
head -30 path/to/file.md
```

**4. Does it follow established patterns?**
- If "inconsistent approach" → What do similar files do?
- If "should use X instead" → What's the project standard?

```bash
# Example: Check existing patterns
grep -rn "def self\." lib/ace/review/atoms/ | head -20
```

#### 2c. Document Verification Result

Based on verification:

**Valid Finding** - All claim dimensions check out:
```bash
ace-review-feedback verify <id> --valid --research "Confirmed: <evidence>"
```

**Invalid Finding** - Any claim dimension fails:
```bash
ace-review-feedback verify <id> --invalid --research "<dimension> incorrect: <evidence>"
```

**Skip Finding** - Valid but not being fixed:
```bash
ace-review-feedback verify <id> --skip --research "Design: <reason>"
ace-review-feedback verify <id> --skip --research "Tracked in task XXX"
```

### Step 3: Common False Positive Patterns

Watch for these scope errors that simple verification misses:

| False Positive Pattern | How to Detect |
|----------------------|---------------|
| "CI environment" claims | Check if code actually runs in CI workflows |
| "Production" claims | Verify environment-specific behavior |
| "External API" claims | Check if feature is actually enabled/used |
| "Thread safety" claims | Verify concurrency context |
| "User input" claims | Trace actual data flow |

### Step 4: Verification Decision Table

| Factual Claim | Scope Correct | Addressed | Verdict |
|--------------|---------------|-----------|---------|
| True | True | No | **VALID** |
| True | True | Yes | **INVALID** (already addressed) |
| True | False | - | **INVALID** (scope error) |
| False | - | - | **INVALID** (factual error) |

### Step 5: Final Summary

After verifying all items:

```bash
# Check verification status
ace-review-feedback list

# Should show items as pending (valid) or invalid
```

## Examples

### Example 1: CI Scope Error

**Feedback**: "E2E tests may fail in CI environments without API keys"

**Verification**:
1. Factual: Do E2E tests make API calls? → Yes
2. Scope: Do E2E tests run in CI? → **NO** (check workflows)
3. Addressed: Are API requirements documented? → Yes (frontmatter)

**Result**: INVALID - scope claim is wrong
```bash
ace-review-feedback verify <id> --invalid --research "E2E tests are agent-executed, not CI. API requirements documented in frontmatter."
```

### Example 2: Valid Finding

**Feedback**: "Missing null check in user_handler.rb:45"

**Verification**:
1. Factual: Is there a null check? → No
2. Scope: Can this receive null? → Yes (from API response)
3. Addressed: Is null handled elsewhere? → No

**Result**: VALID
```bash
ace-review-feedback verify <id> --valid --research "Confirmed: API can return null, no check present"
```

### Example 3: Location Error

**Feedback**: "No input validation for user email"

**Verification**:
1. Factual: Is email validated in handler? → No
2. Scope: Is this the entry point? → Yes
3. Addressed: Is validation elsewhere? → **YES** (middleware)

**Result**: INVALID - validation exists in different location
```bash
ace-review-feedback verify <id> --invalid --research "Email validated in AuthMiddleware:23"
```

## Quick Reference

> **Tip**: Exact flag syntax per subcommand is available in the embedded `<feedback_cli_reference>` section above (loaded via ace-bundle).

```bash
# List items to verify
ace-review-feedback list --status draft

# Show item details
ace-review-feedback show <id>

# Mark as valid (confirmed issue)
ace-review-feedback verify <id> --valid --research "Evidence..."

# Mark as invalid (false positive)
ace-review-feedback verify <id> --invalid --research "Reason..."

# Mark as skipped (valid but not fixing)
ace-review-feedback verify <id> --skip --research "Design: reason..."

# Search helpers
grep -rn "pattern" path/           # Find code
cat file | head -30                # Check frontmatter
ls .github/workflows/              # Check CI config
```

## Choosing Between Verification Modes

All three modes archive feedback items, but they mean different things:

```
┌─────────────────────────────────────────────────────────────────┐
│  Is the feedback claim factually correct?                        │
├─────────────────┬───────────────────────────────────────────────┤
│  NO             │  YES                                          │
│  → verify --invalid  │  → Are you fixing it?                      │
│  (False positive)  │     ├─ YES → verify --valid (then resolve)  │
│                    │     └─ NO → verify --skip "..."            │
│                    │           (Not applicable)                  │
└────────────────────┴─────────────────────────────────────────────┘
```

| Question | `verify --invalid` | `verify --skip` |
|----------|-------------------|-----------------|
| Is the claim factually wrong? | ✅ Yes | ❌ No |
| Is the finding correct but not fixed? | ❌ No | ✅ Yes |

### Quick Examples

**`verify --invalid`** - The finding is incorrect:
- "Code doesn't exist" → Actually exists
- "Missing validation" → Exists elsewhere
- "Fails in CI" → Doesn't run in CI

**`verify --skip`** - The finding is correct but not being fixed:
- "Design: using polling for simplicity"
- "Tracked in task 253"
- "Duplicate of abc120"

## Success Criteria

- [ ] Each draft feedback item reviewed
- [ ] Factual claims verified against codebase
- [ ] Scope claims verified (where/when code executes)
- [ ] Existing documentation/handling checked
- [ ] Each item marked valid or invalid with research notes
- [ ] No items left in draft status