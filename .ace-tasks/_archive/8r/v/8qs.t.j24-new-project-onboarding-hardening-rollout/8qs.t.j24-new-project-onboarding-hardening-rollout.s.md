---
id: 8qs.t.j24
status: done
priority: high
created_at: "2026-03-29 12:42:22"
estimate: TBD
dependencies: []
tags: [dx, onboarding, orchestrator, docs, ace-support-core, ace-handbook, ace-llm, ace-assign]
bundle:
  presets: [project]
  files: [.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/0-prove-rubygems-dependency-metadata-stays/8qs.t.j24.0-prove-rubygems-dependency-metadata-stays-correct-after.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/1-make-ace-framework-init-generate/8qs.t.j24.1-make-ace-framework-init-generate-valid-generic.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/2-clarify-ace-handbook-sync-completeness/8qs.t.j24.2-clarify-ace-handbook-sync-completeness-and-project.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/3-make-ace-llm-provider-setup/8qs.t.j24.3-make-ace-llm-provider-setup-and-errors.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/4-make-work-on-task-safe/8qs.t.j24.4-make-work-on-task-safe-on-plain.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/5-publish-a-step-by-step/8qs.t.j24.5-publish-a-step-by-step-full-stack.s.md]
  commands: []
needs_review: false
worktree:
  branch: j24-new-project-onboarding-hardening-rollout
  path: ../ace-t.j24
  created_at: "2026-03-29 22:11:46"
  updated_at: "2026-03-29 22:11:46"
  target_branch: main
---

# New-project onboarding hardening rollout

## Objective

Turn the first-run ACE setup experience into a short, working, full-stack onboarding path for normal projects. The rollout should remove hidden monorepo assumptions, make generated bootstrap files valid, explain provider and handbook setup clearly, and ensure `work-on-task` does not fail on plain projects.

## Behavioral Specification

### User Experience

- **Input:** A user starts with a fresh project, adds the ACE full stack to the Gemfile, runs `bundle install`, initializes config with `ace-framework`, syncs agent assets with `ace-handbook`, and begins using ACE in a non-monorepo repository.
- **Process:** The rollout is split into six child tasks: release-metadata proof, scaffold correctness, handbook sync/extensibility, provider UX, assignment safety, and final onboarding docs.
- **Output:** New projects reach a working baseline through one documented path, generated files are valid and generic, provider and handbook setup failures are actionable, and the main assignment preset works without hidden workflow assumptions.

### Expected Behavior

1. The parent task is an orchestrator only and does not own direct implementation details.
2. Child `8qs.t.j24.0` defines the proof/guard story for RubyGems dependency metadata lag after multi-package releases.
3. Child `8qs.t.j24.1` makes `ace-framework init` generate valid generic bootstrap files.
4. Child `8qs.t.j24.2` defines handbook sync completeness and project-extension behavior.
5. Child `8qs.t.j24.3` defines actionable provider error and configuration guidance.
6. Child `8qs.t.j24.4` makes `work-on-task` usable on plain projects and aligns WFI resolution behavior.
7. Child `8qs.t.j24.5` publishes the final step-by-step full-stack onboarding path after the earlier slices settle their behavior.

### Interface Contract

```bash
bundle install
ace-framework init
ace-handbook sync
ace-bundle project
ace-llm --list-providers
ace-assign create --preset work-on-task --task <taskref>
```

```ruby
# Gemfile: the onboarding story must use real gem names, not a nonexistent gem "ace-framework"
# The final docs child defines the blessed full-stack bundle add / Gemfile path.
```

### Error Handling

- If RubyGems metadata lag cannot be eliminated at ACE's layer, the rollout must still define a deterministic proof and mitigation path rather than leaving first-run install behavior ambiguous.
- If any child requires a changed public contract, that contract must be explicit in the child spec and reflected in the final docs child.
- If a slice cannot keep plain-project behavior safe, it is incomplete even if the ACE monorepo still works.

### Edge Cases

- Fresh projects without ACE-monorepo package directories are first-class targets.
- Projects with only a subset of agent integrations installed still need clear sync guidance.
- Provider config may include unsupported names, alias-only names, or inactive providers.
- Project-level `wfi://` sources must behave consistently across `ace-bundle` and `ace-assign`.

## Success Criteria

1. The task tree has exactly six direct children.
2. Each child is a complete behavioral contract for one vertical slice.
3. Child `8qs.t.j24.5` depends on children `8qs.t.j24.0` through `8qs.t.j24.4`.
4. The rollout covers both setup discoverability and runtime safety for plain projects.
5. The source idea is archived after drafting so the task tree becomes the source of truth.

## Validation Questions

- No blocking questions remain.
- The rollout intentionally uses one orchestrator plus six child tasks rather than more granular horizontal tasks.

## Vertical Slice Decomposition (Task/Subtask Model)

**Orchestrator with six child tasks**

- **Child `8qs.t.j24.0`:** prove RubyGems dependency metadata behavior after multi-package releases
- **Child `8qs.t.j24.1`:** make `ace-framework init` scaffolds valid and generic
- **Child `8qs.t.j24.2`:** clarify `ace-handbook sync` completeness and project extension
- **Child `8qs.t.j24.3`:** make `ace-llm` provider setup and errors actionable
- **Child `8qs.t.j24.4`:** make `work-on-task` safe and align `wfi://` resolution
- **Child `8qs.t.j24.5`:** publish the full-stack onboarding docs path
- **Advisory size:** Large
- **Context dependencies:** root docs, scaffold generation, handbook sync, provider config, assignment preset behavior, child specs

## Verification Plan

### Unit/Component Validation

- `ace-task show 8qs.t.j24` reports exactly six direct children.
- `ace-task show 8qs.t.j24.5` shows dependencies on `8qs.t.j24.0` through `8qs.t.j24.4`.

### Integration/E2E Validation

- The six child specs together describe a complete fresh-project onboarding path.
- The final docs child can be implemented without inventing behavior outside the earlier product children.

### Failure/Invalid Path Validation

- No child task invents a new onboarding install path that conflicts with the rollout.
- No child assumes ACE-monorepo-only paths as part of the public onboarding contract.

### Verification Commands

- `ace-task show 8qs.t.j24`
- `ace-task show 8qs.t.j24.0`
- `ace-task show 8qs.t.j24.5`

## Scope of Work

### Included

- Release-proofing for RubyGems metadata lag
- Valid generic scaffolds for `ace-framework init`
- Handbook sync completeness and extension behavior
- Provider error/config guidance
- Assignment preset safety on plain projects
- Final root onboarding docs path

### Out of Scope

- Implementing any child behavior directly in the parent task
- Adding a new minimal-profile onboarding track
- Splitting the rollout into more orchestrator levels

## Deliverables

### Behavioral Specifications

- Parent rollout contract
- Six child vertical-slice specs
- Usage docs for interface-changing child tasks where needed

### Validation Artifacts

- Task tree with explicit dependencies
- Archived source idea `8qsi6p`

## Concept Inventory (Orchestrator Only)

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| release metadata proof/gate | `8qs.t.j24.0` | -- | KEPT |
| valid generic init scaffolds | `8qs.t.j24.1` | -- | KEPT |
| handbook sync completeness | `8qs.t.j24.2` | -- | KEPT |
| actionable provider guidance | `8qs.t.j24.3` | -- | KEPT |
| assignment-safe release workflow resolution | `8qs.t.j24.4` | -- | KEPT |
| full-stack onboarding docs path | `8qs.t.j24.5` | -- | KEPT |

## References

- Source idea: `.ace-ideas/8qsi6p-clarify-and-harden-new-project/8qsi6p-clarify-and-harden-new-project-onboarding-path.idea.s.md`
- Raw feedback attachment: `.ace-ideas/8qsi6p-clarify-and-harden-new-project/raw-feedback.md`
