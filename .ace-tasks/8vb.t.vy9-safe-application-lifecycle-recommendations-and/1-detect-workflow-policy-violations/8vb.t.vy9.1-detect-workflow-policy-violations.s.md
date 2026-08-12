---
id: 8vb.t.vy9.1
status: draft
priority: high
created_at: "2026-08-12 21:18:17"
estimate: TBD
dependencies: [8vb.t.vy9.0]
tags: [doctor, policy, workflows, lifecycle]
parent: 8vb.t.vy9
bundle:
  presets: [project]
  files: [ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb, ace-git-worktree/.ace-defaults/git/worktree.yml, ace-git-worktree/lib/ace/git/worktree/models/worktree_config.rb, ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-task/handbook/workflow-instructions/task/work.wf.md, ace-review/.ace-defaults/review/config.yml, ace-handbook/.ace-defaults/handbook/providers/agents.yml, ace-support-core/.ace-defaults/project-root/AGENTS.md]
  commands: [ace-config doctor --no-probe --json, ace-bundle wfi://task/work, ace-bundle wfi://assign/drive, ace-handbook status]
---

# Detect workflow policy violations

## Behavioral Specification

### User Experience

- **Input:** A developer runs recommendations for a selected profile from the repository root, a nested directory, or a linked worktree.
- **Process:** ACE inspects only installed and profile-required capabilities, resolves effective values and sources, and checks their lifecycle semantics.
- **Output:** Findings identify unsafe behavior and the owning package/config source, while intentional ACE-development breadth is accepted under its profile.

### Expected Behavior

The `application` profile checks repository-local/common-root worktrees, checkout-only creation, one task per sequential delivery, single completion ownership, verified draft-PR timing, executed provider-neutral review, blocking feedback disposition, post-change verification, leased rewritten-history pushes, final PR refresh, compact guidance, neutral skill projection, and resolvable bundle declarations.

The `minimal` profile checks only quick-start capabilities. The `ace-development` profile accepts intentional batch, fork, release, demo, and retrospective behavior without reporting application drift.

### Interface Contract

```bash
ace-config doctor --recommendations --profile application [--json] [--strict]
ace-config doctor --recommendations --profile ace-development
```

Error Handling:

- An unreadable installed workflow or unresolved declared bundle source produces an attributable finding, not a crash.
- A missing optional package is ignored unless the selected profile requires its capability.
- Root discovery failure reports the attempted location and does not silently assess the wrong checkout.

Edge Cases:

- Root, nested-directory, primary-worktree, and linked-worktree invocations produce equivalent logical findings.
- Project overrides are evaluated as intentional current values; mere difference from package defaults is not automatically unhealthy.
- Provider session preparation without a produced review report never satisfies the review gate.

## Success Criteria

- Application fixtures detect unsafe worktree, assignment, completion, review, verification, guidance, projection, and bundle behavior.
- Minimal fixtures receive no full-stack warnings.
- ACE-development fixtures accept the current broad development pipeline.
- Findings are identical across logical invocation locations and cite current value, source, evidence, and next action.
- Important review findings remain blocking until applied, resolved, or explicitly waived with evidence.

## Validation Questions

- None open. Capability absence is a finding only when required by the selected profile.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Orchestrator subtask
- **Slice outcome:** Projects receive semantic policy findings rather than raw config diffs
- **Advisory size:** Large
- **Context dependencies:** Recommendation finding contract, package defaults, workflow resources, config-source discovery

## Verification Plan

### Unit/Component Validation

- Verify each policy check against safe, unsafe, unavailable, overridden, and package-owned inputs.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Run minimal, application, and ACE-development fixtures from root, nested, and linked-worktree locations.

### Failure/Invalid Path Validation

- Unresolved sources, malformed workflows, non-executed reviews, and incorrect common-root resolution create stable findings without mutation.

### Verification Commands

- `ace-test ace-support-config all`
- `ace-test-suite --target fast`

## Objective

Turn lifecycle recommendations into actionable semantic checks that understand profile intent and effective package/project policy.

## Scope of Work

- Profile-scoped policy inventory
- Common-root and source-layer evidence
- Application safety and ACE-development exception semantics
- Guidance, projection, and bundle resolution checks

## Deliverables

### Behavioral Specifications

- Check families and profile behavior defined here

### Validation Artifacts

- Safe/unsafe profile fixtures and location-equivalence evidence

## Out of Scope

- Changing the unsafe defaults (`8vb.t.vy9.2`)
- Bootstrap-specific policy from issue #313
- Rewriting project workflow files

## References

- https://github.com/cs3b/ace/issues/311
- Parent `8vb.t.vy9`
- Dependency `8vb.t.vy9.0`
- `../ux-usage.md`
