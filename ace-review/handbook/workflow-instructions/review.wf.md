---
name: review
description: Review code with preset and plan feedback application
argument-hint: "[preset] [subjects...]"
allowed-tools: Read, Bash, TodoWrite
update:
  frequency: on-change
  last-updated: '2026-02-03'
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

**Important for Claude Code**: Run with 10-minute timeout (600000ms) and wait for completion inline (not background). Review typically takes 3-5 minutes.

Wait for the review to complete. Note the session directory path from the output.

The review generates:
- LLM model reviews (e.g., `review-gemini.md`)
- Feedback items in `feedback/` directory

### Step 2: List Feedback Items

List the feedback items extracted from the review:

```bash
ace-review feedback list --status draft
```

This shows all draft feedback items with their IDs, severity, and summaries.

#### Understanding Feedback Context

Feedback items are **session-scoped**. The `feedback list` command discovers items based on:
1. Explicit `--session <path>` flag (if provided)
2. Explicit `--task <ref>` flag (if provided)
3. Current task context (from git branch pattern)
4. `.ace-review-session` cache file in current directory

If `feedback list` returns empty after a review, the session may not be linked to current context.
Use `ace-review feedback list --session <session-dir>` to list from a specific session:

```bash
# List feedback from a specific session (path shown in review output)
ace-review feedback list --session .cache/ace-review/sessions/review-8p2pk3
```

### Step 3: Verify Each Feedback Item

For each feedback item (prioritize Critical and High severity):

```bash
# Read the finding details
ace-review feedback show {id}
```

**Then verify in the codebase:**

1. **Check the claim** - Use grep/read to verify the issue exists:
   - If claim is "X doesn't exist" → `grep -rn "class X" lib/`
   - If claim is "method missing" → check the actual file
   - If claim is "file not deleted" → `ls path/to/file`

2. **Mark the verification result:**

   ```bash
   # If issue is confirmed (valid finding)
   ace-review feedback verify {id} --valid --research "Confirmed: issue exists at line X"

   # If issue is not real (false positive)
   ace-review feedback verify {id} --invalid --research "False positive: handled by Y"
   ```

3. **Categorization guide:**

   | Result | Command | When |
   |--------|---------|------|
   | ✅ VALID | `--valid` | Issue confirmed in code |
   | ❌ INVALID | `--invalid` | False positive, code is correct |
   | ⚠️ SKIP | `feedback skip {id}` | Out of scope, known limitation |

**Example verification:**
```bash
# Claim: "TaskPatternExtractor is undefined"
grep -rn "class TaskPatternExtractor" ace-git/lib/
# Result: Found at ace-git/lib/ace/git/atoms/task_pattern_extractor.rb:10
ace-review feedback verify {id} --invalid --research "Class exists at ace-git/lib/ace/git/atoms/task_pattern_extractor.rb:10"
```

**Skip verification for:**
- Low priority items (verify only if time permits)
- Documentation-only suggestions
- Style/formatting recommendations

### Step 4: List Pending Items

After verification, list items ready to work on:

```bash
ace-review feedback list --status pending
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
   ace-review feedback show {id}
   ```

2. **Implement the fix** based on the recommendation

3. **Mark as resolved:**
   ```bash
   ace-review feedback resolve {id} --resolution "Fixed in commit abc123"
   ```

4. **Commit the fix** with a clear message referencing the feedback item

### Step 7: Handle Not-Applicable Items

For items that are out of scope or not worth fixing:

```bash
ace-review feedback skip {id} --reason "Out of scope for this PR"
```

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
ace-review feedback list                      # All feedback
ace-review feedback list --status draft       # Unverified items
ace-review feedback list --status pending     # Verified valid items
ace-review feedback list --session <path>     # From specific session
ace-review feedback show {id}                 # Full item details
ace-review feedback verify {id} --valid       # Mark as valid
ace-review feedback verify {id} --invalid     # Mark as false positive
ace-review feedback resolve {id}              # Mark as fixed
ace-review feedback skip {id}                 # Mark as skipped

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
