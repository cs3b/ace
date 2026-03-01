---
id: 8pap55
title: ace-lint E2E Test Suite Restructuring Analysis
type: standard
tags: []
created_at: "2026-02-11 16:45:42"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8pap55-ace-lint-e2e-restructuring-analysis.md
---
# Reflection: ace-lint E2E Test Suite Restructuring Analysis

**Date**: 2026-02-11
**Context**: Analysis of ace-lint E2E test coverage overlap with unit tests, leading to consolidation from 8 scenarios / 31 TCs to 3 scenarios / 9 TCs
**Author**: Development Team
**Type**: Standard

## What Went Well

- Systematic analysis of all 31 TCs against the 265 unit tests (766 assertions) revealed clear overlap patterns
- The E2E test format (TS-format with scenario.yml + .tc.md files) made it easy to audit each TC's unique value
- Unit test coverage in ace-lint is comprehensive — atoms and molecules cover validator execution, report generation, config parsing, and skill validation thoroughly
- The existing fixture files are well-designed and reusable across consolidated scenarios

## What Could Be Improved

- Initial E2E test creation didn't have a clear "E2E-only" criteria — many TCs duplicate unit test coverage (e.g., compact ID format validation, nonexistent file error handling, doctor quiet/verbose modes)
- Some TCs test presentation concerns (output formatting, verbose vs quiet modes) that belong in unit tests
- The RuboCop fallback TC (TS-001/TC-003) was created as PENDING because PATH manipulation doesn't work with mise shims — this should have been caught before creating the TC
- Doctor exit code 2 for YAML syntax errors is a known bug tracked in two separate TCs (TS-005/TC-004, TS-008/TC-004) — bugs should be tracked as issues, not E2E tests

## Key Learnings

- **E2E test value criteria**: E2E tests should only exist for behaviors that require the full CLI pipeline — real binary execution, real subprocess calls (StandardRB/RuboCop), real filesystem I/O, real config discovery. Anything testable with stubs/mocks belongs in unit tests.
- **Coverage overlap metric**: ~60% of TCs (19/31) duplicate coverage already provided by unit tests. This is expensive — each TC costs an LLM agent invocation (~$0.05-0.15 + 30-120s).
- **Assertion reliability**: Verbose output assertions (checking which validator was used by grepping output) proved unreliable across environments. Better to verify observable side effects (files processed, reports generated, exit codes).
- **Batch testing efficiency**: Multiple related assertions can be consolidated into fewer TCs when they share the same setup. E.g., checking report.json structure, exit code, and markdown existence can be one TC instead of three.

## Action Items

### Stop Doing

- Creating E2E TCs for atom-level concerns (format validation, error message content)
- Testing output formatting/presentation in E2E (quiet mode, verbose mode, output styling)
- Creating PENDING E2E TCs for environment-dependent features that can't run in CI

### Continue Doing

- Using the TS-format with scenario.yml for deterministic setup
- Writing fixtures that represent real-world files (frozen_string_literal, proper class structure)
- Mapping TC origins to maintain traceability during consolidation

### Start Doing

- Apply "E2E-only" gate before creating new TCs: "Does this require the full CLI binary + real tools + real filesystem?"
- Track known bugs as GitHub issues, not as E2E test cases
- Review E2E suite quarterly for coverage overlap with growing unit test suite

## Technical Details

### Coverage Analysis Summary

| Old Scenario | TCs | Unique E2E Value | Disposition |
|---|---|---|---|
| TS-001 Ruby Validator Fallback | 5 | Valid lint + fix mode + batch (3 TCs) | → TS-LINT-001 |
| TS-002 JSON Report Generation | 5 | Report structure + categorization (2 TCs) | → TS-LINT-001 |
| TS-003 Skill Validation | 2 | None — 332 lines of unit tests cover everything | Dropped |
| TS-004 CLI Exit Codes | 5 | Exit codes + no-report + group routing (3 TCs) | → TS-LINT-001, TS-LINT-002 |
| TS-005 Doctor Command | 4 | Validator detection + config reading (2 TCs) | → TS-LINT-003 |
| TS-006 Report Markdown Files | 3 | Markdown file format verification (3 TCs) | → TS-LINT-001 |
| TS-007 Validator Config Overrides | 3 | Config override + group routing (2 TCs) | → TS-LINT-002 |
| TS-008 Doctor Modes/Exit Codes | 4 | Healthy exit code (1 TC) | → TS-LINT-003 |

### Consolidation Result

- **TS-LINT-001** (Core Lint Pipeline): 5 TCs — valid lint, fix mode, syntax errors, batch, no-report
- **TS-LINT-002** (Configuration & Routing): 2 TCs — group routing with config, CLI override
- **TS-LINT-003** (Doctor Diagnostics): 2 TCs — healthy environment, YAML syntax error detection

### Impact

| Metric | Before | After | Reduction |
|---|---|---|---|
| Scenarios | 8 | 3 | 63% |
| Test cases | 31 | 9 | 71% |
| LLM invocations/run | ~30 | ~9 | 70% |
| Est. cost/run | $1.50-$4.50 | $0.45-$1.35 | 70% |

## Additional Context

- Task: 261 — E2E Per-TC Infrastructure Implementation
- Branch: 261-e2e-per-tc-infrastructure-implementation
- ace-lint unit tests: 265 tests, 766 assertions across atoms/molecules/organisms
