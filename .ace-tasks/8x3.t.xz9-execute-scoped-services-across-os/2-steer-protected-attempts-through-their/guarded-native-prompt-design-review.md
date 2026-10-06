# Guarded native prompt design review

Reviewed 2026-10-05: scratch `guarded-native-prompt-design.md`, durable xz9.2 task and pinned native source research, and current Runtime SendContract. Design/spec-decision review only; no source change, status change, test, native execution or installed acceptance.

## Verdict and recommendation

The proposal is a sound technical default for **submission to the original attempt terminal**, conditional on a coherent upstream implementation across app, spawned runtime and PTY actor. It closes native pane/runtime retargeting, preserves canonical original spawned-child PID/birth provenance, and honestly treats acknowledgment as text-plus-Enter submission rather than agent consumption. A process exiting after first-write admission cannot retroactively invalidate bytes already issued; partial/unknown submission must remain uncertain without resend.

It does **not** yet satisfy the durable unqualified requirement to refuse a replaced terminal/process before effect. The task's pinned-source clarification explicitly names terminal/process replacement, and current wording does not restrict process replacement to the spawned runtime child. A new foreground provider/descendant in the same PTY can receive input while the original spawned child remains alive and its guard still matches. The design acknowledges this gap correctly. Calling the proposed pidfd check an atomic original-process delivery guarantee would weaken that requirement.

Recommend the terminal-submission model for responsive Overseer: it matches the existing SendContract's single agent prompt and the task's explicit acknowledgment-not-consumption boundary. Exclusive delivery to a particular provider PID is neither established by SendContract nor implied merely by an acknowledgment. However, acknowledgment-not-consumption alone does not erase the separately explicit replaced-process refusal. Before promotion, the durable specification must say whether its target is the immutable original attempt terminal/runtime with a live original spawned child at admission, or the original provider process recipient. This is a real contract-owner/Captain decision if the explicit process-recipient requirement is retained; it must not be silently narrowed by implementation. The recommended terminal model is a proposed explicit scope clarification, not current readiness approval.

## Exact upstream prerequisite

Pinned Herdr v0.9.3 lacks the required guard. Require a reviewed frozen upstream source revision that extends the existing agent.prompt schema/response, exact ID-only terminal resolver, spawn-established kernel origin, captured TerminalRuntime wrapper and PTY actor submission path together. An app-only expected terminal ID or preflight/postflight observation is insufficient. Native-owned origin must capture immutable runtime incarnation and original child identity/handle before the owned Child is transferred to its reaper; restoration/handoff cannot synthesize handle provenance from saved PID. ACE must compare that origin with accepted 09j binding under its pinned authenticated server identity and refuse missing capability.

For the recommended model, native replacement/close/handoff must close admission before detach, never repurpose the old actor's owned FD, and never migrate or retry a partially submitted command. The actor must validate its exact origin and accepting/liveness state immediately before the first actual write, including delayed flush; focus bytes must share that guard. Define this first-write admission boundary explicitly without claiming kernel exit and TTY write are atomic. A death after admission is an issued race; rechecking before later writes/Enter reduces further input but cannot provide exclusive reader truth.

If original provider-process receipt is selected instead, this patch is insufficient: require an existing native/harness owner endpoint with provider-bound delivery or a concrete enforced restriction preventing competing PTY recipients. A foreground-PID recheck, pidfd alone, dedicated server or 9c2 containment does not supply that guarantee. No such prerequisite is delivered in the reviewed pinned source.

## Acceptance conditions

- Independently accept precise target/admission semantics in durable xz9.2 before implementation or promotion; retain no raw text in canonical records and bounded ephemeral prompt transfer.
- Verify exact-ID lookup without pane/name fallback, canonical PID/birth match, app-to-actor immutable pin, rejected guard yielding zero prompt/focus bytes, stale/replaced runtime and unsupported/restored-origin refusal.
- Verify queue/delay races at actual first write, close/handoff ordering, same-PID different birth, and typed definite not-issued outcomes only with positive zero-effect evidence.
- Verify partial text, missing Enter, postadmission death, write failure, server/channel/ACK loss remain uncertain; full text plus Enter alone yields exact-origin submitted; canonical same-ID retry never resends.
- Review frozen upstream source and ACE consumer integration independently, then execute required actual native and installed distinct-user acceptance under authorized gates. Designed tests and source inspection are not executed or installed proof.

No new research branch, native probe or alternate controller is needed to reach this design verdict. xz9.2 remains draft until the semantic decision and missing upstream source prerequisite are closed.

## Decision clarification review — 2026-10-07

Captain explicitly selected original-attempt-terminal submission. Independent
reviewer `/root/wave_412` approved the corresponding canonical specification diff:
immutable original terminal/runtime and spawned-child incarnation at guarded
first write; preadmission replacement refuses with zero bytes; no retargeting;
postadmission death or uncertain writes retain uncertainty without resend;
complete text-plus-Enter acknowledgement means submitted, not consumed.
Descendant readers of the same PTY are explicitly outside any exclusive-recipient
guarantee. The native guard remains absent and draft/needs_review remains set.
This approves decision fidelity only, not source, full readiness or installation.
