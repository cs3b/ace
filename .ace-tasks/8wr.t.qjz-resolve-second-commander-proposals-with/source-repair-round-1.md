# Independent review repair round 1

Rejected frozen source a2cdb5804 remains historical, never source acceptance.
Independent review8x42r9 and root probes8x42z4/8x42yz verified all four findings.
Feedback8x42z0iq/ir/is/it were shown and verified valid through source feedback CLI.

F1: Hermes retains later same-request replies unresolved behind earlier
nonterminal ingress and replays transient bodies from Telegram. HITL deduplicates
exact sequence/content/time against canonical history; unseen lower sequence
applies and changed duplicate refuses. Applied reply evidence grows only in the
existing qjl event chain, not a new ledger or expanding IPC set. No raw message
bodies enter Hermes metadata.

F2: resolve-due --project is an authenticated proposer wake. The existing HITL
boundary records an idempotent reconciliation marker in canonical evidence;
the existing Hermes serve actor polls and reconciles under transport admission.
Only post-poll coverage/checkpoint permits silence. Proposer never spawns Hermes
or opens private transport configuration. Source tests use a real proposer Unix
socket and distinct transport Peer role dispatch; actual installed cross-UID
policy remains separate acceptance.

F3: root34b22e72a catches visible tick deferral locally and preserves watch/status
and future retries. Maintained tests and full Overseer8x43fs259/1025 green.
Feedback8x42z0is resolved to that scoped root commit.

F4: public creation now requires stable caller-persisted proposal ID. Prepare the
allowed immutable lifecycle request under authoritative attempt validation;
commit it in canonical Assign proposal before creating projection. Failed initial
commit leaves no lifecycle request. Exact retries and existing transport pending
scans recover committed-but-unprojected state. No blind deletion follows uncertain
commit. Same ID changed caller/content/assignment/attempt refuses, including global
owner-layer cross-assignment identity guard. Concurrent materializers use original
create-once atomic commit and protected public projection initialization; mutable
public state never becomes part of immutable request equality or reset on retry.

Executed checkpoints: HITL lifecycle8x43ih113/743; final expanded feature/edge
8x43k2 28/199 green, one existing multi-UID skip; Hermesall8x43is116/659 green;
Overseerall8x43fs259/1025 green. Initial8x43cg was intentionally stopped after a
nested request flock was found; it is incomplete/zero tests despite old runner
exit0. The nested lock was removed and bounded concurrent materialization passes.
8x43gr failed only protected440 public file fixture write; repaired fixture uses
actual AtomicJson. These earlier runs are not acceptance receipts.

Public contract spec/usage changes set needs_review true until independent review.
Source prerequisites and installed sixteen-hour/native/Telegram/multi-UID gates
remain separate. No main mutation, publication, push, merge to main or done claim.
Final affected suites after adopting current reviewed main test runner are pending.
