# Task 047: Workflow Migration - Usage Scenarios

## Output Locations

**Key Concept:** Workflows output to different locations based on their purpose:
- **Quick ideas** (via `capture-idea`): Brief concepts like "Add caching layer" → `.ace-taskflow/backlog/ideas/`
- **Detailed ideas** (via `capture-features`): Comprehensive "beefy" ideas with full specs → `.ace-taskflow/backlog/ideas/`
- **Unplanned work** (via `document-unplanned`): Completed work as done tasks → `.ace-taskflow/v.X.X.X/t/done/`

This approach treats feature documentation as a more detailed form of idea capture (same storage as ideas), while unplanned work becomes a completed task directly in the done folder.

## What We're Migrating

### 1. Prioritize and Align Ideas Workflow
**Current Location:** `dev-handbook/workflow-instructions/prioritize-align-ideas.wf.md`
**Target Location:** `ace-taskflow/handbook/workflow-instructions/prioritize-align-ideas.wf.md`
**Command:** `/ace:prioritize-ideas`

**Purpose:** Systematically organize and prioritize backlog ideas, aligning them with project architecture and creating an implementation roadmap.

### 2. Capture Application Features Workflow
**Current Location:** `dev-handbook/workflow-instructions/capture-application-features.wf.md`
**Target Location:** `ace-taskflow/handbook/workflow-instructions/capture-application-features.wf.md`
**Command:** `/ace:capture-features`

**Purpose:** Create detailed/comprehensive idea documentation for application features. Outputs to `.ace-taskflow/backlog/ideas/` (same location as quick ideas, but creates "beefy" ideas with full component specs, interactions, tracking, and business rules).

### 3. Document Unplanned Work Workflow
**Current Location:** `dev-handbook/workflow-instructions/document-unplanned-work.wf.md`
**Target Location:** `ace-taskflow/handbook/workflow-instructions/document-unplanned-work.wf.md`
**Command:** `/ace:document-unplanned`

**Purpose:** Document significant work completed during a session that wasn't part of any planned task. Creates completed task files in `.ace-taskflow/v.X.X.X/t/done/` with status `done`.

---

## Usage Scenarios

### Scenario 1: Organizing Backlog Ideas

**Context:** You have 20 unorganized idea files in `.ace-taskflow/backlog/ideas/` and need to prioritize them for the next release cycle.

**Current Workflow (Before Migration):**
```
User invokes Claude Code command:
/prioritize-align-ideas

Claude reads file directly:
read whole file and follow @dev-handbook/workflow-instructions/prioritize-align-ideas.wf.md
```

**After Migration:**
```
User invokes migrated Claude Code command:
/ace:prioritize-ideas

Claude uses wfi:// protocol:
read and run `ace-nav wfi://prioritize-align-ideas`
read and run `ace-nav wfi://commit`
```

**Expected Output:**
- Ideas prioritized using `ace-taskflow idea reschedule` with sort metadata
- High priority ideas positioned first (via `--add-next` and `--after` commands)
- Implementation roadmap created at `000-implementation-roadmap.md`
- All ideas aligned with current project architecture
- Git commit shows modified idea files (sort field added/updated, not renamed)

**Example Reschedule Sequence:**
```bash
# After analyzing 20 ideas, prioritize top 3:
ace-taskflow idea reschedule context-optimization --add-next --backlog
# → Sets sort: 10.0 (first position)

ace-taskflow idea reschedule error-handling --after context-optimization --backlog
# → Sets sort: 20.0 (after first)

ace-taskflow idea reschedule workflow-automation --after error-handling --backlog
# → Sets sort: 30.0 (after second)

# Position lower priority ideas at end:
ace-taskflow idea reschedule minor-refactor --add-at-end --backlog
# → Sets sort: 90.0 (last position)

# Verify order:
ace-taskflow ideas --backlog --limit 5
# Shows ideas in priority order based on sort values
```

**Test Validation:**
```bash
# Verify workflow is discoverable
ace-nav wfi://prioritize-align-ideas --content | head -10

# Check command file exists
test -f .claude/commands/ace/prioritize-ideas.md

# Verify command uses wfi:// protocol
grep -q "wfi://prioritize-align-ideas" .claude/commands/ace/prioritize-ideas.md

# Verify ideas have sort metadata
grep -l "^sort:" .ace-taskflow/backlog/ideas/*.md | wc -l
```

---

### Scenario 2: Documenting CMS Feature as Detailed Idea

**Context:** Building a marketing site with CMS-editable sections. Need to create comprehensive documentation for the Hero Banner feature as a detailed idea file.

**Current Workflow (Before Migration):**
```
User invokes Claude Code command:
/capture-application-features

Claude reads file directly from dev-handbook:
read whole file and follow @dev-handbook/workflow-instructions/capture-application-features.wf.md
```

**After Migration:**
```
User invokes migrated Claude Code command:
/ace:capture-features

Claude uses wfi:// protocol:
read and run `ace-nav wfi://capture-application-features`
read and run `ace-nav wfi://commit`
```

**Example Session:**
```
User: /ace:capture-features

Claude: I'll help document application features. What feature would you like to capture?

User: The Hero Banner section on our homepage

Claude: [Follows workflow]
- Identifies feature: Hero Banner
- Documents structure (background image, title, subtitle, CTA button)
- Captures user interactions (click CTA → navigate to product page)
- Defines tracking events (hero_cta_clicked with parameters)
- Documents states (loading, default, error)
- Documents business rules and component specs

Output: Detailed idea file saved at:
.ace-taskflow/backlog/ideas/hero-banner-feature.md

Note: This is a "beefy" idea with comprehensive specs, stored alongside
simpler ideas but with much more detail (components, tracking, interactions).
```

**Test Validation:**
```bash
# Verify workflow discoverable via ace-nav
ace-nav 'wfi://*feature*' --list | grep capture-application-features

# Test command file
test -f .claude/commands/ace/capture-features.md
grep -q "wfi://capture-application-features" .claude/commands/ace/capture-features.md
```

---

### Scenario 3: Capturing Unplanned Bug Fix

**Context:** During development, you fixed a critical bug that wasn't tracked in any task. Need to document it for retrospectives and release notes.

**Current Workflow (Before Migration):**
```
User invokes Claude Code command:
/document-unplanned-work

Claude reads file directly:
read whole file and follow @dev-handbook/workflow-instructions/document-unplanned-work.wf.md
```

**After Migration:**
```
User invokes migrated Claude Code command:
/ace:document-unplanned

Claude uses wfi:// protocol:
read and run `ace-nav wfi://document-unplanned-work`
read and run `ace-nav wfi://commit`
```

**Example Session:**
```
User: /ace:document-unplanned

Claude: I'll help document unplanned work. What work did you complete?

User: Fixed a race condition in task scheduler that caused duplicate task IDs

Claude: [Follows workflow]
- Creates task file with status: done (work already completed)
- Documents: issue, root cause, solution, files modified
- Includes: git commit references, testing validation
- Moves directly to done folder

Output: Completed task documented in:
.ace-taskflow/v.0.9.0/t/done/XXX-fix-task-scheduler-race-condition/task.XXX.md

File metadata:
---
id: v.0.9.0+task.XXX
status: done
priority: high
---
```

**Test Validation:**
```bash
# Verify workflow in ace-nav
ace-nav wfi://document-unplanned-work --content | grep "## Goal"

# Check command
test -f .claude/commands/ace/document-unplanned.md
grep -q "wfi://document-unplanned-work" .claude/commands/ace/document-unplanned.md
```

---

## Integration Testing

### Test 1: Workflow Discovery
**Goal:** Verify ace-nav discovers all three workflows from @ace-taskflow source

```bash
# List all workflows and filter for our migrations
ace-nav 'wfi://*' --list | grep -E "prioritize-align-ideas|capture-application-features|document-unplanned-work"

# Expected output (after migration):
# wfi://prioritize-align-ideas → .../ace-taskflow/handbook/workflow-instructions/prioritize-align-ideas.wf.md (@ace-taskflow)
# wfi://capture-application-features → .../ace-taskflow/handbook/workflow-instructions/capture-application-features.wf.md (@ace-taskflow)
# wfi://document-unplanned-work → .../ace-taskflow/handbook/workflow-instructions/document-unplanned-work.wf.md (@ace-taskflow)
```

### Test 2: Command File Structure
**Goal:** Verify Claude Code command files follow thin wrapper pattern

```bash
# Check all three commands exist in ace/ namespace
ls -1 .claude/commands/ace/ | grep -E "prioritize-ideas|capture-features|document-unplanned"

# Verify each uses wfi:// protocol
for cmd in prioritize-ideas capture-features document-unplanned; do
  echo "Checking $cmd..."
  grep -q "ace-nav wfi://" .claude/commands/ace/$cmd.md && echo "✓ Uses wfi://" || echo "✗ Missing wfi://"
  grep -q "source: ace-taskflow" .claude/commands/ace/$cmd.md && echo "✓ Has source metadata" || echo "✗ Missing metadata"
done
```

### Test 3: Workflow Self-Containment
**Goal:** Verify workflows maintain embedded templates (ADR-001 compliance)

```bash
# Check for embedded templates in moved workflows
for wf in prioritize-align-ideas capture-application-features document-unplanned-work; do
  echo "Checking $wf..."
  file="ace-taskflow/handbook/workflow-instructions/$wf.wf.md"

  # Look for template/document tags
  if grep -q "<template\|<documents>" "$file"; then
    echo "✓ Has embedded templates"
  else
    echo "⚠ No embedded templates found"
  fi
done
```

---

## Post-Migration User Experience

### Quick Reference Card

| Task | Command | Workflow Location | Output |
|------|---------|-------------------|--------|
| Organize ideas | `/ace:prioritize-ideas` | `wfi://prioritize-align-ideas` | Ranked ideas in `.ace-taskflow/backlog/ideas/` with sort metadata |
| Document features (detailed ideas) | `/ace:capture-features` | `wfi://capture-application-features` | Beefy idea in `.ace-taskflow/backlog/ideas/` |
| Capture unplanned work | `/ace:document-unplanned` | `wfi://document-unplanned-work` | Completed task in `.ace-taskflow/v.X.X.X/t/done/` with status `done` |

### For Users

**New Architecture:**
- Commands organized under `.claude/commands/ace/` namespace
- Workflows in `ace-taskflow/handbook/workflow-instructions/`
- wfi:// protocol for platform-independent access
- Clean command names with `/ace:` prefix
- **Organized storage**:
  - Ideas (quick & detailed): `.ace-taskflow/backlog/ideas/`
  - Unplanned work: `.ace-taskflow/v.X.X.X/t/done/` (as completed tasks)
- **Prioritization**: Uses `ace-taskflow idea reschedule` with sort metadata (no file renaming)

### For AI Agents (Platform Independent)

```bash
# Any AI platform can access workflows via ace-nav
ace-nav wfi://prioritize-align-ideas
ace-nav wfi://capture-application-features
ace-nav wfi://document-unplanned-work

# Claude Code users get convenient slash commands
/ace:prioritize-ideas
/ace:capture-features
/ace:document-unplanned
```

---

## Success Metrics

- [ ] All three workflows accessible via `ace-nav wfi://` protocol
- [ ] All three commands work via `/ace:` prefix in Claude Code
- [ ] Zero broken references in project documentation
- [ ] Workflows maintain self-containment (embedded templates)
- [ ] Git history preserved for all moved files
- [ ] Old command files cleaned up or redirected
