---
id: 8r9m81
title: 8r9.t.j82.5 worktree fix recovery
type: standard
tags: [assignment, 8r9kdv, 8r9.t.j82.5]
created_at: "2026-04-10 14:48:56"
status: active
---

# 8r9.t.j82.5 worktree fix recovery

## What Went Well
- Recovered the intended `fix/e2e` behavior with narrow scope: `WorktreeRemover` cleanup failure now returns hard errors, and prune uses `--expire now`.
- Added direct regression coverage for both acceptance points:
  - prune arg enforcement (`--expire now`)
  - stuck-directory failure behavior
- Validation was clean at both targeted and package level:
  - `ace-test ace-git-worktree/test/commands/prune_command_test.rb`
  - `ace-test ace-git-worktree/test/molecules/worktree_remover_test.rb`
  - `ace-test ace-git-worktree`
- Release execution completed with package + root changelog updates and coordinated commits (`f220b3b8f`, `cc86910c9`).
- RubyGems propagation proof succeeded on retry with final `SAFE` classification:
  - `.ace-local/test-e2e/8r9m4k2-monorepo-e2e-ts001-reports/report.md`

## What Could Be Improved
- The release workflow text uses `--test-id` for `ace-test-e2e`, but current CLI expects positional `TEST_ID`; this caused avoidable first-attempt failure.
- Initial TS-MONO-001 run was non-deterministic (`PARTIAL 3/4`) before passing on retry, indicating occasional environment/tooling flakiness in proof runs.
- `ace-task update ... status=done` modified the task spec after earlier commit, leaving a residual uncommitted task-file change that should be intentionally handled in closeout steps.

## Action Items
- Add/update workflow guidance so TS-MONO-001 uses the current invocation form:
  - `ace-test-e2e ace-monorepo-e2e TS-MONO-001`
- Track and reduce TS-MONO-001 flake sources around Bundler directory-removal/full-index scenarios.
- Add a closeout reminder/check in work-on-task or release flow to explicitly commit post-status task-spec mutations.
