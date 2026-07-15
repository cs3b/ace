---
id: 8ue.t.bo8
status: in-progress
priority: medium
created_at: "2026-07-15 07:46:55"
estimate: TBD
dependencies: []
tags: [handbook, skills, agents, projection]
github_issue: 307
bundle:
  presets: [project]
  files: [ace-handbook/.ace-defaults/handbook/providers/agents.yml, ace-handbook/docs/usage.md, ace-handbook/lib/ace/handbook/atoms/provider_registry.rb, ace-handbook/lib/ace/handbook/organisms/skill_inventory.rb, ace-handbook/lib/ace/handbook/molecules/skill_projection.rb, ace-handbook/lib/ace/handbook/organisms/provider_syncer.rb, ace-handbook/lib/ace/handbook/organisms/status_collector.rb, ace-handbook/test/fast/organisms/skill_inventory_test.rb, ace-handbook/test/fast/organisms/provider_syncer_test.rb, ace-handbook/test/fast/organisms/status_collector_test.rb, ace-handbook/test/e2e/TS-HANDBOOK-002-sync-behavior/scenario.yml, ace-handbook/test/e2e/TS-HANDBOOK-002-sync-behavior/TC-003-default-agents-projection.verify.md, .ace-tasks/8ue.t.bo8-align-agents-projection-with-canonical/ux/usage.md]
  commands: [ace-task show 8ue.t.bo8 --content, ace-handbook sync, ace-handbook status, ace-handbook status --format json, ace-handbook sync --provider codex, ace-test ace-handbook, ace-test-e2e ace-handbook TS-HANDBOOK-002]
needs_review: false
worktree:
  branch: bo8-align-agents-projection-with-canonical-inventory
  path: ../ace-t.bo8
  created_at: "2026-07-15 09:54:15"
  updated_at: "2026-07-15 09:54:15"
  target_branch: main
---

# Align agents projection with canonical inventory

## Behavioral Specification

### User Experience

- **Input:** A developer or agent installs the ACE handbook skill sources and runs the documented default `ace-handbook sync`.
- **Process:** ACE treats the neutral `agents` provider as the default projection for common ACE workflow skills. It includes skills compatible with the documented default policy, including legacy full-provider targets, while keeping intentionally narrow provider-specific skills scoped. Sync and status evaluate the same effective expected set and report its coverage against the canonical inventory.
- **Output:** `.agents/skills/` contains the effective expected skills, including `as-git-commit`, and `ace-handbook status` explains when the projection is curated instead of reporting a falsely complete canonical projection.

### Expected Behavior

1. A default sync projects every skill in the documented effective `agents` policy into `.agents/skills/`, including skills whose metadata targets the legacy full provider set (`claude`, `codex`, `gemini`, `opencode`, and `pi`).
2. Intentionally narrow provider-specific targets remain excluded from the neutral projection unless they explicitly opt into `agents`; explicit provider sync continues to honor those narrow targets.
3. The neutral `agents` projection has a dynamic expected set derived from the canonical inventory and the documented policy; exact global skill counts are not part of the user-facing contract.
4. `as-git-commit` is a required sentinel: when `ace-git-commit` is installed and discovered, `.agents/skills/as-git-commit/SKILL.md` is present after default sync.
5. `ace-handbook status` uses the exact expected skill set that default sync would write. After a clean sync, expected, installed, and in-sync counts agree, with zero missing, outdated, or extra entries.
6. When the effective expected set is smaller than the canonical inventory, status explicitly reports a curated projection policy, the excluded count, and the reason or policy boundary; a file-level clean projection must not appear to mean that every canonical skill is projected.
7. Provider-specific frontmatter overrides remain isolated to their requested provider. The neutral projection contains the canonical skill contract without unrelated provider override metadata.
8. Explicit provider sync remains provider-specific: `ace-handbook sync --provider codex` writes only the Codex projection and continues honoring Codex targeting and overrides.

### Interface Contract

```bash
ace-handbook sync
# Expected: default sync reports the agents projection and its dynamic skill count.
# Expected: .agents/skills/<canonical-skill>/SKILL.md exists for every effective expected skill.
# Expected: .agents/skills/as-git-commit/SKILL.md exists when ace-git-commit is installed.
```

```bash
ace-handbook status
# Expected: canonical inventory and agents expected-set metrics are shown together.
# Expected after a clean sync: missing=0, outdated=0, extra=0, and in_sync=expected.
# Expected when canonical total exceeds expected: the output identifies a curated policy, excluded count, and reason.
# Expected table output: the agents row exposes the policy mode and excluded count, with a human-readable reason when curated.
```

```bash
ace-handbook status --format json
# Expected: machine-readable canonical inventory, provider metrics, and projection coverage fields.
# Expected agents provider fields: projection_policy (complete|curated), excluded_count, and policy_reason.
```

```bash
ace-handbook sync --provider codex
# Expected: writes only the Codex provider projection and does not update .agents/skills/.
```

Error Handling:

- Unknown providers continue to return a non-zero result with the existing actionable unknown-provider error.
- Disabled providers requested explicitly continue to return a non-zero result with the existing disabled-provider error.

Edge Cases:

- A clean sync from an empty `.agents/skills/` directory and a sync over stale entries converge on the same effective expected set.
- Canonical inventory growth changes dynamic counts but does not require hard-coded expected totals.
- Provider-specific frontmatter overrides are absent from the neutral projection and present only in the explicitly requested provider projection.
- An intentionally curated deployment reports the excluded-skill boundary consistently in sync and status.

## Success Criteria

- [x] Default sync projects the complete effective `agents` policy; no common workflow skill is silently omitted because of legacy provider target metadata.
- [x] A clean default sync makes `as-git-commit` available whenever `ace-git-commit` is installed and discovered.
- [x] `ace-handbook status` and `ace-handbook sync` agree on the exact expected set and report a clean state after sync without false extras or hidden missing skills.
- [x] Any intentional difference between canonical total and `agents` expected count is explicitly identified in status with a curated policy, excluded count, and reason or policy boundary.
- [x] Explicit provider sync continues to write only the requested provider projection and preserves provider-specific targeting and frontmatter isolation.
- [x] Fast tests cover default projection membership, narrow-target handling, status/sync agreement, stale cleanup, filtering disclosure, and failure handling.
- [x] The retained handbook sync E2E scenario verifies default projection output, status output, sentinel availability, and clean exit behavior; full execution is blocked by the dedicated sandbox precondition documented below.

## Validation Questions

- No pending human-input questions for the draft. Repository research resolved the policy choice: `agents` is the neutral surface for common workflow skills, while intentionally narrow provider targets remain provider-specific; any resulting canonical-versus-expected gap must be observable.
- Exact canonical totals are intentionally not fixed because the inventory changes across ACE releases.
- Explicit provider projections remain a separate contract from the neutral default and must not be broadened as a side effect.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Standalone task.
- **Slice outcome:** A default ACE setup exposes the complete effective common-workflow projection through `.agents/skills/`, and status truthfully reports projection coverage against the canonical inventory.
- **Advisory size:** Medium.
- **Context dependencies:** GitHub issue 307, the agents provider manifest, canonical skill inventory discovery, projection rules, sync/status collectors, the handbook sync E2E scenario, and task-local usage scenarios.

## Verification Plan

### Unit/Component Validation

- Given multiple canonical sources and skills with legacy full-provider targets, verify the neutral `agents` expected set includes every common workflow skill and preserves the projected skill body.
- Given the same inventory, verify sync and status compute identical skill names and counts.
- Given a canonical skill with an intentionally narrow provider target, verify it remains excluded from `agents` while remaining available to its explicit provider.
- Given canonical total greater than `agents` expected, verify status exposes the curated policy, excluded count, and reason or policy boundary.
- Verify provider-specific overrides do not appear in the neutral projection and remain available for the explicitly requested provider.
- Verify stale entries are removed only when they are outside the declared expected set.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Run default sync in a clean sandbox, inspect the generated `.agents/skills/` tree for `as-git-commit` and representative skills from multiple sources, then run status.
- Confirm status reports the same expected set that sync maintained and has no missing, outdated, or extra entries after the clean sync.
- Confirm a scenario with intentionally narrow targets reports curated coverage rather than implying that expected equals canonical.
- Run explicit Codex sync and confirm only `.codex/skills/` changes for that invocation.
- Exercise JSON status output so automation can distinguish file-level sync from intentionally curated coverage.

### Failure/Invalid Path Validation

- Request an unknown provider and confirm the existing non-zero error contract remains intact.
- Request a disabled provider and confirm the existing non-zero error contract remains intact.
- Exercise a documented curated subset and confirm sync and status disclose the same filtered boundary.

### Verification Commands

- `ace-test ace-handbook`
- `ace-test-e2e ace-handbook TS-HANDBOOK-002 --dry-run`
- `ace-test-e2e ace-handbook TS-HANDBOOK-002`

## Objective

Make the documented default ACE setup trustworthy. When canonical skill sources are installed and available, agents should receive the complete common-workflow projection under `.agents/skills/`, and handbook status should make coverage against the canonical inventory visible instead of reporting a clean-looking hidden subset.

## Scope of Work

- Define the neutral `agents` provider's common-workflow projection contract.
- Align default sync and status around one dynamic expected skill set.
- Make intentional filtering visible to users and automation.
- Preserve explicit provider projection behavior and provider-specific frontmatter isolation.
- Add sentinel and cross-source verification for `as-git-commit` and representative canonical skills.

## Deliverables

### Behavioral Specifications

- Complete common-workflow projection behavior for the neutral `agents` provider.
- Sync/status consistency and transparency contract.
- Curated projection coverage behavior.
- Preservation of explicit provider projection semantics.

### Validation Artifacts

- Fast tests for projection membership, status/sync agreement, filtering disclosure, and failure paths.
- Retained handbook sync E2E coverage for default and explicit provider behavior.
- Task-local usage scenarios for sync, status, JSON status, and error/curated cases.

## Out of Scope

- Rewriting canonical skill content or changing individual skill instructions.
- Restoring provider-specific folders as the default output.
- Changing explicit provider-specific frontmatter semantics except where required to keep neutral projection metadata clean.
- Fixing unrelated handbook resources or non-skill sync behavior.
- Changing the documented common-workflow policy to project every canonical skill.
- Redesigning canonical source discovery or error recovery.
- Hard-coding a fixed canonical skill count into behavior or acceptance criteria.

## References

- GitHub issue 307: `https://github.com/cs3b/ace/issues/307`
- Issue report: `ace-handbook sync` reports 32 installed/expected agents skills while canonical inventory reports 90, silently removing 58 skills including `as-git-commit`.
- Issue environment evidence: all 22 direct `ace-*` dependencies are loaded with `missing=0`, so a clean file-level status must not hide a smaller provider expectation than the canonical inventory.
- Repository research: `ace-handbook/docs/usage.md`, ADR-027, and completed task `8tt.t.stj` define `agents` as the neutral surface for common workflow skills, not an unconditional mirror of every canonical skill.
- Local verification: current checkout reports canonical `99`, agents expected `99`, installed `99`, in-sync `99`; issue #307 is not reproducible in this workspace, so acceptance uses the dynamic coverage invariant rather than fixed local counts.
- `ace-handbook/.ace-defaults/handbook/providers/agents.yml`
- `ace-handbook/lib/ace/handbook/atoms/provider_registry.rb`
- `ace-handbook/lib/ace/handbook/organisms/skill_inventory.rb`
- `ace-handbook/lib/ace/handbook/molecules/skill_projection.rb`
- `ace-handbook/lib/ace/handbook/organisms/provider_syncer.rb`
- `ace-handbook/lib/ace/handbook/organisms/status_collector.rb`
- `ace-git-commit/handbook/skills/as-git-commit/SKILL.md`
- `ace-handbook/test/e2e/TS-HANDBOOK-002-sync-behavior/scenario.yml`
- `.ace-tasks/8tt.t.stj-project-default-ace-workflow-skills/8tt.t.stj-project-default-ace-workflow-skills-into-agents.s.md`

## Verification Results

- Correction after the published `ace-handbook 0.30.0` retest: the original success evidence was invalid because the
  fast tests and local checkout discovered globally installed `ace-handbook-integration-*` manifests. In a project
  where only `agents` is known, `SkillProjection.projection_targets` filtered the declared legacy target set to an empty
  list before checking neutral compatibility, leaving `as-git-commit` absent and reporting 32 of 90 canonical skills.
- The corrective acceptance case must inject or install an agents-only provider registry and prove that the canonical
  legacy target declaration is recognized before provider availability filtering. Installed integration manifests are
  not valid evidence for this case.
- Corrective agents-only fixture using local `ace-handbook` and `ace-git-commit` with no integration gems: passed;
  sync projected 17/17 canonical skills, status reported `complete`, `EXCLUDED=0`, and
  `.agents/skills/as-git-commit/SKILL.md` existed. Explicit Codex status failed with `Unknown provider: codex`, proving
  the fixture had no Codex provider manifest.
- `ace-test ace-handbook`: passed, 37 tests, 193 assertions, 0 failures.
- `ace-test-e2e ace-handbook TS-HANDBOOK-002 --dry-run`: passed, three test cases discovered.
- `ace-test-e2e ace-handbook TS-HANDBOOK-002`: the default Ruby 3.4.9 runtime is blocked by global ACE gems; a clean
  Ruby 3.2.2 runtime passed dependency setup but the macOS host cannot provide the Linux-only `bwrap` backend. No E2E
  scenario assertion ran locally; the retained scenario now builds its own agents-only fixture bundle for Linux CI.

## Review Summary

**Readiness Checklist:** complete after reconciling the draft with the documented common-workflow projection policy
**Questions Generated:** 1 high-priority ambiguity resolved through repository docs, ADR-027, completed task 8tt.t.stj, and current status output
**Critical Blockers:** none remain
**Decision:** Ready for implementation planning; the task now specifies curated coverage disclosure rather than requiring an unconditional all-canonical default
