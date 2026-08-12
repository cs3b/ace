---
id: 8vb.t.ey3
status: pending
priority: medium
created_at: "2026-08-12 09:57:53"
estimate: TBD
dependencies: []
tags: []
github_issue: 310
bundle:
  presets: [project]
  files: [docs/quick-start.md, docs/tools.md, ace-handbook/handbook/skills/as-release/SKILL.md, ace-bundle/test/feat/workflow_resolution_test.rb]
  commands: [ace-bundle wfi://release/local, ace-task show 8vb.t.ey3]
needs_review: false
---

# First-use release workflows and agent setup

## Behavioral Specification

### User Experience

- **Input:** A developer installs the ACE handbook/assign stack in a plain project (no monorepo-local release overlays) and follows first-use setup docs; an agent or human later invokes release skills such as `/as-release`.
- **Process:** Default release workflows resolve from the installed gem bundle. Quick-start steers setup through `.agents/skills/` and root `AGENTS.md` without treating harness-native trees as the primary path.
- **Output:** Release skills load usable baseline workflows; setup docs produce a clean agents-first project without unresolved `wfi://release/*` URIs or harness-first noise.

### Expected Behavior

A new project that installs the handbook/assign stack can:

1. Invoke distributed release skills and assign release steps without unresolved workflow URIs.
2. Complete first-use setup with `.agents/skills/` and `AGENTS.md` as the default agent surface.
3. Optionally consult a separate harness document for Claude/Codex/etc. projections—without needing that document for the default path.

Parent owns the umbrella outcome only. Concrete capabilities live in child subtasks.

### Interface Contract

```bash
# After installing ACE gems (no project .ace-handbook/release overlays):
bundle exec ace-bundle wfi://release/local
# Expected: resolves and loads a baseline workflow (non-publishing by default)

bundle exec ace-handbook sync
# Expected: skills under .agents/skills/ including as-release*

# Quick-start default path documents:
# sync ace-support-core → AGENTS.md (+ docs/tools.md)
# ace-handbook sync → .agents/skills/
```

Error Handling:

- Missing release URI still fails clearly with a resolvable-error message (not silent skip).
- Projects that already customize release workflows via higher-priority local sources keep those overrides.

Edge Cases:

- ACE monorepo may keep specialized release overlays that override gem baselines; plain projects must not depend on those overlays.
- Assign catalog steps that reference `wfi://release/publish` must resolve in plain installs.

## Success Criteria

- Plain-install projects resolve every `wfi://release/*` URI referenced by distributed release skills and assign release catalog steps.
- Quick-start default path is agents-first (`AGENTS.md` + `.agents/skills/`); other harness setup is optional and separate.
- Linked GitHub issue #310 tracks this parent task after github-sync.

## Validation Questions

- None open for drafting. Research-confirmed defaults:
  - Baselines ship under `ace-handbook/handbook/workflow-instructions/release/` (currently absent; monorepo `.ace-handbook/` overlays are the only resolvers today).
  - Docs deepen is in-scope as subtask `.1` (`docs/agent-harnesses.md` + agents-first quick-start).
  - URI set matches shipped skills + assign catalog: `local`, `bump-version`, `update-changelog`, `publish`, `rubygems-publish`.

## Vertical Slice Decomposition Task/Subtask Model

| Slice | Ref | Outcome | Size |
|-------|-----|---------|------|
| Orchestrator | `8vb.t.ey3` | First-use release + agent setup works out of the box | medium |
| Subtask | `8vb.t.ey3.0` | Default release WFIs resolve from installed gems | medium |
| Subtask | `8vb.t.ey3.1` | Quick-start defaults to AGENTS.md + `.agents/` | small–medium |

## Verification Plan

### Unit/Component Validation

- Covered by child verification plans.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Parent success = both children pass their verification plans.

### Failure/Invalid Path Validation

- Covered by children (unresolved URI remains a clear failure when intentionally absent).

### Verification Commands

- `ace-task show 8vb.t.ey3`
- Child-specific `ace-test` / doc review commands listed on children

## Objective

Close the gap where shipped release skills and assign recipes point at `wfi://release/*` URIs that do not resolve in a standard installed bundle (#310), and make first-use documentation present `.agents/` + `AGENTS.md` as the default setup path.

## Scope of Work

- User experience: first-use install, release skill invocation, quick-start reading path
- System behavior: resolvable baseline release workflows; agents-first setup docs
- Interface scope: `ace-bundle wfi://release/*`, handbook sync to `.agents/skills/`, quick-start (+ separate harness doc)

## Deliverables

### Behavioral Specifications

- Parent umbrella contract (this file)
- Child specs for release WFI baselines and quick-start reorientation

### Validation Artifacts

- Feat-level WFI resolution coverage (child `.0`)
- Doc review checklist for quick-start / harness split (child `.1`)

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
|---------|---------------|------------|--------|
| Gem-shipped generic release WFI baselines | `8vb.t.ey3.0` | — | KEPT |
| Non-publishing default until publication contract | `8vb.t.ey3.0` | — | KEPT |
| Agents-first quick-start default path | `8vb.t.ey3.1` | — | KEPT |
| Separate optional harness doc | `8vb.t.ey3.1` | — | KEPT |

## Out of Scope

- Publishing ACE gems to RubyGems as part of this task’s verification
- Rewriting ACE monorepo-specific release overlays into the only shipped copy
- Implementing package code during draft (specs only)

## References

- https://github.com/cs3b/ace/issues/310
- `docs/quick-start.md`
- `ux-usage.md` (draft usage scenarios)
