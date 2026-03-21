## E2E Coverage Review: ace-git-commit

**Reviewed:** 2026-03-18
**Scope:** package-wide (`ace-git-commit`)
**Workflow:** `wfi://e2e/review`

### Summary

| Metric | Count |
|--------|-------|
| Package command implementations | 1 |
| Unit test files | 17 |
| E2E scenarios | 1 |
| E2E test cases | 6 |

### Feature Inventory

| Feature | Command | External Tools | Description |
|---------|---------|----------------|-------------|
| Commit all changes | `ace-git-commit` | `git` | Stages and commits all tracked changes |
| Commit specific paths | `ace-git-commit <paths...>` | `git` | Restricts staging to explicit files/paths/globs |
| Dry-run preview | `ace-git-commit -n` | `git` | Shows staged/commit intent without writing commit |
| Delete + rename handling | `ace-git-commit` | `git` | Commits delete/rename operations correctly |
| Auto-split by config scopes | `ace-git-commit <paths...>` | `git` | Creates per-scope commits when multiple config scopes are touched |
| No-split override | `ace-git-commit --no-split <paths...>` | `git` | Forces single commit even across scopes |
| Help/CLI discoverability | `ace-git-commit --help` | none | Documents interface, options, and usage |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Commit all changes/direct message | `test/organisms/commit_orchestrator_test.rb` | `TC-002` | Covered |
| Path-restricted staging | `test/organisms/commit_orchestrator_test.rb`, `test/molecules/path_resolver_test.rb` | `TC-003` | Covered |
| Dry-run behavior | `test/organisms/commit_orchestrator_test.rb` | `TC-003` | Covered |
| Delete + rename flow | partial (`git_executor*`, orchestrator integration mocks) | `TC-004` | E2E-weighted |
| Auto-split | `test/molecules/commit_grouper_test.rb`, `test/molecules/split_commit_executor_test.rb` | `TC-005` | Covered |
| No-split override | `test/models/commit_options_test.rb`, orchestrator tests | `TC-006` | Covered |
| Help/CLI docs | `test/commands/cli_routing_test.rb` | `TC-001` | Overlap |

### Overlap and Gaps

- `TC-001` (help survey) has low E2E value and overlaps with CLI routing/option tests; keep only if treated as lightweight smoke guard.
- `TC-002` to `TC-006` provide clear end-to-end value by exercising real git state transitions.
- Runner and verifier instructions contain coupling to Goal 1 discovery language ("using what you learned from Goal 1") that can be removed to reduce dependency and improve determinism.
- Verifier docs repeat numbered lists in a way that reduces clarity and consistency.

### Recommendations

1. Keep functional E2E coverage (`TC-002`..`TC-006`) and keep `TC-001` as minimal smoke/documentation guard.
2. Modify runner docs to eliminate cross-goal dependency on Goal 1 discovery.
3. Normalize verifier expectation formatting and tighten deterministic evidence checks.

### Next Step

Run `wfi://e2e/plan-changes` and classify test cases as KEEP/MODIFY/REMOVE/CONSOLIDATE/ADD.
