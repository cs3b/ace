## E2E Coverage Review: ace-support-nav

**Reviewed:** 2026-03-19 00:15 WET  
**Scope:** package-wide (`ace-support-nav`)  
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features | 6 |
| Unit test files | 11 |
| Unit assertions (approx) | 258 |
| E2E scenarios | 1 |
| E2E test cases | 5 |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Resolve URI + extension inference chain (`guide://`, `wfi://`) | `test/atoms/extension_inferrer_test.rb`, `test/molecules/protocol_scanner_test.rb`, `test/organisms/navigation_engine_test.rb` | `TS-NAV-001` / TC-002, TC-003, TC-005 | Covered |
| Missing resource error UX (`Resource not found`, non-zero) | `test/commands/cli_test.rb` | `TS-NAV-001` / TC-004 | Covered |
| Help surface discovery | implicit command coverage, no dedicated help assertions | `TS-NAV-001` / TC-001 | E2E-only |
| Auto-routing from resolve to list for wildcard/protocol-only URI | `test/commands/cli_test.rb` (`magic_wildcard_pattern?`) | none | Unit-only |
| `sources` command output and source listing | `test/molecules/source_registry_test.rb`, command-level unit coverage | none | Gap |
| `create` command end-to-end file creation UX | command and organism unit tests | none | Unit-only |

### E2E Decision Coverage

| TC ID | Evidence Status | Notes |
|------|------------------|-------|
| TC-001..TC-005 | complete | Runner/verifier split is consistent and artifact-first |

### Gap Analysis

- Highest-value missing E2E behavior is explicit `sources` command execution through the real binary and configured fixture sources.
- Auto-routing (`resolve` wildcard/protocol-only) is only unit tested; this behavior is CLI-facing and should be validated E2E at least once.
- Current scenario is still lightweight and can absorb one additional TC without over-expanding cost.

### Recommendations

1. **Modify** TC-004 and TC-005 verifiers to tighten evidence criteria (reduce false positives).
2. **Expand** TC-001 to capture/verify `ace-nav sources` output so command-surface coverage improves without increasing scenario size.
3. Keep current five goals otherwise; no removals needed.
