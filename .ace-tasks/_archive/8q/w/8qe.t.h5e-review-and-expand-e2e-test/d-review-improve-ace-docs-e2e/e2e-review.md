## E2E Coverage Review: ace-docs

**Reviewed:** 2026-03-20 23:33 WET  
**Scope:** package-wide (`ace-docs`)  
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features | 7 |
| Unit test files | 16 |
| Unit assertions (approx) | 220 |
| E2E scenarios | 1 |
| E2E test cases | 3 |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Discover managed docs (`ace-docs discover`) | `test/cli/commands/discover_test.rb` | `TS-DOCS-001` / TC-001 | Covered |
| Validate frontmatter and structure (`ace-docs validate`) | `test/cli/commands/validate_test.rb`, `test/organisms/validator_test.rb` | `TS-DOCS-001` / TC-002 | Covered |
| Status/health summary (`ace-docs status`) | `test/cli/commands/status_test.rb`, `test/integration/status_command_integration_test.rb` | `TS-DOCS-001` / TC-003 | Covered |
| Frontmatter update flow (`ace-docs update`) | `test/cli/commands/update_test.rb`, `test/molecules/frontmatter_manager_test.rb` | none | Unit-only |
| Analyze docs content (`ace-docs analyze`) | `test/cli/commands/analyze_test.rb`, `test/prompts/document_analysis_prompt_test.rb` | none | Unit-only |
| Analyze consistency (`ace-docs analyze-consistency`) | `test/cli/commands/analyze_consistency_test.rb` | none | Unit-only |
| Scope filtering options | `test/cli/commands/scope_options_test.rb` | none | Gap |

### E2E Decision Coverage

| TC ID | Evidence Status | Notes |
|------|------------------|-------|
| TC-001..TC-003 | complete | Runner/verifier split exists but assertions are too generic and allow weak evidence |

### Gap Analysis

- Highest-value missing E2E behavior is `ace-docs update` on real files, because it validates CLI wiring + file mutation path that unit tests do not fully exercise end-to-end.
- Existing discover/validate/status verifiers are broad and should be tightened to require concrete artifact names and stronger output evidence.
- Current scenario can absorb one additional TC without exceeding the recommended per-scenario size.

### Recommendations

1. **Add** TC-004 for `ace-docs update` with before/after artifact checks.
2. **Modify** TC-001..TC-003 runner/verifier files to standardize explicit artifact filenames (`discover.*`, `validate.*`, `status.*`) and tighter evidence criteria.
3. **Modify** scenario and bundle includes to register the new goal and keep runner/verifier orchestration aligned.
