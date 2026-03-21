## E2E Coverage Review: ace-prompt-prep

**Reviewed:** 2026-03-20  
**Scope:** package-wide, focused rewrite target `TS-PREP-001`  
**Workflow version:** 2.1

### Summary

| Metric | Count |
|--------|-------|
| Package features reviewed | 7 |
| Unit test files reviewed | 4 |
| E2E scenarios | 1 |
| E2E test cases (before rewrite) | 3 |
| TCs with decision evidence | 3/3 |

### Feature Inventory

| Feature | Command | External Tools | Notes |
|---------|---------|----------------|-------|
| Help and command discovery | `ace-prompt-prep --help` | none | CLI surface and subcommand discoverability |
| Setup workspace | `ace-prompt-prep setup` | none | Creates prompt workspace and template |
| Process prompt and archive | `ace-prompt-prep process` | `ace-b36ts` | Archives content and updates symlink |
| Context-enabled processing | `ace-prompt-prep process --bundle` | `ace-bundle` | Injects bundled context before output |
| Enhanced processing | `ace-prompt-prep process --enhance` | `ace-llm` | LLM enhancement path with model options |
| Task-scoped prompts | `ace-prompt-prep process --task <id>` | `ace-task`, `ace-git` | Task-specific prompt directory selection |
| Version reporting | `ace-prompt-prep version` | none | Semantic version display |

### Coverage Matrix

| Feature | Unit Tests | E2E Tests | Status |
|---------|------------|-----------|--------|
| Help and command discovery | `test/commands/cli_test.rb` | `TC-001` | Covered |
| Setup workspace | `test/integration/cli_integration_test.rb`, `test/commands/setup_reset_test.rb` | `TC-002` | Covered |
| Process/archive baseline | `test/integration/cli_integration_test.rb`, `test/commands/cli_test.rb` | `TC-003` | Covered |
| Context-enabled processing (`--bundle`) | `test/integration/cli_integration_test.rb` | none | Unit-only (E2E gap) |
| Enhanced processing (`--enhance`) | `test/integration/cli_integration_test.rb` | none | Unit-only (not selected for E2E due provider variability) |
| Task-scoped prompts (`--task`) | `test/integration/cli_integration_test.rb` | none | Unit-only (possible future E2E candidate) |
| Version reporting | `test/commands/cli_test.rb`, `test/integration/cli_integration_test.rb` | none | Unit-only |

### Overlap Analysis

- Existing TCs still provide E2E value because they verify real CLI execution and filesystem side effects.
- No current TC is pure overlap eligible for removal.

### Gap Analysis

| Feature | Unit Coverage | E2E Needed? | Reason |
|---------|---------------|-------------|--------|
| Context-enabled processing (`--bundle`) | yes | yes | Requires end-to-end CLI invocation and observable output/artifact behavior |
| Enhanced processing (`--enhance`) | yes | no (for now) | External provider variability makes this unsuitable for default deterministic smoke flow |

### Structure/quality findings

- Runner goals define intent but do not consistently require explicit artifact filenames per command.
- Verifier files are mostly clear but should require concrete filename-level evidence in verdicts.

### Recommendations

1. Add `TC-004-bundle-context` to cover context-enabled processing through the real CLI path.
2. Tighten artifact naming and capture expectations across existing runner files.
3. Tighten verifier wording to require explicit artifact references per goal.

### Next Step

Run plan stage and execute rewrite against `TS-PREP-001` with KEEP/MODIFY/ADD decisions.
