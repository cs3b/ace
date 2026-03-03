---
id: 8o0000
title: ace-config Migration Gaps
type: self-review
tags: []
created_at: '2026-01-01 00:00:00'
status: done
source: taskflow:v.0.9.0
migrated_from: ".ace-taskflow/v.0.9.0/retros/8o0000-ace-config-migration-gaps.md"
---

# Reflection: ace-config Migration Gaps

**Date**: 2026-01-01
**Context**: Post-audit analysis of why Task 157 (ace-config extraction) missed hardcoded values across 8 gems
**Author**: Claude Code + Human Review
**Type**: Self-Review

## What Went Well

- Successfully extracted ace-config from ace-support-core (Tasks 157.01-157.06)
- Created comprehensive documentation and migration guide (Task 157.11)
- Renamed .ace.example/ to .ace-defaults/ across all 19 gems (Task 157.08)
- Migrated 16 packages to use new `Ace::Config.create()` API (Task 157.09)
- Added useful new methods: `resolve_namespace()`, `Config.wrap()`, `Config.merge()`

## What Could Be Improved

- **Incomplete Scope Definition**: Task 157 focused on "extracting ace-config" but didn't include auditing all gems for hardcoded values that should be configurable
- **Missing Verification Step**: No subtask to verify all gems properly use their `.ace-defaults/` configs
- **Depth vs Breadth Trade-off**: Migration focused on API changes (breadth) rather than ensuring each gem fully leverages config (depth)

## Key Learnings

### Root Cause Analysis: Why Gaps Were Missed

1. **Task Scope Was Too Narrow**
   - Task 157 was scoped as "Extract ace-config Gem" - focused on extraction mechanics
   - Didn't include "Ensure all user-configurable values are in .ace-defaults"
   - Subtask 157.09 "Migrate ace-* Gems" only updated `require` statements and API calls

2. **No Compliance Audit in Original Plan**
   - ADR-022 defines the pattern: "All user-configurable values should be in .ace-defaults"
   - But Task 157 didn't include a subtask to audit compliance with this principle
   - Assumed existing gems already followed the pattern - they didn't

3. **Incremental Migration vs Full Migration**
   - Tasks 157.01-157.17 were incremental: extract, rename, update API
   - Each subtask passed its acceptance criteria
   - But the sum of passing subtasks ≠ complete migration

4. **Missing "Definition of Done" for Config Migration**
   - No checklist item: "All hardcoded timeouts, paths, limits are now configurable"
   - No checklist item: "All config values in .ace-defaults are actually read by code"
   - No verification that config files are loaded (ace-nav had config but didn't load it)

## Action Items

### Stop Doing

- Assuming existing code follows patterns just because it uses the right library
- Scoping extraction tasks without compliance verification subtasks
- Marking migrations "complete" without post-migration audit

### Continue Doing

- Breaking large tasks into subtasks with clear acceptance criteria
- Creating comprehensive documentation (the migration guide was good)
- Using orchestrator tasks to group related work

### Start Doing

- **Add Audit Subtask**: Every migration task should include a final "audit compliance" subtask
- **Use Explore Agents**: Before marking extraction complete, run codebase-wide search for violations
- **Define "Done" Explicitly**: Include in orchestrator task: "All hardcoded values that should be configurable are now in .ace-defaults"
- **Post-Migration Checklist**:
  1. Every .ace-defaults/*.yml file is actually loaded by its gem
  2. Every DEFAULT_* constant in code has corresponding config entry
  3. Every hardcoded timeout/path/limit is now configurable
  4. Every gem has reset_config! for test isolation

## Technical Details

### Gaps Found in Audit (Tasks 157.18-157.25)

| Gem | Issue | Why Missed |
|-----|-------|------------|
| ace-docs | DocumentRegistry uses manual YAML loading | Code predates ace-config, wasn't touched in migration |
| ace-nav | Config file exists but not loaded | File was renamed but no code changes |
| ace-git-worktree | 5 files with duplicate timeouts | Not in scope of API migration |
| ace-prompt | 4 hardcoded cache paths | Paths are "internal" so weren't considered |
| ace-search | Timeout hardcoded in executors | Timeout not seen as user-configurable |
| ace-review | execute_simple ignores config | Method was considered "internal" |
| ace-context | No config.yml at all | Only has presets, not settings |
| ace-support-core | Hardcoded timeouts/limits | Core lib, assumed "stable" |

### Pattern: What Gets Missed

1. **"Internal" code paths** - Config migration focused on public API, not internal constants
2. **Existing code that "works"** - If code runs, it's assumed correct
3. **Files created but not wired** - .ace-defaults/ files created but never required

## Process Improvement Proposal

### Add to Orchestrator Task Template

```markdown
## Final Subtask: Compliance Audit

### Verify Migration Complete
- [ ] Run codebase search for remaining violations
- [ ] Every config file in .ace-defaults is loaded
- [ ] Every DEFAULT_* constant has config alternative
- [ ] Every hardcoded value that should be configurable is now configurable
- [ ] Run tests to verify config loading works
```

### Tool Enhancement: `ace-audit config-compliance`

Proposed CLI command to automatically check:
- Gems with .ace-defaults that don't load config
- DEFAULT_* constants in code
- Hardcoded paths, timeouts, limits
- Missing reset_config! methods

## Additional Context

- Original Task 157: Extract ace-config Gem from ace-support-core (Orchestrator)
- Audit performed: 2026-01-01
- New subtasks created: 157.18-157.25 (8 tasks, ~13h estimated)
- Related ADR: ADR-022 Configuration Default and Override Pattern