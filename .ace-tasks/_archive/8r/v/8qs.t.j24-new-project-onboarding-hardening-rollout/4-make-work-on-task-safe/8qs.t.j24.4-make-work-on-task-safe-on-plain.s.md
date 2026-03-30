---
id: 8qs.t.j24.4
status: done
priority: high
created_at: "2026-03-29 12:42:29"
estimate: TBD
dependencies: []
tags: [ace-assign, workflow, nav, dx]
parent: 8qs.t.j24
bundle:
  presets: [project]
  files: [ace-assign/.ace-defaults/assign/presets/work-on-task.yml, ace-assign/.ace-defaults/assign/catalog/steps/release-minor.step.yml, ace-assign/lib/ace/assign/molecules/skill_assign_source_resolver.rb, ace-assign/handbook/workflow-instructions/assign/create.wf.md, ace-assign/handbook/workflow-instructions/assign/prepare.wf.md, ace-assign/README.md]
  commands: []
needs_review: false
---

# Make work-on-task safe on plain projects and align assign-source WFI resolution

## Objective

`ace-assign create --preset work-on-task` must work in a normal project without hidden unreleased workflow assumptions. Release-related assignment steps need a shipped generic path, and `wfi://` resolution must behave consistently across `ace-bundle` and `ace-assign`.

## Behavioral Specification

### User Experience

- **Input:** A user in a normal project runs `ace-assign create --preset work-on-task --task <taskref>` after documented setup.
- **Process:** ACE expands assignment steps, including release-related steps, using shipped/default workflows and registered project protocol sources.
- **Output:** The assignment is created successfully without requiring the user to hand-create `release/publish.wf.md` in special hidden paths.

### Expected Behavior

1. The `work-on-task` preset is usable in a plain project after documented setup.
2. Release-related steps have a shipped generic workflow path or equivalent safe default.
3. `assign.source` WFI resolution honors the same registered `wfi-sources` model used by nav/bundle resolution.
4. A project-level registered `wfi://` source can satisfy `ace-assign` step expansion.
5. Release-step absence is handled deliberately, not through opaque resolution failure.

### Interface Contract

```bash
ace-assign create --preset work-on-task --task <taskref>
ace-bundle wfi://release/publish
```

```text
Assignment creation succeeds in a plain project with the documented setup.
```

### Error Handling

- If `work-on-task` still fails because `wfi://release/publish` is missing by default, the task is incomplete.
- If `ace-bundle` can resolve a project-level `wfi://` source but `ace-assign` cannot, the task is incomplete.

### Edge Cases

- Non-gem projects with project-level workflow overrides
- Projects that intentionally customize release behavior through `wfi://` sources
- Projects that use the default generic release workflow without package-publish behavior

## Success Criteria

1. `ace-assign create --preset work-on-task --task <taskref>` works in a plain project after documented setup.
2. `wfi://release/publish` has a generic shipped/default path or equally safe default behavior.
3. `ace-assign` and `ace-bundle` no longer disagree on project-level `wfi://` resolution.
4. This child provides stable input to the final onboarding docs child.

## Validation Questions

- No blocking questions remain.
- The resolution model should align with registered nav sources rather than a parallel hidden search model.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** assignment preset safety, generic release workflow availability, WFI resolution consistency
- **Advisory size:** Medium
- **Context dependencies:** assignment preset, release step catalog, resolver behavior, nav sources

## Verification Plan

### Unit/Component Validation

- Assignment source resolution accepts project-level registered `wfi://` sources.
- Default release workflow resolution no longer fails on plain projects.

### Integration/E2E Validation

- Plain-project assignment creation works end-to-end with the documented setup.
- Project-level workflow overrides resolve consistently across bundle and assign flows.

### Failure/Invalid Path Validation

- Hidden required workflow paths are failure.
- Divergent resolver behavior between tools is failure.

### Verification Commands

- `ace-assign create --preset work-on-task --task <taskref>`
- `ace-bundle wfi://release/publish`

## Scope of Work

### Included

- Assignment preset safety for plain projects
- Generic release workflow availability
- WFI resolution consistency with nav sources

### Out of Scope

- Redesigning the entire assignment preset system
- Removing release handling from work-on-task entirely

## Deliverables

### Behavioral Specifications

- Plain-project assignment creation contract
- WFI resolution consistency contract

### Validation Artifacts

- Plain-project creation scenario
- Project-level override scenario

## References

- Usage doc: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/4-make-work-on-task-safe/ux-usage.md`
- Parent task: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/8qs.t.j24-new-project-onboarding-hardening-rollout.s.md`
