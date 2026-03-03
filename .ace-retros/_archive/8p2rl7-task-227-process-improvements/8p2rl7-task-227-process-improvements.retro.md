---
id: 8p2rl7
title: Task 227 - Spec-to-Implementation Gaps and Process Improvements
type: standard
tags: []
created_at: '2026-02-03 18:23:32'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8p2rl7-task-227-process-improvements.md"
---

# Reflection: Task 227 - Spec-to-Implementation Gaps and Process Improvements

**Date**: 2026-02-03
**Context**: Comprehensive analysis of task 227 "Feedback-Based Review Output Architecture" - comparing specs vs implementation, and identifying improvements for drafting/reviewing processes
**Author**: Claude Opus 4.5
**Type**: Process Analysis

## Summary

Task 227 implemented a feedback system for ace-review with ~40 new files, ~3000 lines of production code, and comprehensive tests. Despite this substantial delivery, several gaps exist between the original specifications and what was landed. This retro identifies process improvements for `/ace:draft-task`, `/ace:plan-task`, `/ace:review-task`, and `ace-review --preset spec`.

## What Went Well

- **ATOM architecture adherence**: All new components follow the Atoms/Molecules/Organisms pattern correctly
- **Comprehensive test coverage**: 10+ test files covering all new components
- **File locking for concurrency**: Proper flock-based locking with retry/backoff for multi-agent access
- **CLI completeness**: All planned feedback commands implemented (list, show, verify, resolve, skip)
- **Workflow updates**: `review.wf.md` and `review-pr.wf.md` were updated (after being initially missed)
- **Good iteration**: Multiple review cycles caught and fixed issues (lock acquisition, deduplication, ID uniqueness)

## What Could Be Improved

### 1. Spec Internal Contradictions

The orchestrator spec (227.00) contained self-contradictory requirements:
- **Line 20**: "Replace the monolithic `synthesis-report.md` with a structured feedback file system"
- **Line 104**: "Synthesis preserved (feedback is additive, `--no-feedback` to disable)"

This created ambiguity that cascaded through implementation.

### 2. Naming Drift from Spec

| Spec Name | Implemented Name | Impact |
|-----------|------------------|--------|
| `FeedbackExtractor` | `FeedbackSynthesizer` | Semantic confusion - "extract" implies parsing, "synthesize" implies combining |
| 6-char ID | 10-char ID | Implementation changed for uniqueness but spec not updated |

### 3. Missing Interface Validation

The spec defined interface contracts (e.g., `extract_from_multiple(reports)` signature) but implementation diverged:
```ruby
# Spec defined:
def extract_from_multiple(reports)
  # reports: [{ content:, reviewer: }, ...]

# Implemented:
def synthesize(report_paths:, session_dir: nil, model: nil)
  # Takes file paths, not content hashes
```

### 4. Subtask Status Never Updated

All 8 subtasks remain in "pending" status despite being implemented and merged. The workflow doesn't include a step to mark subtasks done.

## Key Learnings

### On Spec Writing

1. **"Replace" means remove** - If spec says "replace X with Y", there should be NO config toggle for X. Add explicit statement: "The old approach is removed entirely. No backward compatibility."

2. **Interface contracts are commitments** - If spec defines `extract_from_multiple(reports)`, implementation must match or spec must be updated before implementation.

3. **Subtasks need completion tracking** - Add explicit "mark subtask done" step to work-on-subtasks workflow.

### On Review Presets

4. **`spec` preset misses contradictions** - Current prompts don't detect when Overview contradicts Design Decisions within the same document.

5. **`spec` preset doesn't validate interface contracts** - Method signatures in specs are treated as documentation, not testable contracts.

### On Task Workflow

6. **Orchestrator + subtask pattern needs discipline** - When orchestrator defines architecture, subtasks must reference it consistently. Changes to architecture during implementation must propagate back to orchestrator.

## Process Improvement Proposals

### For `/ace:draft-task`

1. **Add contradiction checker**: When drafting, scan for conflicting statements:
   - "Replace X" vs "Preserve X"
   - "Remove Y" vs "Add config for Y"
   - "Required" vs "Optional"

2. **Require explicit removal statements**: For any "replace" task, require explicit section:
   ```markdown
   ## What Gets Removed
   - [ ] Old code path: `report_synthesizer.rb`
   - [ ] Old config keys: `synthesis.enabled`
   - [ ] Old file outputs: `synthesis-report.md`
   ```

### For `/ace:plan-task`

3. **Consumer audit checklist**: Before marking plan complete:
   - [ ] List all workflows that reference changed outputs
   - [ ] List all configs that reference changed components
   - [ ] List all docs that describe changed behavior

4. **Interface contract formatting**: Use code blocks with "MUST MATCH" annotation:
   ```ruby
   # INTERFACE CONTRACT - Implementation MUST match
   def extract(report_content, reviewer:)
   ```

### For `/ace:review-task`

5. **Add contradiction detection rule**: Scan document for pattern pairs:
   - Overview section says "X" but Design Decisions says "not X"
   - Behavioral spec says "required" but Out of Scope lists it

6. **Add interface drift detection**: Compare code block signatures in spec against actual implementation signatures.

### For `ace-review --preset spec`

7. **New check: Self-consistency**: Add prompt that specifically looks for contradictions within a single spec file.

8. **New check: Completeness for "replace" tasks**: Require explicit removal section, no config toggles for replaced features.

9. **New check: Consumer coverage**: Verify that any output format changes have corresponding workflow updates listed.

### For `/ace:work-on-subtasks`

10. **Auto-update subtask status**: When committing subtask work, automatically mark the subtask done (or prompt to do so).

## Action Items

### Stop Doing

- Writing specs with "backward compatibility" hedges when intent is replacement
- Allowing interface contracts to drift without spec updates
- Leaving subtask status as "pending" after implementation

### Continue Doing

- ATOM architecture for all new components
- Comprehensive testing with mocked dependencies
- Multiple review cycles for complex features
- File locking for concurrent access scenarios

### Start Doing

- **Pre-implementation consistency check**: Before coding, verify Overview aligns with Design Decisions
- **Interface contract tests**: Write spec-derived interface tests before implementation
- **Subtask completion discipline**: Mark subtasks done immediately after commit
- **Removal manifest**: For "replace" tasks, explicit list of what gets removed

## Concrete Updates Needed

### 1. Update spec review prompt (`ace-review --preset spec`)

Add these checks to the spec review system prompt:
```markdown
## Self-Consistency Check
- Does the Overview align with Design Decisions?
- If Overview says "replace", verify no "preserve" in Design Decisions
- If something is "required", verify it's not also in "Out of Scope"

## Interface Contract Validation
- Identify method signatures in code blocks
- Flag if description says one thing but signature shows another

## Replacement Task Checklist
- If task says "replace X with Y", verify:
  - No config toggle for X exists
  - Explicit removal section lists what's deleted
  - All consumers of X are listed for update
```

### 2. Update `/ace:review-task` workflow

Add step before approval:
```markdown
## Pre-Approval Checklist
- [ ] Overview and Design Decisions are consistent
- [ ] Interface contracts have "MUST MATCH" annotations
- [ ] For replacement tasks: removal manifest is complete
- [ ] All consumers of changed outputs are listed
```

### 3. Update `/ace:work-on-subtasks` workflow

Add completion step:
```markdown
## After Each Subtask Commit
1. Run tests: `ace-test ace-{package}`
2. Update subtask status:
   ```bash
   ace-taskflow task done {subtask-id}
   ```
3. Push changes
```

## Technical Details

### Commits in PR #189 (33 commits)

- 8 feature commits implementing subtasks 01-08
- 14 fix commits addressing review feedback
- 6 release commits (v0.36.0 through v0.36.6)
- 5 other (chore, docs)

### Files Changed Summary

| Category | Count |
|----------|-------|
| New production files | ~15 |
| New test files | ~10 |
| Modified existing files | ~10 |
| New documentation | 3 |

### Spec vs Implementation Naming

| Spec Component | Implemented As | Notes |
|----------------|----------------|-------|
| FeedbackExtractor | FeedbackSynthesizer | Renamed to reflect actual behavior |
| 6-char ID (Base36) | 10-char ID | Changed for collision resistance |
| `extract_from_multiple` | `synthesize` | Interface changed significantly |
| FeedbackContextResolver | Added | Not in original spec |
| FeedbackStateValidator | Added | Not in original spec |

## Additional Context

- **PR**: #189 - feat(ace-review): Feedback-based review output architecture
- **Branch**: 227-feedback-based-review-output-architecture
- **Related Retro**: `8p2ozm-task-227-spec-contradiction.md` (specific contradiction analysis)
- **Related Retro**: `8nr000-review-pr-workflow-developer-feedback-handling.md` (earlier feedback handling learnings)
- **Spec Files**: `.ace-taskflow/v.0.9.0/tasks/227-feedback-review-arch/*.s.md`