---
title: E2E Test Granularity and Parallelization Optimization
filename_suggestion: feat-test-e2e-granularity
enhanced_at: 2026-02-11 22:20:15.000000000 +00:00
llm_model: gflash
id: 8paxi8
status: done
tags: []
created_at: '2026-02-11 22:20:14'
---

# E2E Test Granularity and Parallelization Optimization

## Problem
Existing E2E test suites in the ACE ecosystem, particularly those involving complex LLM interactions, are currently monolithic and take 13-18 minutes to complete. This creates a slow feedback loop for developers and inefficient CI resource utilization. Multi-phase test cases (e.g., 003c) are coupled, meaning a failure in Phase 1 prevents execution of Phase 2, even if they are logically distinct.

## Solution
Implement a granularity optimization strategy for the `ace-test-runner` and `ace-test-e2e` gems. This involves decomposing long-running test suites into atomic, independent scenarios with a target execution time of 5-6 minutes. We will leverage the recently implemented per-TC (Test Case) infrastructure to facilitate physical separation and parallel execution.

## Implementation Approach
- **Refactor TCs:** Split multi-phase test files into distinct `.tc.md` files (e.g., `003c-phase1.tc.md` and `003c-phase2.tc.md`).
- **Atoms/Molecules:** Develop a `ScenarioLoader` molecule in `ace-test-runner` that can identify and isolate independent test units based on metadata tags.
- **Orchestration:** Enhance the `TestOrchestrator` organism to support a `--parallel` flag, utilizing Ruby's concurrency features to execute independent TCs simultaneously.
- **State Management:** Implement a shared context mechanism in `ace-test-support` for scenarios that require a specific prerequisite state without re-running full setup phases.

## Considerations
- Integration with `ace-llm` to ensure parallel API calls respect rate limits and provider quotas.
- Configuration cascade: Allow project-level `.ace/test/runner.yml` to define parallel worker counts.
- CLI Output: Ensure `ace-test-runner` provides deterministic, aggregated output when running parallel scenarios to maintain inspectability.

## Benefits
- Reduces CI pipeline duration by up to 60% through parallelization.
- Faster developer feedback loops during local development.
- Improved debugging by isolating failures to smaller, atomic test units.

---

## Research Findings (2026-02-11)

### Investigation: Slow E2E Test Suites

Investigation of ace-coworker E2E tests revealed the root cause of slow execution times:

| Test Suite | Duration | TC Files | Phases | Avg per Phase |
|------------|----------|----------|--------|---------------|
| 003b-injection-renumbering | 18m 11s | 3 | ~9 | ~2 min |
| 003c-auto-completion | 16m 11s | 1 | 2 | ~8 min |
| 003d-display-audit | 13m 35s | 2 | 2 | ~7 min |

### Root Cause Analysis

**Why E2E Tests Are Slow:**

1. **LLM Invocation Overhead** (~80% of time)
   - Each test case requires a full LLM API call (claude:sonnet)
   - Context loading: ~30-60 seconds
   - Reasoning/execution: ~2-5 minutes per TC
   - Token generation for reports: ~30-60 seconds

2. **Sequential Execution**
   - Test cases run one after another
   - No caching between runs

3. **Complex Test Steps**
   - ace-coworker tests involve session creation, job manipulation, state verification
   - Each `ace-coworker` command is a full CLI invocation

### Time Per Test Case Breakdown

| Component | Estimated Time |
|-----------|----------------|
| LLM context loading | 30-60s |
| Bash command execution | 5-15s |
| State verification | 10-30s |
| Report generation | 30-60s |
| **Total per TC** | **2-5 minutes** |

### Specific Suite Analysis

**TS-COWORKER-003c (16m 11s, 2/2 cases)**
- 1 TC file with **2 explicit phases**
- Phase 1: Single-Level Auto-Completion (5 steps) ~7 min
- Phase 2: Multi-Level Auto-Completion (3 steps) ~7 min
- Each phase could be an independent test scenario

**TS-COWORKER-003b (18m 11s, "9/9 cases")**
- 3 TC files with multiple verification steps each
- TC-001-child-injection: 2 phases
- TC-002-sibling-injection: 2 phases
- TC-003-cascade-renumbering: 2 phases
- Could be split into 6 independent scenarios

**TS-COWORKER-003d (13m 35s, 2/2 cases)**
- 2 TC files, already reasonably sized
- Could remain as-is or be further optimized

### Recommended Splits

**003c → 2 scenarios:**
- `TS-COWORKER-003c1-single-level-auto-completion`
- `TS-COWORKER-003c2-multi-level-auto-completion`

**003b → 6 scenarios:**
- `TS-COWORKER-003b1-child-injection`
- `TS-COWORKER-003b2-sibling-injection`
- `TS-COWORKER-003b3-cascade-renumbering`
- (or further split verification phases)

### Architecture Context

The E2E test architecture involves:
1. `TestOrchestrator` discovers and schedules tests
2. `TestExecutor` invokes LLM provider via `ace-llm`
3. Skill `/ace:run-e2e-test` executes in sandbox
4. Agent writes reports to `.cache/ace-test-e2e/`

Each LLM call is the bottleneck. Splitting scenarios allows:
- Parallel execution across multiple LLM calls
- Faster failure isolation
- Better CI resource utilization

---

## Original Idea

```
E2E Test Granularity Optimization: Split slow test suites (13-18min) into smaller independent scenarios. Target: 5-6 min per scenario. Strategy: 1) Split multi-phase TCs into separate test suites (e.g., 003c Phase 1/2 become separate scenarios), 2) Create atomic test cases that can run independently, 3) Enable parallel execution of independent scenarios. Benefits: Faster feedback, easier debugging, better CI resource utilization.
```