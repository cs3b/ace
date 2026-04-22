---
id: 8rl.t.ks9.1
status: pending
priority: medium
estimate: TBD
dependencies: []
bundle:
  presets: [project]
  files: [README.md, docs/quick-start.md, docs/tools.md, ace-support-config/README.md, ace-llm/docs/usage.md]
  commands: [ace-task show 8rl.t.ks9.1 --content]
tags: []
parent: 8rl.t.ks9
created_at: "2026-04-22 13:51:35"
needs_review: false
---

# Standardize repo-local command examples

## Behavioral Specification

### User Experience

- Input: A user has just added ACE gems to the project bundle and is following repo-local setup docs.
- Process: The user copies commands that resolve to the versions installed in the current project instead of any globally installed ACE gems.
- Output: Setup behavior is reproducible across machines and does not depend on global gem state.

### Expected Behavior

Repo-local setup instructions should consistently show `bundle exec` for `ace-*` commands after `bundle install`. The docs can still explain that installed executables may be run directly in environments where binstubs, shell wrappers, or globally installed gems are intentional, but the quick-start setup path should prefer the project bundle.

### Interface Contract

```bash
bundle install
bundle exec ace-config init
bundle exec ace-handbook sync
bundle exec ace-llm --list-providers
bundle exec ace-bundle project
bundle exec ace-config doctor
bundle exec ace-git-commit --only-staged --no-split -m "chore: set up ace tooling"
```

Error Handling:

- If a bare `ace-*` command differs from the project bundle, the docs should have made the Bundler path the copied default.
- If a user intentionally uses global ACE commands, docs should frame that as an advanced or already-configured environment choice.

Edge Cases:

- Commands in ACE repository contributor docs may still use direct `ace-*` commands where repo policy requires it; this task focuses on downstream first-use setup docs.
- Commands before `bundle install` should not use `bundle exec` because the bundle is not installed yet.

## Success Criteria

- Quick-start setup commands after `bundle install` use `bundle exec`.
- README install/setup section either uses `bundle exec` for repo-local setup or points to quick start as the canonical repo-local flow.
- Docs explain why `bundle exec` is used for project-local ACE installs.
- The command examples remain copy/pasteable and do not mix bare and Bundler forms in the same repo-local flow without explanation.

## Validation Questions

- None.

## Vertical Slice Decomposition: Task/Subtask Model

- Slice type: subtask.
- Slice outcome: users execute ACE commands from the project bundle during first setup.
- Advisory size: small.
- Context dependencies: README, quick-start docs, tools reference, config and LLM usage docs.

## Verification Plan

### Unit/Component Validation

- Documentation search confirms repo-local setup blocks use `bundle exec ace-config init`, `bundle exec ace-handbook sync`, `bundle exec ace-llm --list-providers`, and `bundle exec ace-bundle project`.

### Integration/E2E Validation

- Fresh-repo walkthrough executes setup using Bundler-prefixed commands after `bundle install`.

### Failure/Invalid Path Validation

- Docs explain the failure mode where global ACE gems are older or configured differently than the project bundle.

### Verification Commands

- `ace-lint README.md docs/quick-start.md docs/tools.md`

## Objective

Make the first setup path reproducible by avoiding accidental global ACE command resolution.

## Scope of Work

- Public setup docs and command examples.
- No changes to command dispatch or executable installation.

## Deliverables

### Behavioral Specifications

- Repo-local command examples and explanatory guidance.

### Validation Artifacts

- Fresh-repo command-sequence expectations in `ux-usage.md`.

## Out of Scope

- Binstub generation.
- Changing repository-internal command integrity rules for agents.

## References

- GitHub issue: https://github.com/cs3b/ace/issues/299
