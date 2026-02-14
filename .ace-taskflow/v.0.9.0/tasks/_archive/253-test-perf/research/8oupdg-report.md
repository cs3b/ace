# Research Report: Fast/Slow Loop Test Strategy, Mocking Discipline, E2E Coverage

Date: 2026-01-31
Context: PR 187 / task 251-252 test performance optimization and E2E migration
Author: Codex (automated research synthesis)

## Scope
This report consolidates:
1) Internal repo evidence from task docs and retros (task 251, 252) about test performance optimizations.
2) External research on test pyramid sizing, hermetic test definitions, risk-based coverage, and contract testing.

## Internal Findings (Repo Evidence)

### A) Integration -> E2E migrations (task 251)
Multiple packages moved real-IO integration tests to E2E `.mt.md` files to preserve coverage while keeping fast loops hermetic:
- ace-support-timestamp: CLI integration moved to MT-TIMESTAMP-004.
- ace-lint: CLI + doctor integration moved to MT-LINT-004/005.
- ace-git-secrets: full workflow + rewrite + config cascade moved to MT-SECRETS-001/002/003.
- ace-bundle: section workflow moved to MT-BUNDLE-001.
- ace-review: preset composition, multi-subject, and auto-save flows moved to MT-REVIEW-001/002/003.

Pattern: remove `test/integration/*.rb` that spawn subprocesses, replace with E2E that explicitly declares requirements (CLI tools, git, gitleaks, etc.). Fast loop retains unit tests with IO stubs.

### B) Outer-boundary stubbing for subprocess and IO
Retros explicitly call out that stubbing inner calls is insufficient when a guard method triggers subprocesses (eg. `available?` calling `system`). Fix pattern: stub the highest boundary (eg. `available?`) and only then stub inner `Open3.capture3` calls.

### C) Cache-driven flakiness and random slowness
Random slow tests were caused by shared caches being reset or invalidated across test interleaving. Fix pattern: pre-warm caches in test helper, avoid global resets in `setup`, and ensure stub helpers reset then repopulate caches before yielding.

### D) Targeted stubbing (task 252)
`ace-review/test/molecules/context_extractor_test.rb` was slowed by real `Ace::Bundle.load_auto` calls. Stubbing the call reduced runtime from seconds to tens of milliseconds, with coverage preserved. This is a strong example of verifying behavior without real IO while maintaining E2E coverage for true integration.

### E) Test runner improvements
`ace-test-runner` introduced slowest-first scheduling, new run modes, and updates to `.ace/test/runner.yml` and `.ace/test/suite.yml` to keep the suite fast and deterministic. This provides a framework for periodic performance audits.

## External Research Summary (Key Points)

### 1) Test Pyramid and Sizing Guidance
- The test pyramid model emphasizes many fast unit tests, fewer integration tests, and the smallest number of E2E tests.
- Google testing guidance defines small (hermetic), medium (local resources), and large (external services) tests. External IO belongs in large tests.

### 2) Risk-Based Coverage
- Risk-driven testing focuses coverage on high-impact, high-likelihood failure areas. Fast-loop tests handle breadth; E2E tests cover critical user workflows.

### 3) Contract Testing for External APIs
- Contract testing validates the interface between systems without needing full end-to-end runs, typically using provider test environments or recorded contracts.

### 4) Behavior vs Interaction Testing
- Modern testing literature recommends defaulting to state/behavior verification and only using interaction verification (strict mocks) when interaction itself is the requirement.

## Synthesis: A Practical Coverage Model

### A) Test responsibility map
Define a matrix: behavior -> test layer. Each behavior should be assigned to the lowest possible layer that can prove it, and only a single E2E test per flow should remain for true integration.

### B) Fast loop (unit + mocked integration)
- No filesystem, no network, no subprocess. Stub boundary methods.
- Use state verification for output data, not only mock expectations.
- Enforce per-layer time budgets (ex: atoms <10ms, molecules <50ms, organisms <100ms).

### C) Slow loop (E2E)
- Use real IO safely: sandboxed project folders, test tokens, restricted scopes.
- One representative E2E per major workflow; no flag permutations or edge cases here.
- External APIs: prefer contract tests where possible; E2E hits only validated test endpoints.

### D) Performance verification cadence
- PR checks: run `ace-test --profile 10` to detect regressions.
- Nightly/weekly: run E2E suite and report coverage gaps.
- Quarterly: audit integration tests for migration to E2E or refactoring to mocks.

## References (External Sources)
- Test pyramid overview: https://martinfowler.com/articles/practical-test-pyramid.html
- Google testing sizes (small/medium/large): https://testing.googleblog.com/2010/12/test-sizes.html
- Risk-based testing overview: https://en.wikipedia.org/wiki/Risk-based_testing
- Consumer-driven contract testing (Pact): https://docs.pact.io/
- Mockist vs classicist testing (interaction vs state): https://martinfowler.com/articles/mocksArentStubs.html

## Repo Sources Consulted
- .ace-taskflow/v.0.9.0/tasks/_archive/251-test-refactor/*.s.md
- .ace-taskflow/v.0.9.0/tasks/_archive/252-test-perf/252-mock-ace-bundle-in-context-extractor-test.s.md
- .ace-taskflow/v.0.9.0/retros/8oums2-performant-unit-integration-tests.md
- .ace-taskflow/v.0.9.0/retros/8ouo8f-performant-unit-tests-cache-management.md
- ace-test/handbook/guides/testing-philosophy.g.md
- ace-test/handbook/guides/test-performance.g.md
- ace-test/handbook/guides/mocking-patterns.g.md
- ace-test-e2e-runner/handbook/guides/e2e-testing.g.md
