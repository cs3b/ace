---
title: "Refactor Test Suites: Isolate Minitest Units and Migrate Integration to E2E"
filename_suggestion: refactor-test-minitest-e2e-split
enhanced_at: 2026-01-19 22:59:41
location: backlog
blocked_by: v.0.9.0+task.272
notes: |
  Deferred until after specflow rename (271+272) lands. Those tasks touch test files across the repo.
  Better as a policy/guide than a sweeping refactor — enforce boundary going forward, migrate packages opportunistically.
llm_model: gflash
---

# Refactor Test Suites: Isolate Minitest Units and Migrate Integration to E2E

## Problem
As the ACE project matures and introduces the `ace-test-e2e-runner`, the existing Minitest suites across various `ace-*` gems likely contain integration tests that perform heavy I/O (filesystem, Git, LLM calls). This violates the principle of fast, isolated unit testing, leading to slow test execution times and brittle tests. We need to enforce strict separation to maintain developer velocity and ensure test determinism.

## Solution
Implement a project-wide test refactoring initiative to strictly separate unit tests from integration/E2E tests. The goal is to ensure Minitest suites are pure (no IO side effects) and achieve a maximum runtime of 5-10 minutes per package. All integration tests that touch the filesystem, use `ace-llm`, or interact with Git must be migrated or rewritten as E2E scenarios using the `ace-test-e2e-runner` framework.

## Implementation Approach

1.  **Audit by ATOM Layer:** Review existing tests in each gem, guided by the ATOM pattern:
    *   **Atoms/Models:** Must remain in Minitest, ensuring 100% mocking of external dependencies.
    *   **Molecules/Organisms/Commands:** If these layers involve real I/O (file creation, Git commands, LLM API calls), the tests covering these paths must be migrated to E2E scenarios.
2.  **Minitest Isolation:** Refine remaining Minitest tests to use `ace-test-support` helpers for mocking `ace-git` and `ace-llm` interactions. Ensure configuration loading is isolated using `reset_config!` to prevent cross-test contamination.
3.  **E2E Scenario Creation:** Create new E2E test scenarios (`.mt.md` files) in the `ace-test-e2e-runner` structure for complex workflows (e.g., testing the full `ace-git-commit` generation process or `ace-review` analysis). These scenarios validate the composition of CLI tools, which is the primary purpose of the E2E runner.
4.  **Performance Tracking:** Integrate test timing into the CI/CD pipeline to monitor Minitest runtime and enforce the 5-10 minute limit per package.

## Considerations
- **Configuration Cascade:** Ensure tests that rely on configuration (via `ace-support-config`) are mocked or use temporary, isolated configuration files to avoid relying on the global project/user `.ace/` settings.
- **Agent Integration:** The E2E tests must validate the output format of CLI tools to ensure they remain deterministic and parseable for autonomous agent execution.
- **Git Worktree Isolation:** E2E tests involving Git must utilize temporary directories or worktrees to guarantee isolation and cleanup.

## Benefits
- **Improved Developer Experience:** Significantly faster unit test execution provides immediate feedback during development.
- **Clear Test Boundaries:** Enforces the ATOM architecture by clearly defining where unit logic ends and integration logic begins.
- **Robust Agent Validation:** Dedicated E2E tests provide higher confidence that complex, multi-step agent workflows (like those defined in `handbook/workflow-instructions/*.wf.md`) function correctly in a real environment.

---

## Original Idea

```
refactor all the tests, as we have now e2e tests, we should try to move some tests from regular minitest to our new approach, or just create new ones. And review all the tests in the minitest, that it should be tests that doesn't touch the IO (network / filesystem / git / etc ). We should have limit 5 minutes, maybe 10 minutes per package test suite - just for now, maybe later we will optimize it. So it should improve the speed of minitest runtime, and also benefit full e2e testing with good balance

1. Package Rename: ace-prompt → ace-prep (Task 217.01)
Gem rename: ace-prompt/ → ace-prep/
Module namespace: Ace::Prompt → Ace::Prep
CLI binary: ace-prompt → ace-prep
Config directory: .ace/prompt/ → .ace/prep/
Cache directory: .cache/ace-prompt/ → .cache/ace-prep/
Updated all references: 19 Ruby lib files, 22 test files, documentation, configs
2. Package Rename: ace-prep → ace-prompt-prep (Task 218)
Gem rename: ace-prep → ace-prompt-prep
Module namespace: Ace::Prep → Ace::PromptPrep
CLI binary: ace-prep → ace-prompt-prep
Config directory: .ace/prep/ → .ace/prompt-prep/
Cache directory: .cache/ace-prep/ → .cache/ace-prompt-prep/
Follows compound naming: Like ace-git-commit, ace-git-secrets
```

## Attached Files

- [clipboard-content.html](./clipboard-content.html)