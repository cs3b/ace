---
id: 8rl.t.ks9.0
status: done
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, ace-handbook-integration-codex/README.md, ace-handbook-integration-claude/README.md, .ace-tasks/8rl.t.ks9-clarify-ace-quick-start-first/ux-usage.md]
  commands: [ace-task show 8rl.t.ks9.0 --content]
tags: []
parent: 8rl.t.ks9
created_at: "2026-04-22 13:51:35"
needs_review: false
---

# Document setup modes and generated artifacts

## Behavioral Specification

### User Experience

- Input: A user opens the README or quick start before installing ACE in a new repository.
- Process: The user sees two setup choices and a preview of the files setup will add before copying commands.
- Output: The user chooses the smallest path that fits their goal or intentionally chooses the full-stack path, and the generated file volume is expected rather than surprising.

### Expected Behavior

README and quick-start docs should distinguish minimal setup from full-stack setup. Minimal setup should cover enough for task specs, bundle/handbook resources, LLM/provider access, and one agent integration. Full-stack setup should keep the existing broad workflow packages for overseer, assign, review, tmux, tests, docs, retro, demo, and git helpers.

Docs should include a "What this will create" section before setup commands. That section should name expected generated locations: `.ace/`, agent skill directories such as `.codex/skills/` and `.claude/skills/` when those integrations are installed, `AGENTS.md`, `CLAUDE.md`, `Gemfile`, and `Gemfile.lock`.

### Interface Contract

```bash
# Minimal setup
bundle add --group "development, test" \
  ace-task ace-bundle ace-handbook ace-llm ace-llm-providers-cli \
  ace-handbook-integration-codex

# Full-stack setup
bundle add --group "development, test" \
  ace-idea ace-task ace-sim \
  ace-overseer ace-assign ace-git-worktree ace-tmux \
  ace-bundle ace-handbook ace-search ace-docs ace-llm ace-llm-providers-cli \
  ace-review ace-lint ace-test-runner ace-test-runner-e2e ace-retro ace-demo \
  ace-git-commit ace-git-secrets ace-git \
  ace-handbook-integration-claude ace-handbook-integration-codex
```

Error Handling:

- If a user installs only the minimal setup, docs should say advanced workflow commands may be unavailable until the full-stack packages are added.
- If a user installs a different agent integration, docs should make it clear the generated agent skill directory changes with the selected integration.

Edge Cases:

- Users who choose Claude, Gemini, OpenCode, or PI instead of Codex should see where optional integration packages fit.
- Users with existing `AGENTS.md` or `CLAUDE.md` should understand ACE should preserve user-owned guidance and only add missing starter guidance.

## Success Criteria

- README and `docs/quick-start.md` include minimal and full-stack setup paths.
- The minimal setup path includes `ace-llm-providers-cli` and exactly one example agent integration by default.
- The full-stack path includes `ace-llm-providers-cli` and keeps the currently documented broad ACE tool set.
- A "What this will create" section appears before setup commands and names generated file categories.
- Docs explain that generated guidance files are safe to customize.

## Validation Questions

- None. Default minimal path uses Codex integration because issue #299 is about the current Codex-oriented first-use path.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: users know which setup path to copy and what repository files ACE will generate.
- Advisory size: small.
- Context dependencies: README, quick-start docs, integration package READMEs, draft usage doc.

## Verification Plan

### Unit/Component Validation

- Documentation check confirms both setup paths exist and mention the expected package categories.

### Integration/E2E Validation

- Fresh-repo walkthrough uses the documented minimal setup command as the default first-use path.

### Failure/Invalid Path Validation

- A user following minimal setup but invoking full-stack-only commands sees docs that explain those commands require the full-stack package set.

### Verification Commands

- `ace-lint README.md docs/quick-start.md`

## Objective

Reduce first-use surprise by making setup size and generated files explicit before a user runs setup commands.

## Scope of Work

- Public docs for setup choices and generated artifacts.
- No runtime package installation behavior changes in this subtask.

## Deliverables

### Behavioral Specifications

- Minimal setup, full-stack setup, and generated-file preview contracts.

### Validation Artifacts

- Usage scenario for setup-mode selection in the parent `ux-usage.md`.

## Out of Scope

- Provider readiness diagnostics.
- Commit staging and message generation behavior.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/299
