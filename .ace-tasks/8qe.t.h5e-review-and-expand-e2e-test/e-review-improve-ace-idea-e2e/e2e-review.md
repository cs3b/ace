## E2E Coverage Review: ace-idea

**Reviewed:** 2026-03-20
**Scope:** package-wide, focused rewrite target `TS-IDEA-001`
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features reviewed | 6 |
| Unit test files reviewed | 22 |
| E2E scenarios | 1 |
| E2E test cases (before rewrite) | 3 |
| TCs with decision evidence | 3/3 |

### Feature Inventory

| Feature | Command | External Tools | Notes |
|---------|---------|----------------|-------|
| Create idea | `ace-idea create` | none | Writes frontmatter + files to `.ace-ideas/` |
| List ideas | `ace-idea list` | none | Supports `--status`, `--tags`, `--in` folder filtering |
| Update metadata | `ace-idea update --set/--add/--remove` | none | Mutates frontmatter fields |
| Move idea to root/folder/archive | `ace-idea update --move-to` | none | Path transition behavior on real filesystem |
| Show idea | `ace-idea show` | none | Read/display behavior |
| Doctor status/repair | `ace-idea doctor`, `ace-idea status` | none | Health and structure checks |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Create with persisted file + ID output | `test/molecules/idea_creator_test.rb`, `test/commands/idea_cli_test.rb` | `TC-001` | Covered |
| List with status/folder filtering through CLI output | `test/molecules/idea_scanner_test.rb`, `test/commands/idea_cli_test.rb` | `TC-002` | Covered |
| Move to root (`--move-to next`) | `test/molecules/idea_mover_test.rb`, `test/integration/idea_integration_test.rb` | `TC-003` | Covered |
| Move to archive (`--move-to archive`) with archive listing | unit coverage exists (`idea_mover_test`, integration roundtrip) | none | Unit-only (E2E gap) |

### Overlap Analysis

- Existing TCs have overlap with unit/integration tests but retain E2E value because they assert real CLI subprocess output plus disk state transitions.
- No full-overlap candidate to remove.

### Gap Analysis

| Feature | Unit Coverage | E2E Needed? | Reason |
|---------|---------------|-------------|--------|
| Archive transition + archive filtered listing | yes | yes | Requires end-to-end CLI-to-disk transition and archive folder projection through real command output |

### Structure/quality findings

- `TC-002` runner language conflicts with expected behavior (`--in next` should include root ideas, not “returns empty”).
- `TC-002` lacked explicit artifact capture list despite verifier expecting concrete command evidence.

### Recommendations

1. Add `TC-004` for archive transition + `--in archive` listing verification.
2. Fix `TC-002` wording and evidence capture contract.
3. Keep existing 3 TCs; no removals or consolidation needed.

### Next Step

Run plan stage and execute rewrite against `TS-IDEA-001` with KEEP/MODIFY/ADD decisions.
