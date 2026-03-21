## E2E Coverage Review: ace-search

**Reviewed:** 2026-03-20
**Scope:** package-wide, focused rewrite target `TS-SEARCH-001`
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features reviewed | 6 |
| Unit test files reviewed | 13 |
| E2E scenarios | 1 |
| E2E test cases (before rewrite) | 3 |
| TCs with decision evidence | 3/3 |

### Feature Inventory

| Feature | Command | External Tools | Notes |
|---------|---------|----------------|-------|
| Content search | `ace-search "pattern" <path>` | `rg` | Primary match-oriented CLI behavior |
| File search | `ace-search --files "glob" <path>` | `rg` | File discovery output mode |
| Count output | `ace-search --count "pattern" <path>` | `rg` | Count-focused reporting |
| Files-with-matches | `ace-search --files-with-matches ...` | `rg` | Filename-only output behavior |
| Search-type routing | `ace-search --type <file|content|hybrid|auto>` | `rg` | Strategy selection path |
| Structured output | `ace-search --json ...` | `rg` | Machine-readable output contract |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Content search baseline | `test/integration/cli_integration_test.rb`, `test/organisms/search_service_test.rb` | `TC-001` | Covered |
| File-search mode | `test/molecules/search_option_builder_test.rb`, `test/organisms/file_search_strategy_test.rb` | `TC-002` | Covered |
| Count and files-with-matches behavior | `test/organisms/result_formatter_test.rb`, `test/organisms/content_search_strategy_test.rb` | `TC-003` | Covered |
| JSON output contract | formatter/unit coverage exists | none | Unit-only (E2E gap) |

### Overlap Analysis

- Existing TCs overlap with integration coverage but still add E2E value by asserting full CLI subprocess behavior and real filesystem traversal.
- No TC is a pure duplicate candidate for removal.

### Gap Analysis

| Feature | Unit Coverage | E2E Needed? | Reason |
|---------|---------------|-------------|--------|
| JSON output mode contract | yes | yes | End-to-end command behavior for structured stdout should be validated in the same scenario matrix as other output modes |

### Structure/quality findings

- Existing runner TCs lacked explicit artifact naming conventions (`*.stdout`, `*.stderr`, `*.exit`) per command, creating verifier ambiguity.
- Verifier expectations were broad and did not consistently require per-command evidence references.

### Recommendations

1. Add `TC-004` for JSON output mode with deterministic repo-scoped content search.
2. Add explicit artifact capture lists to all runner TCs.
3. Tighten verifier expectations to cite concrete artifact filenames for each goal.

### Next Step

Run plan stage and execute rewrite against `TS-SEARCH-001` with KEEP/MODIFY/ADD decisions.
