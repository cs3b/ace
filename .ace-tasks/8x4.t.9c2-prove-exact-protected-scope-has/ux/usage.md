# Exact scope proof — proposed usage, draft

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
