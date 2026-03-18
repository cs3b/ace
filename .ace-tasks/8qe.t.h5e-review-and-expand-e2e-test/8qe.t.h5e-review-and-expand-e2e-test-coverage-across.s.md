---
id: 8qe.t.h5e
status: in-progress
priority: medium
created_at: "2026-03-15 11:26:00"
estimate: TBD
dependencies: []
tags: [e2e, testing, coverage]
bundle:
  presets: [project]
needs_review: false
worktree:
  branch: h5e-review-and-expand-e2e-test-coverage-across-ace-packages
  path: ../ace-task.h5e
  created_at: "2026-03-18 22:28:21"
  updated_at: "2026-03-18 22:28:21"
  target_branch: main
---

# Review and expand E2E test coverage across ACE packages

## Behavioral Specification

### User Experience
- **Input**: An orchestrator coordinating 27 subtasks across two phases: managing existing E2E suites through the canonical review pipeline (19 packages) and creating initial value-gated E2E coverage (8 packages).
- **Process**: Phase 1 runs the canonical `review -> plan-changes -> rewrite` lifecycle for packages with existing E2E tests, preferably via `/as-e2e-manage`. Phase 2 uses `/as-e2e-create` to add 1-2 value-gated smoke scenarios per package where real CLI/filesystem/subprocess behavior justifies E2E coverage.
- **Output**: All 27 packages have E2E coverage decisions and package-scoped verification aligned with ACE E2E workflow standards.

### Expected Behavior

E2E tests across the monorepo have grown organically with inconsistent patterns, coverage gaps, and varying quality. This orchestrator systematically:

1. **Phase 1 (Manage existing suites)**: Run the canonical E2E lifecycle for each of 19 packages with existing E2E tests: produce a coverage matrix, classify KEEP/MODIFY/REMOVE/CONSOLIDATE/ADD decisions, then rewrite the suite to match the approved plan.
2. **Phase 2 (Create initial suites)**: Run `/as-e2e-create` on each of 8 packages with CLIs but no E2E tests. Create only value-gated smoke scenarios that require real CLI/filesystem/subprocess coverage, and document the unit-test evidence reviewed for each scenario.

This parent task coordinates:
- `h5e.0` through `h5e.i` — Phase 1: Review and improve existing E2E tests (19 subtasks)
- `h5e.j` through `h5e.q` — Phase 2: Create new E2E tests (8 subtasks)

### Success Criteria

- [ ] All 19 existing E2E suites complete the `review -> plan-changes -> rewrite` lifecycle with coverage matrices, classified decisions, and rewrite summaries
- [ ] All rewrite decisions for existing suites are documented and applied
- [ ] 8 packages without E2E coverage receive initial value-gated smoke scenarios, or an explicit unit-backed decision that no E2E scenario should be added for a candidate behavior
- [ ] Each subtask records its package-scoped verification outcome
- [ ] Consistent E2E decision records, scenario structure, and quality standards are applied across all subtasks

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator
- **Slice Outcome**: Comprehensive, consistent E2E test coverage across all ACE packages with CLIs
- **Advisory Size**: large
- **Context Dependencies**: 19 existing E2E suites, 8 packages needing initial E2E coverage, and the `/as-e2e-manage`, `/as-e2e/plan-changes`, `/as-e2e-rewrite`, and `/as-e2e-create` workflows

### Verification Plan

#### Integration / E2E Validation
- [ ] All Phase 1 subtasks complete with review outputs, change plans, and rewrite summaries
- [ ] All Phase 2 subtasks complete with value-gated smoke scenarios and E2E decision records
- [ ] Each subtask records its package-scoped verification outcome

#### Verification Commands
- [ ] Package-scoped verification commands are completed and recorded in each subtask
- [ ] Optional follow-up: `ace-test-suite`

## Objective

Systematically bring ACE package E2E coverage under the canonical workflow model, ensuring existing suites are reviewed and rewritten consistently while new suites are added only where E2E value is justified.

## Scope of Work

- **Phase 1**: Run the canonical E2E management lifecycle across 19 packages with existing E2E suites
- **Phase 2**: Create initial value-gated smoke scenarios for 8 packages with CLIs but no E2E coverage

### Subtask Summary

#### Phase 1: Review Existing E2E Tests

| Subtask | Package | Scenarios/TCs |
|---------|---------|---------------|
| h5e.0 | ace-git-worktree | 2 scenarios, 13 TCs |
| h5e.1 | ace-assign | 2 scenarios, 10 TCs |
| h5e.2 | ace-b36ts | 1 scenario, 8 TCs |
| h5e.3 | ace-lint | 1 scenario, 7 TCs |
| h5e.4 | ace-review | 1 scenario, 7 TCs |
| h5e.5 | ace-git-secrets | 1 scenario, 7 TCs |
| h5e.6 | ace-git-commit | 1 scenario, 6 TCs |
| h5e.7 | ace-bundle | 1 scenario, 6 TCs |
| h5e.8 | ace-overseer | 1 scenario, 5 TCs |
| h5e.9 | ace-support-nav | 1 scenario, 5 TCs |
| h5e.a | ace-test-runner | 2 scenarios, 5 TCs |
| h5e.b | ace-git | 1 scenario, 4 TCs |
| h5e.c | ace-sim | 1 scenario, 4 TCs |
| h5e.d | ace-docs | 1 scenario, 3 TCs |
| h5e.e | ace-idea | 1 scenario, 3 TCs |
| h5e.f | ace-search | 1 scenario, 3 TCs |
| h5e.g | ace-prompt-prep | 1 scenario, 3 TCs |
| h5e.h | ace-llm | 1 scenario, 2 TCs |
| h5e.i | ace-tmux | 1 scenario, 2 TCs |

#### Phase 2: Create New E2E Tests

| Subtask | Package | CLI(s) |
|---------|---------|--------|
| h5e.j | ace-task | ace-task (7 commands) |
| h5e.k | ace-retro | ace-retro (5 commands) |
| h5e.l | ace-demo | ace-demo (6 commands) |
| h5e.m | ace-support-models | ace-models, ace-llm-providers |
| h5e.n | ace-compressor | ace-compressor |
| h5e.o | ace-test-runner-e2e | ace-test-e2e |
| h5e.p | ace-handbook | ace-handbook |
| h5e.q | ace-llm-providers-cli | ace-llm-providers-cli-check |

### Excluded

- `ace-support-core` — gemspec declares `executables = []`

## Out of Scope

- ❌ Changing CLI command behavior (E2E tests verify existing behavior)
- ❌ Blanket per-command happy-path coverage when unit tests already cover the behavior sufficiently
- ❌ Unit test or molecule test improvements (E2E scope only)

## References

- `/as-e2e-manage` — Canonical E2E lifecycle orchestrator for existing suites
- `/as-e2e-review` — Deep E2E test review workflow
- `/as-e2e-plan-changes` — E2E change planning workflow
- `/as-e2e-rewrite` — E2E rewrite workflow
- `/as-e2e-create` — New E2E test creation workflow
