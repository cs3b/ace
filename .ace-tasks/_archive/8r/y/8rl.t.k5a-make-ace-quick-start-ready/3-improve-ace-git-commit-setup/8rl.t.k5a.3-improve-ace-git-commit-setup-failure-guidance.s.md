---
id: 8rl.t.k5a.3
status: done
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [ace-git-commit/lib/ace/git_commit/molecules/message_generator.rb, ace-git-commit/lib/ace/git_commit/cli/commands/commit.rb, ace-git-commit/docs/getting-started.md, ace-git-commit/docs/usage.md, ace-git-commit/test/fast/molecules/message_generator_test.rb]
  commands: [ace-task show 8rl.t.k5a.3]
tags: []
parent: 8rl.t.k5a
created_at: "2026-04-22 13:26:09"
needs_review: false
---

# Improve ace-git-commit setup failure guidance

## Behavioral Specification

### User Experience

- Input: A developer runs `ace-git-commit -i "set up ace tooling"` in a fresh repo after staging setup files.
- Process: ACE attempts LLM-backed message generation through configured role or model fallback.
- Output: If generation fails, the developer sees which setup path failed and a deterministic command that lets them complete the setup commit without LLM generation.

### Expected Behavior

`ace-git-commit` setup failures should be self-explanatory. When `role:commit` or a configured model cannot generate a message because providers, credentials, CLI models, or accounts are not ready, the error should name the relevant setup surface and show the direct-message fallback:

```bash
ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

### Interface Contract

```bash
ace-git-commit -i "set up ace tooling"
ace-git-commit --model role:commit -i "set up ace tooling"
ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Expected failure guidance includes:

- The failed model or role input, such as `role:commit` or `codex:mini`.
- The underlying provider/model failure when available.
- `ace-llm --list-providers` as the provider discovery command.
- `ace-config doctor` as the setup readiness command.
- The deterministic direct-message fallback command.

Error Handling:

- Missing credentials: point to provider discovery and doctor output.
- Unsupported Codex model: name the unsupported model where available.
- Claude account or org access rejection: preserve provider message and offer deterministic commit fallback.

Edge Cases:

- Explicit `-m` usage should not invoke LLM generation or show LLM setup guidance.
- `--dry-run` failures should show the same diagnostics without committing.
- `--only-staged` guidance should preserve unstaged user changes.

## Success Criteria

- LLM generation errors include setup remediation guidance.
- Direct-message fallback guidance appears for setup-relevant generation failures.
- Explicit `-m` path remains deterministic and avoids provider access.
- Tests cover missing provider/credential style errors and unsupported model style errors.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: first setup commit can proceed after a provider failure.
- Advisory size: medium.
- Context dependencies: ace-git-commit message generation and CLI docs/tests.

## Verification Plan

### Unit/Component Validation

- Message generation failure tests assert remediation commands are present.
- Explicit message tests assert no LLM query is attempted.

### Integration/E2E Validation

- Fresh setup workflow captures the failure output and confirms the direct-message fallback command is documented.

### Failure/Invalid Path Validation

- Simulated `gpt-5-mini` rejection and missing credential failures produce actionable output without stack traces.

### Verification Commands

- `ace-test ace-git-commit`
- `ace-test-e2e ace-git-commit`

## Objective

Make the first setup commit recoverable even when LLM provider setup is incomplete.

## Scope of Work

- User-facing error guidance and docs for `ace-git-commit`.
- Do not change git staging semantics.
- Do not bypass provider failures by silently choosing a message.

## Deliverables

### Behavioral Specifications

- Failure output contract for setup-related LLM generation failures.

### Validation Artifacts

- Tests for remediation text and direct-message fallback behavior.

## Out of Scope

- Provider credential setup.
- Commit message generation quality changes.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/298
