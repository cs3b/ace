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

- **Git index lock in sandbox**: Fork-run agents consistently failed on the release/commit phase due to git worktree index lock permissions (subtrees 010.04–010.07, 010.10–010.11, 010.22, 010.27). This required manual intervention from the orchestrator for ~8 of 26 subtrees
- **Manual phase fixup overhead**: When fork-run failed on release, the orchestrator had to: read 3 phase files, edit them to done, commit manually, then continue. This pattern repeated ~8 times and consumed significant orchestrator context
- **Long polling cycles**: Each fork-run took 10-20 minutes. The sleep-and-poll pattern used ~60% of orchestrator time on waiting. No productive parallel work was done during these waits
- **Stale background task notifications**: Completed fork-runs generated notification messages long after the orchestrator had moved on, requiring 20+ "handled/standing by" responses
- **Provider instability**: The codex provider failed on 010.12 twice before config was changed, wasting ~15 minutes

## Key Learnings

- **Fork-run sandbox git permissions are a systemic issue**: The sandbox environment restricts writes to `.git/worktrees/*/index.lock`. This affects any fork-run that tries to commit. The fix was eventually applied to the fork config, but the first ~8 subtrees all hit it
- **Orchestrator should batch-fix phase files**: Instead of reading+editing 3 files per stuck subtree, a single `ace-assign` command to mark a subtree as done would save significant time
- **Release phase should be optional or orchestrator-owned**: Since the orchestrator has git commit access and the forked agent doesn't (in sandbox), the release phase should either run in the orchestrator context or be skipped in fork-run
- **Idle orchestrator time is wasted context**: While waiting for fork-runs, the orchestrator could review previous subtree reports, pre-read task specs for upcoming subtrees, or run test suites

## Conversation Analysis

### Challenge Patterns Identified

#### High Impact Issues

- **Git index lock in fork-run sandbox**: Forked agents cannot commit because the sandbox restricts access to `.git/worktrees/*/index.lock`
  - Occurrences: ~8 out of 26 subtrees (010.04–010.07, 010.10–010.11, 010.22, 010.27)
  - Impact: Each required 3-5 minutes of manual orchestrator intervention (read phases, edit to done, commit manually)
  - Root Cause: Sandbox writable-roots don't include the parent git repo's worktree metadata directory

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
