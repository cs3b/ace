## E2E Coverage Review: ace-llm

**Reviewed:** 2026-03-21 00:00 WET  
**Scope:** package-wide (`ace-llm`)  
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features (query/model routing slice) | 5 |
| Unit+integration files reviewed | 3 |
| E2E scenarios | 1 |
| E2E test cases | 2 |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Basic prompt query invocation through real CLI | `test/commands/query_command_test.rb` | `TS-LLM-001` / TC-001 | Covered |
| `--model` override + provider/model routing behavior | `test/commands/query_command_test.rb`, `test/molecules/client_registry_test.rb` | `TS-LLM-001` / TC-002 | Covered |
| Timeout normalization in query path | `test/commands/query_command_test.rb`, `test/integration/query_interface_fallback_test.rb` | none | Unit-only |
| Provider alias and registry resolution behavior | `test/molecules/client_registry_test.rb` | partial via TC-002 | Partial |
| Invalid/unsupported provider error surface at CLI boundary | command-level coverage only | none | Gap |

### E2E Decision Coverage

| TC ID | Evidence Status | Notes |
|------|------------------|-------|
| TC-001-basic-query | complete | Runner/verifier pairing is valid; verifier assertions can be stricter |
| TC-002-model-selection | complete | Captures success/failure surface; model-routing proof can be tightened |

### Gap Analysis

- Current scenario misses a deterministic routing failure path that does not rely on external provider availability.
- Verifier checks are currently broad enough to allow ambiguous PASS outcomes when artifact evidence is thin.
- Scenario remains small and can absorb one additional focused TC without inflating runtime significantly.

### Recommendations

1. **Keep** both existing TCs as core query/model coverage.
2. **Modify** TC-001 and TC-002 verifier expectations to require explicit artifact and exit-code evidence.
3. **Add** one TC for unknown-provider routing failure to validate CLI boundary behavior deterministically.
