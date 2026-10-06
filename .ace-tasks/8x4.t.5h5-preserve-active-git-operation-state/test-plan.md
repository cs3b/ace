# Test responsibility map

All operation safety behavior is high risk because it protects user Git state.

| Behavior | Layer | Evidence |
| --- | --- | --- |
| Git-resolved marker paths, precedence, absent markers, failed resolution/stat | Fast atom | Operation inspector tests with executor/filesystem boundaries |
| Guard before stager/split/message generation, all option shapes | Fast organism | Orchestrator strict mocks reject downstream calls |
| Resolved/unresolved merge, rebase, cherry-pick, revert preserve state and continue | Deterministic feature CLI | Disposable real repositories; index/refs/markers/content snapshots, native continuation |
| Linked worktree operation isolation and sequencer/git-am | Deterministic feature CLI | Git-created metadata; refusal matrix and native continuation where real operation |
| Ordinary scoped and staged-only behavior | Deterministic feature CLI and existing fast suite | Requested commit files and unrelated changes preserved |

Fast tests inject only external Git/filesystem boundaries. Feature tests use real Git and CLI with supplied messages, avoiding network/LLM. CLI mode matrix covers explicit paths, all, only-staged, split/no-split, dry-run, quiet and debug. No duplicate full matrix per operation: resolved merge owns matrix, other operations own detection and native continuation. Inspection failure tests own malformed/failed Git path resolution and inaccessible metadata; empty/no-change controls remain existing coverage.

Verification: `bin/ace-test ace-git-commit all`, targeted new feature file through `bin/ace-test` first, then package suite. No raw Ruby package test invocation.

Independent spec readiness: root APPROVE, 2026-10-06. Per-worktree Git-resolved markers, fail-closed pre-mutation guard for all modes and verified native continuation accepted; no shared enum redesign.

Executed package verification: `bin/ace-test ace-git-commit all`: 267 tests, 943 assertions, zero failures/errors. Final report `.ace-local/test/reports/git-commit/4d9b2121-5da8-4df8-bcb8-35484b4b5df3/`. Six real CLI feature tests verify merge mode matrix plus unresolved/resolved preservation, linked cherry-pick/rebase isolation, native revert/git-am continuation, sequencer markers, ordinary scoped/staged-only behavior. Targeted initial detector/orchestrator tests: 22 tests, 62 assertions passed.

Lint passed six files with warnings (existing changelog formatting/link references and seven new test style warnings, repaired before final tests). `git diff --check` clean. Independent implementation review and root integration remain outstanding; task stays progress.
