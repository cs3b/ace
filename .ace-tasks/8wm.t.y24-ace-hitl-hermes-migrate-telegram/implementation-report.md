# Hermes implementation candidate — 2026-10-04

Worktree: `/Users/mc/Ps/ace/.ace-wt/codex-wave4-hermes`; branch `codex/wave4-hermes`; foundation `ce7e39228` includes the published prerequisite repairs.

## Delivered package boundary

Hermes owns exact project/group/target registration, Captain allowlists, Reply and explicit command correlation, ordinary protected folder publication, sanitized submission acknowledgement, durable receipt time/sequence, Telegram cursor and reconciliation. `ace-hitl` owns authenticated actor/project authorization, active binding validation, terminal history, lifecycle effects and scoped ephemeral OTP consume.

`serve` is a package-owned Bot API poller. Startup requires `polling_owner: ace-hitl-hermes` and verifies the named actual Hermes gateway configuration has `platforms.telegram.enabled: false`. The operator must apply/restart the gateway before starting it. A nonblocking actor lease excludes another package poller. Conflicting/error polls invalidate coverage. The guard plugin alone cannot issue a healthy checkpoint.

Every ordinary answer publisher now requires authenticated request classification. OTP/sensitive classification is rejected before any file creation. OTP enters `ace-hitl` IPC directly and never enters Hermes answer folders, journal, checkpoint or instruction pipeline. Endpoint failure records only `secret-unavailable`, discards the transient value and requires a fresh authorized challenge. Third-party Telegram message history is outside the erasure guarantee.

The journal uses a private, single-writer fsynced JSON file, same-directory atomic rename and directory fsync, following the existing folder/store patterns. This implements transactional ordering without adding SQLite. It retains non-secret correlation/receipt metadata for at least the required 24 hours; authoritative lifecycle history remains independent. No compatibility or registry fallback path was added.

## Executed evidence

- `bin/ace-test ace-hitl-hermes all`: **100 tests, 585 assertions, zero failures/errors**. Receipt: `.ace-local/test/reports/hitl-hermes/8x3ygl/`.
- `bin/ace-test ace-hitl all`: **219 tests, 1181 assertions, zero failures/errors, one existing opt-in multi-UID edge skip**. Receipt: `.ace-local/test/reports/hitl/8x3y72/`.
- `git diff --check`: clean.
- Clean installed acceptance builds the current Hermes package and complete local dependency closure, installs into empty GEM_HOME without repository load paths, invokes the installed executable against a real local authenticated Unix socket, delivers an OTP surrogate and verifies absent answer folder/public value, then installs guard assets from that gem. Current controlled identities use the test UID and numeric test group; no real Telegram destination is contacted.
- Installer archives, installed tree and non-secret proof retained at `.ace-local/test/artifacts/hitl-hermes/installed-20261004225825-7a8e4e6a/`.
- Tests cover same/cross-channel Reply, unauthorized sender, malformed/unknown correlation, explicit command, plain instructions, uncertain/failed/wrong-chat submissions, immutable request binding, retry without second effect, crash after ordinary folder write, cursor held on unresolved ingress, durable sequence/receipt clock, queued/retention/poll gaps and reply/checkpoint serialization at timeout cutoff.

## Remaining acceptance gates

Independent current-head review has not yet run. This candidate does not authorize merge or publication.

No real Telegram test destination was authorized, so task SC2's actual registered Telegram channel is **unverified**. `lab-config:gad.2` deployment/adoption and removal of the old `hermes-lab-hitl`, `lab-hitl-broker` and `lab-hitl-channels` files are **unexecuted external acceptance**, not claimed by the controlled package fixture. SC3's package test half passes; its Lab smoke half remains open. Keep task status in-progress and do not mark full Lab acceptance.

Source version remains 0.1.0 with Unreleased changelog; coordinated version preparation belongs to the parent after independent review/integration, and publication requires Captain's interactive OTP.

## Skills applied

Loaded and executed `as-task-work`, `as-git-worktree-create`, their workflow bundles and the generated JIT task plan. Loaded `as-test-plan`/`wfi://test/plan` and retained the responsibility map. Loaded `as-git-commit`/`wfi://git/commit` and used path-scoped ACE commits. No nested subagents were started.

## Independent review repair — 2026-10-05

The independent review rejected `1d016f20d` for three verified P1s. The replacement candidate repairs all three without changing the live Telegram/Lab acceptance boundary:

1. Retention gaps are invalidated durably before any successful response batch can advance the cursor. Requests bind to a coverage generation; a recovered epoch cannot certify requests from the old generation. Prior poll epochs remain in the non-secret journal.
2. An unhealthy epoch can recover on verified empty polling, beginning fresh coverage instead of inheriting unhealthy forever. Fresh requests in that epoch can obtain healthy checkpoints; older requests remain unknown. Startup now establishes coverage before sending new questions so those submissions fall within the new epoch.
3. A crashed queued sensitive receipt becomes sanitized `secret-unavailable` on replay, without IPC redelivery. Polling can advance its offset; both duplicate and newly messaged codes on the interrupted original challenge remain unavailable, requiring a fresh authorized challenge.

Durable regressions include the three exact reviewer behaviors plus old/new epoch separation, history preservation, cursor advancement without secret IPC, original-challenge refusal and startup poll/send ordering.

Executed repair receipts:

- Hermes full suite: **106 tests, 607 assertions, zero failures/errors**, `.ace-local/test/reports/hitl-hermes/8x3yqk/`.
- HITL full suite: **219 tests, 1181 assertions, zero failures/errors, one existing opt-in multi-UID skip**, `.ace-local/test/reports/hitl/8x3ype/`.
- Original reviewer PoCs with repaired-library bootstrap: **49 tests, 198 assertions, zero failures/errors**, `.ace-local/test/reports/hitl-hermes/8x3yql/`. The unchanged reviewer file directly requires its own worktree library; direct invocation before updating that checkout reproduced the original three failures (`8x3ymz`). Independent recheck should update the reviewer worktree to the replacement SHA and run its original file directly.
- Installed clean-home artifact proof retained under `.ace-local/test/artifacts/hitl-hermes/installed-20261004230927-433245fc/`.
- `git diff --check`: clean.

Task remains in-progress, source version unchanged, no merge or publication. Fresh independent review remains required.
