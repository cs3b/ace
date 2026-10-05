# Integrated source verification — 2026-10-05

Exact main at final run: `c4b1db0386cfbb9618d2bc065482e83d0db4e40f`. This includes accepted recovery/Hermes source, fixture correction and reviewed boundary/consumer specifications. It excludes unmerged vs2, delivery repair and protected authority implementation.

- `bin/ace-test-suite` at prior `394d816dc`: 49 package entries passed, 2 failed. Hermes built-install fixture expected a nonexistent archive for default Fiddle; corrected and independently reviewed in `673eb0f08`. ace-assign reached the unchanged 120-second package limit under default parallelism.
- `bin/ace-test ace-assign all`: 803 tests / 3120 assertions, zero failures/errors, two existing edge skips; receipt `assign/8x4010`, 9m10s. Its package source did not change during the run. Feature tests account for 7m24s; no performance improvement is claimed.
- `bin/ace-test-suite --parallel 2` on final main: **51 package entries passed, 0 failed; 11162 tests passed, 24 skipped; 33863 assertions; 186.73s; exit0**. ace-assign fast: 778 / 2861 in111.65s; Hermes106 /607. Per-package120s timeout stayed unchanged. Lower contention passes; default-parallel timeout remains a recorded execution limitation, not a successful default run.

Suite package entries include the existing repeated ace-lab registration; totals are reported as emitted, not a claim of51 unique gems. The requested --profile flag from the older health-audit workflow is absent from current suite help, so timings above are executed runner timings rather than invented per-test profiles.

This is source verification, not publication propagation or installed Lab acceptance. Actual Telegram/native Codex/Pi/cross-user kernel boundaries and R2/R3 remain required. Lab access was not available: SSH Tailscale check expired; the new check is pending. No same-UID fixture, native capability probe or source report closes those installed gates.
