---
id: 8rl.t.ks9
status: pending
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, ace-support-config/README.md, ace-llm/docs/usage.md, ace-git-commit/docs/usage.md, ace-git-commit/docs/getting-started.md, ace-support-core/.ace-defaults/project-root/AGENTS.md, ace-support-core/.ace-defaults/project-root/CLAUDE.md, ace-support-core/.ace-defaults/README.md, .ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/8rl.t.k5a-make-ace-quick-start-ready-out-of.s.md, .ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/2-add-setup-readiness-doctor/8rl.t.k5a.2-add-setup-readiness-doctor.s.md, .ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/3-improve-ace-git-commit-setup/8rl.t.k5a.3-improve-ace-git-commit-setup-failure-guidance.s.md, .ace-tasks/8rl.t.ks9-clarify-ace-quick-start-first/ux-usage.md]
  commands: [ace-task show 8rl.t.ks9 --tree, ace-task show 8rl.t.ks9 --content]
tags: []
created_at: "2026-04-22 13:51:24"
github_issue: 299
needs_review: false
---

# Clarify ACE quick-start first-use setup flow

## Behavioral Specification

### User Experience

- Input: A first-time ACE user follows the quick start in a fresh repository after adding ACE gems to the project bundle.
- Process: The user chooses a minimal or full-stack setup path, runs repo-local commands through Bundler, sees what files ACE will generate, initializes and syncs agent assets, checks provider/setup readiness, and makes the first setup commit.
- Output: The user understands the large generated file set is expected, knows which commands should run through the project bundle, and can make the setup commit deterministically even if LLM provider readiness is incomplete.

### Expected Behavior

The quick-start experience should set expectations before setup changes the repository. It should present a small starter path and a full-stack path, preview generated files, consistently show repo-local commands with `bundle exec`, explain first setup commit recovery, and describe split-scope commit behavior in first-use language.

This task is separate from issue #298. Runtime work already drafted under `8rl.t.k5a` remains authoritative for stale Codex defaults, `ace-config doctor`, provider readiness checks, and `ace-git-commit` setup failure guidance. This task should document and coordinate those behaviors without duplicating the runtime implementation unless the #298 task leaves a user-facing gap.

### Interface Contract

```bash
bundle add --group "development, test" ace-task ace-bundle ace-handbook ace-llm ace-llm-providers-cli ace-handbook-integration-codex
bundle install
bundle exec ace-config init
bundle exec ace-handbook sync
bundle exec ace-llm --list-providers
bundle exec ace-bundle project
bundle exec ace-config doctor
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Error Handling:

- If setup creates many tracked files, the docs should have already named the expected generated locations.
- If a bare `ace-*` command would resolve to a global gem version, the repo-local setup path should prefer `bundle exec`.
- If LLM-backed commit generation fails after staging, docs and runtime guidance should say changes may already be staged and show the deterministic `-m` recovery command.
- If provider discovery succeeds but a role/model cannot complete a prompt, setup readiness guidance should point to `ace-config doctor` from `8rl.t.k5a.2`.

Edge Cases:

- Users who only want API-backed providers should not be forced into local CLI provider checks.
- Users who already have global ACE gems installed should still see project-bundle commands for reproducibility.
- Generated `AGENTS.md` and `CLAUDE.md` should be described as ACE-generated, safe to customize, and refreshable/syncable.

## Success Criteria

- Quick-start docs include "Minimal setup" and "Full-stack setup" command blocks.
- Quick-start docs include a "What this will create" section before install/setup commands.
- Repo-local setup examples consistently use `bundle exec` for `ace-*` commands after `bundle install`.
- First setup commit docs include deterministic `ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"` guidance.
- Split-scope behavior is explained for first-time setup commits, including when to use `--no-split`.
- Setup readiness docs refer to `ace-config doctor` and align with `8rl.t.k5a.2`.
- Generated guidance files identify their ACE provenance and customization/refresh expectations.

## Validation Questions

- None. GitHub issue #299 defines the desired first-use documentation outcome and explicitly delegates provider readiness/runtime details to issue #298.

## Vertical Slice Decomposition: Task/Subtask Model

- Orchestrator task: coordinate the first-use setup documentation and runtime-guidance contract across quick-start docs, generated guidance files, commit docs, and fresh-repo verification. Advisory size: large.
- Subtask 0: document setup modes and generated artifacts. Advisory size: small.
- Subtask 1: standardize repo-local command examples. Advisory size: small.
- Subtask 2: align setup readiness runtime guidance. Advisory size: medium.
- Subtask 3: clarify first setup commit recovery. Advisory size: medium.
- Subtask 4: verify the fresh-repo first-use walkthrough. Advisory size: medium.

## Verification Plan

### Unit/Component Validation

- Documentation checks confirm the quick-start command blocks use the expected setup modes and `bundle exec` command forms.
- Generated guidance-file templates or seed output include ACE provenance and customization guidance.

### Integration/E2E Validation

- Fresh-repo walkthrough validates the documented setup path through install, init, sync, provider discovery, setup readiness, and deterministic setup commit guidance.

### Failure/Invalid Path Validation

- Missing provider readiness and LLM-backed commit failure paths remain recoverable through documented `ace-config doctor` and direct-message commit guidance.

### Verification Commands

- `ace-lint README.md docs/quick-start.md ace-git-commit/docs/usage.md ace-git-commit/docs/getting-started.md`
- `ace-test ace-support-config`
- `ace-test ace-git-commit`
- `ace-test-e2e ace-llm`
- `ace-test-e2e ace-git-commit`

## Objective

Make the ACE quick start trustworthy for first-time users by explaining setup size, repo-local command execution, provider/setup readiness, and the first setup commit before users encounter those behaviors.

## Scope of Work

- User experience scope: fresh-repo setup, generated-file expectations, repo-local command examples, setup readiness explanation, and first commit recovery.
- System behavior scope: documentation and generated guidance-file provenance, plus coordination with the existing #298 runtime-readiness tasks.
- Interface scope: README, quick-start docs, generated guidance file content, setup doctor docs, and `ace-git-commit` first-use docs.

## Deliverables

### Behavioral Specifications

- Complete subtasks for setup modes, Bundler command examples, setup readiness alignment, first commit recovery, and fresh-repo verification.

### Validation Artifacts

- Draft usage scenarios in `ux-usage.md`.
- Fresh-repo verification scenario requirements.

## Concept Inventory: Orchestrator Only

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| Minimal setup path | subtask 0 | -- | KEPT |
| Full-stack setup path | subtask 0 | -- | KEPT |
| Generated-file preview | subtask 0 | -- | KEPT |
| Repo-local `bundle exec` commands | subtask 1 | -- | KEPT |
| Setup readiness docs tied to `ace-config doctor` | subtask 2 | -- | KEPT |
| Deterministic first setup commit fallback | subtask 3 | -- | KEPT |
| Split-scope first-use explanation | subtask 3 | -- | KEPT |
| Generated guidance-file provenance | subtask 4 | -- | KEPT |

## Out of Scope

- Replacing the runtime implementation work already scoped in `8rl.t.k5a`.
- Provider account provisioning, credentials, or billing setup.
- Changing the default ACE package architecture or dependency graph beyond documented setup modes.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/299
- Related task: `8rl.t.k5a` for GitHub issue #298 runtime readiness work.
- Draft usage: `ux-usage.md`
