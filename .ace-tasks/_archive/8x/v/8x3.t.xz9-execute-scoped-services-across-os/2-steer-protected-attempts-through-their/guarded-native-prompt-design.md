# Guarded existing native prompt: normative source contract

Selected by Captain on 2026-10-07 for original-attempt-terminal submission.
This is the N1 producer contract owned by xz9.2; it is not delivered code or
installed proof. Retained research is based on Herdr v0.9.3. The historical
pre-decision proposal is preserved in history/. Source implementation and
independent review are required; native/multi-UID acceptance belongs to gad.2.

## Selected mechanism and its exact limit

Extend existing agent.prompt with a required guard for the ACE protected invocation, passed through the existing app → captured TerminalRuntime → captured PTY actor. Add a spawn-established original-child incarnation to that runtime/actor. Validate expected guard in the app and again in the PTY actor's first-write admission. Once admitted, retain the same actor and same owned PTY file; never resolve a pane/name again, attach a new runtime, respawn, retry or convert to raw keys. Text plus Enter use the existing submission encoder, queue and acknowledgement.

This can prevent native app target replacement from redirecting the prompt: a replacement gets a new runtime/actor/child incarnation, and an already pinned old-runtime request can only write the original PTY or fail. It does not establish that the agent consumed the prompt, that every PTY reader is the original child, or that a kernel process cannot exit after admission. That distinction is material, not an implementation detail.

**Selected admission boundary:** native effect admission is the actor's guarded
first-write transition. Replacement/revocation before admission yields zero
prompt/focus bytes; child exit or closure after admitted partial submission
returns uncertain without retry. Asynchronous death does not revoke already
admitted input. This contract does not promise exclusive receipt by a provider
PID or atomic kernel-exit plus TTY-write behavior. Descendants sharing the
original PTY may receive bytes. The target remains the original attempt terminal,
with spawn-established original child provenance; terminal ID alone is not
a substitute for that provenance.

## Source evidence establishing owner boundaries

- `src_app_api_agents.rs:82–106,111–214`: app target resolution, validation, captured runtime and existing queue. Positive response waits completion. Currently request has no expected incarnation.
- `src_app_terminal_targets.rs:74–103`: agent targets public pane or name, not terminal ID. Runtime attachment can change between caller pre-read and request. Existing generic terminal resolver supports terminal ID separately at33–70; do not assume prompt does.
- `src_pane.rs:2580–2624`: native child spawn returns owned Child, PID is stored in AtomicU32 and waiter later sets child_wait_completed then posts PaneDied. Cached PID/app event is not current kernel incarnation/liveness proof. The new birth/pidfd capture must happen synchronously before transferring Child into this waiter.
- `src_pty_backend_unix.rs:12–43`: spawn owns child and duplicates actual PTY master into OwnedFd. This is the provenance boundary where runtime origin can be established without caller-selected PID.
- `src_pane.rs:2687–2696`: PTY actor receives that exact master FD, but currently no child origin/handle.
- `src_pty_actor_unix.rs:143–179`: enqueue UserInputSubmission into a bounded1024-command data channel. App success is not enqueue success.
- `src_pty_actor_unix.rs:580–674`: data command admission and active_submission; actor owns write ordering; control commands still run during active submission. Commands queue bytes against this actor, not a mutable app lookup.
- `src_pty_actor_unix.rs:485–525,860–916`: pending write flush, text→delay→Enter, Enter completion ack and fail_active_submission. This is where a guard must reach actual first prompt-write admission; checking only in app or only enqueue is insufficient.
- `src_terminal_runtime.rs:481–490`: wrapper currently forwards unguarded queue; preserve one wrapper path rather than alternate protected controller.
- `src_app_api_panes.rs:519–564`: pane.process_info reports cached runtime.shell_pid and scanned foreground job, no birth/pidfd. Extend origin projection from native-owned runtime provenance, not by trusting caller pre-read.

## Closed protected request and origin representation

The existing method extension payload is `{target, text, expected_origin}` with wait omitted. For protected requests target is one canonical terminal ID, resolved by **exact ID-only lookup**, not a ID→pane/name fallback. AgentPrompt's old unguarded product can stay upstream if upstream supports other users, but ACE protected driver must never omit expected_origin or fall back. Pre1.0 ACE has no compatibility branch.

`expected_origin` exactly `{terminal_id, runtime_incarnation, child:{pid,uid,gid,groups,parent_pid,started_at,host}}`. Linux-only initially; child uses the existing ACE ProtectedLinux identity: positive PID/parent PID, nonnegative integer UID/GID, sorted unique nonnegative supplementary groups, `started_at` equal to `linux:<boot UUID>:<proc stat start-time ticks>`, and exact nonempty kernel hostname. terminal_id is the exact opaque native TerminalId emitted by the pinned producer (`term_` followed by 2–48 lowercase hexadecimal characters); it is never parsed as a timestamp/counter or normalized into another identity. runtime_incarnation is a fresh canonical UUID. Unknown fields/types refuse. runtime_incarnation is source-owned unique per spawned actor, never reused on respawn/restoration/handoff. Native captures the same identity from its owned child; ACE compares every field with canonical 09j origin rather than introducing a second identity dialect. Original child is the owned child returned from the exact runtime spawn, not a current foreground descendant or arbitrary same-UID agent. UID/group/native lineage checks remain ACE's canonical origin policy; native owner establishes its own PID/birth provenance and verifies requested values against it.

Native origin projection is a read-only extension of existing pane/process response: immutable runtime_incarnation and original child fields, plus guarded_prompt capability. ACE compares it to existing09j canonical binding under authenticated pinned-server identity; the caller cannot select a different child. Capability unknown/missing refuses before durable issuance. The full ACK must privately include the same origin and native submission outcome; public Assign response retains only its specified mutation identity/evidence reference. Server epoch need not duplicate the existing09j pinned peer/birth+socket identity; native runtime token resets on server restart and ACE separately enforces generation.

At synchronous native spawn, before starting child.wait: read original child identity, open pidfd for that PID, re-read identity and compare, retain pidfd/identity in immutable runtime origin shared with actor. Because child is still owned and not yet reaped by this parent's waiter, PID reuse cannot substitute an unrelated reaped child during capture; inability to establish exact identity fails guarded capability. Gated09j child cannot execute payload before ACE bind/release and supplies actual birth. Generic native startup that exits too soon simply lacks positive guarded capability. No synthetic token replaces kernel birth. After spawn, preserve immutable origin; exec that preserves PID/start-time is same incarnation, a new spawned child always gets a new token. Handoff/import/restoration cannot fabricate provenance from serialized PID; unsupported or unverified transfer refuses guarded prompt. 9c2 forbids old-generation restoration; explicitly retain guarded unsupported behavior for those native paths until proper handle provenance exists.

## Admission and concurrent native lifecycle

1. App event owner selects exact terminal ID once, checks expected immutable runtime/child origin, active supported agent, no pending startup, blocked/refusal state, exact live original pidfd and installed guard capability. Encode via existing native submission encoder; do not enqueue Copilot focus before protected admission. Any required native focus bytes belong to the same guarded actor command, otherwise a rejected guarded prompt could still issue input.
2. Acquire existing actor user-write admission gate. Attach full expected immutable origin to one GuardedSubmission command. A full queue returns a typed definite not_issued result. Pin that exact actor handle, not public pane/name. Closed/quiesced/handoff pending actor refuses. App runtime replacement after this step cannot redirect this command to its new actor.
3. Actor owns its actual PTY FD and immutable spawn-origin handle. At first-write admission, compare expected origin against actor origin, verify accepting state and current original-child pidfd liveness. This check is in the same actor transition that creates active_submission; no later target lookup. If guard differs/dead before transition, drop bytes and return typed not_issued. Native app close/handoff/replacement must close actor admission before detaching and must never repurpose the old actor FD for a new runtime. Existing old-runtime actor command can only target old FD; a replacement receives a fresh actor/origin.
4. Avoid a queue-admission-to-write delay becoming an assumed proof: put guard check immediately before first actual prompt write. Guarded active_submission carries expected origin and immutable actor pin; if actor delays writing, revalidate before first-byte flush. Before Enter and each subsequent partial write, detect origin-handle death/closure and fail remaining input without another target. Those checks bound uncertainty but do not make kernel process exit and write atomic. Once any bytes are written, return only completed or indeterminate, never definite not_issued.
5. Existing actor serializes text and delayed Enter with user-input data; terminal protocol responses remain allowed as existing behavior. Close/shutdown can interrupt submission and records indeterminate if partial input; handoff must refuse/wait while guarded submission active and never migrate a partially submitted command. Do not serialize arbitrary outside app state with a new global controller. Child.wait completion should mark this actor origin no longer accepting guarded input immediately, not wait for delayed PaneDied handling, but pidfd remains authoritative for checks.
6. Successful submission ack occurs after existing full text and Enter write completion, names the captured original origin, and is only `submitted`. ACK loss → canonical uncertain. No native request id dedup is assumed. A canonical identical retry reports existing record and never sends another native command.

The actor admission plus immutable owned FD provides atomic protection against *native runtime retargeting*. It does not promise lock-based serialization with asynchronous kernel death or changing PTY foreground reader. Those stronger properties are outside Captain's selected guarantee; pidfd checks must never be described as atomic recipient delivery.

### Descendant/replacement reader in the same PTY

The native backend `src_pty_backend_unix.rs:34–37` spawns a child on the PTY slave. Descendants can inherit that slave/session, and the actor's original master at `src_pane.rs:2687–2696` remains the same object while those processes use it. Retaining master FD and original child pidfd cannot prove that only the original child reads queued input. The existing foreground-agent check `src_app_agents.rs:427` inspects current agent-kind processes; it does not retain a unique provider/harness process-birth token as queue ownership. Another foreground agent of the same kind in the same PTY can pass it. No9c2 rule examined freezes that process topology: it requires descendants/native creation to remain in scope, not forbids them.

Native pane/runtime replacement before actor admission must refuse. A different
descendant/foreground reader on the same original PTY is outside any exclusive
reader guarantee: Captain selected terminal submission, not provider-PID receipt.
The guard still preserves original spawned-child incarnation and live-handle
checks at admission; it never substitutes a fresh child or native runtime. No
foreground-PID preflight/recheck may be represented as atomic exclusive delivery.

## Typed outcomes required inside existing native owner

Use closed native result/error categories without parsing human messages. Definite refusal `{code:guard_mismatch|origin_unavailable|origin_exited|agent_blocked|agent_not_ready|target_missing|submission_busy, phase:not_issued}` only when owner positively knows no guarded prompt/focus bytes were queued/written. Queue full must have distinct code; existing agent_prompt_failed conflates prequeue and postqueue.

Completion `{type:agent_prompted, origin:<exact immutable guard>, submission:submitted, agent:<sanitized/private normal projection>}` is issued only after existing write completion. Unknown runtime errors, write failure, text-only completion with missing Enter, server loss, channel loss, deadline, guard death after partial write all yield `{code:submission_uncertain,phase:issued_or_unknown}` or no reply; ACE retains uncertain. Future `not_issued` response does not authorize silent same-ID retries; it records definite refusal. New intentional mutation can be authorized separately after current state checks. A method wait/options combination with expected_origin should refuse: protected consumer chooses no wait, and lifecycle/activity waiting is xza/normal observation, not prompt issuance proof.

## Source change owners, bounded test design

Upstream existing schema/response/agents handler, terminal target resolver, native SpawnedPty/PaneRuntime origin, TerminalRuntime wrapper and PTY actor are the owners. Linux incarnation reader should live in existing platform/process module and use maintained existing syscall support; verify dependency before selecting rustix/nix/libc. No new daemon, arbitrary argv broker, controller, raw key primitive or client-selected callback. ACE ProtectedNativeControl adds one fixed guarded_prompt call, matching typed response, one canonical durable driver issuance and bounded transfer body; existing runtime send remains its own standalone consumer. Do not merely attach expected_terminal_id in app while leaving actor unguarded.

Tests to implement after readiness: pure schema rejects unknown/omitted guard and wait; app mismatch rejects before focus/queue; runtime replacement between app capture/queue and actor admission cannot redirect; oldactor/newruntime samepane and samePIDdifferentbirth refuse; actor queued guard mismatch/dead pidfd before firstwrite yields zero; partialtext then exit/error no Enter and uncertain; fulltext+Enter produces exact-origin submitted; app/pane shutdown and handoff timing yields truthful typed result; queuefull distinct definite refusal; stale restored/imported origins refuse; ack lost canonical exactretry sends once; frame/body limits16KiB UTF8/controlescaping; no raw text journal/logs. Real native tests ultimately must prove actual process birth capture, pidfd semantics and FD ownership; unexecuted test design is no installed evidence. Tests here are designed only, not run.

## Delivery gate

N1 covers a coherent native source change across the existing schema/handler,
resolver, spawn-origin owner, TerminalRuntime and actual PTY actor, with executed
producer tests, independent review and an exact build/install selection. An
app-only terminal-ID patch does not satisfy it. N2 consumes that frozen reviewed
protocol and supplies canonical issuance/replay/uncertainty and stop integration.
No implementation must pre-exist for specification readiness. Actual supported
native process/FD and installed distinct-user evidence remain required in gad.2;
controlled tests are not substitutes. No blocked probe is authorized by this
source contract.
