---
id: 8tt.t.stj
status: done
priority: medium
created_at: "2026-06-30 19:12:50"
estimate: TBD
dependencies: []
tags: [handbook, skills, agents]
github_issue: 306
bundle:
  presets: [project]
  files: [ace-git-commit/handbook/skills/as-git-commit/SKILL.md, ace-handbook/.ace-defaults/handbook/providers/agents.yml, ace-handbook/lib/ace/handbook/atoms/provider_registry.rb, ace-handbook/lib/ace/handbook/molecules/skill_projection.rb, ace-handbook/lib/ace/handbook/organisms/provider_syncer.rb, ace-handbook/lib/ace/handbook/organisms/status_collector.rb, ace-handbook/test/fast/organisms/provider_syncer_test.rb, ace-handbook/test/fast/organisms/status_collector_test.rb, ace-handbook/test/e2e/TS-HANDBOOK-002-sync-behavior/scenario.yml, .ace-tasks/8tt.t.stj-project-default-ace-workflow-skills/ux/usage.md]
  commands: [ace-task show 8tt.t.stj --content, ace-handbook status, ace-handbook sync, ace-test ace-handbook, ace-test ace-handbook test/e2e/TS-HANDBOOK-002-sync-behavior]
needs_review: false
---

# Project default ACE workflow skills into agents provider

## Behavioral Specification

### User Experience

- **Input:** A developer or agent follows the modern ACE setup path and runs `ace-handbook sync` without opting into a provider-specific target such as `.codex/skills/`.
- **Process:** ACE treats the default `agents` provider as the neutral projection surface for common ACE workflow skills that are already installed and intended for agent use.
- **Output:** `.agents/skills/` contains the expected workflow skills, including `as-git-commit`, and `ace-handbook status` reports a clean provider state instead of hiding expected skills behind provider-specific targets.

### Expected Behavior

1. A fresh default sync projects commonly used ACE workflow skills into `.agents/skills/` when their gems are installed.
2. `as-git-commit` from `ace-git-commit` is a required sentinel skill for the default `agents` projection.
3. Skills whose canonical metadata targets the legacy full provider set (`claude`, `codex`, `gemini`, `opencode`, `pi`) are treated as compatible with the modern neutral `agents` provider unless they are explicitly narrowed by design.
4. `ace-handbook status` counts the same skills as expected for `agents` that `ace-handbook sync` will write during a clean sync.
5. Stale `.agents/skills/` entries are still pruned when they are not expected, but common installed workflow skills are not classified as extras only because they lack an explicit `agents` target.
6. Explicit provider sync remains unchanged: `ace-handbook sync --provider codex` still writes Codex-native projections and does not write `.agents/skills/`.
7. Provider-specific frontmatter overrides remain scoped to their provider and do not leak into the neutral `agents` projection.
8. Projects are not required to restore `.codex/skills/` or add local skill overrides to access common ACE workflows under the modern default setup.

### Interface Contract

```bash
ace-handbook sync
# Expected: writes default provider skills under .agents/skills/
# Expected: .agents/skills/as-git-commit/SKILL.md exists when ace-git-commit is installed
```

```bash
ace-handbook status
# Expected: the agents provider's expected/installed/in-sync counts describe the same clean projection set
# Expected: as-git-commit is not treated as an extra or missing-from-expectation workflow
```

```bash
ace-handbook sync --provider codex
# Expected: writes Codex projection only, preserving explicit provider behavior
```

Error Handling:

- Unknown providers should continue to fail with the existing explicit unknown-provider error.
- Disabled providers should continue to fail when requested explicitly.
- Skills with intentionally narrow provider targets should not be silently widened unless they match the documented compatibility rule or explicitly include `agents`.

Edge Cases:

- Skills with no `integration.targets` continue to project to all known providers.
- Skills with provider-specific frontmatter overrides apply those overrides only for that provider.
- A clean sync from an empty `.agents/skills/` directory and a sync over a stale directory both converge on the same expected skill set.
- Inventory growth should not require hard-coded counts in user-facing behavior; verification should assert representative sentinel skills and consistency between status and sync.

## Success Criteria

- [x] A clean default sync creates `.agents/skills/as-git-commit/SKILL.md` when `ace-git-commit` is installed.
- [x] Common ACE workflow skills using the legacy full provider target set are included in the neutral `agents` projection by default.
- [x] `ace-handbook status` no longer reports a state where `agents` expects only a small subset while installed common workflow skills are treated as extras.
- [x] Explicit provider sync for Codex, Claude, Gemini, OpenCode, and Pi preserves current target and frontmatter override semantics.
- [x] Stale projection pruning still removes truly unexpected skill directories.
- [x] Fast tests cover default `agents` projection, status consistency, legacy target compatibility, provider override isolation, and stale cleanup.
- [x] Retained handbook sync E2E coverage exercises the default sync behavior with `as-git-commit` or an equivalent real workflow-skill sentinel.
- [x] User-facing docs or changelog notes explain that `.agents/skills/` is the modern default projection for common ACE workflows.

## Validation Questions

- No pending human-input questions.
- Resolved by codebase scan: 65 of 102 canonical skill files currently target the full legacy provider set (`claude`, `codex`, `gemini`, `opencode`, `pi`), including broad workflow skills such as `as-bundle`, `as-onboard`, and docs workflows. Treating that exact target set as a neutral `agents` compatibility signal is a reasonable default rather than a one-off `as-git-commit` exception.
- Default decision: include skills that target the full legacy provider set as common workflow skills for `agents`; exclude narrower provider-specific skills unless they explicitly add `agents`.
- Default decision: keep exact skill counts out of the public contract because the canonical inventory changes across releases; use sentinel skills and status/sync consistency as the durable acceptance criteria.

## Vertical Slice Decomposition Task/Subtask Model

- **Slice type:** Standalone task.
- **Slice outcome:** Modern default ACE projects installed common workflow skills into `.agents/skills/`, with `as-git-commit` available after sync.
- **Advisory size:** Medium.
- **Context dependencies:** GitHub issue 306, current `as-git-commit` skill metadata, handbook provider registry, skill projection logic, provider sync/status behavior, handbook sync E2E suite, and task-local usage scenarios.

## Verification Plan

### Unit/Component Validation

- Add or update fast tests showing a skill with the legacy full provider target set is expected for `agents`.
- Add or update fast tests showing `as-git-commit`-like metadata projects into `.agents/skills/` without leaking Claude/Codex-specific overrides.
- Add or update status collector tests so `status` and `sync` agree on the `agents` expected set.
- Preserve existing tests for explicit provider sync, disabled provider rejection, and stale directory pruning.

### Integration/E2E Validation If Cross-Boundary Behavior Exists

- Extend retained handbook sync E2E coverage so a default sync from an empty projection directory produces an `agents` skill tree containing a common workflow sentinel.
- Verify a subsequent `ace-handbook status` reports the provider as in sync without classifying that sentinel as an extra.
- Verify explicit provider sync still targets only the requested provider directory.

### Failure/Invalid Path Validation

- Verify an intentionally narrow provider target does not project to `agents` unless it explicitly includes `agents` or matches the compatibility rule.
- Verify unknown and disabled provider errors are unchanged.
- Verify stale projection entries are still removed when absent from the expected set.

### Verification Commands

- `ace-test ace-handbook`
- `ace-test-e2e ace-handbook TS-HANDBOOK-002`
- `ace-test-e2e ace-handbook TS-HANDBOOK-002 --dry-run`

### Verification Results

- `ace-test ace-handbook` passed: 30 tests, 165 assertions, 0 failures.
- `ace-test-e2e ace-handbook TS-HANDBOOK-002 --dry-run` passed scenario discovery with 3 test cases.
- `ace-test-e2e ace-handbook TS-HANDBOOK-002` reached scenario load, then stopped on sandbox runtime contamination: the dedicated sandbox Ruby already exposes global `ace-*` gems. This is an environment precondition failure, not a scenario assertion failure.
- Local patched projection check returned `["claude", "codex", "gemini", "opencode", "pi", "agents"]` for the legacy full-provider target set.

## Objective

Make the modern default ACE setup usable without provider-specific projection fallback. A project that installs ACE gems and runs the documented default sync should have access to common workflow skills in `.agents/skills/`, especially the commit workflow from `ace-git-commit`.

## Scope of Work

- Define the default `agents` projection contract for common ACE workflow skills.
- Ensure sync and status use the same expected-skill rules for `agents`.
- Preserve explicit provider projection behavior and provider-specific frontmatter isolation.
- Add verification that prevents `as-git-commit` from disappearing from default `.agents/skills/` again.
- Update docs or changelog notes for the user-visible default projection behavior.

## Deliverables

### Behavioral Specifications

- Default sync behavior for common workflow skills.
- Status consistency contract for the `agents` provider.
- Compatibility rule for legacy full-provider target metadata.
- Explicit provider behavior preservation.

### Validation Artifacts

- Fast tests for projection target compatibility and status/sync agreement.
- Retained handbook sync E2E scenario for default provider output.
- Task-local `ux/usage.md` scenarios.

## Out of Scope

- Restoring provider-specific folders as the default output.
- Requiring local project overrides for installed ACE workflow skills.
- Rewriting the canonical skill inventory format beyond what is needed to satisfy the projection contract.
- Changing how non-skill handbook resources are synced.

## References

- GitHub issue 306: `https://github.com/cs3b/ace/issues/306`
- Current runtime evidence from the issue: 91 canonical skills, 34 expected for `agents`, and `as-git-commit` installed but not projected.
- Current local evidence: `ace-handbook status` reports 99 canonical skills, 35 expected for `agents`, and stale extra projection entries.
- Current local metadata scan: 65 of 102 canonical skill files target the full legacy provider set and 37 omit explicit targets.
- `ace-git-commit/handbook/skills/as-git-commit/SKILL.md`
- `ace-handbook/lib/ace/handbook/atoms/provider_registry.rb`
- `ace-handbook/lib/ace/handbook/molecules/skill_projection.rb`
- `ace-handbook/lib/ace/handbook/organisms/provider_syncer.rb`
- `ace-handbook/lib/ace/handbook/organisms/status_collector.rb`
- `.ace-tasks/8tt.t.stj-project-default-ace-workflow-skills/ux/usage.md`
