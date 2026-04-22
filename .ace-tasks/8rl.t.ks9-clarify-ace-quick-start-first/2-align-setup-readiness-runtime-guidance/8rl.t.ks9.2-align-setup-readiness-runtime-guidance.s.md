---
id: 8rl.t.ks9.2
status: draft
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: ["project"]
  files:
    - README.md
    - docs/quick-start.md
    - ace-support-config/README.md
    - ace-support-config/docs/usage.md
    - ace-llm/docs/usage.md
    - .ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/2-add-setup-readiness-doctor/8rl.t.k5a.2-add-setup-readiness-doctor.s.md
    - .ace-tasks/8rl.t.ks9-clarify-ace-quick-start-first/ux-usage.md
  commands:
    - ace-task show 8rl.t.ks9.2 --content
tags: []
parent: 8rl.t.ks9
created_at: "2026-04-22 13:51:35"
---

# Align setup readiness runtime guidance

## Behavioral Specification

### User Experience

- Input: A user runs provider discovery and wants to know whether ACE is actually ready to execute configured setup workflows.
- Process: The docs explain the difference between provider discovery and setup readiness, then point to the setup doctor contract owned by `8rl.t.k5a.2`.
- Output: The user has one documented readiness command and understands which failures are blockers versus actionable setup warnings.

### Expected Behavior

Quick-start docs should not imply that `ace-llm --list-providers` proves a configured role can complete a prompt. Provider discovery should remain the inventory command. Setup readiness should be documented as `bundle exec ace-config doctor`, aligned with the runtime contract in `8rl.t.k5a.2`.

This subtask should not redefine the doctor implementation. It should ensure the first-use docs describe the readiness model accurately and link runtime expectations to the existing task.

### Interface Contract

```bash
bundle exec ace-llm --list-providers
bundle exec ace-config doctor
bundle exec ace-config doctor --no-probe
bundle exec ace-config doctor --json
```

Expected docs behavior:

- `ace-llm --list-providers` lists available providers and setup hints.
- `ace-config doctor` validates setup readiness, including generated files, ignored local artifacts, bundled gems, and provider execution readiness once implemented by `8rl.t.k5a.2`.
- `--no-probe` is the documented path for users who do not want live prompt probes during setup checks.

Error Handling:

- Missing provider packages should direct users to the setup mode install lists.
- Missing credentials or local CLI account access should be described as provider readiness issues, not ACE install corruption.
- Users who choose API-only setup should not be blocked by inactive unrelated CLI providers.

Edge Cases:

- If `ace-config doctor` is not yet implemented when docs are updated, docs should frame it as part of the coordinated setup-readiness change rather than claiming current availability prematurely.
- If issue #298 lands first, this task should adopt its final doctor command wording and status categories.

## Success Criteria

- Quick-start docs explain provider discovery versus provider readiness.
- Quick-start docs include `bundle exec ace-config doctor` as the setup readiness command.
- Setup doctor documentation references generated files, ignored local artifacts, bundled gems, and provider execution readiness.
- The wording remains consistent with `8rl.t.k5a.2` and does not create a second runtime contract.

## Validation Questions

- None. Issue #299 requests setup doctor documentation, while issue #298 owns runtime doctor behavior.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: users know how to diagnose first-use setup readiness and how that differs from provider listing.
- Advisory size: medium.
- Context dependencies: quick-start docs, config docs, LLM usage docs, related #298 setup doctor task.

## Verification Plan

### Unit/Component Validation

- Documentation checks confirm discovery and readiness commands are both present and described distinctly.

### Integration/E2E Validation

- Fresh-repo walkthrough records provider discovery followed by setup readiness validation.

### Failure/Invalid Path Validation

- Missing credentials, missing provider package, and `--no-probe` flows are documented with actionable user-facing outcomes.

### Verification Commands

- `ace-lint README.md docs/quick-start.md ace-support-config/docs/usage.md ace-llm/docs/usage.md`
- `ace-test ace-support-config`

## Objective

Prevent first-time users from confusing provider inventory with proof that configured ACE roles and models can execute.

## Scope of Work

- Documentation and coordination with the existing setup doctor task.
- No independent doctor implementation in this subtask unless `8rl.t.k5a.2` is explicitly folded into this task later.

## Deliverables

### Behavioral Specifications

- Provider discovery versus readiness documentation contract.

### Validation Artifacts

- Setup readiness scenario in `ux-usage.md`.

## Out of Scope

- Duplicating or superseding `8rl.t.k5a.2`.
- Live provider credential provisioning.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/299
- Related runtime task: `8rl.t.k5a.2`
