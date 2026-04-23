---
id: 8rf2m2
title: 8re-t-n1d-0-tmux-runtime-control-surface
type: standard
tags: [ace-tmux, assignment, task]
created_at: "2026-04-16 01:44:31"
status: active
---

# 8re-t-n1d-0-tmux-runtime-control-surface

## What Went Well

- The task landed as a coherent public surface instead of another consumer-local wrapper: `ace-tmux` now owns `send`, `capture`, `wait`, `attach`, and `detach` behind one runtime API and CLI contract.
- The implementation stayed aligned with the existing package structure by extending `TmuxCommandBuilder`, `TmuxExecutor`, and CLI registration rather than inventing a parallel command path.
- Fast feedback loops stayed cheap and reliable. `ace-test ace-tmux` and `cd ace-tmux && ace-test all --profile 6` both passed after the one parser fix in the new `wait` command.
- Release follow-through stayed contained: `ace-tmux` was bumped to `0.14.0`, the required follower `ace-overseer` dependency was updated to `~> 0.14`, and the coordinated release commit set was produced cleanly.

## What Could Be Improved

- The initial `wait` CLI implementation used an unsupported dry-cli option type (`:numeric`). This was caught quickly in fast tests, but it is still an avoidable parser-contract mistake when adding new command options.
- The pre-commit review step had to fall back to `ace-lint` because native `/review` was not available in this execution environment. The fallback worked, but issue-finding depth stayed below a full review pass.
- `ace-git-commit` initially failed because the worktree did not have local git author identity configured. Reusing the latest repo author fixed it, but that interruption cost time inside the subtree.
- The release workflow’s RubyGems propagation proof was not exercised here because this subtree only handled local release metadata and release commits. The release note captured that limitation, but the proof remains a later-stage responsibility.

## Action Items

### Stop Doing

- Relying on unverified option-type assumptions when introducing new ACE CLI command flags.
- Treating missing local git identity as something that will sort itself out during commit time.

### Continue Doing

- Reusing package-native building blocks before adding new abstractions.
- Running package tests immediately after adding new CLI/runtime surfaces and fixing failures before moving on.
- Recording follower-package dependency bumps explicitly in both package and root changelogs.

### Start Doing

- Defaulting new numeric CLI flags to string parsing plus explicit coercion when dry-cli type support is uncertain.
- Checking local git author config before the first scoped commit in forked assignment worktrees.
- Capturing a small reusable note or helper about release-proof expectations so subtree release steps are explicit about what they do and do not validate.
