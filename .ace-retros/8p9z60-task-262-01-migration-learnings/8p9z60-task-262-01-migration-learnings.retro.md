---
id: 8p9z60
title: Task 262.01 — First E2E Migration (ace-lint)
type: standard
tags: []
created_at: "2026-02-10 23:26:40"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8p9z60-task-262-01-migration-learnings.md
---
# Reflection: Task 262.01 — First E2E Migration (ace-lint)

**Date**: 2026-02-10
**Context**: Learnings from migrating 8 ace-lint .mt.md E2E tests to per-TC directory format — the first subtask of a 43-file migration across 10 packages
**Author**: claude-opus-4.6
**Type**: Standard

## What Went Well

- Faithful migration preserved all test behavior — no coverage lost
- Directory-based format is much cleaner: real fixture files with IDE support instead of heredoc strings-within-strings
- Review found 0 bugs — all 4 findings were either design decisions or pre-existing conditions faithfully carried over
- TC-000 "setup-only" test case in MT-LINT-004 was cleanly absorbed into scenario.yml `write-file:` step — the right call

## What Could Be Improved

- **SetupExecutor shorthand extensibility**: The current 261.01 design hardcodes step types (`git-init`, `copy-fixtures`) in a Ruby `case` statement. This works for 5 known steps but loses the flexibility that ace-bundle's data-driven preset model provides. New step types require code changes rather than config additions.
- **Sandbox isolation is implicit**: The old `.mt.md` files had explicit sandbox isolation checkpoints (verify working dir, check for remotes). The new format relies entirely on SetupExecutor creating fresh sandboxes — correct by design, but the safety net is invisible. If the runner regresses, there's no in-scenario guard.
- **Unused fixtures carried forward**: Some scenarios (e.g., TS-LINT-005) have fixture directories that no TC references. The migration faithfully preserved these, but they add clutter. A lint/validation step for scenario directories would catch this.

## Key Learnings

### Data-driven vs hardcoded dispatch in SetupExecutor

SetupExecutor supports two kinds of setup steps:

1. **String shorthands** — bare strings like `git-init`, `copy-fixtures` that take no parameters
2. **Hash params** — keyed entries like `run:`, `write-file:`, `env:` that carry structured data

The dispatch logic is a Ruby `case` statement that routes each step to its `handle_*` method:

```ruby
case step
when String  → route "git-init" → handle_git_init, "copy-fixtures" → handle_copy_fixtures
when Hash    → route "run:" → handle_run, "write-file:" → handle_write_file, "env:" → handle_env
end
```

This works for the current 5 step types. But adding a new one (e.g. `create-branch`, `install-deps`) means modifying SetupExecutor Ruby code — a code change for what is conceptually a config change.

**Comparison: hardcoded vs data-driven dispatch**

| Aspect | Current (hardcoded) | Data-driven (ace-bundle pattern) |
|--------|---------------------|----------------------------------|
| Adding a step type | Modify Ruby `case` + add `handle_*` method | Add YAML entry mapping shorthand → `run:` sequence |
| Validation | Compile-time (Ruby) | Load-time (YAML schema) |
| Flexibility | Full (arbitrary Ruby) | Bounded (expands to existing primitives) |
| Discoverability | Read source code | Read config file |
| Complexity | Low (5 branches) | Higher (config parsing + expansion) |

**Key insight**: The `run:` step already provides an escape hatch for arbitrary commands. The shorthands (`git-init`, `copy-fixtures`) are just convenience wrappers. The question isn't whether the system is flexible enough — it is, via `run:` — but whether the *shorthand layer* should be extensible without code changes.

A data-driven approach would define shorthands as YAML that expand to `run:` sequences:

```yaml
# hypothetical: step-shorthands.yml
git-init:
  - run: git init --quiet .
  - run: git config user.name "Test User"
  - run: git config user.email "test@example.com"
```

**Recommendation**: At 5 step types, the hardcoded dispatch is fine. Revisit if step types proliferate beyond ~8 or if non-developers need to define new shorthands. The `run:` escape hatch keeps the system unblocked in the meantime.

### Other learnings

- **Migration is translation, not improvement**: Resisting the urge to "fix" pre-existing issues (missing `git-init`, unused fixtures) during migration kept the scope clean and the review simple. Improvements belong in separate tasks.
- **31 TCs not 32 is correct**: When a "test case" is purely setup with no assertions, absorbing it into `scenario.yml` setup steps is the right pattern — it's not a test, it's infrastructure.

## Action Items

### Continue Doing

- Faithful migration without behavior changes — keeps diffs reviewable
- Absorbing setup-only TCs into scenario.yml rather than creating assertion-free TC files

### Start Doing

- Consider a `scenario-lint` tool that validates: all fixtures referenced by TCs, no orphan fixtures, required setup steps present
- When designing new infrastructure (like SetupExecutor), evaluate data-driven extensibility upfront — ask "could this be config instead of code?"

## Technical Details

- 8 `.mt.md` files → 8 `TS-LINT-*` directories (68 new files total)
- Setup step types used across ace-lint: `git-init`, `copy-fixtures`, `write-file`, `run`, `env`
- Scenarios without `git-init` (TS-LINT-001, 005, 008) — intentional, matching originals

## Additional Context

- PR: https://github.com/cs3b/ace-meta/pull/196
- Commit: `e54b769a9`
- 9 remaining subtasks (262.02–262.10) can apply these learnings
