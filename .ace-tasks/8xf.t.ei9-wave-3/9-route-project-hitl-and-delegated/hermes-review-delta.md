# Hermes source review delta

Base: `c1e9fe02bfaad37974d6e070129d360e5f25b125`; separate branch `codex/ei9-hermes-review-delta` preserves the reviewed operator freeze. Review source: PR375 session `review-8xfshr` actual configured Pi report; root verified feedback IDs `8xfsqo26` through `8xfsqo2e`.

| Feedback | Disposition |
|---|---|
| 26 M1 | Ruby already retains exception causes. Preserve existing typed IngressUnavailable refusals unchanged; a closed reason table supplies static messages. Only this exact typed static diagnostic is logged during poll/drain; raw lower-level messages/OTP are not. Regression verifies the specific route reason, raw cause retention, and diagnostic redaction. |
| 27 M2 | Intentional fail-closed project ordering. Document exact trusted backup/digest/identity restoration, same journal/offset and no journal surgery/abandonment; exercise actual missing-file and atomic exact-byte restoration. Other projects retain independent draining. |
| 28 L1 | Reuse HermesAtomicWriter.sync_directory for parent and cleanup barriers. Parent barrier also applies on existing-directory recovery, covering interruption between mkdir and parent fsync. |
| 29 L2 | Normalize only captain_user_ids as a unique sorted set during Registry admission. Both project and instruction route bindings use this admitted representation. Regression keeps unrelated array ordering significant. |
| 2a L3 | Closed runtime schema is runtime/v2, no fallback or migration. Update source/current examples and positive runtime fixtures, including HITL consumers. Regression refuses v1 and preserves its bytes. Domain deployment plan must select v2. |
| 2b L4 | Root owns root CHANGELOG release formatting; deliberately excluded here. Package Unreleased notes describe this delta. |
| 2c L5 | Fake Lifecycle counts every deliver invocation, independent of its idempotent answer projection; terminal crash/restart regression requires exactly one invocation. |
| 2d cleanup | Return before constructing ingress box when terminal body is already absent. Regression removes the empty directory and proves drain does not recreate it or redeliver. |
| 2e eager ingress | Skipped design: lazy private folder creation and durability occur before offset acknowledgment; activation already validates authority/channel roots, and eager creation cannot guarantee future capacity. No speculative storage API. |

No publication, deployment, version bump, journal edits or abandonment protocol. Legacy domain history/all-group installation remain open. The separate operator states race fix and its prior actual Pi approval remain unchanged.

Verification and fresh configured Pi verdict are recorded after the frozen source commit. No monorepo suite duplication.

Executed source verification:

- Focused Hermes routing/diagnostics: 23 tests,136 assertions PASS, report `hitl-hermes/78dacb0f-5763-46f3-970f-20c333463557`.
- Final entire Hermes package: 192 tests,1115 assertions PASS, report `hitl-hermes/5f76f0e5-b9a3-4417-9652-3c7093b73db8` (28.03s).
- HITL proposal feature/real socket runtime consumers: 28 tests,186 assertions PASS, report `hitl/8d6cf319-ce36-4fe7-a619-0428c6421bad` (2m03s). Installed consumer fixture schema updated consistently; a fresh installed-artifact scenario remains the release gate.
- `git diff --check` PASS. Initial fresh-worktree tests refused missing Bundler dependencies before execution; reused the established ignored vendor dependency tree, then tests ran against this checkout. An in-flight process that loaded the pre-cleanup-guard source caught the new cleanup regression (1 failure); a fresh final process passed all192. A method-name `--filter` attempt selected no files and is not counted as verification.

Fresh actual configured Pi delta review is required for the frozen commit; no source gate or installed acceptance is inferred from these author tests alone.
