---
doc-type: workflow
title: Self-Improve Workflow
purpose: Documentation for ace-retro/handbook/workflow-instructions/retro/selfimprove.wf.md
ace-docs:
  last-updated: 2026-03-01
  last-checked: 2026-03-21
---

# Self-Improve Workflow

## Goal

Transform mistakes and recurring issues into system improvements. Fix the process first, then fix the immediate issue.

## Anti-Pattern

❌ Mistake happens → Agent re-runs instruction → Same mistake can happen again

## Correct Pattern

✅ Mistake identified → Analyze root cause → Update process → Fix immediate issue → Record retro

## Input Sources

Self-improvement is always a consequence of retrospective. Input can come from:

- **Session context** — analyze current conversation for mistakes or suboptimal patterns
- **Existing retros** — load retros via `ace-retro list`/`ace-retro show` to find recurring issues
- **User input** — user describes what went wrong

## Process Steps

### Step 1: Gather Input

Determine the source and capture incident details:

**From session context:**
- Review the current conversation for mistakes, repeated attempts, or corrections
- Identify what went wrong and what should have happened

**From existing retros:**
```bash
# Find retros with relevant issues
ace-retro list --status active

# Load specific retro content
ace-retro show REF --content
```

**From user input:**
- Capture the user's description of the problem

Document the incident:

| Question | Details |
|----------|---------|
| **What happened** | What action was taken? |
| **Actual result** | What was the output? |
| **Expected result** | What should have happened? |
| **Source** | Session / retro REF / user description |

### Step 2: Identify Root Cause Category

Ask: "Why did this happen?" Categorize the root cause:

| Category | Description | Example |
|----------|-------------|---------|
| **Ambiguous instructions** | Workflow allows misinterpretation | "Reorganize commits" without specifying scope source |
| **Missing validation** | No checkpoint to catch the error | No step to verify scope before executing |
| **Assumed context** | Agent didn't have necessary information | Agent used plan data instead of querying actual state |
| **Scope narrowing** | Agent under-scoped the task | Followed plan literally instead of understanding intent |
| **Scope creep** | Agent over-scoped the task | Made changes beyond what was requested |
| **Missing example** | No example of correct behavior | Workflow lacks example showing full scope discovery |
| **Redundant computation** | Multiple agents derive same value independently, causing divergence | Orchestrator computes path one way, agent re-derives differently |

### Step 3: Find the Source

Search for the relevant process files that need updating:

```bash
# Search workflow instructions
ace-bundle wfi://{relevant-workflow}

# Search guides
ace-bundle guide://{relevant-guide}

# Search skills
ace-bundle skill://{relevant-skill}

# Discover available resources
ace-nav --sources
```

**Search targets (in preference order):**

1. **Workflow instructions** (`wfi://namespace/action`) — preferred for process improvements
2. **Guides** (`guide://topic`) — preferred for best practices and conventions
3. **Skills** (`.claude/skills/*/SKILL.md`) — only when workflow/guide doesn't exist
4. **CLAUDE.md files** — project-level overrides only

### Step 4: Draft the Fix

Propose specific edits. The fix should:

1. **Address the root cause** — not just the symptom
2. **Be minimal** — only change what's necessary
3. **Include validation** — add checkpoints where missing
4. **Add examples** — show correct behavior if unclear

**Fix templates by category:**

**For ambiguous instructions:**
```markdown
## After
**Scope Discovery**: Before executing, always query the actual state:
- Run the relevant query command to get the full scope
- Do NOT rely on estimates — query actual state
- Confirm scope with user if actual differs from expectations
```

**For missing validation:**
```markdown
## After
### Validate Before Executing
- [ ] Query actual state
- [ ] Compare to expected scope
- [ ] If mismatch, confirm with user before proceeding
```

**For redundant computation:**
```markdown
## After
Pass computed values explicitly; don't re-derive:
- Orchestrator computes once and passes to subagent
- Subagent uses the provided value, never re-derives
```

### Step 5: Present to User

Before making any changes, present:

```markdown
## Root Cause Analysis

**What happened**: [Concise description]
**Why it happened**: [Root cause category and explanation]
**Source file**: [File path(s) to update]

## Proposed Process Changes

**File**: `{path/to/file}`
**Change**: [Description]

**Diff preview**:
` ``diff
- [old content]
+ [new content]
` ``

## Questions

1. Does this analysis match your understanding?
2. Should I proceed with these process changes?
3. After updating the process, should I also fix the immediate issue?
```

### Step 6: Implement Changes

After user approval:

1. **Update the process file(s)** — apply the proposed edits
2. **Fix the immediate issue** (if requested)
3. **Record a retro** documenting the improvement:

```bash
ace-retro create "selfimprove-TOPIC" --type self-improvement --tags process-fix
```

Populate the retro with the root cause analysis, the fix applied, and the expected impact.

### Step 7: Archive Consumed Retros

If the input source was an existing retro, archive it after the improvement has been applied — the retro has been "consumed":

```bash
ace-retro move REF --to archive
```

## Success Criteria

- Root cause is identified (not just symptoms)
- Process fix prevents recurrence
- User approves changes before implementation
- Both process and immediate issue are addressed
- Improvement is recorded as a retro via `ace-retro create`
- Source retros (if any) are archived after processing
