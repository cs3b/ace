---
id: 8yj.t.cri
status: draft
priority: medium
created_at: "2026-11-20 08:30:35"
estimate: TBD
dependencies: []
tags:
  - docs
  - lab
  - overseer
  - coworker
  - hitl
bundle:
  presets:
    - "project"
  files:
    - "docs/lab-flow.md"
    - "docs/lab-setup.md"
    - "docs/blueprint.md"
    - "docs/tools.md"
    - "ace-lab/README.md"
    - "ace-lab/docs/usage.md"
    - "ace-overseer/README.md"
    - "ace-overseer/docs/usage.md"
    - "ace-coworker/README.md"
    - "ace-coworker/docs/usage.md"
    - "ace-hitl/docs/usage.md"
    - "ace-herdr/README.md"
    - "ace-herdr/docs/usage.md"
    - "ace-assign/README.md"
    - "ace-assign/docs/usage.md"
    - "ace-review/README.md"
    - "ace-git-worktree/README.md"
    - "ace-task/README.md"
    - "ace-git/docs/usage.md"
    - "ace-git/docs/handbook.md"
    - "ace-monorepo-e2e/lab-vm/README.md"
  commands: []
---

# Synchronize lab and package documentation with delivered L2-L10 and 0.31.0

## Behavioral Specification

### User Experience

- **Input**: Operators, developers, and AI agents reading project and package documentation (`docs/lab-flow.md`, `docs/blueprint.md`, package `README.md` and `docs/usage.md` files) or loading context bundles (`ace-bundle project`) when configuring, upgrading, or running the autonomous ACE Lab.
- **Process**: Readers inspect top-level architecture documents and package usage guides to determine which capabilities are available today, what CLI contracts apply (`ace-lab`, `ace-overseer`, `ace-coworker`, `ace-hitl`, `ace-wake`, `ace-herdr`), and which state owners manage each artifact.
- **Output**: Every referenced document accurately describes the delivered capabilities as of the `2026-11-12` release train (`ace-lab 0.16.1`, `ace-overseer 0.31.0`, `ace-coworker 0.10.0`, `ace-hitl 0.27.0`, `ace-wake 0.4.0`, `ace-herdr 0.11.2`), without contradictory September/October banners claiming that delivered L2–L10 waves are "Planned / not available yet".

### Expected Behavior

1. **Cross-cutting architecture and navigation docs (`docs/`)**:
   - `docs/lab-flow.md`: Replace or retire the stale `## Planned Waves L2-L10 (not available yet)` table (lines 172–195), where `L2`, `L3`, `L9`, `L10` are still listed as `Planned` and `L4`, `L6`, `L8` as `Partially shipped`, so it reflects that L2–L10, `8xs.t.pu0`, and `8y0.t.x27` (including live UTM ARM64 acceptance) are shipped.
   - `docs/blueprint.md`: Refresh `last-updated`/`last-checked`, include `ace-lab`, `ace-coworker`, `ace-wake`, and `ace-herdr` in the key gems list, and update `.ace-local/coworker/` from `"reserved L3 coworker configuration"` to the active owner of coworker run configuration and review-round history (`ace-coworker`).
2. **Core autonomous lab package docs (`ace-lab`, `ace-overseer`, `ace-coworker`, `ace-hitl`)**:
   - `ace-lab/README.md` and `ace-lab/docs/usage.md`: Remove the top-level banner claiming L8 (`project add`, `install`, `verify`) is not available yet and that the package only ships `prepare`; summarize delivered `prepare`, `project add`, `install` (locked runtime bundle + extension projection), `verify`, and `auth`.
   - `ace-overseer/README.md` and `ace-overseer/docs/usage.md`: Remove `Planned (L4 / L6 / L7) -- not available yet` callouts; document the current `0.31.0` contract including `ace-overseer start [--scope lab] [--reconcile]` (automatic `ACE_OVERSEER_EYES_CONFIG` arming), explicit `--manager <id>` binding on `work-on` and `handoff`, exact `--report <id>` matching on `process-reports` (and the `process_reports` extension tool), and automatic private manager closure when all declared `metadata.roles` complete.
   - `ace-coworker/README.md` and `ace-coworker/docs/usage.md`: Document all shipped role presets (`worker`, `spec`, `reviewer`, `integrator`, `bootstrap-worker`, `bootstrap-verifier`, `second-captain`), the separation of operational configuration verification from code review, and the execution-evidence / structured failure-receipt flags on `ace-coworker report` (`--commands`, `--artifact`, `--failure-category`, `--failure-command`, `--failure-output`).
   - `ace-hitl/docs/usage.md`: Document atomic decision closure with a lesson (`ace-hitl close <CASE> --lesson-file <PATH>` / `--lesson <TEXT>`) alongside `ace-hitl suggest`, `lesson`, `history`, `apply`, `cancel`, and `sweep`.
3. **Residual `Planned (L2 / L5.5 / L6)` banners across supporting packages**:
   - Remove or update obsolete `> Planned (L2 / L5.5 / L6): ... not available yet` sections in `ace-herdr/README.md`, `ace-herdr/docs/usage.md`, `ace-assign/README.md`, `ace-assign/docs/usage.md`, `ace-review/README.md`, `ace-git-worktree/README.md`, `ace-task/README.md`, `ace-git/docs/usage.md`, `ace-git/docs/handbook.md`, `ace-hitl-hermes/README.md`, `ace-hitl-hermes/docs/usage.md`, `ace-hitl-contract/README.md`, and `ace-runtime/README.md`.
   - Update `ace-monorepo-e2e/lab-vm/README.md` to reflect that the provisioning and fixture flow has been validated live on the UTM ARM64 VM (`8y0.t.x27`).

### Interface Contract

Documentation-only specification synchronizing published CLI and configuration contracts already delivered in code:

```bash
# Overseer start & delegation contract (ace-overseer 0.31.0)
ace-overseer start [--scope project|lab] [--reconcile] [--format table|json]
ace-overseer work-on --task <TASK_ID> --manager <MANAGER_ID> [--runtime herdr] [--format json]
ace-overseer handoff --task <TASK_ID> --manager <MANAGER_ID> [--runtime herdr] [--format json]
ace-overseer process-reports --report <REPORT_ID> --manager <MANAGER_ID> \
  --task <TASK_ID> --role <ROLE> --assignment <ASSIGNMENT_ID> [--json]

# Coworker execution evidence & failure receipt reporting (ace-coworker 0.10.0)
ace-coworker report --result success|error --message <TEXT> \
  [--commands <CMD>...] [--artifact <PATH>...] \
  [--failure-category <CATEGORY> --failure-command <CMD> --failure-output <TEXT>]

# Atomic HITL decision closure with lesson (ace-hitl 0.27.0)
ace-hitl apply <CASE_ID> --ref <MANAGER_ID>
ace-hitl close <CASE_ID> --lesson-file <PATH>
```

Error Handling:
- Stale references to removed L1 commands (`ace-lab service`, `ace-overseer ordinary`, etc.) remain explicitly documented as removed rather than planned.
- Where a capability has a genuine boundary (e.g., `ace-lab` does not own task or assignment state), that boundary remains explicit without falsely marking delivered L2–L10 features as unimplemented.

Edge Cases:
- Historical `CHANGELOG.md` entries that mention `Planned (L2-L10)` as part of past release notes must not be rewritten; only active documentation (`docs/*.md`, `README.md`, `docs/usage.md`, `docs/handbook.md`) is updated.

### Success Criteria

- [ ] Active documentation searches for `Planned \(L[0-9]` or `not available yet` across `docs/`, `ace-*/README.md`, and `ace-*/docs/*.md` return zero stale L2–L10 markers.
- [ ] `docs/lab-flow.md` and `docs/blueprint.md` accurately reflect the current state owners, gem inventory (`ace-lab`, `ace-coworker`, `ace-wake`, `ace-herdr`), and completed L2–L10 / `8y0.t.x27` status.
- [ ] `ace-lab`, `ace-overseer`, `ace-coworker`, and `ace-hitl` README/usage guides match the `2026-11-12` released CLI flags and role catalogs.
- [ ] No runtime code, gem versions, or historical `CHANGELOG.md` entries are modified by this task.

### Validation Questions

- None open — all target interfaces are already shipped and verified in the `2026-11-12` release train (`ace-overseer 0.31.0`, `ace-coworker 0.10.0`, `ace-hitl 0.27.0`, `ace-wake 0.4.0`, `ace-herdr 0.11.2`, `ace-lab 0.16.1`).

### Vertical Slice Decomposition (Task / Subtask Model)

- **Slice type**: Standalone task (documentation-only synchronization across active markdown docs).
- **Slice outcome**: Consistent, current documentation across `docs/` and package `README.md` / `docs/usage.md` files with zero stale L2–L10 `"not available yet"` banners.
- **Advisory size**: Medium (touches ~20 markdown files across monorepo docs and packages, zero code changes).
- **Context dependencies**: Listed in `bundle.files` frontmatter above.

### Verification Plan

#### Unit / Component Validation
- Verify via content search (`bin/ace-search`) that no active `README.md`, `docs/usage.md`, `docs/handbook.md`, `docs/lab-flow.md`, or `docs/blueprint.md` contains stale `Planned (L2`–`L10)` or `not available yet` notices for shipped capabilities.
- Verify that CLI examples in `ace-overseer/docs/usage.md`, `ace-coworker/docs/usage.md`, `ace-hitl/docs/usage.md`, and `ace-lab/docs/usage.md` match the actual `--help` output of `bin/ace-overseer`, `bin/ace-coworker`, `bin/ace-hitl`, and `bin/ace-lab`.

#### Integration / E2E Validation (if cross-boundary behavior exists)
- Run `bin/ace-bundle project` to confirm the updated project bundle (`docs/blueprint.md`, `docs/tools.md`) compresses and loads cleanly.

#### Failure / Invalid-Path Validation
- Ensure historical `CHANGELOG.md` files and `.ace-tasks/` archive records are untouched (`git diff -- '*CHANGELOG.md'` is empty).

#### Verification Commands
- `bin/ace-search "Planned \(L|not available yet" --glob "**/*.md"` (expect matches only in historical `CHANGELOG.md` or archived task specs, zero in active docs)
- `bin/ace-overseer work-on --help`
- `bin/ace-overseer process-reports --help`
- `bin/ace-coworker report --help`
- `bin/ace-hitl close --help`

## Objective

During September–November 2026, waves L2–L10, `8xs.t.pu0`, and `8y0.t.x27` delivered the complete file-based autonomous lab (`ace-lab install/verify/auth`, `ace-overseer start/work-on/handoff/process-reports`, `ace-coworker` role presets and execution evidence gates, `ace-hitl` decision/lesson lifecycle, and `ace-wake` eyes observation). While `docs/tools.md`, `docs/lab-setup.md`, and portions of `docs/lab-flow.md` were updated, ~20 sections across `docs/lab-flow.md`, `docs/blueprint.md`, and package `README.md`/`docs/usage.md` files still retain pre-delivery `Planned (L2–L10) -- not available yet` banners or pre-`0.31.0` CLI examples. Synchronizing these documents prevents both human operators and AI agents from misinterpreting shipped capabilities as unavailable.

## Scope of Work

- **User Experience Scope**: Active project and package markdown documentation (`docs/lab-flow.md`, `docs/blueprint.md`, package `README.md`, `docs/usage.md`, `docs/handbook.md`).
- **System Behavior Scope**: Documentation accuracy and CLI reference alignment with `ace-lab 0.16.1`, `ace-overseer 0.31.0`, `ace-coworker 0.10.0`, `ace-hitl 0.27.0`, `ace-wake 0.4.0`, and `ace-herdr 0.11.2`.
- **Interface Scope**: Documentation of existing CLI flags and configuration schemas only (no new flags or behavior changes).

## Deliverables

### Behavioral Specifications
- Updated `docs/lab-flow.md` and `docs/blueprint.md`.
- Updated `README.md` and `docs/usage.md` for `ace-lab`, `ace-overseer`, `ace-coworker`, and `ace-hitl`.
- Cleaned-up `Planned waves` sections across `ace-herdr`, `ace-assign`, `ace-review`, `ace-git-worktree`, `ace-task`, `ace-git`, `ace-hitl-hermes`, `ace-hitl-contract`, `ace-runtime`, and `ace-monorepo-e2e/lab-vm/README.md`.

### Validation Artifacts
- Clean `bin/ace-search` audit confirming zero stale `Planned (L2–L10)` / `not available yet` markers in active documentation.

## Out of Scope

- Modifying Ruby/JS source code, tests, or gem versions.
- Editing historical `CHANGELOG.md` entries, ADRs (`docs/decisions/`), or completed task/retro files.

## References

- [docs/lab-setup.md](../../docs/lab-setup.md)
- [docs/lab-flow.md](../../docs/lab-flow.md)
- [docs/blueprint.md](../../docs/blueprint.md)
- [docs/tools.md](../../docs/tools.md)
