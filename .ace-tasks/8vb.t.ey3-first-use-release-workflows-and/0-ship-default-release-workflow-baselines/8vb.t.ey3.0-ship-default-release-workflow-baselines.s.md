---
id: 8vb.t.ey3.0
status: progress
priority: medium
created_at: "2026-08-12 09:58:01"
estimate: TBD
dependencies: []
tags: []
parent: 8vb.t.ey3
bundle:
  presets: [project]
  files: [ace-handbook/handbook/skills/as-release/SKILL.md, ace-handbook/handbook/skills/as-release-bump-version/SKILL.md, ace-handbook/handbook/skills/as-release-update-changelog/SKILL.md, ace-handbook/handbook/skills/as-release-rubygems-publish/SKILL.md, ace-handbook/.ace-defaults/nav/protocols/wfi-sources/ace-handbook.yml, ace-assign/.ace-defaults/assign/catalog/steps/release.step.yml, ace-assign/.ace-defaults/assign/catalog/steps/release-minor.step.yml, ace-bundle/test/feat/workflow_resolution_test.rb, .ace-handbook/workflow-instructions/release/local.wf.md, .ace-handbook/workflow-instructions/release/publish.wf.md]
  commands: [ace-bundle wfi://release/local, ace-bundle wfi://release/bump-version, ace-bundle wfi://release/update-changelog, ace-bundle wfi://release/publish, ace-bundle wfi://release/rubygems-publish]
needs_review: false
---

# Ship default release workflow baselines

## Behavioral Specification

### User Experience

- **Input:** A plain project installs ACE gems that ship release skills / assign release steps, then an agent or human runs `ace-bundle wfi://release/<name>` or `/as-release`.
- **Process:** Baseline release workflows load from the installed gem bundle without requiring the project to author its own `.ace-handbook` release files first.
- **Output:** The agent receives a self-contained, generic release contract that explains local preparation vs publication, defaults to non-publishing behavior, and documents how to override with project-local workflows.

### Expected Behavior

In a project with only installed ACE gems (no project `.ace-handbook` release overlays), these URIs resolve and load:

- `wfi://release/local`
- `wfi://release/bump-version`
- `wfi://release/update-changelog`
- `wfi://release/publish`
- `wfi://release/rubygems-publish`

Baselines are **generic project contracts**, not ACE-monorepo gem-release procedures.

Observable rules:

1. Local preparation versus externally mutating publication is explicit in the workflow text.
2. Default behavior is **non-publishing** until the project supplies a publication contract (placeholders/examples for version surfaces, changelog format, build commands, registries, deploy targets, verification gates).
3. Each workflow is self-contained (does not require running another WFI first).
4. Each workflow explains override via project `handbook/workflow-instructions/` and WFI source priority.
5. ACE monorepo may keep specialized overlays under `.ace-handbook/...` at higher priority without being the only copy in the ecosystem.
6. Assign release steps that reference `wfi://release/publish` resolve without a project-local shim.

### Interface Contract

```bash
bundle exec ace-bundle wfi://release/local
# Expected: prints a loadable workflow path; content is generic + non-publishing by default

bundle exec ace-bundle wfi://release/bump-version
bundle exec ace-bundle wfi://release/update-changelog
bundle exec ace-bundle wfi://release/publish
bundle exec ace-bundle wfi://release/rubygems-publish
# Expected: each resolves from installed gem sources

# Assign release catalog / work-on-task release steps:
# Expected: wfi://release/publish resolves without project-local release WFI files
```

Error Handling:

- An unknown `wfi://release/<missing>` still fails with a clear unresolved-source error.
- If a project registers a higher-priority local override, that override wins over the gem baseline.

Edge Cases:

- `wfi://release/publish` may remain a compatibility entrypoint that points agents at local/prep behavior when no publication contract exists.
- RubyGems-oriented publish guidance may exist as a specialized baseline, but must not mutate registries until the project opts into a publication contract / explicit publish path.
- Monorepo overlays must not be required for plain-project resolution.

## Success Criteria

- Every `wfi://` referenced by distributed release skills and assign release catalog steps resolves from the installed gem bundle.
- Loaded baselines are usable guidance (not empty stubs) and default to non-publishing preparation.
- Package tests prove resolution for the URI set above (extend the existing workflow-resolution feat pattern).
- At least one failure-path test shows a missing WFI URI still fails clearly.

## Consumer Packages

| Package | Role |
|---------|------|
| `ace-handbook` | Ships baseline `handbook/workflow-instructions/release/*.wf.md` via existing `wfi-sources` registration |
| `ace-assign` | Catalog steps `release` / `release-minor` consume `wfi://release/publish` |
| `ace-bundle` | Feat coverage for URI resolution/load (extend `workflow_resolution_test.rb`) |

Monorepo `.ace-handbook/workflow-instructions/release/*` remains a higher-priority specialized overlay and is **not** the shipped baseline copy.

## Validation Questions

- None open. Research-confirmed defaults:
  - Ship home: `ace-handbook/handbook/workflow-instructions/release/` (gem already registers that tree).
  - Today those URIs resolve only via monorepo `.ace-handbook/` overlays; gem tree has no `release/` WFIs yet (#310).
  - Assign keeps catalog refs; baselines are generic contracts, not ACE monorepo release procedures.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Plain installs resolve and load safe default release workflows for all shipped release skill/catalog URIs
- **Advisory size:** Medium
- **Context dependencies:** release skills under `ace-handbook/handbook/skills/as-release*`, assign release catalog steps, `ace-bundle` workflow resolution tests, monorepo `.ace-handbook/workflow-instructions/release/` as override reference only

## Verification Plan

### Unit/Component Validation

- Feat tests assert each required `wfi://release/*` URI resolves against installed/gem-default sources (without project release overlays).
- Resolution evidence must identify the gem handbook path (not monorepo `.ace-handbook/`); isolate or fixture away project overlays when asserting the plain-install contract.
- Assert loaded workflow content distinguishes prep vs publish and defaults to non-publishing.
- Assert missing URI failure remains clear.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Optional: only if cross-gem install proof is needed beyond feat coverage; not required for draft acceptance of the slice intent.

### Failure/Invalid Path Validation

- `ace-bundle wfi://release/does-not-exist` (or equivalent) fails with unresolved error.

### Verification Commands

- `bundle exec ace-bundle wfi://release/local` (and siblings listed in bundle.commands)
- `ace-test` targeting the extended workflow-resolution coverage

## Objective

Ship safe, general-purpose release workflow templates for the URIs already referenced by distributed ACE skills and recipes so first-use projects never hit unresolved release WFIs before receiving customization guidance (#310).

## Scope of Work

- Resolvable baseline WFIs for the URI set above
- Explicit prep vs publish + non-publishing default
- Override documentation inside each baseline
- Automated resolution coverage

## Deliverables

### Behavioral Specifications

- This subtask contract

### Validation Artifacts

- Workflow-resolution tests covering the release URI set

## Out of Scope

- Replacing ACE monorepo-specific release procedures with the generic baseline inside this repo’s day-to-day overlay usage
- Live RubyGems publication as part of this slice
- Quick-start / AGENTS.md documentation (owned by `8vb.t.ey3.1`)

## References

- https://github.com/cs3b/ace/issues/310
- Parent `8vb.t.ey3`
- `../ux-usage.md`
