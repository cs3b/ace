---
name: review
description: Review code with preset and plan feedback application
argument-hint: "[preset] [subjects...]"
allowed-tools: Read, Bash, TodoWrite
update:
  frequency: on-change
  last-updated: '2026-01-05'
---

# Code Review Workflow

## Goal

Review code using ace-review, read the synthesis report, and create a plan for applying feedback.

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

### Step 3: Verify Action Items

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

### Step 4: Categorize Results

Based on verification results, categorize each item:

**Goes to "No Action Needed" (no numbering):**
- INVALID - False positives, LLM hallucinations, code is correct
- VERIFIED CORRECT - LLM suggested to verify, but verification confirmed code is correct

**Goes to "Action Items" (numbered with priority):**
- VALID - Issue confirmed, needs fixing
- SUGGESTION - Optional improvement

### Step 5: Present Results

Present results in two separate sections:

#### No Action Needed

List items that don't require changes (no numbering):
- Description + why it's invalid/correct
- Verification evidence

#### Action Items

List items that need fixing with priority indicators:

```
🔴 #1 [Critical] Issue description
   File: path/to/file.rb:123
   Fix: What needs to be done

🟡 #2 [High] Another issue
   File: another/file.rb:45
   Fix: Suggested fix

🟢 #3 [Medium] Improvement suggestion
   File: path/to/file.rb:89
   Fix: Optional enhancement

🔵 #4 [Low] Nice-to-have
   File: path/to/file.rb:12
   Fix: Minor improvement
```

Priority indicators: 🔴 Critical/Blocking, 🟡 High, 🟢 Medium, 🔵 Low

### Step 6: Apply Priority Threshold

**Default behavior**: Implement **Medium and higher** priority items (skip Low).

This means:
- 🔴 Critical → Implement
- 🟡 High → Implement
- 🟢 Medium → Implement
- 🔵 Low → Skip (unless explicitly requested)

Proceed directly to implementation.

### Step 7: Implement Fixes

Implement the confirmed fixes. After each fix:
- Commit with a clear message referencing the issue
- Mark completion in the plan

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

- [ ] Review completed with synthesis report
- [ ] Action items verified (Critical/High priority)
- [ ] False positives identified and excluded
- [ ] Feedback plan created and confirmed by user
- [ ] Confirmed items implemented with commits
