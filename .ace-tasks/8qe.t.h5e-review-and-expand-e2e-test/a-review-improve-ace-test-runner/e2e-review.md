## E2E Coverage Review: ace-test-runner

**Reviewed:** 2026-03-20 22:49 WET  
**Scope:** package-wide (`ace-test-runner`)  
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features | 5 |
| Unit test files | 21 |
| Unit assertions (approx) | 111 |
| E2E scenarios | 2 |
| E2E test cases | 5 |
| TCs with decision evidence | 5/5 |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Package-scoped execution (`ace-test <pkg> <group>`) | `test/integration/package_argument_test.rb`, `test/commands/cli_routing_test.rb` | `TS-TEST-001` / TC-001, TC-003 | Covered |
| File-scoped execution (`ace-test <pkg> <file>`) | `test/integration/explicit_file_execution_test.rb` | `TS-TEST-001` / TC-002 | Covered |
| Group filtering and report dir behavior | `test/molecules/cli_argument_parser_test.rb`, `test/molecules/rake_task_test.rb` | `TS-TEST-001` / TC-003 | Covered |
| Suite aggregation across packages (`ace-test-suite`) | `test/integration/suite/orchestrator_test.rb`, `test/integration/suite/result_aggregator_test.rb`, `test/integration/suite/display_helpers_test.rb` | `TS-TEST-002` / TC-001 | Covered |
| Failure propagation/non-zero exit in suite mode | `test/molecules/failed_package_reporter_test.rb`, `test/integration/suite/orchestrator_test.rb` | `TS-TEST-002` / TC-002 | Covered |

### Overlap Analysis

TCs with overlap that still retain E2E value:

| TC ID | Feature | Overlapping Unit Tests | Recommendation |
|-------|---------|------------------------|----------------|
| TS-TEST-001/TC-002 | file-scoped execution | `test/integration/explicit_file_execution_test.rb` | Keep — validates real CLI invocation + report artifact generation |
| TS-TEST-001/TC-003 | group-scoped execution | `test/integration/package_argument_test.rb`, parser tests | Keep — validates real report-dir side effects and group invocation contract |
| TS-TEST-002/TC-002 | failure propagation | orchestrator/reporter unit tests | Keep — validates end-to-end non-zero propagation through CLI layer |

**Candidates for removal:** 0

### E2E Decision Record Coverage

| TC ID | Evidence Status | Missing Fields |
|-------|------------------|----------------|
| TS-TEST-001 / TC-001..003 | complete | none |
| TS-TEST-002 / TC-001..002 | complete | none |

### Gap Analysis

Potential quality gaps are primarily assertion quality, not missing scenarios:

| Area | Current State | E2E Needed? |
|------|---------------|-------------|
| Verifier specificity in suite tests | Some expectations allow broad phrasing (`references multiple package runs or grouped execution`) | Yes — tighten to explicit artifact/output markers |
| Failure evidence strictness | Failure propagation checks rely on generic wording | Yes — require explicit non-zero and failure indicator evidence |
| Test health metadata | No explicit per-TC freshness metadata beyond files | Optional |

### Health Status

| Scenario | Status |
|----------|--------|
| TS-TEST-001-test-execution | Healthy (structure and evidence fields are consistent) |
| TS-TEST-002-suite-execution | Healthy but verifier expectations should be tightened |

### Consolidation Opportunities

| CLI Command Pattern | TCs | Recommendation |
|---------------------|-----|----------------|
| `ace-test` scoped execution | TS-TEST-001 TC-001/002/003 | Keep separate; each validates distinct scope mode |
| `ace-test-suite` execution/failure | TS-TEST-002 TC-001/002 | Keep separate; positive vs failure path |

### Recommendations

1. Modify TS-TEST-002 verifiers to require stronger evidence (explicit output markers + exit evidence).
2. Tighten TS-TEST-001 TC-001 verifier to include explicit report artifact assertions (not only summary text).
3. Keep scenario count unchanged unless rewrite uncovers concrete redundancy.

### Next Step

Run Stage 2 plan generation and classify concrete changes in `e2e-change-plan.md`.
