# 8wq.t.34i implementation design (JIT planning record)

The generated plan (`.ace-local/task/8wq.t.34i/8x2zx1-plan.md`) is the skeleton.
This record fixes the decisions where implementation reality required a call,
so review can check intent against outcome. Spec wins over plan where they
conflict.

## Ground truth from the delivered qjx/qjl program

- `Ace::Assign::Organisms::AttemptCoordinator` already owns authoritative
  managed attempts (`service_attempt`, `authoritative_attempt`, journal CAS
  guard) with receipt-validated service requests.
- `Ace::Assign::Molecules::LifecycleExclusion` is the assignment transition
  lock (flock shared/exclusive under the Git common dir).
- `Ace::Lab::Molecules::{ServicePolicy, GrantResolver, CallerAuthorizer,
  ServiceExecutor}` are the trusted-grant authorization backbone
  (`/etc/lab/ace-lab/authorization.yml`, verified traversal, principals with
  per-project visibility).
- Attempt bindings freeze `actor` (execution-boundary identity),
  `assignment_id`, `project_id`; attempts are b36ts compact IDs
  (NOT `A-<24hex>` — that regex belongs to the lab Work/Attempt namespace
  and stays with the Work path).

## Decisions

1. **Boundary = peer-credential UNIX-socket service** (`ace-hitl serve`).
   Every client authenticates by kernel peer credentials (`getpeereid`);
   payload/env identity is never authority. Clients authenticate the
   endpoint: socket must be a socket, owned by the configured service UID,
   not group/world-writable, in a protected directory; the connected peer
   must be the service UID. Store root is service-owned `0711` (traverse
   only); `requests/ answers/ secrets/ effects/ locks/` are `0700`;
   `public/` is `0755` with non-secret `0440` projections. No
   chmod-world-writable workaround anywhere.
2. **Per-connection identity**: the service builds the Store view per peer
   (`Lifecycle::Peer.for_uid` → passwd username, unknown fails closed).
   Store role gates come from the peer, not from `Identity` euid:
   - create: peer is the requester; managed requests always bind-verify
     (admin binding exception removed — spec binds EVERY request).
   - consume/cancel: requester only (root bypass removed).
   - deliver/pending/states/read: configured transport principals
     (grants `hitl.transport_uids` + `principals` project visibility).
3. **Managed binding** = new `AssignmentBinding` calling a narrow
   lock-scoped ace-assign check under `LifecycleExclusion` (assignment
   key). The **Work binding (DaemonBinding) stays** — the spec removes it
   only "when vs2 switches consumers" (vs2 is still open; plan deviation:
   no delete of `daemon_binding.rb` in this task). CLI: `--assignment
   --attempt --project` for managed; `--work --attempt` keeps working.
   `LAB_ATTEMPT_ID` env default is removed (env is never authority).
4. **Lock order** (documented, single direction, review 8x327bun):
   HITL per-request lock file FIRST, then the assignment exclusion
   (shared) inside `with_live_authority!`, then the journal CAS.
   Attempt terminal transitions (`finish`/`reconcile`) take the
   assignment exclusion EXCLUSIVE plus the assign store lock — they
   never take a HITL lock, so the order is acyclic. A liveness check
   holding shared cannot interleave with a terminal commit. Stable
   per-request lock files live in `locks/` and are never unlinked, so
   id reuse cannot land on a fresh inode.
   
   **Terminal receipt retention (review 8x327buj, design)**: receipts
   (`terminals/<id>.json`, service-owned 0600) carry replay answers for
   NON-sensitive kinds only; OTP receipts never hold bytes. Receipts
   are overwritten by the next incarnation of the same id and removed
   with the store; long-term retention pruning is a gad.2 concern.
5. **Idempotent terminals**: every terminal transition writes a
   `terminals/<id>.json` receipt {incarnation, state, correlation, at}
   before/with the projection update. Duplicate deliver/consume/cancel on a
   terminal request returns the committed receipt (idempotent) unless the
   payload conflicts (different incarnation → StateError).
6. **OTP**: challenges are created only with publisher-result evidence
   ({operation, result_ref, input_digest, expires_at}, structurally
   validated, non-secret). Answer bytes are persisted NOWHERE: the service
   holds them in a bounded TTL memory vault bound to the request
   incarnation; `consume --operation <digest>` transfers bytes once over
   the socket and invalidates; expiry/rejection prompts again. OTP
   requests reject effect declarations (the authorized operation consumes
   the OTP transiently; it never runs as a request effect). Vault is a
   seam: file-backed default for direct-library use (0600 service-owned),
   memory vault in the service.
7. **Effects**: the validated argv contract (y21 §5) is unchanged for
   non-secret kinds; dispatch stays inside the delivery lock after
   re-verifying binding liveness. An `effect_authorizer` seam records the
   scope; full named-operation routing through the lab executor is the
   gad.2 acceptance, not a 34i local deliverable (spec: "Full deployed Lab
   transport proof belongs gad.2").
8. **Dependencies**: ace-hitl gains `ace-assign` (narrow coordinator
   check). No ace-lab dependency (herdr maps the ace-hitl delivery
   contract; a future reverse dep must stay possible → cycle avoided).
   ace-lab gains `HitlAuthorizer` (transport check + Captain project
   visibility from its trusted grants) for the lab-side delivery path.
   The grants FILE format is the shared contract; ace-hitl reads it with
   its own verified reader (same traversal rules as lab's GrantResolver).
9. **Multi-UID acceptance** (`test/edge/lifecycle/`): runs for real when
   the suite executes as root (existing unprivileged UIDs: daemon, nobody,
   _www, …) — service under one UID, two requester UIDs, transport UID.
   Without root it reports one explicit skip line (SC1/SC3 note: the
   installed OS-boundary acceptance also joins vs2 + gad.b; local
   non-root unit runs cannot prove it — claimed nowhere).
10. **Store API**: `create` gains `assignment:`; `consume` gains
    `operation:`; `read(id)` (requester, non-secret facts) added;
    `deliver/pending/states` lose the root gate in favor of the policy
    seam. Direct-file use stays for the service process and tests only.

## Concurrency states

created → answer-delivered → consumed | cancelled; one terminal transition
per incarnation wins the lock; losers observe the receipt (idempotent) or a
classified conflict. Transport failures are `Lifecycle::TransportError`
(new), mapped from client-side socket/deadline/parse failures — visible and
recoverable, never silent.
