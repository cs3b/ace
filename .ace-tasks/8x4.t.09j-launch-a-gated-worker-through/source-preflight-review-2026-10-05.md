# Protected launch source preflight review — 2026-10-05

Reviewer: root, independent of the 09j implementation author. Scope: work in progress in `codex/wave5-protected-launch`, before a frozen candidate or full-source acceptance. This record does not approve the task or installed protected launch.

## Resolved finding: terminal attempt continued to own its scope

`LaunchLifecycle#terminal_events?` read `transition.payload.state`, while the authority wrote `transition.payload.to` and the canonical journal derived the attempt state from `to`. Consequently, a positively observed pre-release child termination produced a canonical failed attempt, but a new reservation of the same scope was refused as already owned. Definition replacement was similarly blocked by the inconsistent terminal predicate.

The reviewer added an isolated real-journal regression under the author's ignored `.ace-local/review/09j-preflight/terminal_scope_test.rb`. It reserves, records the child, observes positive termination through the controlled kernel boundary, aborts, confirms canonical `failed`, then requests a new reservation of the same scope.

- Before correction: `bin/ace-test ace-assign /Users/mc/Ps/ace-wave5-protected-launch/.ace-local/review/09j-preflight/terminal_scope_test.rb`; receipt `assign/8x42gf`: 7 tests, 47 assertions, 1 error. The replacement reservation raised `AttemptErrors::Conflict: scope is already owned` after the canonical failed-state assertions passed.
- Author correction: use the latest canonical lifecycle projection (`transition.to`, receipt verdict, reconciliation resolution, or process start). Author regressions additionally cover changed definition after all attempts terminate and unchanged canonical ref when another scope remains active.
- Independent retest with the same command: receipt `assign/8x42h7`: 9 tests, 59 assertions, zero failures/errors, exit 0. The loaded test file also includes the author's lifecycle cases, hence the larger count.

Finding resolved in the current source. These runs used the author's evolving worktree; final acceptance still requires a frozen reviewed revision and appropriate package/source tests. Controlled kernel observations here are not proof of native Linux isolation, installed Lab operation, or actual Herdr gate execution.

## Open finding: listener shutdown releases ownership before dispatch ends

Subsequent WIP review of `Authority::Server` found that `stop` closed sockets but did not retain/join spawned receive threads; `serve` then unlinked the endpoint and closed its exclusive owner lock. A handler already in dispatch could continue after that release, while another server acquired listener ownership. Socket closure is not positive completion of an in-flight journal/native operation.

The author confirmed this path on 2026-10-05 and is repairing it. Required regression: block a handler inside dispatch, request shutdown, prove a second owner remains refused until that handler actually ends. Do not claim successful cleanup or release ownership on a bounded wait timeout. Independent repair verification remains open; no frozen 09j source acceptance is recorded here.
