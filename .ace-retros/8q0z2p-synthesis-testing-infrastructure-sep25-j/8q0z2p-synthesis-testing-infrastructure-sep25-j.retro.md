---
id: 8q0z2p
title: "Synthesis: Testing Infrastructure and Quality (Sep 2025 – Jan 2026)"
type: standard
tags: [synthesis]
created_at: "2026-03-01 23:23:01"
status: active
---

# Synthesis: Testing Infrastructure and Quality (Sep 2025 – Jan 2026)

**Scope**: 23 retros covering test runner performance, test isolation, sleep delays, E2E tests, fast unit tests, profiling, fail-fast, discovery fixes, and output interpretation.
**Date range**: 2025-09-20 through 2026-01-03

## What Went Well

- **Systematic profiling and root cause analysis** (Identified in 19/23 retros): Teams consistently used `ace-test --profile` and methodical investigation to identify actual bottlenecks before applying fixes. Successful outcomes correlated directly with thorough profiling (e.g., parser performance traced to O(n^2) regex, real git calls identified as bottleneck, sleep delays found in retry tests).

- **Dramatic test performance improvements through stubbing/mocking** (Identified in 14/23 retros): Eliminating real I/O (git commands, subprocess calls, filesystem scans, sleep delays) from unit tests produced massive speedups: ace-docs 12x, ace-review 32x, ace-git atoms 500x, ace-test-runner 7.8x, ace-git-secrets 75%. The protected method pattern for stubbing external dependencies was repeatedly validated.

- **Willingness to revert and accept "good enough"** (Identified in 6/23 retros): Teams recognized when complex solutions were not working and cleanly reverted changes (timeout investigation rollback, failed organism test stubs, premature optimizations), preventing unnecessary complexity.

- **Incremental, phased implementation approach** (Identified in 10/23 retros): Breaking work into logical phases (atoms then molecules then organisms; one layer at a time) with tests run after each phase caught regressions early.

- **Creation of reusable shared test infrastructure** (Identified in 6/23 retros): Building centralized mock helpers (CommandMockHelper, TestRunnerMocks, MockGitRepo) in ace-support-test-helpers provided value across multiple packages.

## What Could Be Improved

- **Real I/O in unit tests not caught early enough** (Identified in 16/23 retros): The single most pervasive problem. Tests shipped with real git commands, subprocess spawning, filesystem scanning, network calls, and actual sleep delays. Only caught when someone profiled the suite, often long after initial development.

- **Premature optimization and incorrect assumptions** (Identified in 8/23 retros): Teams repeatedly optimized without first validating the problem existed or understanding the actual bottleneck. Example: 2+ hours on config system investigation vs. one-line `fallback: false` fix.

- **Over-engineering before trying simple solutions** (Identified in 7/23 retros): Complex multi-file solutions implemented before trying minimal fixes. The timeout investigation (8mh000) is the clearest cautionary tale.

- **Misunderstanding test boundaries (unit vs. integration)** (Identified in 10/23 retros): Tests categorized as "integration" were actually testing component logic. Tests categorized as "unit" were executing real external commands. Boundary not consistently enforced.

- **Cross-package dependency impacts on test performance** (Identified in 4/23 retros): ace-core's ConfigResolver filesystem scanning impacted multiple downstream packages. Stubbing from the consumer package was ineffective; fixes needed in the dependency itself.

- **Test output misinterpretation and filtering anti-patterns** (Identified in 4/23 retros): Grepping or filtering ace-test output lost critical failure information. Misunderstanding "0 failures" as success when errors existed separately.

## Key Learnings

- **Measure before optimizing** (from 12 retros): Actual bottlenecks are almost never where initially assumed. Ruby/framework startup dominates execution time. `ace-test --profile` is the essential first step before any optimization work.

- **Unit tests must never perform real I/O** (from 14 retros): Git commands, subprocess spawning, filesystem scanning, network calls, and sleep delays must all be stubbed. The protected method pattern (extract external dependency to a protected method, stub it in tests) is the standard approach.

- **Stub at the right level** (from 9 retros): Stub at system boundaries (CommandExecutor, Open3, external APIs), not at internal implementation details. Use full module paths when stubbing across layers.

- **Test the simplest solution first** (from 7 retros): Before implementing complex multi-file solutions, try the one-line fix. When a direct API call works but a wrapper does not, the problem is in how the wrapper calls the API.

- **Distinguish failures from errors in Minitest** (from 3 retros): Exit code 1 with "0 failures" can mean errors exist. Both the failures and errors arrays must be checked.

- **Test isolation requires careful initialization ordering** (from 4 retros): Commands using ConfigDiscovery must be initialized inside test blocks (after stubbing is active), not in `setup`. Global ENV modification breaks parallel test execution.

- **Cross-package dependencies cannot be effectively stubbed from downstream** (from 3 retros): When slow code lives in a dependency, the fix must happen in that dependency, not through heroic stubbing in the consumer.

## Action Items

- **Enforce no-real-I/O in unit tests**: Implement automated detection of system calls, Open3, File I/O, sleep, and network calls in unit test files. Add to CI as a lint check.

- **Add CI performance gates for test suites**: Fail CI if any unit test exceeds 100ms. Run `ace-test --profile` in CI and alert on regressions. Establish per-test-type budgets: unit pure <1ms, unit mocked <10ms, integration <500ms.

- **Create gem scaffolding with test infrastructure**: New ace-* gems must include test_helper.rb with proper load paths and at least one smoke test.

- **Document and enforce test categorization guidelines**: Clear definitions of unit vs. integration test boundaries. Unit tests use stubs for all external dependencies. Integration tests use real I/O but are kept minimal.

- **Profile tests during initial development, not retroactively**: Run `ace-test --profile` before committing new tests. Make performance awareness part of the test-writing workflow.

- **Stub sleep in all retry/backoff tests**: Standardize the pattern. Consider a shared `without_sleep` helper in ace-support-test-helpers.

- **Never filter or pipe ace-test output**: Read output directly. Use `test-reports/latest/raw_output.txt` for detailed error information.

## Additional Context

**Source retro IDs** (23 total):
8kj000, 8kn000, 8kt000, 8l0000 (×3), 8l1000 (×3), 8l6000, 8l7000, 8lk000, 8m8000, 8mb000 (×2), 8mg000, 8mh000, 8ng000, 8no000 (×3), 8o1000, 8o2000

**Dominant theme**: Test performance optimization through elimination of real I/O in unit tests. This theme appears in 16/23 retros, making it the most significant recurring pattern. The project achieved speedups ranging from 2.5x to 500x by applying consistent stubbing patterns.

**Key contradiction**: Several retros praise systematic profiling as "what went well" while noting profiling should have happened earlier. The team learned the lesson but continued encountering the pattern in new packages, indicating the practice was not yet institutionalized through tooling.

**Key diagnostic principle** (from 8mh000): "When the direct API call works but the wrapper doesn't, the problem is in how the wrapper calls the API, not in missing API features."
