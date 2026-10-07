# Original foreground launch CLI consumer

The existing authority launch command calls `LaunchDriver#serve_control!(state:)` only for its newly issued launch result. Dry run, failed/uncertain outcomes and replayed reservation retain their ordinary JSON response and do not enter the original control loop. The driver remains the authority for original ownership.

Readiness is one bounded JSON line, flushed before returning to the retained control loop. CLI checks the exact typed frame and selected mapping/assignment/attempt. Duplicate, missing, malformed, mismatched or oversized readiness raises a CLI error without a second success line. Local ensure cancellation requests only that driver's loop cleanup; neither interruption, EOF nor process exit produces a stopped/settled proof.

Controlled public CLI tests: `bin/ace-test ace-assign test/feat/authority/public_launch_test.rb --timeout 60` PASS 8 tests/73 assertions, receipt `1de6a440-2088-43f0-9a66-ce1e8d3bab38`. These tests inject the Driver boundary and prove CLI ordering/flush/lifetime/error behavior; they are not the genuine protected Server/Driver integration or installed acceptance.

Independent scoped review by wave_n0n: APPROVE the two-file consumer/test diff. The same original Driver API is being implemented separately in its owned source worktree. This consumer must be joined with that producer and verified through the maintained CLI/Driver path before main integration. xz9.2 remains in progress; source stop/drain and whole installed acceptance are not delivered by this checkpoint.
