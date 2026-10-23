# Event-driven eyes implementation checkpoint

Owner sbz.6.2; dependencies sbz.5 and sbz.1 read back done. Prior receipts retained.

Plan: expose bounded semantic HITL revisions through the HITL owner; integrate deterministic native sync and observation into existing Pi wake extension; retain pending/acks and breaker in existing session custom entries; preserve report adoption in sbz.5.4; add clock/filesystem/restart/uncertainty coverage and packaged usage. No new queue, daemon, runtime override or provider request.

Friction recorded before edits: task/work suggests an LLM-generated task plan, but this execution explicitly forbids provider calls. This local checklist substitutes for that generation. Existing wake persists definitions only, fingerprints mtime/size, and settles in-memory pending on agent_settled; these do not satisfy semantic/durable acknowledgement. HITL list has no machine-readable semantic revision projection; that belongs in ace-hitl, not a duplicate Markdown parser in Pi.

Source checks, publication and live acceptance remain separate. Never restore stopped legacy loops for testing.

Executed first HITL projection test: 1 test / 7 assertions pass. First Pi suite: 9 Ruby tests / 86 assertions, 1 wrapper failure (two Node lifecycle assertions). The session harness invokes only the first registered lifecycle handler; adding eyes revealed that it did not exercise actual multiple-handler Pi semantics. Correct harness to execute all handlers and add integrated lifecycle coverage before accepting the source.

Implementation review friction: slash-only acknowledgements are operator commands, not an agent tool. Add a narrow native Pi status/ack/deadline tool, keeping start/resume/retire operator-controlled. Also found delivery failures reset their consecutive-error counter before send; corrected to reset only after a successful observation/delivery cycle, with regression coverage.

Integrated eyes-start regression caught incorrect assumed WakeRegistry.list shape (array, not loops/watches object). Start failed before dispatch. Correcting adapter against actual public list entries; the new lifecycle test covers removal/reload/retirement.

Full HITL source suite: 336 tests / 1740 assertions, one TLS fingerprint assertion failure, 5 skips. Reproducing that exact target against unmodified df906e5 before disposition. Pi SDK acceptance skips because the host wrapper does not expose an installed SDK package; found a stale hardcoded asset count in that skipped fixture and will make it assert the actual projected source inventory. Canonical owner filtering/adoption coverage added after scope review: outbound Captain events must never create a self-wake loop.

Final state review caught partial-batch acknowledgement releasing the whole in-flight notification, which could requeue unhandled members. Corrected to release only after every dispatched member is acknowledged/settled/cancelled, with a regression; cancelled deadlines also release their notification slot.

Found cached host Pi SDK 1.4.0 under npm npx cache (not a runtime install). Existing acceptance discovery missed non-symlink npx wrapper and assumed nested rather than hoisted dependencies. Extending only the test discovery to explicit PI_PKG_ROOT and package-relative module resolution so the real SDK test can execute without provider calls.

SDK test still skipped with explicit fixture override: its node check used `system("command", "-v", candidate)`, which tries to exec a shell builtin as a binary. Replace that test-only check with executable PATH lookup, then run the real cached SDK. This is test-discovery repair, not a live runtime workaround.

Real SDK discovery progressed but fixture import failed: pi-ai exposes ESM imports only, so CommonJS require.resolve rejects its root export. Resolve the existing fixture entrypoint via SDK module search directories (works for nested/hoisted packages) without importing through CommonJS.

Real Pi SDK 1.4.0 now executes: seven existing acceptance cases pass, new eyes-tool case fails `Eyes session not initialized` (SDK tool can run before session_start notification). Use the documented fifth tool context argument to lazily bind the same session owner, matching slash-command initialization; rerun real SDK before freezing.

## Source validation / handoff

Implemented in ace-handbook-integration-pi, ace-hitl and ace-overseer; Hermes production transport is reused unchanged. The Hermes test exercises actual native sync and source CLIs into Eyes on real temporary folders. Observation never invokes process-reports: the agent retains that decision, and canonical adoption/continuation remains with sbz.5.4. Owner selection excludes outbound Captain reports/questions and other recipients/projects. Matched closed/archived manager trees suppress historical notifications; recorded reports with incomplete continuation remain eligible. Pending acknowledgements are session delivery state, not a new business journal.

Executed checks:

- `bin/ace-test ace-handbook-integration-pi fast`: 9 Ruby wrapper tests, 94 assertions, pass; includes accelerated 24h/zero-notification, partial-batch coalescing, restart, exact ack, actual quota lifecycle hook, explicit resume, deadline cancellation and retirement.
- Real host cached Pi SDK 1.4.0: `bin/ace-test ace-handbook-integration-pi feat --config-path /tmp/ace-eyes-sdk-test.yml`, with fixture `environment.overrides.PI_PKG_ROOT` pointing to the existing SDK package. 1 Ruby wrapper / 5 assertions, eight underlying SDK cases pass (including actual projected eyes tool schema/execution). Report `handbook-integration-pi/9b3975b3-0989-4b0f-93d2-718c80b90eef`. Scripted local streams only; no external provider requests.
- `bin/ace-test ace-hitl-hermes all`: 212 tests / 1225 assertions, pass. Report `hitl-hermes/9188781d-e136-4d98-a2f9-8ca03b751b31`.
- `bin/ace-test ace-overseer all`: 373 tests / 1674 assertions, pass. Report `overseer/f127ef3d-5188-4c38-a8bb-e677739db140`. Final canonical-terminal helper check: observation test 1 / 7 pass, `overseer/c2fbc49a-6968-445e-bd0f-4193f23ba976`.
- `bin/ace-test ace-hitl all`: 337 tests / 1748 assertions, one existing TLS assertion failure, five skips. Report `hitl/24d46ffc-8b01-42ed-a660-20e09e6fcc3b`. All new observation tests and all atoms/molecules/organisms/commands/providers pass. Exact TLS target independently reproduced on unmodified df906e5 export: 9 tests / 42 assertions, same fingerprint-vs-connection-reset failure (`/tmp/ace-eyes-baseline-df906e5`, report `hitl/62a7b3e4-525e-4034-9f17-92edfecccfc3`). Not claimed green or fixed here.
- Existing report continuation safety: 16 tests / 106 assertions pass (`overseer/c6bd5197-6041-4194-9830-192e6a0189b1`).
- `ace-task doctor`: 860 tasks, 509 pre-existing warnings, unchanged health score 0/100. Host task-ID provenance test: 1 pass; no new task IDs. Diff whitespace check and changed-file Gitleaks pass.

Task stays in-progress. Source review, coordinated package publication (HITL observation + overseer adapter + Pi assets with matching dependency floors), installed-only projection and actual live Telegram/report/24h no-change acceptance are still required. No Lab installation, agent dispatch, provider call, old loop restoration or external business effect was performed by this implementation. Existing sbz.5.4 and sbz.0.1 retain adoption/retirement ownership.

## Independent review R1 — REJECT, before correction

Exact candidate 0c6785dc: real Pi SDK sendUserMessage is a void wrapper which catches async rejection. During compaction, Eyes treated void as acceptance and stranded pending forever (review PoC: acceptedUserWakes 0, pending 1, attempts 1, observations 7, no breaker). Fix must distinguish attempted notification from actual matching user-message acceptance. Reconcile through existing Pi message_start, idle/pending and compaction lifecycle surfaces; keep uncertain queued notification without retry while host busy, retry rejected delivery only on a later bounded observation, and retain independent business acknowledgement. No new queue or journal. Reviewer report /tmp/ace-eyes-code-review.md.

Correction refinement: existing Pi API exposes no async rejection receipt. Idle with no queued messages is insufficient proof of rejection because input/auth preflight can await while isIdle remains true. Defer sends during known compaction/non-run busy states; correlate actual message_start as acceptance. An attempted void send with idle/no confirmation becomes notification-unconfirmed (durable breaker), never an automatic resend. Owner must reconcile before explicit resume. Added real SDK delayed-input test to prevent duplicate prompts from this uncertainty window.

R2 first rerun exposed three old test callers not awaiting asynchronous lifecycle helpers (two settle, one agentStart), now visible with multiple legitimate lifecycle subscribers. Add the missing awaits so assertions run after every handler, preserving actual SDK order.

R2 executed validation: `bin/ace-test ace-handbook-integration-pi all --config-path /tmp/ace-eyes-sdk-test.yml` passes 10 Ruby wrapper tests / 99 assertions, no skips. Report `handbook-integration-pi/c680f2a9-3058-4596-a3fd-a436d667d597`; real SDK cases include the review's compaction condition, busy queued follow-up, asynchronous input interception, delayed preflight without duplicate prompts, breaker survival across actual extension reload and explicit safe resume. The exact compaction condition now records zero attempts during compaction and one accepted notification afterward; business pending remains until owner acknowledgement. `bin/ace-test ace-hitl-hermes test/fast/organisms/native_sync_test.rb` passes 10 / 51 (`hitl-hermes/80a898b1-b95b-456a-95d3-0b86d62e708f`). No unaffected full suites or known baseline TLS suite repeated. Source remains unpublished and task remains in-progress.

## Bounded TLS baseline diagnostic (after eyes R2 approval)

The reproduced tls_service_test.rb:90 failure expects a server-internal fingerprint error in the unauthenticated client's response. Production TlsService#authorize! rejects the mismatched pin. FrameServing#serve_connection rescues Lifecycle::Error (including TransportError), attempts an error frame and then closes the socket; the client can observe that frame or ECONNRESET during transport teardown. This is a stale test-layer expectation, not evidence that TLS identity checks failed. Proposed test-only correction observes the real authorize! rejection locally while retaining a real TLS 1.3 peer, client TransportError, and no stored requests. No production behavior change or commit authorized by this diagnostic.

TLS test-only correction results: focused real TLS suite 9 tests / 45 assertions, PASS (`hitl/dc09c9af-6c03-4144-8add-78a6a929aa8e`); complete `bin/ace-test ace-hitl all` 357 tests / 1806 assertions, zero failures/errors, six skips (`hitl/6e54f68f-2037-4e78-a2e9-bce13623d5ee`). Full run now reaches later fast/edge targets previously skipped by fail-fast. The exact pinned client also succeeds in the amended rejection test. Production TLS unchanged. This two-file diagnostic/test delta remains uncommitted for independent review; Gitleaks/diff checks and host task-ID test pass.

Independent TLS review finding recorded before correction: the diagnostic and test comment incorrectly said authentication rejection closes before any lifecycle frame. FrameServing#serve_connection rescues Lifecycle::Error (including TransportError) and attempts an error frame before closing; the client can observe that frame or a connection reset. Correct only those descriptions; retain the exact local pin rejection, client TransportError, zero stored requests and successful pinned-client assertions.

Release preparation: local bundle resolution refused HITL 0.24.0 because published Hermes 0.9.2 constrains HITL below 0.24. Required dependency-only Hermes 0.9.3 release will adopt the new floor; this is a graph compatibility follower, not a test-only package bump. No runtime installation or publication performed.

Release validation friction: installing unpublished candidate artifacts through a filename glob tried coworker/Pi before their unpublished dependencies and correctly refused missing versions. Use the publisher’s dependency order for the isolated host acceptance installation; do not weaken dependency floors or publish to satisfy the test.

Coordinated source release candidate (PR71 + PR72): git 0.31.0, Forgejo 0.8.0, GitHub 0.5.0, HITL 0.24.0, Hermes 0.9.3 dependency follower, review 0.62.2, coworker 0.6.2, overseer 0.26.0, Pi integration 0.7.0. Local bundle resolution passes; publisher --dry-run confirms exactly nine pending gems in dependency order. Handbook itself is unchanged and is not bumped.

Release verification: all nine gems built and installed with their published dependencies into an isolated temporary host GEM_HOME, without source path gems or Bundler/RUBYOPT/RUBYLIB overrides. Packaged HITL/overseer observed a real temporary report and ignored delivery-only metadata; all nine exact versions activated together, all loaded non-default gems came from the private installation, and packaged reviewer/workflow/Pi message_start assets were verified. Installed ace-git pr approve help exposes exact-head/report/correlation options. Initial acceptance-script marker referenced eyes-runtime instead of eyes for the breaker; corrected the assertion to that module’s actual message_start hook. No product fix was needed.

Focused release suites: Pi real SDK 10/99, git formal approval 18/107, Forgejo 9/139, GitHub 6/128, HITL observations 3/18 and overseer observations 1/7, all PASS. Reports reside in each package’s .ace-local/test/reports (Pi shared root), release worktree /tmp/ace-eyes-release-20261023. This validates source artifacts on the host only; no credential probe, publication, live activation or real-time 24-hour acceptance performed. Existing task remains in progress.
