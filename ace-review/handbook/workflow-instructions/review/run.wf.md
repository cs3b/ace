---
doc-type: workflow
title: Code Review Workflow
purpose: Review code with preset and plan feedback application
ace-docs:
  last-updated: 2026-03-18
  last-checked: 2026-03-21
---

# Code Review Workflow

## Goal

Review code using ace-review, verify feedback items, and create a plan for applying fixes.

## Arguments

- `$1`: Preset name (optional). Run `ace-review --list-presets` to see options.
- `$2+`: Subject(s) using `type:value` syntax (optional, additive to preset):

  **IMPORTANT: The type prefix is REQUIRED for all subjects except keywords**

  - `staged`, `working` - keywords (no prefix needed)
  - `diff:origin/main..HEAD` - git range (prefix required)
  - `diff:origin/main...HEAD -- ace-test-runner-e2e` - git range filtered to paths
  - `pr:123` - PR diff (prefix required)
  - `files:lib/**/*.rb` - file pattern (prefix required)
  - `task:145` - task context (prefix required)

## Instructions

### Step 1: Run Code Review

```bash
# Default preset
ace-review --auto-execute

# With preset
ace-review --preset $1 --auto-execute

# With subject(s) - additive to preset
ace-review --subject "$2" --auto-execute

# File pattern review (NOTE: files: prefix is REQUIRED)
ace-review --preset spec --subject "files:.ace-taskflow/**/*.md" --auto-execute

# Multiple subjects merge automatically
ace-review --subject pr:76 --subject files:CHANGELOG.md --auto-execute
```

**Important for Claude Code**: Run with 15-minute timeout (900000ms) and wait for completion inline (not background). Review typically takes 3-5 minutes.

#### Execution Guard (Mandatory)

- Completion is defined by **process exit** (success or failure), not by partial output.
- Do **not** treat temporary silence/no new output as completion.
- Do **not** run any Step 2+ commands until Step 1 process exit is confirmed.
- If 15-minute timeout (900000ms) is reached, report timeout and last observed output, then stop dependent steps.

Wait for the review process to exit. Note the session directory path from the output.

The review generates:
- LLM model reviews (e.g., `review-gemini.md`)
- Feedback items in `feedback/` directory

### Step 2: List Feedback Items

List the feedback items extracted from the review:

```bash
ace-review-feedback list --status draft
```

**Precondition**: Run this step only after Step 1 process exit is confirmed.

When session ambiguity is possible, use explicit session path from Step 1:

```bash
ace-review-feedback list --status draft --session <session-dir-from-step-1>
```

This shows all draft feedback items with their IDs, severity, and summaries.

#### Understanding Feedback Context

Feedback items are **session-scoped**. The `feedback list` command discovers items based on:
1. Explicit `--session <path>` flag (if provided)
2. `.ace-review-session` cache file in current directory (auto-created after reviews)

If `feedback list` returns empty after a review, first verify Step 1 process completion.
The session may not be linked to current context.
Use `ace-review-feedback list --session <session-dir>` to list from a specific session:

```bash
# List feedback from a specific session (path shown in review output)
ace-review-feedback list --session .ace-local/review/sessions/review-8p2pk3
```

### Step 3: Verify Feedback Items

**For thorough verification**, use the dedicated verification workflow:

```
ace-bundle wfi://review/verify-feedback
```

This workflow guides you through multi-dimensional claim analysis:
- **Existence claims**: Does the code/issue actually exist?
- **Scope claims**: Does the issue apply where claimed (CI, production, etc.)?
- **Documentation claims**: Are there docs/handling elsewhere?
- **Pattern claims**: Is this consistent with codebase patterns?

**For quick verification** of straightforward items:

```bash
# Read the finding details
ace-review-feedback show {id}

# Verify and mark result
ace-review-feedback verify {id} --valid --research "Confirmed: issue exists at line X"
ace-review-feedback verify {id} --invalid --research "False positive: handled by Y"
```

**Categorization guide:**

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

**Skip verification for:**
- Low priority items (verify only if time permits)
- Documentation-only suggestions
- Style/formatting recommendations

### Step 4: List Pending Items

After verification, list items ready to work on:

```bash
ace-review-feedback list --status pending
```

This shows only verified valid items that need fixing.

### Step 5: Apply Priority Threshold

**Default behavior**: Implement **Medium and higher** severity items (skip Low).

This means:
- 🔴 Critical → Implement
- 🟡 High → Implement
- 🟢 Medium → Implement
- 🔵 Low → Skip (unless explicitly requested)

### Step 6: Implement Fixes

For each pending item:

1. **Read the full details:**
   ```bash
   ace-review-feedback show {id}
   ```

2. **Implement the fix** based on the recommendation

3. **Mark as resolved:**
   ```bash
   ace-review-feedback resolve {id} --resolution "Fixed in commit abc123"
   ```

4. **Commit the fix** with a clear message referencing the feedback item

### Step 7: Handle Not-Applicable Items

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

# Common patterns
ace-review --auto-execute                                  # Default preset
ace-review --subject staged --auto-execute                 # Staged only
ace-review --subject diff:origin/main..HEAD --auto-execute # vs main
ace-review --subject pr:76 --subject files:README.md --auto-execute  # Combined

# Debug
ace-review --dry-run   # See what would run
```

## Common Mistakes

❌ **Wrong**: `ace-review --subject path/to/file`
✅ **Correct**: `ace-review --subject files:path/to/file`

❌ **Wrong**: `ace-review --subject 123`
✅ **Correct**: `ace-review --subject pr:123`

❌ **Wrong**: `ace-review --subject origin/main..HEAD`
✅ **Correct**: `ace-review --subject diff:origin/main..HEAD`

The type prefix (`files:`, `pr:`, `diff:`, `task:`) is **required** for all subjects except the keywords `staged` and `working`.

## Success Criteria

- [ ] Review completed with feedback items
- [ ] Feedback items verified (Critical/High priority)
- [ ] False positives marked as invalid
- [ ] Confirmed items implemented with commits
- [ ] Items marked as resolved with commit references
