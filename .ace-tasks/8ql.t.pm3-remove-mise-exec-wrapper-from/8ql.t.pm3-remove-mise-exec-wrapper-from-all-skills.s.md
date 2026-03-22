---
id: 8ql.t.pm3
status: draft
priority: medium
created_at: "2026-03-22 17:04:33"
estimate: TBD
dependencies: []
tags: [cleanup, mise, skills, docs]
bundle:
  presets: ["project"]
  files:
    - AGENTS.md
    - ace-handbook/lib/ace/handbook/organisms/provider_syncer.rb
    - ace-handbook/test/organisms/provider_syncer_test.rb
  commands: []
---

# Remove mise exec Wrapper from All Skills, Docs, and Tapes

## Objective

Remove all `mise exec --` wrappers from active project files so that `ace-*` commands are invoked directly. PATH is now configured correctly for all providers (Claude, Codex, OpenCode, Pi, Gemini) — the wrapper is unnecessary overhead.

## Current State

The `mise exec -- ace-*` pattern appears ~850+ times across ~600+ files. This was originally required to ensure `ace-*` binaries were on PATH, but provider environments now resolve PATH correctly. The wrapper adds visual noise, confuses onboarding, and creates a false dependency on mise being installed.

## Behavioral Specification

### Interface Contract

**Before:**
```
mise exec -- ace-bundle wfi://git/commit
mise exec -- ace-test atoms
mise exec -- ace-nav --sources
```

**After:**
```
ace-bundle wfi://git/commit
ace-test atoms
ace-nav --sources
```

The transformation is purely textual: remove the `mise exec -- ` prefix wherever it precedes an `ace-*` command. No behavioral change to the commands themselves.

### Scope of Changes

| Category | Files | Action |
|----------|-------|--------|
| A. Canonical skills | ~91 `handbook/skills/*/SKILL.md` | Replace `mise exec -- ace-*` with `ace-*` |
| B. Provider projections | ~450 `.claude/`, `.codex/`, `.opencode/`, `.pi/`, `.gemini/` skills | Re-sync via `ace-handbook sync` after fixing canonical |
| C. Agent config | `AGENTS.md`, `CLAUDE.md` | Remove mise mandate, keep command integrity rules |
| D. VHS tapes | 8 `.tape` files | Remove `mise exec --` from `Type` commands |
| E. Getting-started docs | 5 files | Remove `mise exec --` from examples |
| F. Usage docs | 3 active files | Remove `mise exec --` from examples |
| G. README files | 5 files (ace-support-nav heaviest at 32 hits) | Remove `mise exec --` from examples |
| H. Ruby source | 1 file (worktree_provisioner.rb error message) | Remove `mise exec --` from string |
| I. Ruby tests | 5 files (fixture strings) | Update test expectations |
| J. Workflow instructions | 1 `.wf.md` file | Remove `mise exec --` |
| K. E2E runners | 4 runner.md files | Remove `mise exec --` from commands |

### Explicitly Excluded (Historical Records)

These files are intentionally left unchanged — they document what was true at the time:

- `CHANGELOG.md` files
- `.ace-retros/` retrospective records
- `.ace-ideas/` idea files (including archived)
- `.ace-tasks/_archive/` archived task specs

## Success Criteria

- [ ] `grep -r "mise exec" . --include="*.md" --include="*.rb" --include="*.tape"` returns zero hits outside excluded paths
- [ ] `ace-test-suite` passes (especially provider_syncer_test.rb, status_collector_test.rb, markdown_linter_test.rb, assignment_executor_test.rb)
- [ ] Provider-projected skills match updated canonical sources after `ace-handbook sync`
- [ ] AGENTS.md no longer mandates `mise exec`
- [ ] CLAUDE.md no longer references `mise exec` as required invocation

## Verification Plan

- **Unit:** Test fixtures in 5 test files updated; `ace-test ace-handbook`, `ace-test ace-lint`, `ace-test ace-assign` pass
- **Integration:** `ace-handbook sync` regenerates provider skills without `mise exec`
- **Grep gate:** Zero non-excluded hits for `mise exec` pattern
- **Spot check:** Read 2-3 projected skills to confirm sync propagated changes

## Architecture Decisions

| Decision | Rationale |
|----------|-----------|
| Fix canonical skills first, then sync | Provider projections are generated from canonical — fixing source ensures consistency |
| Single flat task, no subtasks | The change is mechanically uniform text substitution + one re-sync |
| Exclude historical records | CHANGELOGs and retros document past state accurately |

## Out of Scope

- Removing mise from the project entirely (it still manages Ruby/tool versions)
- Changing how `ace-*` commands resolve on PATH
- Modifying the `ace-handbook sync` mechanism itself
- Updating archived tasks or historical records
