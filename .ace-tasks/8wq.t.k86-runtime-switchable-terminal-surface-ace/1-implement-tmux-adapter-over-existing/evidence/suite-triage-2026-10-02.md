# Suite triage — k86.1 verify-test-suite (2026-10-02)

Branch `k86.1-tmux-runtime-adapter` (HEAD 599df0900) vs base `5bdc5c1f8` (main).

`ace-test-suite --target all` on the branch: 44 packages passed, 6 failed. Every failing
package was re-run individually on BOTH trees; all pass with identical test/assertion
counts. The branch does not modify any failing package (only version/changelog bumps in
ace-assign; ace-demo and ace-overseer followers passed inside the suite).

| Package | Base (individual) | Branch (individual) | Branch suite failure |
|---|---|---|---|
| ace-support-config | 252 ✓ | 252 ✓ | `test_deep_merge_performance` median 0.278s > 0.25s threshold under parallel load |
| ace-idea | 258 ✓ | 258 ✓ | `test_creator_raises_argument_error_when_clipboard_empty` (clipboard env) |
| ace-test-runner | 176 ✓ | 176 ✓ | hermetic fixture-home / exe-path expectations under parallel HOME overrides |
| ace-llm-providers-cli | 400 ✓ (`all`) | 400 ✓ (`all`) | open_code ArgumentError trio only under suite parallelism; package bit-identical to base |
| ace-assign | 741 ✓ (82s) | 741 ✓ (71s) | timeout at 120s per-package cap, 0 tests executed |
| ace-review | 997 ✓ | 997 ✓ | timeout at 120s per-package cap, 0 tests executed |

Branch-targeted packages: ace-tmux 319 ✓ (854 asserts), ace-runtime 150 ✓ (407 asserts).

Verdict: zero regressions attributable to this branch; suite failures are
load/environment artifacts of the parallel hermetic run, matching the pre-existing
suite-noise precedent from 8wr.t.qjl and 8wq.t.k86.0.
