---
id: 8qs.t.j24.0
status: draft
priority: high
created_at: "2026-03-29 12:42:28"
estimate: TBD
dependencies: []
tags: [release, rubygems, dx, proof]
parent: 8qs.t.j24
bundle:
  presets: [project]
  files:
    - ace-handbook/handbook/workflow-instructions/release/rubygems-publish.wf.md
    - ace-handbook/handbook/workflow-instructions/release/publish.wf.md
    - ace-handbook/handbook/skills/as-release-rubygems-publish/SKILL.md
    - ace-handbook/README.md
    - Gemfile.lock
  commands: []
---

# Prove RubyGems dependency metadata stays correct after ACE multi-package releases

## Objective

Convert the known RubyGems lag issue into a deterministic ACE proof/gate. ACE does not need to pretend the lag never happens; it needs a reproducible way to prove when dependency metadata is safe and to tell users when `bundle install --full-index` is still required because RubyGems has not caught up.

## Behavioral Specification

### User Experience

- **Input:** A maintainer publishes many ACE gems or a user installs the full ACE stack in a fresh project immediately after a release.
- **Process:** ACE provides a release-validation story that checks whether published dependency metadata is visible correctly through normal install behavior, and distinguishes temporary RubyGems lag from actual ACE packaging errors.
- **Output:** Maintainers have proof that a release is safe or a concrete signal that RubyGems lag is still present; users are not left guessing whether install failures are expected, transient, or caused by bad ACE metadata.

### Expected Behavior

1. ACE defines a reproducible post-release validation flow for multi-package dependency metadata.
2. The proof is scoped to the many-package release case, not just one gem.
3. The result clearly distinguishes external index lag from broken ACE release metadata.
4. If lag remains possible, ACE documents the mitigation and when it should be applied.
5. The proof is strong enough that future large releases can be checked before claiming the onboarding path is stable.

### Interface Contract

```bash
# Representative release proof flow
bundle install
bundle install --full-index
```

```text
Normal install path is safe
# or
RubyGems metadata lag detected; use the documented mitigation until the registry catches up
```

### Error Handling

- If the proof cannot distinguish lag from broken metadata, the task is incomplete.
- If the only valid mitigation is `--full-index`, that must be presented as a deliberate and validated fallback, not tribal knowledge.

### Edge Cases

- Releases touching dozens of gems at once
- Users installing immediately after release publication
- Partial registry propagation where some gem dependency graphs are fresh and others are stale

## Success Criteria

1. ACE has one reproducible verification story for post-release dependency metadata.
2. The verification covers the full-stack install case.
3. The task does not promise a RubyGems-side fix; it promises proof and clear mitigation.
4. The outcome is usable by child `8qs.t.j24.5` when writing onboarding docs.

## Validation Questions

- No blocking questions remain.
- The root cause is treated as RubyGems lag until the proof says otherwise.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** release proof, detection contract, user-facing mitigation contract
- **Advisory size:** Small-Medium
- **Context dependencies:** release workflows, package publish behavior, install guidance

## Verification Plan

### Unit/Component Validation

- The proof defines what counts as a successful metadata propagation result.
- The proof defines what counts as a lag result.

### Integration/E2E Validation

- Fresh install immediately after a multi-package release has an explicit expected outcome.
- The validation story can be repeated on future releases.

### Failure/Invalid Path Validation

- A release cannot be called “safe for onboarding docs” without proof.
- The task must not collapse “lag” and “broken metadata” into one generic failure.

### Verification Commands

- `bundle install`
- `bundle install --full-index`

## Scope of Work

### Included

- Post-release proof/gate definition
- Clear mitigation contract if lag persists
- Input for onboarding docs

### Out of Scope

- Changing RubyGems behavior
- Rewriting package dependency architecture unrelated to the lag proof

## Deliverables

### Behavioral Specifications

- Post-release verification contract
- Lag-vs-broken-metadata decision contract

### Validation Artifacts

- Reproducible release-proof scenario
- Clear documentation input for onboarding guidance

## References

- Parent task: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/8qs.t.j24-new-project-onboarding-hardening-rollout.s.md`
- Source feedback: `.ace-ideas/8qsi6p-clarify-and-harden-new-project/raw-feedback.md`
