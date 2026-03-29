---
id: 8qs.t.j24.5
status: pending
priority: high
created_at: "2026-03-29 12:42:29"
estimate: TBD
dependencies: [8qs.t.j24.0, 8qs.t.j24.1, 8qs.t.j24.2, 8qs.t.j24.3, 8qs.t.j24.4]
tags: [docs, readme, quick-start, onboarding, dx]
parent: 8qs.t.j24
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, DEVELOPMENT.md, ace-support-core/ace-support-core.gemspec, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/0-prove-rubygems-dependency-metadata-stays/8qs.t.j24.0-prove-rubygems-dependency-metadata-stays-correct-after.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/1-make-ace-framework-init-generate/8qs.t.j24.1-make-ace-framework-init-generate-valid-generic.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/2-clarify-ace-handbook-sync-completeness/8qs.t.j24.2-clarify-ace-handbook-sync-completeness-and-project.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/3-make-ace-llm-provider-setup/8qs.t.j24.3-make-ace-llm-provider-setup-and-errors.s.md, .ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/4-make-work-on-task-safe/8qs.t.j24.4-make-work-on-task-safe-on-plain.s.md]
  commands: []
needs_review: false
---

# Publish a step-by-step full-stack new-project getting-started path

## Objective

Publish one blessed full-stack onboarding path across root docs. The docs must use one exact curated core gem set, include config initialization with `ace-framework`, sync agent assets with `ace-handbook`, and reflect the verified behavior from the earlier children rather than inventing new setup guidance.

## Behavioral Specification

### User Experience

- **Input:** A new user opens the root docs and wants one step-by-step path to install ACE in a normal project.
- **Process:** The docs provide a full-stack Gemfile or `bundle add` story for development/test, install the exact curated ACE core gem set needed for the workflow, add explicit `ace-handbook-integration-*` gem names for the agent platforms being documented, initialize config, sync agent assets, configure providers, and show first commands to prove the setup works.
- **Output:** README, `docs/quick-start.md`, and `DEVELOPMENT.md` agree on the same onboarding path and no longer leave key steps discoverable only by accident.

### Expected Behavior

1. The docs present one blessed full-stack path, not a minimal/profile matrix.
2. The docs use the exact curated core gem set `ace-support-core`, `ace-bundle`, `ace-handbook`, `ace-llm`, `ace-task`, and `ace-assign`, and must not tell users to add `gem "ace-framework"`.
3. The docs include `bundle install`, `ace-framework init`, and `ace-handbook sync` in the correct order.
4. The docs name explicit `ace-handbook-integration-*` gem(s) for the agent platforms they cover instead of referring to integrations generically.
5. The docs include provider setup and first commands to verify the system is working.
6. If the RubyGems-lag proof child still requires mitigation, the docs include the validated mitigation and when to apply it.

### Interface Contract

```bash
bundle install
ace-framework init
ace-handbook sync
ace-llm --list-providers
ace-bundle project
```

```ruby
# Gemfile / bundle add story uses this exact curated core set:
# - ace-support-core
# - ace-bundle
# - ace-handbook
# - ace-llm
# - ace-task
# - ace-assign
# Docs must also name the exact ace-handbook-integration-* gem(s) for the agent platforms they cover.
# `ace-framework` is documented as an executable from `ace-support-core`, not as a gem.
```

### Error Handling

- If the docs recommend a nonexistent gem name or omit required setup steps, the task is incomplete.
- If the docs disagree across README, quick-start, and DEVELOPMENT, the task is incomplete.

### Edge Cases

- Users installing immediately after a release when RubyGems lag mitigation may still apply
- Users only interested in the default documented agent sync path
- Projects that are not ACE monorepos and do not start with handbook assets

## Success Criteria

1. README, `docs/quick-start.md`, and `DEVELOPMENT.md` agree on one full-stack setup path.
2. The path uses the exact curated core gem set and correct command ordering.
3. The path includes explicit agent integration gem names for the platforms it covers.
4. The path includes config init, handbook sync, provider setup, and first-use commands.
5. The docs are derived from children `8qs.t.j24.0` through `8qs.t.j24.4`, not independent guesses.

## Validation Questions

- No blocking questions remain.
- The docs intentionally prefer one full-stack path over a minimal-profile matrix.

## Vertical Slice Decomposition (Task/Subtask Model)

**Single standalone task**

- **Slice:** root onboarding docs aligned to verified product behavior
- **Advisory size:** Small-Medium
- **Context dependencies:** root docs, real gem ownership, child task contracts

## Verification Plan

### Unit/Component Validation

- The three docs surfaces present the same ordered onboarding path.
- The install snippet uses real gem names.

### Integration/E2E Validation

- A new user can follow the docs from install through first working commands.
- The docs are consistent with the scaffold, handbook, provider, and assignment children.

### Failure/Invalid Path Validation

- Divergent docs guidance is failure.
- Reintroducing undocumented magic steps is failure.

### Verification Commands

- `bundle install`
- `ace-framework init`
- `ace-handbook sync`
- `ace-llm --list-providers`
- `ace-bundle project`

## Scope of Work

### Included

- Root README onboarding path
- Quick-start onboarding path
- DEVELOPMENT onboarding alignment
- Full-stack install story

### Out of Scope

- A second minimal-install track
- Package-specific docs beyond what the onboarding path needs

## Deliverables

### Behavioral Specifications

- Full-stack onboarding docs contract
- Cross-doc consistency contract

### Validation Artifacts

- One documented install/init/sync/use scenario
- Consistent docs across the three root surfaces

## References

- Parent task: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/8qs.t.j24-new-project-onboarding-hardening-rollout.s.md`
- Child inputs: `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/0-prove-rubygems-dependency-metadata-stays/8qs.t.j24.0-prove-rubygems-dependency-metadata-stays-correct-after.s.md`, `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/1-make-ace-framework-init-generate/8qs.t.j24.1-make-ace-framework-init-generate-valid-generic.s.md`, `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/2-clarify-ace-handbook-sync-completeness/8qs.t.j24.2-clarify-ace-handbook-sync-completeness-and-project.s.md`, `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/3-make-ace-llm-provider-setup/8qs.t.j24.3-make-ace-llm-provider-setup-and-errors.s.md`, `.ace-tasks/8qs.t.j24-new-project-onboarding-hardening-rollout/4-make-work-on-task-safe/8qs.t.j24.4-make-work-on-task-safe-on-plain.s.md`
