---
name: review
description: Review code with preset and plan feedback application
argument-hint: "[preset] [subjects...]"
allowed-tools: Read, Bash, TodoWrite, AskUserQuestion
update:
  frequency: on-change
  last-updated: '2025-12-27'
---

# Code Review Workflow

## Goal

Review code using ace-review, read the synthesis report, and create a plan for applying feedback.

## Arguments

- `$1`: Preset name (optional). Run `ace-review --list-presets` to see options.
- `$2+`: Subject(s) using `type:value` syntax (optional, additive to preset):
  - `staged`, `working` - keywords
  - `diff:origin/main..HEAD` - git range
  - `pr:123` - PR diff
  - `files:lib/**/*.rb` - file pattern
  - `task:145` - task context

## Instructions

### Step 1: Run Code Review

```bash
# Default preset
ace-review --auto-execute

# With preset
ace-review --preset $1 --auto-execute

# With subject(s) - additive to preset
ace-review --subject "$2" --auto-execute

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

### Step 4: Create Feedback Plan

Based on the synthesis report's **Prioritized Action Items** and **verification results**, create a plan:

1. List only VALID and SUGGESTION items by priority (Critical → High → Medium → Low)
2. Note any INVALID items that were filtered out
3. For each VALID item, note:
   - Location (file:line)
   - Description of the issue
   - Recommended fix
   - Verification evidence
4. Identify which items to implement now vs capture as ideas for later

### Step 5: Present Plan and Wait for Confirmation

Present the plan to the user with a summary:
- Number of items per priority level
- Estimated scope of changes
- Any items recommended to defer

Use AskUserQuestion to confirm:
- "Which items should I implement?"
- Options: All items, High priority only, Custom selection

Only proceed with implementation after user confirmation.

### Step 6: Implement Fixes

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

## Success Criteria

- [ ] Review completed with synthesis report
- [ ] Action items verified (Critical/High priority)
- [ ] False positives identified and excluded
- [ ] Feedback plan created and confirmed by user
- [ ] Confirmed items implemented with commits
