---
id: 8ply25
title: Task 278 — Drop DWIM Default Routing and Standardize CLI Help
type: conversation-analysis
tags: []
created_at: "2026-02-22 22:42:22"
status: active
source: "taskflow:v.0.9.0"
migrated_from: .ace-taskflow/v.0.9.0/retros/8ply25-task-278-cli-help-standardization.md
---
# Reflection: Task 278 — Drop DWIM Default Routing and Standardize CLI Help

**Date**: 2026-02-22
**Context**: Migrated all 25+ ace-* CLI gems from DWIM default routing to standard help pattern via ace-assign orchestration with fork-run delegation
**Author**: Claude Code (Opus 4.6)
**Type**: Conversation Analysis

## What Went Well

- **Fork-run delegation at scale**: Successfully orchestrated 26 sequential fork-run subtrees (010.04–010.29), each implementing a complete task lifecycle (onboard → plan → work → release → verify)
- **Consistent migration pattern**: Every gem followed the same migration steps — the forked agents reliably removed DefaultRouting, added HelpCommand, updated exe entrypoints, rewrote CLI routing tests, and bumped versions
- **Provider resilience**: After initial codex provider failures on 010.12, switching fork config resolved the issue and all subsequent subtrees (010.12–010.29) completed successfully
- **Parallel work coordination**: The orchestrator-driver pattern kept the main context focused on queue management while forked agents handled implementation details
- **High test pass rates**: All packages maintained green test suites after migration (e.g., ace-git-commit 234 tests, ace-git 482 tests, ace-test-runner 183 tests)

## What Could Be Improved

- **Git index lock in sandbox (first 8 subtrees)**: The first ~8 fork-run subtrees (010.04–010.11) consistently failed on the release/commit phase due to git worktree index lock permissions. This was a configuration issue resolved when the user changed the fork config around subtree 010.12 — all subsequent subtrees (010.12–010.29) completed fully including release
- **Manual phase fixup overhead for early subtrees**: For the first ~8 subtrees before the config fix, the orchestrator had to: read 3 phase files, edit them to done, commit manually, then continue. This consumed significant orchestrator context until the root cause was resolved
- **Long polling cycles**: Each fork-run took 10-20 minutes. The sleep-and-poll pattern used ~60% of orchestrator time on waiting. No productive parallel work was done during these waits
- **Stale background task notifications**: Completed fork-runs generated notification messages long after the orchestrator had moved on, requiring 20+ "handled/standing by" responses
- **Provider instability**: The codex provider failed on 010.12 twice before config was changed, wasting ~15 minutes

## Key Learnings

- **Fork-run sandbox git permissions need correct initial config**: The sandbox environment restricts writes to `.git/worktrees/*/index.lock` unless configured. The first ~8 subtrees failed before the user corrected the fork config — after the fix, all remaining subtrees worked cleanly
- **Orchestrator should batch-fix phase files**: Instead of reading+editing 3 files per stuck subtree, a single `ace-assign` command to mark a subtree as done would save significant time
- **Release phase should be optional or orchestrator-owned**: Since the orchestrator has git commit access and the forked agent doesn't (in sandbox), the release phase should either run in the orchestrator context or be skipped in fork-run
- **Idle orchestrator time is wasted context**: While waiting for fork-runs, the orchestrator could review previous subtree reports, pre-read task specs for upcoming subtrees, or run test suites

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Git index lock in fork-run sandbox (first 8 subtrees only)**: Forked agents could not commit because the initial sandbox config didn't include git worktree metadata in writable roots
  - Occurrences: First ~8 subtrees in queue (010.04–010.11) — all failed on release phase
  - Impact: Each required 3-5 minutes of manual orchestrator intervention (read phases, edit to done, commit manually)
  - Root Cause: Fork config needed writable-roots update for `.git/worktrees/*/index.lock`; once the user updated the config at 010.12, all remaining 18 subtrees completed fully

- **Provider failures**: Codex provider failed on 010.12 twice before config change
  - Occurrences: 2 consecutive failures
  - Impact: ~15 minutes lost, required user intervention to change provider config
  - Root Cause: Provider configuration didn't match available API endpoints

#### Medium Impact Issues

- **Background task notification storm**: All fork-run background tasks eventually completed and generated notifications long after being handled
  - Occurrences: 30+ notifications after main work was done
  - Impact: Cluttered conversation, required acknowledgment responses
  - Root Cause: Background tasks complete asynchronously; no way to dismiss completed notifications

- **Phase status stuck at in_progress**: When fork-run crashed mid-phase, the phase file remained in_progress rather than being reset
  - Occurrences: 3 times (010.10.04, 010.11.04, 010.22.04)
  - Impact: Required manual phase file edits before queue could advance
  - Root Cause: No cleanup/rollback mechanism when fork-run process exits unexpectedly

#### Low Impact Issues

- **Unrelated file modifications from fork-run**: Fork-run for 010.10 (ace-nav) also modified `ace-llm/lib/ace/llm/molecules/client_registry.rb`, which was unrelated
  - Occurrences: 1
  - Impact: Confusion about what to commit; required stash/unstash
  - Root Cause: Forked agent made opportunistic changes outside its task scope

### Improvement Proposals

#### Process Improvements

- Add a "post-fork-run commit" step in the orchestrator drive workflow that automatically commits uncommitted changes after fork-run completes
- Create an `ace-assign complete-subtree <phase>` command that marks all child phases as done in one operation
- Allow fork-run to skip release/commit phases via a flag (e.g., `--skip-commit`) when sandbox restrictions are known

#### Tool Enhancements

- `ace-assign fork-run` should detect sandbox git restrictions before starting and automatically skip commit-dependent phases
- `ace-assign status` should show a clear "stalled: fork-run failed, manual intervention needed" indicator
- Add `ace-assign fix-subtree <phase> --mark-done` to batch-fix stuck subtrees in one command

#### Communication Protocols

- The drive workflow should document the "fork-run fails on commit" pattern and provide a standard recovery procedure
- Background task notifications should be suppressible or batched when the main conversation has moved past them

## Action Items

### Stop Doing

- Polling with long sleep intervals when fork-run is expected to take 10+ minutes — use the idle time productively
- Manually editing 3 phase files per stuck subtree — need a single command

### Continue Doing

- Fork-run delegation for repetitive batch tasks — the pattern works well when commit permissions are available
- Reviewing work-on-task reports before committing — caught quality and scope issues early
- Using ace-git-commit for structured multi-scope commits

### Start Doing

- Pre-check sandbox git permissions before launching fork-run
- Add a "commit-from-orchestrator" phase that runs after fork-run returns, rather than expecting the forked agent to commit
- Use orchestrator idle time during fork-run to pre-read upcoming task specs or review completed reports

## Test Writing Learnings

### In-Process vs Subprocess CLI Testing

The fork-run agents rewrote CLI routing tests using `Open3.capture3` (subprocess spawning), which introduced a severe performance regression:

| Package | Subprocess (Open3) | In-Process (invoke_cli) | Speedup |
|---------|-------------------|------------------------|---------|
| ace-bundle | 7.12s | 0.005s | **1400x** |
| ace-git-commit | 6.34s | 0.004s | **1585x** |
| ace-git | 2.14s | 0.008s | **267x** |

**Root cause**: Each `Open3.capture3` call spawns a full Ruby process with complete gem loading (~1s per subprocess). A 7-test file with 7 subprocess calls = 7s minimum.

**Fix pattern**: The project already had `Ace::TestSupport::CliHelpers` providing `invoke_cli(CLI, args)` which runs `capture_io { CLI.start(args) }` in-process. Two packages (ace-llm, ace-docs) already used this fast pattern on the same branch — the fork-run agents didn't learn from them.

### Key Test Patterns Learned

1. **CLI.start(args) is the in-process entry point**: Every CLI module needs a `.start(args)` class method that mirrors what the exe does. For single-command CLIs: `Dry::CLI.new(Command).call(arguments: args)`. For registry CLIs: `Dry::CLI.new(self).call(arguments: normalized_args(args))`.

2. **Exe-level normalization belongs in CLI.start, not just the exe**: The ace-git exe had `normalized_args` logic (empty args → help, range patterns → diff). Moving this into `CLI.start` made it testable in-process without duplicating logic.

3. **Stub the heavy operations, not the routing**: Routing tests verify command dispatch, not behavior. Stub at the orchestrator/domain level:
   - `Ace::Bundle.stub(:load_auto, mock_context)` — prevents preset file loading
   - `Ace::GitCommit::Organisms::CommitOrchestrator.stub(:new, mock)` — prevents git/LLM operations
   - `Ace::Git::Organisms::DiffOrchestrator.stub(:generate, mock)` — prevents git diff execution

4. **Struct.new can't use `empty?` as a member**: When creating mock objects with predicate methods like `empty?`, use `Object.new` with `define_singleton_method` instead of Struct — Ruby's `Struct.new(:empty?)` raises `NameError: cannot make operator ID :empty? attrset`.

5. **Routing tests don't need exit-code assertions for error cases**: The original subprocess tests checked `refute_match(/unknown command/)` on output — this works identically in-process since `invoke_cli` catches `CLI::Error` and captures stderr.

### Automation Insight: Detect Subprocess Testing Anti-Pattern

A lint rule or test review check could flag `require "open3"` in test files as a potential performance anti-pattern when `CliHelpers` is available, especially for CLI routing tests where in-process testing is always preferable.

## Technical Details

- **Total commits**: ~70 commits across the session
- **Packages migrated**: 25+ ace-* gems
- **Migration pattern**: Remove DefaultRouting → Add HelpCommand.build → Update exe entrypoint → Rewrite CLI routing tests → Bump version → Update CHANGELOG
- **Single-command gems** (ace-search, ace-git-commit, ace-test): Used `Dry::CLI.new(Command).call` pattern
- **Multi-command gems** (all others): Used `HelpCommand.build` with `REGISTERED_COMMANDS` and `HELP_EXAMPLES`

## Additional Context

- PR: https://github.com/cs3b/ace-meta/pull/212
- Assignment: work-on-tasks-278 (8plhhk)
- Task: v.0.9.0+task.278 — Drop DWIM Default Routing and Standardize CLI Help
