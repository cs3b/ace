# OTP expiry implementation evidence

Regression reproduced before the fix: controlled delivery at expiry minus one second followed by direct-store consumption exactly at expiry returned a secret instead of raising StateError. `bin/ace-test ace-hitl test/fast/lifecycle/otp_challenge_test.rb` failed (12 tests, 73 assertions, one failure); retained report `.ace-local/test/reports/hitl/8x3vtx/`.

Store now checks the persisted challenge deadline under request/live-authority locks both before vault read and immediately before terminal commit. Expiry discards the challenge secret and creates no consumed receipt; the enclosing request/assignment is not cancelled. MemoryVault clamps retention to min(delivery + TTL, challenge expiry) and deletes expired entries. A locked delivery check closes the equivalent delivery/read window.

Coverage uses controlled time for exact/after challenge deadlines, delivery just before expiry, duplicate/repeated consumption, file and memory vaults, waiting consume, restart, vault TTL first, direct vault clamp, and custom vault read crossing expiry. Real authenticated AF_UNIX client/service tests cover a valid pre-expiry transfer, wrong operation, secret-free retry and repeated expiry refusal; existing foreign-requester/ended-attempt tests remain green.

Executed final package verification: `bin/ace-test ace-hitl all` — 221 tests, 1181 assertions, zero failures/errors, one skipped distinct-user/root acceptance fixture (41.71s). Report `.ace-local/test/reports/hitl/8x3vx8/`. `bin/ace-lint ace-hitl/docs/usage.md ace-hitl/CHANGELOG.md` passed with 92 existing style warnings; `bin/ace-task doctor` exit 0, 463 historical warnings; `git diff --check` exit 0.

Task remains in-progress. Exact-head independent review, combined integration with vft, installed multi-user/Telegram/publisher acceptance and coordinator release remain required. No release/version bump, merge, deployment, secret change or external message performed.
