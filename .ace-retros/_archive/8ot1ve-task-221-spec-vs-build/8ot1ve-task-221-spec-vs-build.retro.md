---
id: 8ot1ve
title: Task 221 - Spec vs Build Analysis
type: self-review
tags: []
created_at: '2026-01-30 01:14:52'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8ot1ve-task-221-spec-vs-build.md"
---

# Reflection: Task 221 - Spec vs Build Analysis

**Date**: 2026-01-30
**Context**: Analyzing PR #182 implementation against Task 221.01 specification to identify patterns for improving ace-coworker's first-draft quality
**Author**: ace-coworker
**Type**: Self-Review | Process Analysis

## Executive Summary

Task 221 demonstrates a common pattern: a well-intentioned spec that underestimated the natural implementation cascade. The 4-hour estimate became 3 subtasks with 40+ commits. This retrospective examines what was unpredictable vs what simulation could have revealed.

---

## The Drift: Planned vs Actual

### Original Specification (221.01)

| Aspect | 221.01 Stated | Reality |
|--------|---------------|---------|
| Estimate | 4 hours | 3 subtasks, 40+ commits |
| Scope | Templates + workflow updates | + Directory refactor + Parallel execution |
| Code Changes | Explicitly "Out of Scope" | sandbox.rb, report_writer.rb created |
| Test Migration | "Leave for future" | All 6 packages updated immediately |
| Report Location | Inside sandbox | Moved OUTSIDE sandbox (221.02) |

### How Tasks Emerged

```
221.01 (Planned: 4h)    →  221.02 (Emerged)         →  221.03 (Emerged)
Templates & Workflow       Directory Refactor          Parallel Execution
                           + Ruby implementation       + Subagent orchestration
                           + 6 packages updated        + Suite aggregation
```

### The Critical Contradiction

- **221.01 Spec**: "Out of Scope: Implementation Details, file structures, code organization"
- **221.02 Reality**: ENTIRELY about implementation details and file structures
- **Insight**: The spec didn't anticipate the natural implementation flow

---

## What Went Well

- **Subtask creation when scope expanded**: Rather than bloating 221.01, new tasks (221.02, 221.03) were properly spun off
- **Test migration done immediately**: The "leave for future" items were correctly identified as dependencies during implementation
- **Parallel execution opportunity discovered**: The aggregation need revealed a valuable enhancement opportunity
- **Short naming convention adoption**: Directory structure was standardized across all 6 packages

## What Could Be Improved

- **"Out of Scope" items weren't truly independent**: The spec claimed code organization was out of scope, but it was the critical path
- **Test migration dependency underestimated**: Changing directory structure = ALL tests must update (this is predictable)
- **Scale progression not considered**: Single test → Suite → Aggregation is a natural usage pattern that affects architecture

---

## Key Learnings

### 1. Unpredictable (Legitimate Discoveries)

These emerged during implementation and couldn't reasonably be anticipated:

- **Suite aggregation requirement**: Reports need to persist outside ephemeral sandboxes for suite-level analysis
- **Parallel execution opportunity**: Once aggregation was understood, parallelization became obviously beneficial
- **Experience report integration**: The specific format and location emerged from implementation needs

### 2. Could Have Anticipated (Simulation Would Reveal)

A "dry run" mental simulation would have caught these:

- **Directory structure conflict**: "If reports need aggregation across test runs, can they live in ephemeral sandboxes?" → No
- **Test migration cascade**: "If we change the artifact directory structure, what tests break?" → All 6 packages
- **Usage progression**: "How will this be used at scale?" → Single test → Suite → Aggregation is predictable
- **Consumer identification**: "Who consumes these reports?" → Should have identified the suite runner upfront

### 3. The "Leave for Future" Trap

Items marked "leave for future" often hide critical dependencies:

| Marked as Future | Actually Required Because |
|------------------|---------------------------|
| Test migration | Directory structure changed - tests can't run |
| Report location | Suite runner needs to aggregate across sandboxes |
| Implementation details | You can't deliver the feature without them |

---

## UX Simulation: A Concrete Example

The most actionable improvement from this retrospective is adding an **"Expected User Experience"** section to task specs. Here's what it would have looked like for Task 221:

### What Should Have Been in the Spec

```markdown
## Expected User Experience

### Single Test Run

When I run: `ace-e2e-test run test/e2e/scenarios/001-basic-test.md`

I expect to see:
```
.artifacts/e2e/
├── 001-basic-test/
│   ├── sandbox/           # Ephemeral, cleaned after
│   ├── reports/
│   │   ├── execution.md   # What happened
│   │   └── experience.md  # Agent observations
│   └── summary.json       # Machine-readable
```

### Suite Run

When I run: `ace-e2e-test suite`

I expect to see:
```
.artifacts/e2e/
├── suite-2026-01-30-1430/
│   ├── 001-basic-test/
│   │   └── reports/...
│   ├── 002-error-handling/
│   │   └── reports/...
│   └── suite-summary.md   # Aggregated across all tests
```
```

### What This Simulation Reveals

Walking through this expected output immediately surfaces the architectural conflict:

| Question | Simulation Answer | Implication |
|----------|-------------------|-------------|
| Where do reports live? | Inside test run folder | Must persist after sandbox cleanup |
| Can suite aggregate? | Only if reports survive | Reports CANNOT be inside ephemeral sandbox |
| What's the cleanup boundary? | Sandbox only | Reports must be OUTSIDE sandbox |

**Time to discover via simulation**: ~5 minutes
**Time to discover via implementation**: 2 subtasks, 20+ commits

### Why This Works

1. **Fast validation**: Minutes instead of hours
2. **Surfaces architecture conflicts early**: The "reports in sandbox" assumption fails visibly
3. **Makes implicit assumptions explicit**: "Sandbox is ephemeral" + "Need aggregation" = contradiction
4. **Provides acceptance criteria**: The file tree IS the spec

### Template Addition

Add to task template:

```markdown
## Expected User Experience

### Primary Use Case
When I run: `[command]`
I expect to see:
```
[expected file tree or output]
```

### Scale Use Case
When I run: `[command at scale]`
I expect to see:
```
[expected aggregated output]
```

### Questions This Should Answer
- Where does output live?
- What persists vs what's ephemeral?
- How does aggregation work?
```

---

## Process Improvements

### Task Drafting Enhancements

Add these sections to task specifications:

1. **Usage Scenario Walkthrough**
   - Single execution case
   - Batch/suite execution case
   - Aggregation/reporting case
   - "What happens at 10x, 100x scale?"

2. **Ripple Effect Analysis**
   - "What existing code touches this area?"
   - "If X changes, what else breaks?"
   - "What are all consumers of this deliverable?"

3. **Pre-flight Simulation**
   - Walk through implementation mentally before scoping
   - Identify hidden dependencies
   - Question "Out of Scope" items critically

### Planning Phase Improvements

- **Challenge "leave for future" items**: Ask "Is this truly independent, or just convenient to defer?"
- **Run dry simulations**: Before writing code, walk through the implementation path
- **Identify all consumers**: Who/what will use this deliverable? At what scale?

### Review Phase Improvements

- **Challenge "Out of Scope" items**: Are they truly out of scope, or just uncomfortable to estimate?
- **Validate E2E expectations**: Test the spec against realistic usage patterns
- **Check for cascade effects**: Does the proposed change trigger updates elsewhere?

---

## ace-coworker Implications

These findings suggest enhancements to ace-coworker's workflow:

### 1. Pre-flight Simulation Step

Add to job execution before coding begins:
- Mental walkthrough of implementation path
- "What files will this touch?"
- "What breaks if X changes?"

### 2. Usage Scenario Generation

During planning phase:
- Generate 3 usage scenarios (single, batch, aggregate)
- Ask "Does the architecture support all three?"

### 3. Ripple Effect Detection

During spec review:
- Identify files that consume the deliverable
- Flag potential cascade updates
- Question items marked "out of scope" or "future"

### 4. Dependency Honesty

When something is marked "leave for future":
- Verify it's truly independent
- Flag if the main deliverable depends on it
- Adjust estimates if dependencies exist

---

## Action Items

### Stop Doing

- Marking implementation details "out of scope" when they're on the critical path
- Deferring test updates when they're direct dependencies
- Scoping without considering scale progression

### Continue Doing

- Creating subtasks when scope legitimately expands
- Standardizing patterns across packages (like SHORT naming)
- Documenting decisions in task specs

### Start Doing

- Add "Usage Scenario Walkthrough" to task templates
- Add "Ripple Effect Analysis" to task templates
- Run pre-flight simulations before finalizing estimates
- Question every "Out of Scope" and "Leave for Future" item

---

## Technical Details

### Files Created/Modified in 221 (Evidence of Scope Expansion)

```
221.01 (Expected: templates only)
  → Actually created: sandbox.rb, report_writer.rb

221.02 (Emerged: directory refactor)
  → Updated: 6 package test directories
  → Created: SHORT naming convention

221.03 (Emerged: parallel execution)
  → Subagent orchestration
  → Suite report aggregation
```

### The Architecture Insight

```
Original Assumption:
  test_run → sandbox/reports/ → done

Actual Requirement:
  test_run → sandbox/reports/ → aggregate → suite_report
                                    ↑
                          Reports must persist OUTSIDE sandbox
```

---

## Additional Context

- **PR**: #182
- **Task Spec**: `.ace-taskflow/v.0.9.0/tasks/221-add-report-persistence-and-agent-experience-reports-to-e2e-runner/`
- **Subtasks**: 221.01, 221.02, 221.03
- **Related**: E2E test runner, ace-coworker job execution