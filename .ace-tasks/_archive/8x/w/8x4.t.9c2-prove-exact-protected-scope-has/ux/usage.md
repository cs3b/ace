# Exact scope proof — proposed usage, draft

Current network readiness review target:
[network-installation-evidence-amendment.md](../network-installation-evidence-amendment.md).
9c2 is in-progress / needs_review=true for this material amendment; historical
draft prose below does not define current task status.

Developer/agent API and fixed deployment configuration change. No new CLI.
These are proposed acceptance calls through existing Authority::Client; no calls
below are implemented or executable delivered interfaces. See
../scope-owner-proposal.md for schema, owner identity and readiness obligations.
9c2 stays draft / needs_review, with no Captain architecture approval claimed.

## Observe the original child exiting while a writer survives

Goal: a supervisor can inspect the attempt without falsely releasing ownership.
Client.new(mapping_id:) resolves the fixed project and owner; the consumer calls:

```text
operation: observe_execution_scope
mutation_id: null
params: {assignment_id: "assignment", attempt_id: "attempt"}
```

The client injects installed mapping/project identity. No unit, cgroup path,
PID, generation override or transfer/body is accepted. If original gate child
exited but a baseline/native/descendant process remains, response data is:

```text
{attempt_id: "attempt", scope_generation: 7, state: "running",
 proof_id: null, required_action: "close_scope",
 generation: 24, journal_commit: "<immutable canonical commit>"}
```

The read records no journal event and stops nothing. Existing canonical finish/
stop consumers keep ownership until this exact generation has positive closure.
Unauthorized workers/executors/reviewers cannot use this owner visibility.

## Seal, close and consume proof

Goal: close the dedicated worker native scope after result publication/preparation,
then allow existing finish/stop to consume its proof. A recorded launcher or mapped
supervisor calls:

```text
operation: close_execution_scope
mutation_id: "close-attempt"
params: {assignment_id: "assignment", attempt_id: "attempt",
         expected_generation: 24}
```

The first mutation records the immutable seal and its running reply before asking
the existing system manager to stop the fixed Herdr service. Poll observation;
once the scope is empty but lacks a canonical positive event, it reports
unverifiable with required_action close_scope. Make a fresh verification mutation:

```text
operation: close_execution_scope
mutation_id: "verify-close-attempt"
params: {assignment_id: "assignment", attempt_id: "attempt",
         expected_generation: 25}
```

This cannot reopen or reseal the old scope. After exact retained parent scope
revalidation and positive recursive empty observation it records and returns:

```text
{attempt_id: "attempt", scope_generation: 7, state: "closed_no_writers",
 proof_id: "<canonical observation event ID>", required_action: null,
 generation: 26, journal_commit: "<immutable canonical commit>"}
```

Close stops the dedicated worker server and all its scope processes, including
native baseline panes. The long-lived overseer server is separate. Close does not
accept the result, terminalize the attempt, settle service effects or reconcile
inboxes. Existing finish/stop consumers resolve the proof_id through their
canonical owner and exact generation; a caller-supplied proof object never
authorizes terminality. Finish does not itself issue this close/kill operation.

## Restart and continuous reuse

Goal: lost reply or authority restart can recover exact closure without opening
another writer scope. Retry the same close mutation with exactly the same params,
or make the read-only observation above. Same-ID replay returns its original
committed projection, possibly running, rather than rewriting it with a later
proof. Use a fresh close mutation/current generation to finish verification of
an already sealed scope. The authority reconstructs binding/seal,
reopens the same active parent slice and revalidates its InvocationID/object,
manager/native generation and population. A replaced/unreadable/missing original
scope gives unverifiable with proof_id null and inspect_exact_scope, or
evidence_unavailable when inspection cannot proceed. It never uses service
inactive status, original PID absence or cached booleans as positive proof.

Once the old attempt is positively closed and canonically released, the normal
reserve/launch lifecycle automatically starts a fresh server/scope generation
in that same installed slot. No per-attempt reinstall or Captain interaction is
needed. Old proof cannot release the new generation. Ambiguous start is held for
exact inspection without retry-spawning; same-UID unpartitioned parallel attempts
refuse under this proposal. A boot change before committed closure remains
uncertain. Historical terminal replay validates retained canonical proof after
slot reuse rather than adopting a new scope at the old path.

Malformed selector is invalid_input; wrong role/project/incarnation unauthorized;
stale expected generation/occupied slot conflict; unknown attempt missing;
unsupported or unprovable owner/boundary evidence evidence_unavailable.
All failures keep ownership and authorize no effect or cleanup of unrelated slots.

## Settle a request sealed before dispatch

Goal: an installed service executor can close the pre-seal request without gaining
invocation permission. Through the same Authority::Client framing it calls:

```text
operation: claim_service_settlement
mutation_id: "settle-request"
params: {assignment_id: "assignment", attempt_id: "attempt",
         request_id: "request", head: "<recorded-head>",
         candidate_generation: 3, expected_generation: 25}
```

Client injects mapping/project identity. The owner selects the recorded service's
fixed receiver; a worker or supervisor calling instead is unauthorized. A new
recovery claim returns dispatch_phase settlement_only, exact claim_binding and
reconciliation_challenge. It never grants begin/invocation, consumes no new effect
grant and cannot be changed to an effectful phase.

The executor freshly inspects the actual target and handler/process/writer state,
then sends the exact receipt/artifact bytes through complete_no_effect with the
returned claim/challenge and immutable request/head/candidate identity. See
../sealed-service-settlement-contract.md for the exact closed params, evidence
and error contract. Only verified completion reaches failed-settled. A surviving
handler, unknown outcome or missing evidence keeps uncertainty and blocks finish.

A lost recovery reply retries the same mutation without issuing another claim.
A lost begin or final authorization reply does not permit invocation or assert
no effect; preserve the original claim/phase and obtain challenge-bound fresh
reconciliation. The final fresh service_authorization read checks seal. Effects
admitted before seal still settle independently of local scope emptiness.

## Recover provisioning without a genuine child reply

After exact parent binding but lost native readiness or layout reply, use the
same observe_execution_scope/close_execution_scope selectors and two-phase close
as above. The generation names the original parent, even without child binding.
No pane search, new layout or worker release is allowed. Positive recursive
whole-parent cleanup may yield closed_no_writers; independent service/inbox
settlement still precedes canonical release and fresh slot reuse. With no
verifiable original parent binding, evidence_unavailable preserves the held
intent. See ../provisioning-scope-lineage-amendment.md for immutable event schemas
and the future failure/restart/replay verification map.

## Install and replace effective network policy

The existing trusted root installer verifies ordinary Internet/DNS/provider/Git
egress while denying unsolicited ingress and protected host/internal controls.
It publishes protected immutable effective-policy exports and bounded checked
report/trace evidence selected by the fixed boundary manifest. Runtime validates
that authenticated evidence and exact namespace/boot/stage joins; it does not
read privileged firewall state or accept worker uploads as installation proof.

For replacement, persist activation inhibition, stop/drain every old authority
without holding its lifecycle locks, then enter the shared source-owned sorted
slot exclusion. Scan the complete union of original/candidate descriptor roots;
require exact closure, terminal/release and independent service/inbox settlement.
Retire only exactly released empty retained parents through the same scope owner.
Keep inhibition/exclusion through effective verification and atomic publication;
restart fresh authorities only after leaving locks and verifying the complete set.
Failure/reboot retains inhibition and both scan obligations, never cached old
Deployment readiness. Mapping/project/journal ownership of a physical slot is
fixed; a new owner needs a fresh slot/namespace. Normal unchanged-slot attempt
reuse remains automatic.

These are proposed installer/source interfaces for independent review, not
delivered commands or executed installation. See the linked amendment for exact
schemas, error/order/crash semantics and required source/installed test cases.
