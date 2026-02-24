# Essential E2E Test Suite Plan

## Current Coverage

13 scenarios across 11 packages, ~82 TCs. All use TS-format with standalone runner/verifier pairs.

| Package | Scenarios | Status |
|---------|-----------|--------|
| ace-assign | 2 (ASSIGN-001, ASSIGN-002) | Active |
| ace-b36ts | 1 (B36TS-001) | Active |
| ace-bundle | 1 (BUNDLE-001) | Active |
| ace-git-commit | 1 (COMMIT-001) | Active |
| ace-git-secrets | 1 (SECRETS-001) | Active |
| ace-git-worktree | 2 (WORKTREE-001, WORKTREE-002) | Active |
| ace-lint | 1 (LINT-001) | Active |
| ace-overseer | 1 (OVERSEER-001) | Active |
| ace-prompt-prep | 1 (PREP-001) | Active |
| ace-review | 1 (REVIEW-001) | Active |
| ace-support-nav | 1 (NAV-001) | Active |

---

## P1 — High Value

### ace-taskflow

Most complex CLI tool (30+ commands across 5 binaries: `ace-task`, `ace-idea`, `ace-backlog`, `ace-retro`, `ace-assign-prep`). Multi-command workflows with filesystem state (`.ace-taskflow/` dirs), inter-command dependencies, and YAML frontmatter parsing.

**TS-TASK-001-task-lifecycle** (smoke)
- TC-001: Create task with `ace-task create --title "..." --status draft`; verify `.ace-taskflow/tasks/` file created with correct frontmatter
- TC-002: Start task with `ace-task start {id}`; verify status changes to `in-progress`
- TC-003: Complete task with `ace-task done {id}`; verify status changes to `done`
- TC-004: List tasks with `ace-task list`; verify output includes created task with correct status
- Tags: `[smoke, "use-case:taskflow"]`
- E2E justification: Multi-step filesystem workflow with inter-command state dependencies

**TS-TASK-002-task-queries** (happy-path)
- TC-001: Show task details with `ace-task show {id}`; verify full frontmatter and body output
- TC-002: Filter tasks with `ace-task list --status draft`; verify only matching tasks shown
- TC-003: Task status summary with `ace-task status`; verify count output
- Tags: `[happy-path, "use-case:taskflow"]`
- E2E justification: Real filesystem traversal, YAML parsing, and CLI output formatting

**TS-IDEA-001-idea-lifecycle** (happy-path)
- TC-001: Capture idea with `ace-idea capture`; verify `.ace-taskflow/ideas/` file created
- TC-002: List ideas with `ace-idea list`; verify captured idea appears
- TC-003: Prioritize idea with `ace-idea prioritize`; verify priority field updated
- Tags: `[happy-path, "use-case:taskflow"]`
- E2E justification: Real filesystem state management, separate binary from ace-task

### ace-test-runner

Tests the test infrastructure itself. Real test discovery, subprocess execution, exit code propagation.

**TS-TEST-001-test-execution** (smoke)
- TC-001: Run tests for a package with `ace-test {package}`; verify exit code 0 and test count output
- TC-002: Run tests for a specific file with `ace-test {file}`; verify only that file's tests run
- TC-003: Run tests for a group with `ace-test atoms`; verify only atom-layer tests execute
- Tags: `[smoke, "use-case:testing"]`
- E2E justification: Real subprocess execution, test discovery across filesystem, exit code propagation

**TS-TEST-002-suite-execution** (deep)
- TC-001: Run suite with `ace-test-suite`; verify cross-package execution and aggregate report
- TC-002: Verify exit code reflects failures (intentionally fail one package, check non-zero exit)
- Tags: `[deep, "use-case:testing"]`
- E2E justification: Cross-package coordination, aggregated subprocess management

---

## P2 — Medium Value

### ace-search

Unified search tool with real ripgrep integration and filesystem traversal.

**TS-SEARCH-001-search-workflow** (smoke)
- TC-001: Content search with `ace-search "pattern"`; verify ripgrep output with matched lines
- TC-002: File search with `ace-search --files "*.rb"`; verify file list output
- TC-003: Search with output mode with `ace-search --mode count "pattern"`; verify count format
- Tags: `[smoke, "use-case:search"]`
- E2E justification: Real ripgrep subprocess, filesystem traversal, auto-detection of search mode

### ace-git

Git operations toolkit with real git state inspection.

**TS-GIT-001-git-operations** (smoke)
- TC-001: Git status with `ace-git status`; verify output matches actual working tree state
- TC-002: Git diff with `ace-git diff`; verify diff output for known staged changes
- TC-003: Git branch info with `ace-git branch`; verify current branch display
- TC-004: Git log summary with `ace-git log`; verify recent commit output format
- Tags: `[smoke, "use-case:git"]`
- E2E justification: Real git state inspection, branch operations, subprocess execution

### ace-docs

Document management with real filesystem doc discovery and YAML validation.

**TS-DOCS-001-docs-operations** (smoke)
- TC-001: Discover docs with `ace-docs discover`; verify document listing output
- TC-002: Validate docs with `ace-docs validate`; verify YAML frontmatter validation results
- TC-003: Status check with `ace-docs status`; verify coverage summary output
- Tags: `[smoke, "use-case:docs"]`
- E2E justification: Real filesystem doc discovery, YAML frontmatter parsing, cross-file validation

---

## P3 — Lower Value (defer)

### ace-llm

LLM query tool — expensive real API calls required.

**TS-LLM-001-llm-query** (deep)
- TC-001: Query with `ace-llm query "simple prompt"`; verify response received and formatted
- TC-002: Query with model selection `ace-llm query --model haiku "prompt"`; verify model used
- Tags: `[deep, "use-case:llm"]`
- E2E justification: Real API calls, provider routing, response formatting

### ace-tmux

Tmux management — requires tmux environment.

**TS-TMUX-001-tmux-management** (deep)
- TC-001: List sessions with `ace-tmux list`; verify session listing
- TC-002: Create session with `ace-tmux create --name test`; verify session created
- Tags: `[deep, "use-case:tmux"]`
- E2E justification: Real tmux subprocess, session state management

---

## Packages Skipping E2E (with rationale)

| Package | Rationale |
|---------|-----------|
| ace-support-* (7 packages) | Library code, no user-facing CLI workflows |
| ace-handbook | Documentation package, not executable |
| ace-integration-claude | Thin integration layer, unit tests sufficient |
| ace-test | Test documentation gem (not the runner) |
| ace-test-runner-e2e | The E2E framework itself (self-referential) |
| ace-llm-providers-cli | Health check utility, unit tests sufficient |

---

## Summary

| Priority | Package | Scenarios | Est. TCs | Cost-Tier |
|----------|---------|-----------|----------|-----------|
| P1 | ace-taskflow | 3 | 10-11 | smoke / happy-path |
| P1 | ace-test-runner | 2 | 5 | smoke / deep |
| P2 | ace-search | 1 | 3 | smoke |
| P2 | ace-git | 1 | 4 | smoke |
| P2 | ace-docs | 1 | 3 | smoke |
| P3 | ace-llm | 1 | 2 | deep |
| P3 | ace-tmux | 1 | 2 | deep |
| **Total** | | **10** | **29-30** | |

This brings coverage from 13 → 23 scenarios, ~82 → ~112 TCs, across 18 of 35 packages.

## Implementation Approach

Each priority tier becomes a separate follow-up task:
- **P1 task**: Create ace-taskflow and ace-test-runner scenarios (highest value, unblocks confidence in core tools)
- **P2 task**: Create ace-search, ace-git, ace-docs scenarios (medium value, broadens coverage)
- **P3 task**: Create ace-llm, ace-tmux scenarios (deferred, expensive/environment-dependent)

Actual TC file creation follows the `/ace-e2e-create` workflow with full Value Gate checks.
