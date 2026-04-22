---
id: 8rl.t.k5a
status: in-progress
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, ace-llm/.ace-defaults/llm/config.yml, ace-llm-providers-cli/.ace-defaults/llm/providers/codex.yml, ace-support-config/lib/ace/support/config/organisms/config_initializer.rb, ace-git-commit/lib/ace/git_commit/molecules/message_generator.rb]
  commands: [ace-task show 8rl.t.k5a]
tags: []
created_at: "2026-04-22 13:25:52"
github_issue: 298
needs_review: false
worktree:
  branch: k5a-make-ace-quick-start-ready-out-of-the-box
  path: ../ace-t.k5a
  created_at: "2026-04-22 14:46:52"
  updated_at: "2026-04-22 14:46:52"
  target_branch: main
---

# Make ACE quick start ready out of the box

## Behavioral Specification

### User Experience

- Input: A developer follows the ACE quick start in a fresh repository with Ruby and Bundler installed, no prior Gemfile, and no ACE config.
- Process: The developer installs the documented gems, initializes ACE config, syncs agent assets, checks provider readiness, and tries the first setup commit.
- Output: The developer sees clear setup state, current Codex defaults, expected generated file volume, and actionable recovery guidance if a provider is not ready.

### Expected Behavior

Fresh ACE setup should either make the first `ace-git-commit` path work or explain exactly what is missing and how to keep moving without LLM generation. The quick start should not imply CLI providers are available unless the required CLI provider package is installed. Generated Codex provider defaults should use currently supported model IDs. Project-local artifacts under `.ace-local/` should be ignored or reported as not ignored. Large generated setup output should be disclosed before users see a large tracked diff.

### Interface Contract

```bash
bundle add --group "development, test" ... ace-llm-providers-cli ...
ace-config init
ace-config doctor
ace-llm --list-providers
ace-git-commit -i "set up ace tooling"
ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Error Handling:

- Missing CLI provider gem: provider discovery and doctor output name `ace-llm-providers-cli` as the needed package.
- Unsupported Codex alias: doctor output names the alias and resolved model that failed validation.
- Missing Google credentials or unavailable Claude account: commit setup guidance explains fallback order and direct-message usage.

Edge Cases:

- Existing `.gitignore` mentions `.ace-local/` only in a comment or negation: setup still treats the ignore rule as absent.
- Fresh repo has no `.gitignore`: setup creates one with `.ace-local/`.
- User does not use CLI providers: docs still allow API-provider-only setup without requiring local CLI probes to pass.

## Success Criteria

- Quick-start docs include CLI provider package requirements and generated-file-volume expectations.
- Fresh Codex defaults resolve `codex:mini` to a supported current model, not `gpt-5-mini`.
- `ace-config doctor` provides non-mutating setup readiness output with actionable failures.
- `ace-git-commit` setup failures point users to `ace-llm --list-providers`, `ace-config doctor`, and deterministic `-m` commit usage.
- A fresh-repo verification path covers install guidance, config init, provider discovery, alias readiness, `.ace-local/` ignore behavior, and setup commit failure guidance.

## Validation Questions

- None. GitHub issue #298 defines the expected first-use behavior and suggested improvements.

## Vertical Slice Decomposition: Task/Subtask Model

- Orchestrator task: coordinate the complete first-use setup experience across docs, config readiness, provider defaults, commit failure messaging, and fresh-repo verification. Advisory size: large.
- Subtask 0: Align quick-start install guidance with CLI providers. Advisory size: small.
- Subtask 1: Verify fresh Codex provider defaults. Advisory size: small.
- Subtask 2: Add setup readiness doctor. Advisory size: medium.
- Subtask 3: Improve ace-git-commit setup failure guidance. Advisory size: medium.
- Subtask 4: Validate fresh-repo quick-start path. Advisory size: medium.

## Verification Plan

### Unit/Component Validation

- Each subtask defines its own focused fast or feature checks.

### Integration/E2E Validation

- Fresh-repo setup scenario confirms the complete quick-start path and first setup commit diagnostics.

### Failure/Invalid Path Validation

- Missing provider gem, unsupported Codex alias, missing `.ace-local/` ignore rule, and failed LLM-backed commit all produce actionable user-facing output.

### Verification Commands

- `ace-test ace-support-config`
- `ace-test ace-llm`
- `ace-test ace-llm-providers-cli`
- `ace-test ace-git-commit`
- `ace-test-e2e ace-llm`
- `ace-test-e2e ace-git-commit`

## Objective

Make ACE's first-use path trustworthy for fresh-repo CLI-provider users, especially users following the quick start and expecting `ace-git-commit` with Codex CLI to work or fail with clear next steps.

## Scope of Work

- User experience scope: fresh install, config initialization, provider readiness, and first setup commit.
- System behavior scope: documented dependency requirements, current generated provider defaults, setup readiness diagnostics, and commit generation failure guidance.
- Interface scope: quick-start docs, `ace-config doctor`, provider discovery expectations, and `ace-git-commit` error guidance.

## Deliverables

### Behavioral Specifications

- Complete subtask specs for docs, Codex defaults, setup doctor, commit guidance, and fresh-repo verification.

### Validation Artifacts

- Draft usage contract for `ace-config doctor` in `ux-usage.md`.
- Verification scenarios in each subtask.

## Concept Inventory: Orchestrator Only

| Concept | Introduced by | Removed by | Status |
| --- | --- | --- | --- |
| CLI provider package in quick start | subtask 0 | -- | KEPT |
| Current Codex model aliases | subtask 1 | -- | KEPT |
| `ace-config doctor` setup readiness | subtask 2 | -- | KEPT |
| Direct-message setup commit fallback | subtask 3 | -- | KEPT |
| Fresh-repo quick-start E2E validation | subtask 4 | -- | KEPT |

## Out of Scope

- Implementing provider clients beyond validating current defaults and diagnostics.
- Changing user account credentials, provider authentication, or Codex CLI account capabilities.
- Making every provider pass a live prompt in offline or intentionally unconfigured environments.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/298
- Draft usage: `ux-usage.md`
