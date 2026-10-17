# Protected attempt steering — draft usage

## Send direction once

Specified API (implementation remains to be delivered):
the qk0 consumer calls `prompt_attempt` with control params `{mapping_id, assignment_id, attempt_id,
expected_generation}`, a required `mutation_id`, and one `prompt_text` transfer part with a persisted mutation ID and bounded
text. The owner derives the original target and authorizes the existing mapped
driver. An acknowledgement returns `submitted`, not consumed. Repeating the
exact call returns its immutable finalized result without another send. If that
result is uncertain, a separate authenticated prompt_status query may show later
accepted completion evidence; retry itself never silently upgrades the reply. Changed text with
the same identity is refused.

Captain's 2026-10-07 choice defines the recipient as the immutable original
attempt terminal/runtime, not an exclusive provider-process reader. Replacement
before guarded first-write admission refuses without prompt or focus bytes.
After admission, original-child death or partial/unknown writes return
`uncertain`; the captured actor never retargets or resends. Complete text plus
Enter acknowledged for that origin permits `submitted`, even though another
descendant may read the same original PTY. The native guarded producer source is packaged at the selected reviewed revision;
public N2 steering, retained driver and lost-ACK drain composition remain to be
delivered. These are acceptance scenarios, not currently available public APIs.

## Stop while a descendant or service effect remains uncertain

`stop_attempt(mapping_id, assignment_id, attempt_id, expected_generation,
mutation_id)` records the request and blocks conflicting new dispatch. Closing
the original pane without complete scope-exit proof returns `uncertain` and
required reconciliation. The worktree remains protected; no accepted completion
or prune permission is invented.

## Recover a lost reply

After an issued prompt or stop loses its reply, restart and query the same
canonical mutation. Exact retry never retransmits control. The recorded outcome
remains uncertain until the owner accepts attributable native evidence. A new
attempt generation or substituted target is not a retry of the original action.

## Stop consumes accepted scope closure

stop_attempt sends the exact four params {mapping_id, assignment_id, attempt_id,
expected_generation}, required mutation ID, no body. It delegates sealing/stop
to 9c2 and records uncertain while proof or service/inbox settlement is pending.
A later fresh current-generation call may admit stopped; exact old retry keeps
its original uncertain reply. Slot release follows terminal commit and verified
release-before-reuse. Native pane closure or descendant absence alone cannot
settle independent service/inbox truth.

The target, guarded native method and bounded body framing are specified.
Positive prompt implementation still needs the N2 ACE consumer against reviewed N1 source. The generic CLI
send and ProtectedNativeControl.request are source research, not selected public
protected prompt handlers. No blocked probes are authorized by these examples.


## Retained mapped launch ownership

N2's existing `authority launch` emits and flushes one bounded launch-ready JSON
frame after actual accepted release, then the same foreground original mapped
launcher stays alive in its source-owned control loop. Dry-run and rejected or
replayed launch without original ownership do not attach as the old launcher.
This lifecycle is specified, not implemented by current CLI. qk0's provisioned
launcher-role instance runs the exact installed mapping credentials and owns
that foreground child/readiness stream; arbitrary Captain processes do not gain
that principal. Existing blocking LabClient capture3 cannot consume this stream.

A transient control-channel loss leaves the original driver alive and exposes
disconnected/uncertain status. Reconnect authenticates the same kernel incarnation
and never resends issued prompt text. Cancellation first inhibits dispatch and
uses canonical stop/reconciliation; killing a child or shared native unit is not
proof of stopping an attempt. Lost native ACK requires authentic native drain or
trusted complete affected-scope maintenance recovery. Unrelated work is preserved.
Task source acceptance waits that actual producer/recovery path, not an endless
refusal presented as successful implementation.


## Settlement evidence source checkpoint

The existing Endcap owner can now return complete immutable authenticated service and Inbox settlement evidence at one canonical prefix, including original historical descriptor/key evidence after publication rotation. A verified pending service or signed queued Inbox is distinguished from missing or corrupt evidence; pending work cannot hide another corrupt item. These internal evidence projections do not themselves stop an attempt or change a public reply. Public stopped composition is a separate checkpoint. Fresh challenge-bound no-effect issuance and settlement-only recovery remain unfinished xz9.1/9c2 work, so the projection fixture's injected retained challenge is not a delivered failure recovery API. Installed acceptance remains downstream.
