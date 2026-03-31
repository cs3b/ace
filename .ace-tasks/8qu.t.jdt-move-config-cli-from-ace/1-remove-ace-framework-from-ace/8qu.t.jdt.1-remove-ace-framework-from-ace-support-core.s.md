---
id: 8qu.t.jdt.1
status: pending
priority: medium
created_at: "2026-03-31 12:55:29"
estimate: TBD
dependencies: [8qu.t.jdt.0]
tags: [cli, config, ace-support-core, docs]
parent: 8qu.t.jdt
bundle:
  presets: [project]
  files: [ace-support-core/exe/ace-framework, ace-support-core/lib/ace/core/cli.rb, ace-support-core/lib/ace/core/organisms/config_initializer.rb, ace-support-core/lib/ace/core/organisms/config_diff.rb, ace-support-core/lib/ace/core/models/config_templates.rb, ace-support-core/ace-support-core.gemspec, ace-support-core/README.md, ace-support-core/docs/config.md, ace-support-core/.ace-defaults/README.md, bin/ace-framework, README.md, docs/quick-start.md, DEVELOPMENT.md]
  commands: []
needs_review: false
---

# Remove ace-framework from ace-support-core and update all references

## Behavioral Specification

### User Experience

- **Input**: Users no longer encounter `ace-framework` anywhere — onboarding docs, help text, and tooling all reference `ace-config`
- **Process**: All ace-framework code, executable, bin/ wrapper, and doc references are removed or updated
- **Output**: Clean codebase with no dangling references to the old command name

### Expected Behavior

After subtask .0 delivers the new `ace-config` CLI, this subtask removes the old `ace-framework` ownership from ace-support-core:

1. **Delete executable**: `ace-support-core/exe/ace-framework`
2. **Remove CLI class**: `Ace::Core::FrameworkCLI` from `ace-support-core/lib/ace/core/cli.rb`
3. **Remove config modules** from ace-support-core (they now live in ace-support-config):
   - `ace-support-core/lib/ace/core/organisms/config_initializer.rb`
   - `ace-support-core/lib/ace/core/organisms/config_diff.rb`
   - `ace-support-core/lib/ace/core/models/config_templates.rb`
4. **Update ace-support-core gemspec**: remove `ace-framework` from executables
5. **Update bin/ wrappers**: remove `bin/ace-framework` (the new `bin/ace-config` wrapper already exists from subtask .0)
6. **Update onboarding docs**: replace `ace-framework` with `ace-config` in:
   - `README.md` (install section, step 3)
   - `docs/quick-start.md`
   - `DEVELOPMENT.md`
7. **Update ace-support-core docs**: `ace-support-core/README.md`, `ace-support-core/docs/config.md`

No compatibility shim for `ace-framework` (pre-1.0, ADR-024 applies).

This subtask is cleanup-only. Introduction of the new command, its packaging in `ace-support-config`, the repo-root `bin/ace-config` wrapper, and the migrated bootstrap/config coverage are all completed in subtask .0 before any `ace-framework` removal happens here.

### Interface Contract

```bash
# After this subtask, ace-framework is gone:
$ ace-framework init
# command not found

# ace-config works (delivered by subtask .0):
$ ace-config init
# initializes configurations

# bin/ wrapper:
$ bin/ace-config
# runs ace-config
```

Error Handling:
- If a user still has `ace-framework` in their shell history, they get "command not found" — this is expected and intentional for pre-1.0

### Success Criteria

- `ace-support-core/exe/ace-framework` does not exist
- `bin/ace-framework` does not exist; `bin/ace-config` exists
- `ace-support-core/ace-support-core.gemspec` does not list `ace-framework` in executables
- `FrameworkCLI` class no longer exists in ace-support-core
- `ConfigInitializer`, `ConfigDiff`, `ConfigTemplates` no longer exist in ace-support-core (they live in ace-support-config)
- `grep -r 'ace-framework' README.md docs/quick-start.md DEVELOPMENT.md` returns zero matches
- Remaining `ace-framework` references are limited to changelog/history/task/archive content
- `cd ace-support-core && ace-test` passes with no dangling references
- `cd ace-support-config && ace-test` still passes

### Validation Questions

- Should `ace-support-core/lib/ace/core/cli.rb` be deleted entirely or just have FrameworkCLI removed? **Default**: Remove only the FrameworkCLI class and its require statements. If cli.rb contains other shared CLI infrastructure, keep that. If FrameworkCLI is the only content, delete the file.
- Are there test files in ace-support-core that test config_initializer/config_diff? **Answer**: Yes — `test/integration/config_initializer_bootstrap_test.rb` and related files need to be moved or removed (ace-support-config now owns the tests).

## Vertical Slice Decomposition

- **Slice type**: subtask of orchestrator 8qu.t.jdt
- **Slice outcome**: Old ace-framework code fully removed; all docs reference ace-config
- **Advisory size**: medium — deletion + doc updates across several files, but straightforward
- **Context dependencies**: subtask .0 must be complete (ace-config must work before removing ace-framework)

## Verification Plan

### Unit/Component Validation

- `ace-support-core/exe/ace-framework` file does not exist
- `ace-support-core/lib/ace/core/organisms/config_initializer.rb` file does not exist
- `ace-support-core/lib/ace/core/organisms/config_diff.rb` file does not exist
- `ace-support-core/lib/ace/core/models/config_templates.rb` file does not exist
- `ace-support-core/ace-support-core.gemspec` does not reference `ace-framework`

### Integration Validation

- `cd ace-support-core && ace-test` passes — no require errors, no dangling references
- `cd ace-support-config && ace-test` passes — config CLI tests still work
- `ace-config init --dry-run` works end-to-end (no regression from removal)

### Failure/Invalid Path Validation

- `which ace-framework` returns nothing (command removed)
- No `.md` file in onboarding docs contains `ace-framework` string

### Verification Commands

- `cd ace-support-core && ace-test` — test suite passes
- `cd ace-support-config && ace-test` — test suite passes
- `grep -r 'ace-framework' README.md docs/quick-start.md DEVELOPMENT.md` — zero matches
- `bin/ace-config --help` — still works after removal
- `ace-search ace-framework --content --hidden` — remaining matches should only be in: CHANGELOG.md (historical), `.ace-tasks/_archive/`, `.ace-ideas/_archive/`, `.ace-retros/_archive/`, and the task spec for this task itself
