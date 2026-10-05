# Integrated runner verification — 2026-10-05

Accepted package source is merge `069af128d70110a649d9806eefc3ee00036afb6f`; subsequent commits during these runs changed task documents only. No package source changed during the final full suite.

- Independent package review and root post-merge checks passed 258 tests/987 assertions with zero failures, errors or skips; receipts `8x43eh` and `8x43gf`.
- First `bin/ace-test-suite --parallel 2` completed exit 1: 50 configured entries passed, Assign exceeded the existing 120-second package ceiling, 10,379 tests passed and 24 skipped, 194.74 seconds. Other agent/reviewer checks were running concurrently. This remains a failed execution, not a passing baseline. The suggested `assign/latest` artifact was older and was not used as evidence for this invocation.
- Final `bin/ace-test-suite --parallel 1` completed exit 0: 51 configured entries passed, 11,172 tests and 33,925 assertions passed, 24 skips, 358.71 seconds. Assign completed 792 tests/2,930 assertions in 112.78 seconds. No deadline, package membership, target, environment policy, or test was changed. The configuration already lists ace-lab twice; 51 entries does not mean 51 unique gems.

The sequential run verifies integrated execution under the unchanged ceiling. The earlier timeout and narrow Assign margin remain explicit resource/performance limitations; this comparison alone does not prove a particular scheduler or product root cause. Full native Lab acceptance is not implied.

A diagnostic attempt with `--config` unexpectedly selected the default 51-entry suite and was intentionally interrupted with exit 130. Task `8x4.t.3r3` now tracks that pre-existing flag bug as a separate draft. Temporary isolated-directory attempts failed during bootstrap and are not acceptance evidence. No source workaround or timeout increase was used to obtain the final full-suite result.
