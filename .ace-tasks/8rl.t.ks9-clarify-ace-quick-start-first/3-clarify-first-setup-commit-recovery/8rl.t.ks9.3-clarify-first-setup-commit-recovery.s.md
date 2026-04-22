---
id: 8rl.t.ks9.3
status: pending
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [docs/quick-start.md, ace-git-commit/docs/usage.md, ace-git-commit/docs/getting-started.md, ace-git-commit/handbook/workflow-instructions/git/commit.wf.md, .ace-tasks/8rl.t.k5a-make-ace-quick-start-ready/3-improve-ace-git-commit-setup/8rl.t.k5a.3-improve-ace-git-commit-setup-failure-guidance.s.md, .ace-tasks/8rl.t.ks9-clarify-ace-quick-start-first/ux-usage.md]
  commands: [ace-task show 8rl.t.ks9.3 --content]
tags: []
parent: 8rl.t.ks9
created_at: "2026-04-22 13:51:35"
needs_review: false
---

# Clarify first setup commit recovery

## Behavioral Specification

### User Experience

- Input: A user has generated ACE setup files and wants to make the first setup commit.
- Process: The user reads when to use deterministic direct-message commit mode, what happens if LLM-backed message generation fails, and why setup changes may be split by configuration scope.
- Output: The user can complete the setup commit without provider readiness and can intentionally avoid split commits for the initial setup snapshot.

### Expected Behavior

First-use docs should give users a deterministic setup commit path before they try LLM-backed commit generation. Docs should explain that `ace-git-commit` may stage changes before message generation failure on current runtime paths, that this is recoverable, and that the direct-message fallback commits already staged setup files without invoking an LLM.

Docs should also explain split-scope behavior in simple terms: ACE may detect multiple configuration scopes because setup touches root docs/config and generated agent assets. For a single initial setup snapshot, `--no-split` is the recommended deterministic choice.

Runtime failure-message improvements remain owned by `8rl.t.k5a.3`; this subtask documents the expected user flow and aligns command examples.

### Interface Contract

```bash
bundle exec ace-git-commit -i "set up ace tooling"
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
bundle exec ace-git-commit --dry-run -i "set up ace tooling"
```

Expected docs behavior:

- Direct-message setup commit is presented as the reliable first setup path.
- LLM-backed generation is optional after provider readiness is confirmed.
- `--only-staged` is explained as using the current index and preserving unstaged changes.
- `--no-split` is explained as forcing one setup commit when multiple scopes are detected.

Error Handling:

- If LLM message generation fails, docs tell users staged changes can be inspected with git status and committed with the deterministic command.
- If split scopes appear during setup, docs explain the output and when `--no-split` is appropriate.

Edge Cases:

- Users who intentionally want scoped setup commits can omit `--no-split`.
- Users with unstaged non-setup changes should understand `--only-staged` commits only the current index.

## Success Criteria

- Quick start includes a "First commit after setup" section.
- `ace-git-commit` usage or getting-started docs explain setup commit fallback and split-scope first-use behavior.
- The deterministic command appears with `bundle exec`, `--only-staged`, `--no-split`, and `-m "chore: set up ace tooling"`.
- Docs align with `8rl.t.k5a.3` and do not claim LLM generation is required for the first setup commit.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: users can complete the first ACE setup commit even when provider readiness is incomplete.
- Advisory size: medium.
- Context dependencies: quick-start docs, git-commit docs/workflow, related #298 commit failure guidance task.

## Verification Plan

### Unit/Component Validation

- Documentation checks confirm setup commit command and split-scope explanation are present.

### Integration/E2E Validation

- Fresh-repo walkthrough stages generated setup files and validates the deterministic direct-message command path.

### Failure/Invalid Path Validation

- LLM-backed message generation failure remains recoverable through documented `--only-staged --no-split -m` usage.

### Verification Commands

- `ace-lint docs/quick-start.md ace-git-commit/docs/usage.md ace-git-commit/docs/getting-started.md`
- `ace-test ace-git-commit`
- `ace-test-e2e ace-git-commit`

## Objective

Make the first ACE setup commit deterministic and understandable before users depend on provider-backed commit message generation.

## Scope of Work

- Documentation and workflow guidance for first setup commit recovery.
- Coordination with existing runtime error guidance task.

## Deliverables

### Behavioral Specifications

- First setup commit and split-scope explanation contracts.

### Validation Artifacts

- Commit recovery scenario in `ux-usage.md`.

## Out of Scope

- Reordering staging and message-generation behavior unless handled by `8rl.t.k5a.3`.
- Commit message generation quality changes.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/299
- Related runtime task: `8rl.t.k5a.3`
