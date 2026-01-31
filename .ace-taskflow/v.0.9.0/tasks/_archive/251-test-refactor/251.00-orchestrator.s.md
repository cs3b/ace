---
id: v.0.9.0+task.251
status: done
priority: high
estimate: 14h
worktree:
  branch: 251-optimize-slow-test-suites-move-integration-tests-to-e2e
  path: "../ace-task.251"
  created_at: '2026-01-30 23:53:06'
  updated_at: '2026-01-30 23:53:06'
  target_branch: main
---

# Optimize Slow Test Suites: Move Integration Tests to E2E

## Overview

Move slow integration tests from individual packages to the centralized E2E test suite for improved performance and maintainability. This consolidates test infrastructure and reduces redundant setup across packages.

## Subtasks

- **02** (2h): Move ace-support-timestamp CLI Integration Tests to E2E
- **03** (3h): Move ace-lint CLI Integration Tests to E2E
- **04** (3h): Move ace-git-secrets Integration Tests to E2E
- **05** (2h): Move ace-bundle Section Workflow Integration Tests to E2E
- **06** (4h): Move ace-review Integration Tests to E2E (Complex Refactoring)

## Implementation Phases

1. **Phase 1**: CLI-focused packages (251.02, 251.03) - Simpler test patterns
2. **Phase 2**: Git-integration packages (251.04) - Requires fixture management
3. **Phase 3**: Complex workflows (251.05, 251.06) - Multi-package dependencies

## Cross-Package Acceptance Criteria

- All integration tests moved to `ace-test-suite/` E2E directory
- Test coverage maintained at 100% for affected packages
- CI pipeline execution time reduced by expected 15-20%
- Individual package test suites run faster without integration overhead
- Documentation updated to reflect new test structure