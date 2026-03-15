---
id: 8qe.t.h5e
status: draft
priority: medium
created_at: "2026-03-15 11:26:00"
estimate: TBD
dependencies: []
tags: [e2e, testing, coverage]
bundle:
  presets: [project]
---

# Review and expand E2E test coverage across ACE packages

## Behavioral Specification

### User Experience
- **Input**: An orchestrator coordinating 27 subtasks across two phases: reviewing existing E2E tests (19 packages) and creating new E2E tests (8 packages).
- **Process**: Phase 1 reviews and improves existing E2E test suites using `/as-e2e-review`, then applies improvements. Phase 2 creates new E2E tests for packages that have CLIs but no E2E coverage using `/as-e2e-create`.
- **Output**: All 27 packages have comprehensive, verified E2E test coverage with consistent quality standards.

### Expected Behavior

E2E tests across the monorepo have grown organically with inconsistent patterns, coverage gaps, and varying quality. This orchestrator systematically:

1. **Phase 1 (Review)**: Run `/as-e2e-review` on each of 19 packages with existing E2E tests, producing coverage matrices. Apply recommended improvements. Verify tests pass.
2. **Phase 2 (Create)**: Run `/as-e2e-create` on each of 8 packages with CLIs but no E2E tests. Create supplementary happy-path scenarios. Verify tests pass.

This parent task coordinates:
- `h5e.0` through `h5e.i` — Phase 1: Review and improve existing E2E tests (19 subtasks)
- `h5e.j` through `h5e.q` — Phase 2: Create new E2E tests (8 subtasks)

### Success Criteria

- [ ] All 19 existing E2E test suites reviewed with coverage matrices produced
- [ ] Improvements from reviews applied and verified
- [ ] 8 new E2E test suites created for packages with CLIs but no coverage
- [ ] All E2E tests pass across the monorepo
- [ ] Consistent test patterns and quality standards applied

### Vertical Slice Decomposition (Task/Subtask Model)

- **Slice Type**: Orchestrator
- **Slice Outcome**: Comprehensive, consistent E2E test coverage across all ACE packages with CLIs
- **Advisory Size**: large
- **Context Dependencies**: 19 existing E2E test suites, 8 packages needing new E2E coverage, `/as-e2e-review` and `/as-e2e-create` workflows

### Verification Plan

#### Integration / E2E Validation
- [ ] All Phase 1 subtasks complete with coverage matrices and applied improvements
- [ ] All Phase 2 subtasks complete with new E2E test scenarios
- [ ] `ace-test-suite` passes with all E2E improvements in place

#### Verification Commands
- [ ] `ace-test-suite`

## Objective

Systematically review and expand E2E test coverage across all ACE packages, ensuring consistent quality, comprehensive coverage, and passing test suites.

## Scope of Work

- **Phase 1**: Review and improve existing E2E tests across 19 packages
- **Phase 2**: Create new E2E tests for 8 packages with CLIs but no E2E coverage

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
- ❌ Implementation — this task drafts specs only, execution is per-subtask
- ❌ Unit test or molecule test improvements (E2E scope only)

## References

- `/as-e2e-review` — Deep E2E test review workflow
- `/as-e2e-create` — New E2E test creation workflow
