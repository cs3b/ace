## E2E Coverage Review: ace-tmux

**Reviewed:** 2026-03-21 00:29 WET  
**Scope:** package-wide (`ace-tmux`)  
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features | 6 |
| Unit test files | 13 |
| Unit assertions (approx) | 429 |
| E2E scenarios | 1 |
| E2E test cases | 2 |
| TCs with decision evidence | 2/2 |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Preset listing (`ace-tmux list`, `ace-tmux list sessions`) | `test/commands/cli_test.rb`, `test/atoms/preset_resolver_test.rb`, `test/molecules/preset_loader_test.rb` | `TS-TMUX-001` / TC-001 | Covered |
| Session creation flow (`ace-tmux start <preset> --detach`) | `test/organisms/session_manager_test.rb`, `test/molecules/session_builder_test.rb`, `test/molecules/tmux_executor_test.rb` | `TS-TMUX-001` / TC-002 | Covered |
| Window creation command (`ace-tmux window <preset>`) | `test/organisms/window_manager_test.rb`, `test/molecules/session_builder_test.rb`, `test/molecules/tmux_executor_test.rb` | none | Unit-only |
| CLI help/command discovery (`--help`, `help`) | `test/commands/cli_test.rb` | none | Unit-only |
| CLI version output (`version`, `--version`) | `test/commands/cli_test.rb` | none | Unit-only |
| Preset-layout model normalization/building | `test/models/*.rb`, `test/atoms/layout_string_builder_test.rb` | none | Unit-only |

### Overlap Analysis

TCs that may fail the E2E Value Gate (unit tests cover the same behavior):

| TC ID | Feature | Overlapping Unit Tests | Recommendation |
|------|---------|-------------------------|----------------|
| TC-001-list-presets | preset listing | `test/commands/cli_test.rb`, `test/molecules/preset_loader_test.rb` | Keep — validates CLI + real runtime artifact capture surface |
| TC-002-start-session | detached session creation | `test/organisms/session_manager_test.rb`, `test/molecules/tmux_executor_test.rb` | Keep — validates real tmux interaction and detached workflow |

**Candidates for removal:** 0 TCs have full overlap with unit tests without meaningful E2E value.

### E2E Decision Record Coverage

| TC ID | Evidence Status | Missing Fields |
|------|------------------|----------------|
| TC-001-list-presets | complete | none |
| TC-002-start-session | complete | none |

**Action:** keep scenario evidence metadata intact during rewrite.

### Gap Analysis

Features with no E2E coverage that may need it:

| Feature | External Tools | Unit Coverage | E2E Needed? |
|---------|----------------|---------------|-------------|
| `ace-tmux window` end-to-end invocation | `tmux` | yes | yes — command is user-facing and depends on live tmux context |
| CLI help/version surfaces | none | yes | no — unit coverage is sufficient and behavior is deterministic |

### Health Status

| TC ID | Last Verified | Status |
|------|---------------|--------|
| TC-001-list-presets | (not recorded) | Never verified |
| TC-002-start-session | (not recorded) | Never verified |

**Outdated (> 30 days):** 0 TCs  
**Never verified:** 2 TCs

### Consolidation Opportunities

TCs sharing the same CLI invocation that could be merged:

| CLI Command | TCs | Merged Assertions |
|-------------|-----|-------------------|
| none (distinct commands) | n/a | No consolidation recommended |

### Recommendations

1. **Modify** TC-001 and TC-002 runner/verifier files to make artifact and failure-path evidence stricter and less ambiguous.
2. **Add** one `window`-focused TC under the same scenario to close the highest-value user-facing E2E gap.
3. Keep scenario count at 1 to control execution cost while raising feature coverage.
